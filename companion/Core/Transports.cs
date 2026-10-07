using System.Buffers.Binary;
using System.Net;
using System.Net.Sockets;
using System.Text;

namespace Spektrafilm.Control;

public sealed class PluginConnection : IDisposable
{
    private readonly UdpClient socket;
    private readonly CancellationTokenSource cancellation = new();
    private readonly Task reader;
    private readonly Task heartbeat;
    public InstanceRegistry Registry { get; } = new();
    public event Action<string>? Status;
    public PluginConnection(int port = Wire.DiscoveryPort)
    {
        // Exclusive bind prevents two companions from splitting discovery or duplicating input.
        socket = new UdpClient(AddressFamily.InterNetwork);
        socket.Client.ExclusiveAddressUse = true;
        socket.Client.Bind(new IPEndPoint(IPAddress.Loopback, port));
        // A departed OFX broker may produce an ICMP port-unreachable response. On Windows
        // that otherwise surfaces on the next ReceiveAsync and must not kill discovery.
        if (OperatingSystem.IsWindows())
        {
            try { socket.Client.IOControl(unchecked((int)0x9800000C), new byte[4], null); } // SIO_UDP_CONNRESET=false
            catch (SocketException) { } // Receive loop also handles providers without this option.
            catch (PlatformNotSupportedException) { }
        }
        Registry.SnapshotNeeded += t => Send(t, Wire.Command(t, "SNAPSHOT"));
        Registry.Status += s => Status?.Invoke(s);
        reader = ReadAsync(); heartbeat = HeartbeatAsync();
    }
    private async Task ReadAsync()
    {
        try
        {
            while (!cancellation.IsCancellationRequested)
            {
                try
                {
                    var data = await socket.ReceiveAsync(cancellation.Token);
                    Registry.Receive(data.Buffer, data.RemoteEndPoint);
                }
                catch (SocketException e) when (e.SocketErrorCode == SocketError.ConnectionReset && !cancellation.IsCancellationRequested)
                { Status?.Invoke("A plugin endpoint closed; discovery is still listening for new instances."); }
            }
        }
        catch (OperationCanceledException) { }
        catch (ObjectDisposedException) { }
        catch (SocketException e) { if (!cancellation.IsCancellationRequested) Status?.Invoke("Plugin listener: " + e.Message); }
    }
    private async Task HeartbeatAsync()
    {
        try
        {
            using var timer = new PeriodicTimer(TimeSpan.FromMilliseconds(700));
            while (await timer.WaitForNextTickAsync(cancellation.Token))
                foreach (var t in Registry.Instances.Where(t => t.Armed && t.Fresh(DateTime.UtcNow))) Send(t, Wire.Command(t, "SNAPSHOT"));
        }
        catch (OperationCanceledException) { }
    }
    public void Send(Target target, string text)
    {
        if (!target.Fresh(DateTime.UtcNow) || !IPAddress.IsLoopback(target.Endpoint.Address)) return;
        try { socket.Send(Encoding.UTF8.GetBytes(text), target.Endpoint); }
        catch (Exception e) when (e is SocketException or ObjectDisposedException) { Status?.Invoke("Plugin send: " + e.Message); }
    }
    public void Dispose()
    {
        foreach (var t in Registry.Instances.Where(x => x.Armed)) Send(t, Wire.Command(t, "DISARM"));
        cancellation.Cancel(); socket.Dispose(); cancellation.Dispose();
    }
}

