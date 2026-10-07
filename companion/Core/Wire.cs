using System.Globalization;
using System.Net;
using System.Text;

namespace Spektrafilm.Control;

public static class Wire
{
    public const int Version = 1;
    public const int DiscoveryPort = 55051;
    public static string Escape(string s) => Uri.EscapeDataString(s);
    public static string Unescape(string s)
    {
        for (var i = 0; i < s.Length; i++)
            if (s[i] == '%' && (i + 2 >= s.Length || !Uri.IsHexDigit(s[i + 1]) || !Uri.IsHexDigit(s[i + 2])))
                throw new FormatException("Invalid percent escape");
        return Uri.UnescapeDataString(s);
    }
    public static bool Number(string s, out double n) => double.TryParse(s, NumberStyles.Float, CultureInfo.InvariantCulture, out n) && double.IsFinite(n);
    public static string Number(double n) => n.ToString("R", CultureInfo.InvariantCulture);
    public static string Command(Target target, string operation, params string[] arguments) =>
        string.Join('\t', new[] { operation, "1", Escape(target.Session), Escape(target.Instance), target.Generation.ToString(CultureInfo.InvariantCulture) }.Concat(arguments));
    public static string Key(string id, int component) => id + ":" + component.ToString(CultureInfo.InvariantCulture);
}

public sealed record Parameter(string Id, string Type, int Component, double Minimum, double Maximum,
    double Step, double Default, double Value, bool Available, string Label, string[] Choices)
{
    public string Key => Wire.Key(Id, Component);
    public double Clamp(double value) => Math.Clamp(Type is "int" or "bool" or "choice" ? Math.Round(value, MidpointRounding.AwayFromZero) : value, Minimum, Maximum);
    public string Display => Type == "bool" ? (Value != 0 ? "On" : "Off") : Type == "choice" && Value >= 0 && Value < Choices.Length ? Choices[(int)Value] : Value.ToString("0.####", CultureInfo.InvariantCulture);
}

public sealed record Target(string Session, string Instance, ulong Generation, IPEndPoint Endpoint, bool Armed,
    ulong Revision, string Label, DateTime LastSeen, IReadOnlyDictionary<string, Parameter> Parameters, bool Complete)
{
    public string Identity => Session + "/" + Instance + "/" + Generation;
    public bool Fresh(DateTime now) => now - LastSeen < TimeSpan.FromSeconds(4);
}

