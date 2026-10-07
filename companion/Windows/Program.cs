using System;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading;
using Forms = System.Windows.Forms;

namespace Spektrafilm.Control.Windows;

internal static class Program
{
    [STAThread]
    private static int Main(string[] args)
    {
        try
        {
            var profiles = FindProfiles(args);
            if (args.Contains("--self-test"))
            {
                var profile = MappingProfile.Load(Path.Combine(profiles, "mappings.json"));
                var frames = TangentCodec.Command(0x82, (uint)0x1001, 1.25f, false);
                if (profile.Axes.Count != 24 || frames.Length != 20) throw new InvalidOperationException("Self-test failed");
                File.WriteAllText(Path.Combine(AppContext.BaseDirectory, "self-test-result.txt"), "PASS: 24 axes, profile schema, Tangent frame encoding. Full tests are in companion.tests.\n");
                return 0;
            }
            if (args.Contains("--headless")) return Headless(args, profiles);
            Forms.Application.SetHighDpiMode(Forms.HighDpiMode.PerMonitorV2);
            Forms.Application.EnableVisualStyles();
            Forms.Application.SetCompatibleTextRenderingDefault(false);
            using var form = new MainForm(profiles, MappingProfile.Load(Path.Combine(profiles, "mappings.json")));
            Forms.Application.Run(form); return 0;
        }
        catch (Exception e)
        {
            var error = "Spektrafilm MIDI companion could not start: " + e.Message;
            if (args.Contains("--headless") || args.Contains("--self-test")) { Console.Error.WriteLine(error); return 1; }
            Forms.MessageBox.Show(error, "Spektrafilm MIDI", Forms.MessageBoxButtons.OK, Forms.MessageBoxIcon.Error); return 1;
        }
    }
    private static string FindProfiles(string[] args)
    {
        var supplied = Array.IndexOf(args, "--profiles");
        if (supplied >= 0 && supplied + 1 < args.Length) return Path.GetFullPath(args[supplied + 1]);
        foreach (var start in new[] { AppContext.BaseDirectory, Environment.CurrentDirectory })
        {
            var directory = new DirectoryInfo(start);
            for (var i = 0; directory != null && i < 8; i++, directory = directory.Parent)
            {
                var path = Path.Combine(directory.FullName, "profiles");
                if (File.Exists(Path.Combine(path, "mappings.json"))) return path;
            }
        }
        throw new FileNotFoundException("profiles/mappings.json was not found. Use --profiles PATH.");
    }
    private static int Headless(string[] args, string profiles)
    {
        var outputAt = Array.IndexOf(args, "--output");
        var output = outputAt >= 0 && outputAt + 1 < args.Length ? Path.GetFullPath(args[outputAt + 1]) : Path.Combine(AppContext.BaseDirectory, "headless-log.txt");
        using var writer = new StreamWriter(output, false, new UTF8Encoding(false)) { AutoFlush = true };
        using var connection = new PluginConnection();
        var profile = MappingProfile.Load(Path.Combine(profiles, "mappings.json")); var engine = new ControlEngine(connection.Registry, profile);
        engine.CommandReady += connection.Send;
        connection.Status += s => { lock (writer) writer.WriteLine(s); };
        connection.Registry.Changed += () => { lock (writer) foreach (var t in connection.Registry.Instances) writer.WriteLine($"INSTANCE {t.Instance} armed={t.Armed} complete={t.Complete} revision={t.Revision} rows={t.Parameters.Count}"); };
        using var osc = new OscInput(); osc.Input += input => { lock (engine) engine.Handle(input); };
        var secondsAt = Array.IndexOf(args, "--seconds"); var seconds = secondsAt >= 0 && secondsAt + 1 < args.Length && int.TryParse(args[secondsAt + 1], out var value) ? Math.Clamp(value, 1, 3600) : 30;
        writer.WriteLine("Headless: loopback discovery55051; OSC9000; manual Apply MIDI required.");
        Thread.Sleep(TimeSpan.FromSeconds(seconds)); return 0;
    }
}