public static class OscCodec
{
    private static string ReadString(ReadOnlySpan<byte> packet, ref int offset)
    {
        if (offset >= packet.Length) throw new FormatException("Missing OSC string");
        var length = packet[offset..].IndexOf((byte)0);
        if (length < 0) throw new FormatException("Unterminated OSC string");
        var value = new UTF8Encoding(false, true).GetString(packet.Slice(offset, length));
        var end = offset + length;
        offset = (end + 4) & ~3;
        if (offset > packet.Length) throw new FormatException("Missing OSC padding");
        for (var i = end; i < offset; i++) if (packet[i] != 0) throw new FormatException("Invalid OSC padding");
        return value;
    }
    public static IReadOnlyList<ControlInput> Decode(ReadOnlySpan<byte> packet)
    {
        var inputs = new List<ControlInput>();
        DecodeMessage(packet, inputs, 0);
        return inputs;
    }
    private static void DecodeMessage(ReadOnlySpan<byte> packet, List<ControlInput> inputs, int depth)
    {
        if (depth > 4 || packet.Length > 65507) throw new FormatException("OSC nesting/size limit");
        if (packet.Length >= 8 && packet[..8].SequenceEqual("#bundle\0"u8))
        {
            if (packet.Length < 16) throw new FormatException("Short OSC bundle");
            // Only immediate bundles. Scheduling remote time tags is deliberately unsupported.
            if (BinaryPrimitives.ReadUInt64BigEndian(packet[8..]) is not (0 or 1)) throw new FormatException("Only immediate OSC bundles supported");
            var at = 16;
            while (at < packet.Length)
            {
                if (at + 4 > packet.Length) throw new FormatException("Short OSC bundle member");
                var length = BinaryPrimitives.ReadInt32BigEndian(packet[at..]); at += 4;
                if (length <= 0 || length > packet.Length - at) throw new FormatException("Invalid OSC member length");
                DecodeMessage(packet.Slice(at, length), inputs, depth + 1); at += length;
            }
            return;
        }
        var offset = 0; var address = ReadString(packet, ref offset); var tags = ReadString(packet, ref offset);
        double value;
        if (tags is ",i" or ",f")
        {
            if (packet.Length != offset + 4) throw new FormatException("OSC requires one argument");
            value = tags == ",i" ? BinaryPrimitives.ReadInt32BigEndian(packet[offset..]) : BitConverter.Int32BitsToSingle(BinaryPrimitives.ReadInt32BigEndian(packet[offset..]));
        }
        else if (tags is ",T" or ",F") { if (offset != packet.Length) throw new FormatException("Unexpected OSC data"); value = tags == ",T" ? 1 : 0; }
        else throw new FormatException("Unsupported OSC argument type");
        if (!double.IsFinite(value)) throw new FormatException("Nonfinite OSC value");
        if (address.StartsWith("/spektrafilm/axis/") && int.TryParse(address[18..], out var axis) && axis is >= 0 and < 24) inputs.Add(new(value == 0 ? InputKind.Reset : InputKind.Relative, axis, value));
        else if (address.StartsWith("/spektrafilm/reset/") && int.TryParse(address[19..], out axis) && axis is >= 0 and < 24 && value != 0) inputs.Add(new(InputKind.Reset, axis));
        else if (address.StartsWith("/spektrafilm/action/")) inputs.Add(new(InputKind.Button, 0, Action: address[20..], Pressed: value != 0));
        else if (address.StartsWith("/spektrafilm/bank/")) inputs.Add(new(InputKind.Button, 0, Action: "bank:" + address[18..], Pressed: value != 0));
        else if (address.StartsWith("/spektrafilm/button/") && int.TryParse(address[20..], out var note) && note is >= 0 and < 128) inputs.Add(new(InputKind.Button, note, Action: "midi-note:" + note, Pressed: value != 0));
        else if (address.StartsWith("/1/knob") && int.TryParse(address[7..], out var knob) && knob is >= 1 and <= 24) inputs.Add(new(InputKind.Relative, knob - 1, value));
    }
}

public sealed class OscInput : IDisposable
{
    private readonly UdpClient socket;
    private readonly CancellationTokenSource cancellation = new();
    public event Action<ControlInput>? Input;
    public event Action<string>? Status;
    public OscInput(int port = 9000)
    {
        socket = new UdpClient(new IPEndPoint(IPAddress.Loopback, port));
        _ = ReadAsync();
    }
    private async Task ReadAsync()
    {
        try
        {
            while (!cancellation.IsCancellationRequested)
            {
                var message = await socket.ReceiveAsync(cancellation.Token);
                if (!IPAddress.IsLoopback(message.RemoteEndPoint.Address)) continue;
                try { foreach (var input in OscCodec.Decode(message.Buffer)) Input?.Invoke(input); }
                catch (FormatException e) { Status?.Invoke("Ignored OSC: " + e.Message); }
                catch (DecoderFallbackException) { Status?.Invoke("Ignored invalid OSC UTF-8"); }
            }
        }
        catch (OperationCanceledException) { }
        catch (ObjectDisposedException) { }
        catch (SocketException e) { if (!cancellation.IsCancellationRequested) Status?.Invoke("OSC: " + e.Message); }
    }
    public void Dispose() { cancellation.Cancel(); socket.Dispose(); cancellation.Dispose(); }
}

