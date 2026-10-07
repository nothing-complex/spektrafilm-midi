using System.Buffers.Binary;
using System.Net;
using System.Net.Sockets;
using System.Text;
using Spektrafilm.Control;

var passed = 0;
void Test(string name, Action run)
{
    try { run(); Console.WriteLine("PASS " + name); passed++; }
    catch (Exception e) { Console.Error.WriteLine("FAIL " + name + ": " + e.Message); Environment.ExitCode = 1; }
}
void Check(bool condition, string message = "Assertion failed") { if (!condition) throw new InvalidOperationException(message); }
var endpoint = new IPEndPoint(IPAddress.Loopback, 55599);
bool Receive(InstanceRegistry registry, string text) => registry.Receive(Encoding.UTF8.GetBytes(text), endpoint);
void Advertise(InstanceRegistry registry, ulong generation = 1, ulong revision = 1, bool armed = true) => Check(Receive(registry, $"INSTANCE\t1\tsession\tinstance\t{generation}\t55599\t{(armed ? 1 : 0)}\t{revision}\tTest%20effect"));
void State(InstanceRegistry registry, double value = 0, ulong generation = 1, ulong revision = 1, string type = "double", int component = 0)
{
    Check(Receive(registry, $"STATE_BEGIN\t1\tsession\tinstance\t{generation}\t{revision}\t1"));
    Check(Receive(registry, $"PARAM\t1\tsession\tinstance\t{generation}\t{revision}\tfilmExposureEv\t{type}\t{component}\t-10\t10\t0.1\t0\t{Wire.Number(value)}\t1\tFilm%20exposure\t"));
    Check(Receive(registry, $"STATE_END\t1\tsession\tinstance\t{generation}\t{revision}"));
}
MappingProfile Profile()
{
    var profile = new MappingProfile();
    for (var i = 0; i < 24; i++) profile.Axes.Add(new AxisDefinition { Index = i, Id = (0x1001 + i).ToString(), Label = "Axis " + i });
    profile.Banks.Add(new BankDefinition { Name = "essentials", Id = "0x2001", Label = "Essentials", Pages = new() { new() { Name = "Main", Slots = Enumerable.Range(0, 24).Select(_ => new SlotDefinition { Parameter = "filmExposureEv", Label = "Exposure" }).ToList() } } });
    return profile;
}
byte[] Osc(string address, float value)
{
    using var stream = new MemoryStream();
    foreach (var s in new[] { address, ",f" }) { var bytes = Encoding.UTF8.GetBytes(s); stream.Write(bytes); stream.WriteByte(0); while (stream.Length % 4 != 0) stream.WriteByte(0); }
    Span<byte> n = stackalloc byte[4]; BinaryPrimitives.WriteInt32BigEndian(n, BitConverter.SingleToInt32Bits(value)); stream.Write(n); return stream.ToArray();
}
async Task<byte[]> TangentFrame(NetworkStream stream)
{
    using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(3));
    var header = new byte[4]; await stream.ReadExactlyAsync(header, timeout.Token);
    var frame = new byte[BinaryPrimitives.ReadInt32BigEndian(header)];
    Check(frame.Length is >= 4 and <= 1048576); await stream.ReadExactlyAsync(frame, timeout.Token); return frame;
}
async Task<byte[]> TangentCommandUntil(NetworkStream stream, uint command)
{
    for (var i = 0; i < 100; i++) { var frame = await TangentFrame(stream); if (BinaryPrimitives.ReadUInt32BigEndian(frame) == command) return frame; }
    throw new InvalidOperationException("Expected Tangent command " + command.ToString("X"));
}
async Task Until(Func<bool> condition)
{
    using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(3));
    while (!condition()) await Task.Delay(10, timeout.Token);
}