/// <summary>Only complete, same-revision snapshots replace the authoritative state.</summary>
public sealed class InstanceRegistry
{
    private readonly object gate = new();
    private readonly Dictionary<string, Target> instances = new();
    private readonly Dictionary<string, Pending> pending = new();
    private sealed record Pending(ulong Revision, int Count, Dictionary<string, Parameter> Values, DateTime Started);
    public event Action? Changed;
    public event Action<Target>? SnapshotNeeded;
    public event Action<string>? Status;
    public IReadOnlyList<Target> Instances { get { lock (gate) return instances.Values.OrderBy(x => x.Label).ToArray(); } }
    public Target? ArmedTarget
    {
        get
        {
            lock (gate)
            {
                var armed = instances.Values.Where(x => x.Armed && x.Fresh(DateTime.UtcNow)).Take(2).ToArray();
                return armed.Length == 1 && armed[0].Complete ? armed[0] : null;
            }
        }
    }
    public bool Receive(ReadOnlySpan<byte> bytes, IPEndPoint source)
    {
        if (!IPAddress.IsLoopback(source.Address) || bytes.Length > 65507) return false;
        try
        {
            var f = new UTF8Encoding(false, true).GetString(bytes).TrimEnd('\n', '\r').Split('\t');
            if (f.Length < 5 || f[1] != "1") return false;
            var session = Wire.Unescape(f[2]); var instance = Wire.Unescape(f[3]);
            if (session.Length is 0 or > 128 || instance.Length is 0 or > 128 || !ulong.TryParse(f[4], out var generation)) return false;
            var key = session + "/" + instance;
            Target? refresh = null;
            lock (gate)
            {
                if (f[0] == "INSTANCE")
                {
                    if (f.Length != 9 || !int.TryParse(f[5], out var port) || port is < 1024 or > 65535 || f[6] is not ("0" or "1") || !ulong.TryParse(f[7], out var revision)) return false;
                    // Advertised listener must be the actual sender; never forward tokens to another service.
                    if (port != source.Port) return false;
                    instances.TryGetValue(key, out var old);
                    var same = old?.Generation == generation && old.Endpoint.Equals(source);
                    if (same && revision < old!.Revision) return false;
                    var changed = !same || old!.Revision != revision || old.Armed != (f[6] == "1");
                    var values = same ? old!.Parameters : new Dictionary<string, Parameter>();
                    var complete = same && old!.Complete && old.Revision == revision;
                    var target = new Target(session, instance, generation, source, f[6] == "1", revision, Wire.Unescape(f[8]), DateTime.UtcNow, values, complete);
                    instances[key] = target;
                    if (!same) pending.Remove(key);
                    if (changed || !complete) refresh = target;
                }
                else
                {
                    if (!instances.TryGetValue(key, out var target) || target.Generation != generation || !target.Endpoint.Equals(source)) return false;
                    if (f[0] == "REMOVED")
                    {
                        if (f.Length != 5) return false;
                        instances.Remove(key); pending.Remove(key);
                    }
                    else if (f[0] is "ACK" or "ERROR")
                    {
                        if (f.Length != 8) return false;
                        Status?.Invoke(f[5] + ": " + f[6] + " " + Wire.Unescape(f[7]));
                        return true;
                    }
                    else if (f.Length < 6 || !ulong.TryParse(f[5], out _) ) return false;
                    else if (ulong.Parse(f[5]) < target.Revision) return false;
                    else if (f[0] == "STATE_BEGIN")
                    {
                        var revision = ulong.Parse(f[5]);
                        if (f.Length != 7 || !int.TryParse(f[6], out var count) || count is < 0 or > 4096) return false;
                        pending[key] = new Pending(revision, count, new(), DateTime.UtcNow);
                    }
                    else if (f[0] == "PARAM")
                    {
                        var revision = ulong.Parse(f[5]);
                        if (f.Length != 17 || !pending.TryGetValue(key, out var state) || state.Revision != revision || state.Values.Count >= state.Count) return false;
                        var id = Wire.Unescape(f[6]); var type = f[7];
                        if (id.Length is 0 or > 256 || type is not ("int" or "bool" or "double" or "choice") || !int.TryParse(f[8], out var component) || component is < 0 or > 3) return false;
                        if (!Wire.Number(f[9], out var min) || !Wire.Number(f[10], out var max) || min > max || !Wire.Number(f[11], out var step) || step <= 0 || !Wire.Number(f[12], out var def) || !Wire.Number(f[13], out var value) || f[14] is not ("0" or "1")) return false;
                        var param = new Parameter(id, type, component, min, max, step, def, value, f[14] == "1", Wire.Unescape(f[15]), Wire.Unescape(f[16]).Split('\n'));
                        if (!state.Values.TryAdd(param.Key, param)) return false;
                    }
                    else if (f[0] == "STATE_END")
                    {
                        var revision = ulong.Parse(f[5]);
                        if (f.Length != 6 || !pending.TryGetValue(key, out var state) || state.Revision != revision || state.Values.Count != state.Count || DateTime.UtcNow - state.Started > TimeSpan.FromSeconds(5)) return false;
                        instances[key] = target with { Revision = revision, Parameters = state.Values, Complete = true };
                        pending.Remove(key);
                    }
                    else return false;
                }
            }
            if (refresh != null) SnapshotNeeded?.Invoke(refresh);
            Changed?.Invoke();
            return true;
        }
        catch (Exception e) when (e is FormatException or DecoderFallbackException or UriFormatException) { return false; }
    }
}