public enum MidiEncoding { RelativeTwosComplement, RelativeBinaryOffset, RelativeSignMagnitude, Absolute7Bit, Absolute14Bit }
public sealed class MidiDecoder
{
    public MidiEncoding Encoding { get; set; } = MidiEncoding.RelativeBinaryOffset;
    public int Channel { get; set; } // 0 = any, 1..16 = specific
    private readonly Dictionary<(int Channel, int Axis), (int Msb, int Lsb, bool HaveMsb, bool HaveLsb)> pairs = new();
    public IReadOnlyList<ControlInput> Decode(byte status, byte data1, byte data2)
    {
        var result = new List<ControlInput>();
        if (data1 > 127 || data2 > 127 || Channel is < 0 or > 16) return result;
        var channel = (status & 15) + 1;
        if (Channel != 0 && Channel != channel) return result;
        if ((status & 0xF0) == 0xB0)
        {
            if (Encoding == MidiEncoding.Absolute14Bit && (data1 < 24 || data1 is >= 32 and < 56))
            {
                var axis = data1 < 32 ? data1 : data1 - 32;
                var pair = pairs.GetValueOrDefault((channel, axis));
                pair = data1 < 32 ? (data2, pair.Lsb, true, pair.HaveLsb) : (pair.Msb, data2, pair.HaveMsb, true);
                pairs[(channel, axis)] = pair;
                if (pair.HaveMsb && pair.HaveLsb) result.Add(new(InputKind.Absolute, axis, ((pair.Msb << 7) | pair.Lsb) / 16383.0));
            }
            else if (data1 < 24 && Encoding != MidiEncoding.Absolute14Bit)
            {
                if (Encoding == MidiEncoding.Absolute7Bit) result.Add(new(InputKind.Absolute, data1, data2 / 127.0));
                else
                {
                    var delta = Encoding switch
                    {
                        MidiEncoding.RelativeTwosComplement => data2 < 64 ? data2 : data2 - 128,
                        MidiEncoding.RelativeSignMagnitude => data2 < 64 ? data2 : -(data2 - 64),
                        _ => data2 - 64
                    };
                    if (delta != 0) result.Add(new(InputKind.Relative, data1, delta));
                }
            }
        }
        else if ((status & 0xF0) is 0x80 or 0x90)
        {
            var pressed = (status & 0xF0) == 0x90 && data2 > 0;
            if (data1 < 24) { if (pressed) result.Add(new(InputKind.Reset, data1)); }
            else result.Add(new(InputKind.Button, data1, Action: "midi-note:" + data1, Pressed: pressed));
        }
        return result;
    }
    public void Reset() => pairs.Clear();
}