Test("Wire UTF8 percent strings, finite numbers and malformed escapes", () =>
{
    const string name = "Halation\tα / %"; Check(Wire.Unescape(Wire.Escape(name)) == name);
    Check(!Wire.Number("NaN", out _) && !Wire.Number("Infinity", out _));
    try { Wire.Unescape("%0x"); throw new InvalidOperationException("Accepted bad escape"); } catch (FormatException) { }
});
Test("Complete snapshots only; stale generation/source and duplicate rows rejected", () =>
{
    var registry = new InstanceRegistry(); Advertise(registry);
    Check(registry.ArmedTarget == null); State(registry, 1.5);
    Check(registry.ArmedTarget!.Parameters["filmExposureEv:0"].Value == 1.5);
    Check(!Receive(registry, "STATE_END\t1\tsession\tinstance\t2\t1"));
    Check(!registry.Receive(Encoding.UTF8.GetBytes("INSTANCE\t1\tx\ty\t1\t55599\t1\t1\tBad"), new IPEndPoint(IPAddress.Parse("192.0.2.1"), 55599)));
    Check(!Receive(registry, "INSTANCE\t1\tx\ty\t1\t55400\t1\t1\tWrong%20port"));
    Check(Receive(registry, "STATE_BEGIN\t1\tsession\tinstance\t1\t2\t2"));
    Check(!Receive(registry, "STATE_END\t1\tsession\tinstance\t1\t2"));
    Check(registry.ArmedTarget!.Parameters["filmExposureEv:0"].Value == 1.5);
    Check(Receive(registry, "REMOVED\t1\tsession\tinstance\t1")); Check(registry.ArmedTarget == null);
});
Test("Generation changes invalidate state and arm targeting is unique", () =>
{
    var registry = new InstanceRegistry(); Advertise(registry); State(registry);
    Advertise(registry, generation: 2); Check(registry.ArmedTarget == null);
    State(registry, generation: 2); Check(registry.ArmedTarget != null);
    Check(Receive(registry, "INSTANCE\t1\tsession\tother\t1\t55599\t1\t1\tOther")); Check(registry.ArmedTarget == null);
});
Test("Relative MIDI formats preserve full magnitude and filter channels", () =>
{
    var decoder = new MidiDecoder { Channel = 2 };
    Check(decoder.Decode(0xB0, 0, 65).Count == 0);
    Check(decoder.Decode(0xB1, 23, 127).Single().Value == 63);
    Check(decoder.Decode(0xB1, 1, 0).Single().Value == -64);
    decoder.Encoding = MidiEncoding.RelativeTwosComplement;
    Check(decoder.Decode(0xB1, 1, 127).Single().Value == -1 && decoder.Decode(0xB1, 1, 64).Single().Value == -64);
    decoder.Encoding = MidiEncoding.RelativeSignMagnitude;
    Check(decoder.Decode(0xB1, 1, 65).Single().Value == -1 && decoder.Decode(0xB1, 1, 64).Count == 0);
    Check(decoder.Decode(0x91, 3, 127).Single().Kind == InputKind.Reset && decoder.Decode(0x91, 3, 0).Count == 0);
    Check(decoder.Decode(0x91, 32, 127).Single().Action == "midi-note:32");
});
Test("14bit MSB/LSB pairs, either order, remain channel isolated", () =>
{
    var decoder = new MidiDecoder { Encoding = MidiEncoding.Absolute14Bit };
    Check(decoder.Decode(0xB0, 32, 127).Count == 0);
    Check(decoder.Decode(0xB1, 0, 127).Count == 0);
    Check(decoder.Decode(0xB0, 0, 127).Single().Value == 1);
    Check(decoder.Decode(0xB1, 32, 0).Single().Value == 16256 / 16383.0);
    decoder.Reset(); Check(decoder.Decode(0xB0, 0, 50).Count == 0);
});
Test("OSC fraction, all24 axes, associated reset, buttons and malformed data", () =>
{
    Check(OscCodec.Decode(Osc("/spektrafilm/axis/23", -0.125f)).Single().Value == -0.125);
    Check(OscCodec.Decode(Osc("/spektrafilm/axis/0", 0)).Single().Kind == InputKind.Reset);
    Check(OscCodec.Decode(Osc("/spektrafilm/reset/9", 1)).Single().Index == 9);
    Check(OscCodec.Decode(Osc("/spektrafilm/button/32", 1)).Single().Action == "midi-note:32");
    try { OscCodec.Decode(Osc("/spektrafilm/axis/0", float.NaN)); throw new InvalidOperationException("Accepted NaN"); } catch (FormatException) { }
    try { OscCodec.Decode(new byte[] { 47, 97 }); throw new InvalidOperationException("Accepted unterminated message"); } catch (FormatException) { }
});
Test("Tangent BE framing, bool size, fractional increments and reset", () =>
{
    var packet = TangentCodec.Command(0x82, (uint)0x1001, 1.25f, true);
    Check(packet.Length == 20 && BinaryPrimitives.ReadInt32BigEndian(packet) == 16 && BinaryPrimitives.ReadUInt32BigEndian(packet.AsSpan(16)) == 1);
    var display = TangentCodec.Command(0x86, (uint)1, "Test", false);
    Check(display.Length == 24 && BinaryPrimitives.ReadUInt32BigEndian(display.AsSpan(20)) == 0);
    var input = TangentCodec.Command(2, (uint)0x100C, -0.5f);
    var event1 = TangentCodec.Decode(input.AsSpan(4)).Single(); Check(event1.Id == 0x100C && event1.Value == -0.5);
    var reset = TangentCodec.Decode(TangentCodec.Command(3, (uint)0x1203).AsSpan(4)).Single(); Check(reset.Command == 3);
    try { TangentCodec.Decode(new byte[] { 0, 0, 0, 2 }); throw new InvalidOperationException("Accepted truncated Tangent command"); } catch (FormatException) { }
});
Test("Mapping actual units, simultaneous axes and reset commands", () =>
{
    var registry = new InstanceRegistry(); Advertise(registry); State(registry);
    var engine = new ControlEngine(registry, Profile()); var commands = new List<string>(); engine.CommandReady += (_, text) => commands.Add(text);
    engine.Handle(new(InputKind.Relative, 0, 0.25)); engine.Handle(new(InputKind.Relative, 23, -2)); engine.Handle(new(InputKind.Reset, 12));
    Check(commands.Count == 3 && commands[0].EndsWith("\t0.025") && commands[1].EndsWith("\t-0.2") && commands[2].StartsWith("RESET\t1"));
    Advertise(registry, generation: 2); engine.Handle(new(InputKind.Relative, 0, 1)); Check(commands.Count == 3);
});
Test("Absolute soft takeover relatches after external host changes", () =>
{
    var registry = new InstanceRegistry(); Advertise(registry); State(registry);
    var engine = new ControlEngine(registry, Profile()); var commands = new List<string>(); engine.CommandReady += (_, text) => commands.Add(text);
    engine.Handle(new(InputKind.Absolute, 0, 0)); Check(commands.Count == 0);
    engine.Handle(new(InputKind.Absolute, 0, 0.51)); Check(commands.Count == 1);
    State(registry, 0.2, revision: 2); engine.Handle(new(InputKind.Absolute, 0, 0.6)); Check(commands.Count == 2);
    State(registry, -6, revision: 3); engine.Handle(new(InputKind.Absolute, 0, 0.7)); Check(commands.Count == 2, "External state change did not require pickup");
    engine.Handle(new(InputKind.Absolute, 0, 0.1)); Check(commands.Count == 3);
});
Test("Unavailable primary uses an actual fallback and all schema parameters get pages", () =>
{
    var registry = new InstanceRegistry(); Advertise(registry); State(registry);
    var profile = Profile(); profile.Banks[0].Pages[0].Slots[0] = new() { Parameter = "missing", Label = "Unavailable", Fallbacks = new() { new() { Parameter = "filmExposureEv", Label = "Fallback" } } };
    var engine = new ControlEngine(registry, profile); Check(engine.Displays()[0].Label == "Fallback");
    engine.AddCatalogBank(); Check(profile.Banks.Single(b => b.Name == "all-parameters").Pages.Single().Slots.Single().Parameter == "filmExposureEv");
});
Test("Concurrent relative bursts preserve movement across all24 axes", () =>
{
    var registry = new InstanceRegistry(); Advertise(registry); State(registry);
    var engine = new ControlEngine(registry, Profile()); var sum = 0.0; var count = 0;
    engine.CommandReady += (_, text) => { Check(text.StartsWith("DELTA\t1")); Check(Wire.Number(text.Split('\t')[^1], out var value)); sum += value; count++; };
    for (var eventIndex = 0; eventIndex < 100; eventIndex++) for (var axis = 0; axis < 24; axis++) engine.Handle(new(InputKind.Relative, axis, 0.125));
    Check(count == 2400 && Math.Abs(sum - 30) < 1e-9);
});
Test("Scanner and print diffusion page toggle their own stage", () =>
{
    var registry = new InstanceRegistry(); Advertise(registry);
    Check(Receive(registry, "STATE_BEGIN\t1\tsession\tinstance\t1\t1\t3"));
    foreach (var id in new[] { "cameraDiffusionEnabled", "printDiffusionEnabled", "scannerEnabled" })
        Check(Receive(registry, $"PARAM\t1\tsession\tinstance\t1\t1\t{id}\tbool\t0\t0\t1\t1\t0\t0\t1\t{id}\t"));
    Check(Receive(registry, "STATE_END\t1\tsession\tinstance\t1\t1"));
    var profile = Profile(); var engine = new ControlEngine(registry, profile); var commands = new List<string>(); engine.CommandReady += (_, text) => commands.Add(text);
    var diffusion = new BankDefinition { Name = "diffusion", Id = "0x2007", Pages = new() { new() { StageParameter = "cameraDiffusionEnabled" }, new() { StageParameter = "printDiffusionEnabled" } } };
    engine.SelectBank(diffusion); engine.Action("toggle:stage"); engine.SelectPage(1); engine.Action("toggle:stage");
    engine.SelectBank(new BankDefinition { Name = "scanner", Id = "0x2008", Pages = new() { new() { StageParameter = "scannerEnabled" } } }); engine.Action("toggle:stage");
    Check(commands[0].Contains("\tcameraDiffusionEnabled\t0\t1") && commands[1].Contains("\tprintDiffusionEnabled\t0\t1") && commands[2].Contains("\tscannerEnabled\t0\t1"));
});
Test("Compound printer feedback and reset preserve neutral/chroma semantics", () =>
{
    var registry = new InstanceRegistry(); Advertise(registry);
    Check(Receive(registry, "STATE_BEGIN\t1\tsession\tinstance\t1\t1\t3"));
    foreach (var (id, value) in new[] { ("printerLightR", 3), ("printerLightG", 2), ("printerLightB", 1) })
        Check(Receive(registry, $"PARAM\t1\tsession\tinstance\t1\t1\t{id}\tdouble\t0\t-24\t24\t0.1\t0\t{value}\t1\t{id}\t"));
    Check(Receive(registry, "STATE_END\t1\tsession\tinstance\t1\t1"));
    var profile = Profile(); var terms = new List<TermDefinition> { new() { Parameter = "printerLightR", Scale = 1 }, new() { Parameter = "printerLightG", Scale = 0 }, new() { Parameter = "printerLightB", Scale = -1 } };
    profile.Banks[0].Pages[0].Slots[0] = new() { Operation = "printer-x", Reset = "printer-chroma", Terms = terms };
    profile.Banks[0].Pages[0].Slots[1] = new() { Operation = "printer-neutral", Reset = "printer-neutral", Terms = terms };
    var engine = new ControlEngine(registry, profile); var values = new List<double>();
    engine.CommandReady += (_, text) => { Check(Wire.Number(text.Split('\t')[^1], out var value)); values.Add(value); };
    Check(engine.Displays()[0].Value == 1 && engine.Displays()[1].Value == 2);
    engine.Handle(new(InputKind.Reset, 0)); Check(values.SequenceEqual(new[] { 2.0, 2, 2 })); values.Clear();
    engine.Handle(new(InputKind.Reset, 1)); Check(values.SequenceEqual(new[] { 1.0, 0, -1 }));
});
Test("Real loopback UDP discovery requests snapshot from its exclusive bound socket", () =>
{
    using var connection = new PluginConnection(55053); using var source = new UdpClient(new IPEndPoint(IPAddress.Loopback, 0)); source.Client.ReceiveTimeout = 2500;
    var sourcePort = ((IPEndPoint)source.Client.LocalEndPoint!).Port;
    source.Send(Encoding.UTF8.GetBytes($"INSTANCE\t1\ts\ti\t1\t{sourcePort}\t1\t1\tIntegration"), new IPEndPoint(IPAddress.Loopback, 55053));
    var from = new IPEndPoint(IPAddress.Any, 0); var response = Encoding.UTF8.GetString(source.Receive(ref from));
    Check(from.Port == 55053 && response == "SNAPSHOT\t1\ts\ti\t1");
});
Test("Continuous5ms input dispatches throughout20seconds rather than waiting for silence", () =>
{
    var scheduler = new ApplyScheduler(); var start = new DateTime(2026, 10, 7, 0, 0, 0, DateTimeKind.Utc);
    var dispatches = new List<int>();
    for (var milliseconds = 0; milliseconds <= 20000; milliseconds += 5)
    {
        var now = start.AddMilliseconds(milliseconds); scheduler.Request(now);
        if (milliseconds % 100 == 0 && scheduler.TryTakeDue(now)) dispatches.Add(milliseconds);
    }
    Check(dispatches.Count == 200 && dispatches[0] == 100 && dispatches[^1] == 20000);
    Check(dispatches.Zip(dispatches.Skip(1), (a, b) => b - a).All(gap => gap == 100), "Continuous input postponed an existing deadline");
});
Test("Incomplete snapshot keeps earliest Apply deadline; disconnect clears pending work", () =>
{
    var scheduler = new ApplyScheduler(); var start = new DateTime(2026, 10, 7, 0, 0, 0, DateTimeKind.Utc);
    scheduler.Request(start); var due = scheduler.DueUtc;
    Check(!scheduler.TryTakeDue(start.AddMilliseconds(100), ready: false));
    scheduler.Request(start.AddMilliseconds(500));
    Check(scheduler.DueUtc == due && scheduler.TryTakeDue(start.AddMilliseconds(500), ready: true));
    Check(!scheduler.Pending && !scheduler.TryTakeDue(start.AddSeconds(1)));
    scheduler.Request(start.AddSeconds(2)); scheduler.Clear();
    Check(!scheduler.TryTakeDue(start.AddSeconds(3)));
});
Test("Discovery survives plugin endpoint teardown and receives a new broker", () =>
{
    using var connection = new PluginConnection(55054);
    using (var first = new UdpClient(new IPEndPoint(IPAddress.Loopback, 0)))
    {
        first.Client.ReceiveTimeout = 2500; var port = ((IPEndPoint)first.Client.LocalEndPoint!).Port;
        first.Send(Encoding.UTF8.GetBytes($"INSTANCE\t1\toldSession\toldInstance\t1\t{port}\t1\t1\tOld"), new IPEndPoint(IPAddress.Loopback, 55054));
        var from = new IPEndPoint(IPAddress.Any, 0); Check(Encoding.UTF8.GetString(first.Receive(ref from)).StartsWith("SNAPSHOT\t1\toldSession"));
    }
    // At least one heartbeat hits the departed UDP endpoint and can provoke Windows ICMP/ConnectionReset.
    Thread.Sleep(1100);
    using var replacement = new UdpClient(new IPEndPoint(IPAddress.Loopback, 0)); replacement.Client.ReceiveTimeout = 2500;
    var replacementPort = ((IPEndPoint)replacement.Client.LocalEndPoint!).Port;
    replacement.Send(Encoding.UTF8.GetBytes($"INSTANCE\t1\tnewSession\tnewInstance\t1\t{replacementPort}\t0\t1\tReplacement"), new IPEndPoint(IPAddress.Loopback, 55054));
    var replyFrom = new IPEndPoint(IPAddress.Any, 0); var reply = Encoding.UTF8.GetString(replacement.Receive(ref replyFrom));
    Check(replyFrom.Port == 55054 && reply == "SNAPSHOT\t1\tnewSession\tnewInstance\t1");
    Check(connection.Registry.Instances.Any(t => t.Session == "newSession"));
});
Test("Tangent handshake gates feedback and diagnostics distinguish socket, definition and real input", () =>
{
    async Task Run()
    {
        using var server = new TcpListener(IPAddress.Loopback, 0); server.Start();
        var profile = Profile(); profile.TangentPort = ((IPEndPoint)server.LocalEndpoint).Port;
        profile.Buttons.Add(new() { Id = "0x3001", Action = "fine", Label = "Fine" });
        using var connection = new TangentConnection(profile, Path.GetTempPath(), Path.GetTempPath());
        var statuses = new System.Collections.Concurrent.ConcurrentQueue<string>(); connection.Status += statuses.Enqueue;
        var received = new System.Collections.Concurrent.ConcurrentQueue<ControlInput>(); connection.Input += received.Enqueue;
        await connection.ConnectAsync(); using var peer = await server.AcceptTcpClientAsync(); var stream = peer.GetStream();
        Check(connection.Diagnostics.SocketConnected && !connection.Diagnostics.RegistrationReady && !connection.Registered);
        await connection.UpdateDisplaysAsync(Array.Empty<AxisDisplay>(), 0x2001, "Essentials", "DISARMED");
        await Task.Delay(60); Check(!stream.DataAvailable, "Feedback was sent before InitiateComms/ApplicationDefinition");
        await stream.WriteAsync(TangentCodec.Command(1, 4u, 2u, 0u, 10u, 1u, 11u));
        var definition = await TangentFrame(stream);
        Check(definition.SequenceEqual(TangentCodec.Command(0x81, profile.AppName, Path.GetTempPath(), Path.GetTempPath()).AsSpan(4).ToArray()), "First response was not the application definition");
        await Until(() => connection.Registered);
        Check(connection.Diagnostics.ProtocolRevision == 4 && connection.Diagnostics.ConfiguredPanels == 2 && connection.Diagnostics.ConnectedPanels == 0 && connection.Diagnostics.InputCount == 0);
        await stream.WriteAsync(TangentCodec.Command(0x35, 10u, true));
        await stream.WriteAsync(TangentCodec.Command(0x35, 11u, false));
        await Until(() => connection.Diagnostics.ConnectedPanels == 1);
        Check(connection.Diagnostics.InputCount == 0 && connection.Diagnostics.LastInputUtc == null, "Connection reports were counted as hardware input");
        await stream.WriteAsync(TangentCodec.Command(2, 0x1001u, 0.25f));
        await stream.WriteAsync(TangentCodec.Command(8, 0x3001u));
        await Until(() => connection.Diagnostics.InputCount == 2);
        Check(connection.Diagnostics.LastInputUtc is DateTime last && DateTime.UtcNow - last < TimeSpan.FromSeconds(3));
        Check(received.Any(input => input.Kind == InputKind.Relative && input.Value == 0.25));
        Check(statuses.Any(status => status.Contains("disable Auto-select Application")), "Missing panel ownership guidance");
        peer.Close(); await Until(() => !connection.Diagnostics.SocketConnected);
        Check(!connection.Registered && !connection.Diagnostics.RegistrationReady && connection.Diagnostics.ConnectedPanels == 0);
        Check(connection.Diagnostics.InputCount == 2, "Disconnect cleanup was counted as hardware input");
    }
    Run().GetAwaiter().GetResult();
});
Test("Tangent re-initiation sends definition before feedback and resends the unchanged current mode", () =>
{
    async Task Run()
    {
        using var server = new TcpListener(IPAddress.Loopback, 0); server.Start();
        var profile = Profile(); profile.TangentPort = ((IPEndPoint)server.LocalEndpoint).Port;
        using var connection = new TangentConnection(profile, Path.GetTempPath(), Path.GetTempPath());
        var refreshes = 0; connection.FeedbackRequested += () => Interlocked.Increment(ref refreshes);
        await connection.ConnectAsync(); using var peer = await server.AcceptTcpClientAsync(); var stream = peer.GetStream();
        await stream.WriteAsync(TangentCodec.Command(1, 3u, 0u));
        await TangentCommandUntil(stream, 0x81); await Until(() => Volatile.Read(ref refreshes) == 1);
        await connection.UpdateDisplaysAsync(Array.Empty<AxisDisplay>(), 0x2003, "Print", "DISARMED");
        var firstMode = await TangentCommandUntil(stream, 0x85); Check(BinaryPrimitives.ReadUInt32BigEndian(firstMode.AsSpan(4)) == 0x2003);
        await TangentCommandUntil(stream, 0x86);
        await stream.WriteAsync(TangentCodec.Command(1, 3u, 0u));
        var secondDefinition = await TangentFrame(stream); Check(BinaryPrimitives.ReadUInt32BigEndian(secondDefinition) == 0x81);
        await Until(() => Volatile.Read(ref refreshes) == 2);
        await connection.UpdateDisplaysAsync(Array.Empty<AxisDisplay>(), 0x2003, "Print", "DISARMED");
        var repeatedMode = await TangentCommandUntil(stream, 0x85); Check(BinaryPrimitives.ReadUInt32BigEndian(repeatedMode.AsSpan(4)) == 0x2003);
    }
    Run().GetAwaiter().GetResult();
});
var profilePath = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../profiles/mappings.json"));
if (File.Exists(profilePath)) Test("Real full Element mapping parses and uses all24 unique axes", () =>
{
    var profile = MappingProfile.Load(profilePath);
    Check(profile.Axes.Count == 24 && profile.Buttons.Count == 37);
    Check(profile.Banks.All(b => b.Pages.All(p => p.Slots.Count == 24)));
});
Console.WriteLine($"{passed} tests passed; exit={Environment.ExitCode}");