public static class TangentCodec
{
    public static byte[] Frame(ReadOnlySpan<byte> body)
    {
        var result = new byte[body.Length + 4]; BinaryPrimitives.WriteInt32BigEndian(result, body.Length); body.CopyTo(result.AsSpan(4)); return result;
    }
    public static byte[] Command(uint command, params object[] arguments)
    {
        using var memory = new MemoryStream();
        void Integer(uint n) { Span<byte> b = stackalloc byte[4]; BinaryPrimitives.WriteUInt32BigEndian(b, n); memory.Write(b); }
        Integer(command);
        foreach (var value in arguments)
        {
            switch (value)
            {
                case uint n: Integer(n); break;
                case int n: Integer(unchecked((uint)n)); break;
                case float f: Integer(unchecked((uint)BitConverter.SingleToInt32Bits(f))); break;
                case bool b: Integer(b ? 1u : 0u); break;
                case string s: var bytes = Encoding.UTF8.GetBytes(s); Integer((uint)bytes.Length); memory.Write(bytes); break;
                default: throw new ArgumentException("Unsupported Tangent field");
            }
        }
        return Frame(memory.ToArray());
    }
    public static IReadOnlyList<TangentMessage> Decode(ReadOnlySpan<byte> packet)
    {
        var result = new List<TangentMessage>(); var offset = 0;
        while (offset < packet.Length)
        {
            if (packet.Length - offset < 4) throw new FormatException("Short Tangent command");
            var command = BinaryPrimitives.ReadUInt32BigEndian(packet[offset..]); offset += 4;
            if (command == 1)
            {
                Require(packet, offset, 8); var revision = U32(packet, ref offset); var count = U32(packet, ref offset);
                if (count > 64) throw new FormatException("Invalid panel count");
                Require(packet, offset, checked((int)count * 8)); var panels = new List<(uint Type, uint Id)>();
                for (var i = 0; i < count; i++) panels.Add((U32(packet, ref offset), U32(packet, ref offset)));
                result.Add(new(command, revision, 0, panels));
            }
            else if (command is 2 or 5)
            {
                Require(packet, offset, 8); var id = U32(packet, ref offset); var n = U32(packet, ref offset);
                var value = command == 2 ? BitConverter.Int32BitsToSingle(unchecked((int)n)) : unchecked((int)n);
                if (!double.IsFinite(value)) throw new FormatException("Nonfinite Tangent increment");
                result.Add(new(command, id, value));
            }
            else if (command is 3 or 4 or 6 or 7 or 8 or 9 or 11 or 0x34)
            { Require(packet, offset, 4); result.Add(new(command, U32(packet, ref offset), 0)); }
            else if (command == 0x35)
            { Require(packet, offset, 8); result.Add(new(command, U32(packet, ref offset), U32(packet, ref offset))); }
            else if (command == 0x0A)
            { Require(packet, offset, 8); var jog = unchecked((int)U32(packet, ref offset)); var shuttle = unchecked((int)U32(packet, ref offset)); result.Add(new(command, 0, jog, null, shuttle)); }
            else throw new FormatException("Unsupported Tangent command 0x" + command.ToString("X"));
        }
        return result;
    }
    private static uint U32(ReadOnlySpan<byte> packet, ref int offset) { var value = BinaryPrimitives.ReadUInt32BigEndian(packet[offset..]); offset += 4; return value; }
    private static void Require(ReadOnlySpan<byte> packet, int offset, int count) { if (offset + count > packet.Length) throw new FormatException("Short Tangent command data"); }
}
public sealed record TangentMessage(uint Command, uint Id, double Value, IReadOnlyList<(uint Type, uint Id)>? Panels = null, double Shuttle = 0);

public sealed class TangentConnection : IDisposable
{
    private readonly TcpClient socket = new(AddressFamily.InterNetwork);
    private readonly CancellationTokenSource cancellation = new();
    private readonly SemaphoreSlim writeGate = new(1);
    private readonly MappingProfile profile;
    private readonly string systemPath;
    private readonly string userPath;
    private uint lastMode;
    private readonly HashSet<uint> fineButtons = new();
    private readonly Dictionary<uint, bool> panelStates = new();
    private bool pollingPanels;
    public event Action<ControlInput>? Input;
    public event Action? FeedbackRequested;
    public event Action? Disconnected;
    public event Action<string>? Status;
    public bool Connected => socket.Connected && !cancellation.IsCancellationRequested;
    public TangentConnection(MappingProfile profile, string systemPath, string userPath) { this.profile = profile; this.systemPath = systemPath; this.userPath = userPath; }
    public async Task ConnectAsync()
    {
        await socket.ConnectAsync(IPAddress.Loopback, profile.TangentPort, cancellation.Token);
        Status?.Invoke("Tangent connected. Select Spektrafilm MIDI in Tangent Hub/Mapper.");
        _ = ReadAsync();
    }
    private async Task ReadAsync()
    {
        try
        {
            var stream = socket.GetStream(); var header = new byte[4];
            while (!cancellation.IsCancellationRequested)
            {
                await stream.ReadExactlyAsync(header, cancellation.Token);
                var count = BinaryPrimitives.ReadInt32BigEndian(header);
                if (count is < 4 or > 1048576) throw new FormatException("Invalid Tangent frame size");
                var packet = new byte[count]; await stream.ReadExactlyAsync(packet, cancellation.Token);
                foreach (var message in TangentCodec.Decode(packet))
                {
                    if (message.Command == 1)
                    {
                        if (message.Id < 3) throw new FormatException("Tangent protocol revision too old");
                        await Send(TangentCodec.Command(0x81, profile.AppName, systemPath, userPath));
                        if (message.Id >= 4 && !pollingPanels) { pollingPanels = true; _ = PollPanelStatesAsync(); }
                        Status?.Invoke("Tangent Hub protocol " + message.Id + "; configured panels " + (message.Panels?.Count ?? 0));
                        FeedbackRequested?.Invoke();
                    }
                    else if (message.Command is 2 or 3 or 5 or 6)
                    {
                        var axis = profile.Axes.FirstOrDefault(x => MappingProfile.Id(x.Id) == message.Id);
                        if (axis != null) Input?.Invoke(new(message.Command is 3 or 6 ? InputKind.Reset : InputKind.Relative, axis.Index, message.Value));
                    }
                    else if (message.Command is 4 or 7) FeedbackRequested?.Invoke();
                    else if (message.Command is 8 or 11)
                    {
                        var button = profile.Buttons.FirstOrDefault(x => MappingProfile.Id(x.Id) == message.Id);
                        if (button != null)
                        {
                            var pressed = message.Command == 8;
                            if (button.Action == "fine") { if (pressed) fineButtons.Add(message.Id); else fineButtons.Remove(message.Id); pressed = fineButtons.Count > 0; }
                            Input?.Invoke(new(InputKind.Button, 0, Action: button.Action, Pressed: pressed));
                        }
                    }
                    else if (message.Command == 9) Input?.Invoke(new(InputKind.Mode, 0, message.Id));
                    else if (message.Command == 0x0A) Status?.Invoke("Timeline transport unavailable until a Resolve transport route is validated.");
                    else if (message.Command == 0x35)
                    {
                        var connected = message.Value != 0;
                        var known = panelStates.TryGetValue(message.Id, out var previous);
                        panelStates[message.Id] = connected;
                        if (known && previous && !connected) { fineButtons.Clear(); Input?.Invoke(new(InputKind.Button, 0, Action: "fine", Pressed: false)); Disconnected?.Invoke(); }
                        if (!known || previous != connected) { Status?.Invoke("Panel " + message.Id + (connected ? " connected" : known && previous ? " disconnected; live control disarmed" : " not connected")); FeedbackRequested?.Invoke(); }
                    }
                }
            }
        }
        catch (Exception e) when (e is IOException or SocketException or FormatException or OperationCanceledException or ObjectDisposedException)
        { if (!cancellation.IsCancellationRequested) Status?.Invoke("Tangent disconnected: " + e.Message); }
        finally { fineButtons.Clear(); Input?.Invoke(new(InputKind.Button, 0, Action: "fine", Pressed: false)); socket.Close(); Disconnected?.Invoke(); }
    }
    private async Task PollPanelStatesAsync()
    {
        try
        {
            while (Connected)
            {
                await Send(TangentCodec.Command(0xA5));
                await Task.Delay(1000, cancellation.Token);
            }
        }
        catch (Exception e) when (e is OperationCanceledException or IOException or SocketException or ObjectDisposedException)
        { if (!cancellation.IsCancellationRequested) socket.Close(); }
    }
    private async Task Send(byte[] packet)
    {
        if (!Connected) return;
        await writeGate.WaitAsync(cancellation.Token);
        try { await socket.GetStream().WriteAsync(packet, cancellation.Token); }
        finally { writeGate.Release(); }
    }
    public async Task UpdateDisplaysAsync(IReadOnlyList<AxisDisplay> axes, uint mode, string bank, string state)
    {
        if (!Connected) return;
        try
        {
            if (lastMode != mode) { await Send(TangentCodec.Command(0x85, mode)); lastMode = mode; }
            foreach (var axis in axes)
            {
                var label = axis.Available ? axis.Label : "[off] " + axis.Label;
                // Names include textual choices; values remain real numeric host values.
                if (axis.Available && !double.TryParse(axis.Text, System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out _) && axis.Text != "Paired") label += " " + axis.Text;
                await Send(TangentCodec.Command(0xA2, axis.Id, label[..Math.Min(label.Length, 32)]));
                await Send(TangentCodec.Command(0x82, axis.Id, (float)Math.Clamp(axis.Value, -float.MaxValue, float.MaxValue), axis.AtDefault));
            }
            await Send(TangentCodec.Command(0x86, (uint)2, bank[..Math.Min(bank.Length, 32)], false, state[..Math.Min(state.Length, 32)], false));
        }
        catch (Exception e) when (e is IOException or SocketException or OperationCanceledException or ObjectDisposedException)
        { if (!cancellation.IsCancellationRequested) Status?.Invoke("Tangent feedback: " + e.Message); }
    }
    public void Dispose() { cancellation.Cancel(); socket.Dispose(); }
}
