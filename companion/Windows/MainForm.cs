using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Net.Sockets;
using System.Text.Json;
using System.Threading.Tasks;
using Forms = System.Windows.Forms;

namespace Spektrafilm.Control.Windows;

public sealed class MainForm : Forms.Form
{
    private readonly PluginConnection plugin;
    private readonly ControlEngine engine;
    private readonly string profilesPath;
    private readonly Forms.ComboBox adapter = new() { DropDownStyle = Forms.ComboBoxStyle.DropDownList, Width = 180 };
    private readonly Forms.ComboBox midiDevices = new() { DropDownStyle = Forms.ComboBoxStyle.DropDownList, Width = 230 };
    private readonly Forms.ComboBox encoding = new() { DropDownStyle = Forms.ComboBoxStyle.DropDownList, Width = 185 };
    private readonly Forms.NumericUpDown channel = new() { Minimum = 0, Maximum = 16, Width = 45 };
    private readonly Forms.NumericUpDown oscPort = new() { Minimum = 1024, Maximum = 65535, Value = 9000, Width = 75 };
    private readonly Forms.NumericUpDown relativeSpeed = new() { Minimum = 0.01m, Maximum = 4, Value = 1, Increment = 0.05m, DecimalPlaces = 2, Width = 80 };
    private readonly Forms.ComboBox banks = new() { DropDownStyle = Forms.ComboBoxStyle.DropDownList, Width = 245 };
    private readonly Forms.ComboBox focus = new() { DropDownStyle = Forms.ComboBoxStyle.DropDownList, Width = 280 };
    private readonly Forms.Label target = new() { AutoSize = true, Text = "No armed target. Add the MIDI effect and press Arm MIDI in its controls." };
    private readonly Forms.Label inputStatus = new() { Dock = Forms.DockStyle.Top, Height = 28, Text = "Controller disconnected. Choose an input and click Connect; keep this companion open." };
    private readonly Forms.Label hostApplyStatus = new() { Dock = Forms.DockStyle.Fill };
    private readonly Forms.Label movementStatus = new() { Dock = Forms.DockStyle.Fill, Text = "Last movement: none. Relative speed affects continuous values; hold Fine for another 10× slower." };
    private readonly Forms.Label routingHint = new() { Dock = Forms.DockStyle.Fill, Text = "For Element: connect Tangent Hub, turn off Auto-select Application in Tangent Mapper, then select Spektrafilm MIDI." };
    private readonly Forms.Label page = new() { AutoSize = true };
    private readonly Forms.Label status = new() { AutoSize = false, Height = 45, Dock = Forms.DockStyle.Fill, Text = "Manual Apply MIDI required. Controller input queues edits; the plugin Apply MIDI button commits them." };
    private readonly Forms.DataGridView grid = new() { Dock = Forms.DockStyle.Fill, AllowUserToAddRows = false, AllowUserToDeleteRows = false, ReadOnly = true, RowHeadersVisible = false, AutoSizeColumnsMode = Forms.DataGridViewAutoSizeColumnsMode.Fill, SelectionMode = Forms.DataGridViewSelectionMode.FullRowSelect };
    private readonly Forms.ListBox instances = new() { Dock = Forms.DockStyle.Fill };
    private readonly Forms.ListBox applyCandidates = new() { Width = 390, Height = 54 };
    private readonly Forms.CheckBox autoApply = new() { Text = "Automatic Apply (explicit binding required)", AutoSize = true };
    private readonly Forms.TextBox log = new() { Dock = Forms.DockStyle.Fill, Multiline = true, ReadOnly = true, ScrollBars = Forms.ScrollBars.Vertical };
    private readonly SafeApplyBinding binding = new();
    private readonly Forms.Timer timer = new() { Interval = 100 };
    private MidiInput? midi;
    private OscInput? osc;
    private TangentConnection? tangent;
    private readonly ApplyScheduler applyScheduler = new();
    private DateTime lastFeedback;
    private bool feedbackDirty = true;
    private bool refreshing;
    private bool connecting;
    private bool feedbackSending;
    private bool applyInProgress;
    private string? focusIdentity;
    private string? catalogIdentity;
    private string? boundIdentity;
    private string? lastStatus;
    private long inputCount;
    private DateTime? lastInputUtc;
    private string? lastMovement;
    private string lastApplyResult = "No host Apply confirmed.";
    private readonly HashSet<int> heldFineNotes = new();
    private readonly string settingsPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "TangentMidi", "Spektrafilm", "companion-v1.json");
    private sealed record Settings(string Adapter, string MidiDevice, MidiEncoding Encoding, int Channel, int OscPort, string Bank, double RelativeSensitivity = 1);
    private sealed record FocusItem(string Key, string Label) { public override string ToString() => Label; }
    public MainForm(string profilesPath, MappingProfile profile)
    {
        this.profilesPath = profilesPath;
        Text = "Spektrafilm MIDI — Element Companion (community feasibility build)";
        Width = 1140; Height = 930; MinimumSize = new Size(900, 760); StartPosition = Forms.FormStartPosition.CenterScreen;
        Font = new Font("Segoe UI", 10);
        plugin = new PluginConnection(); engine = new ControlEngine(plugin.Registry, profile);
        engine.CommandReady += plugin.Send;
        plugin.Status += s => UI(() => { if (s.StartsWith("APPLY:", StringComparison.Ordinal)) lastApplyResult = s; SetStatus(s); }); engine.Status += s => UI(() => SetStatus(s));
        engine.ApplySuggested += () => UI(() => { applyScheduler.Request(DateTime.UtcNow); SetStatus("Edits queued. " + (autoApply.Checked && binding.IsBound ? "Automatic Apply pending." : "Press Apply MIDI in the armed plugin within two seconds.")); });
        engine.DisplaysChanged += () => UI(() => feedbackDirty = true);
        BuildLayout();
        adapter.Items.AddRange(new object[] { "Off", "MIDI", "OSC", "Tangent Hub" }); adapter.SelectedIndex = 0;
        encoding.Items.AddRange(Enum.GetValues<MidiEncoding>().Cast<object>().ToArray()); encoding.SelectedItem = MidiEncoding.RelativeBinaryOffset;
        RefreshDevices(); RefreshBanks(); LoadSettings();
        engine.RelativeSensitivity = (double)relativeSpeed.Value;
        relativeSpeed.ValueChanged += (_, _) => { engine.RelativeSensitivity = (double)relativeSpeed.Value; RefreshInputStatus(); };
        autoApply.CheckedChanged += (_, _) => { feedbackDirty = true; RefreshApplyStatus(); };
        banks.SelectedIndexChanged += (_, _) => { if (!refreshing && banks.SelectedItem is BankDefinition bank) { engine.SelectBank(bank); RefreshView(); } };
        focus.SelectedIndexChanged += (_, _) => { if (!refreshing && focus.SelectedItem is FocusItem item) { engine.FocusedKey = item.Key; feedbackDirty = true; } };
        grid.CellDoubleClick += (_, e) => { if (e.RowIndex >= 0) { engine.Handle(new(InputKind.Reset, e.RowIndex)); } };
        timer.Tick += async (_, _) => await TickAsync(); timer.Start();
        FormClosed += (_, _) => { SaveSettings(); timer.Stop(); Disconnect(); plugin.Dispose(); };
    }
    private void BuildLayout()
    {
        var layout = new Forms.TableLayoutPanel { Dock = Forms.DockStyle.Fill, ColumnCount = 1, RowCount = 8, Padding = new Forms.Padding(10) };
        layout.RowStyles.Add(new(Forms.SizeType.AutoSize)); layout.RowStyles.Add(new(Forms.SizeType.Absolute, 180)); layout.RowStyles.Add(new(Forms.SizeType.AutoSize)); layout.RowStyles.Add(new(Forms.SizeType.AutoSize));
        layout.RowStyles.Add(new(Forms.SizeType.Absolute, 90)); layout.RowStyles.Add(new(Forms.SizeType.Percent, 72)); layout.RowStyles.Add(new(Forms.SizeType.AutoSize)); layout.RowStyles.Add(new(Forms.SizeType.Percent, 28));
        var inputs = new Forms.FlowLayoutPanel { AutoSize = true, Dock = Forms.DockStyle.Fill, WrapContents = true };
        inputs.Controls.AddRange(new Forms.Control[] { Label("Input"), adapter, Button("Connect", async () => await ConnectAsync()), Button("Disconnect", Disconnect), Label("MIDI port"), midiDevices, Button("Refresh ports", RefreshDevices), encoding, Label("Ch (0=all)"), channel, Label("OSC port"), oscPort, Label("Relative speed ×"), relativeSpeed });
        layout.Controls.Add(inputs);
        var routing = new Forms.GroupBox { Text = "Controller routing — verify this before testing the effect", Dock = Forms.DockStyle.Fill, Padding = new Forms.Padding(8) };
        var routingRows = new Forms.TableLayoutPanel { Dock = Forms.DockStyle.Fill, RowCount = 4, ColumnCount = 1 };
        routingRows.RowStyles.Add(new(Forms.SizeType.Absolute, 28)); routingRows.RowStyles.Add(new(Forms.SizeType.Absolute, 28)); routingRows.RowStyles.Add(new(Forms.SizeType.Absolute, 28)); routingRows.RowStyles.Add(new(Forms.SizeType.Percent, 100));
        inputStatus.Dock = Forms.DockStyle.Fill;
        routingRows.Controls.Add(inputStatus); routingRows.Controls.Add(hostApplyStatus); routingRows.Controls.Add(movementStatus); routingRows.Controls.Add(routingHint); routing.Controls.Add(routingRows); layout.Controls.Add(routing);
        var tools = new Forms.FlowLayoutPanel { AutoSize = true, Dock = Forms.DockStyle.Fill };
        tools.Controls.AddRange(new Forms.Control[] { Label("Bank"), banks, Button("‹ Page", () => engine.SelectPage(engine.Page - 1)), Button("Page ›", () => engine.SelectPage(engine.Page + 1)), page, Button("Refresh state", () => engine.Action("refresh")), Button("Disarm", () => engine.Action("disarm")), Button("Apply now", ApplyNow), Label("Mf ring focus"), focus });
        layout.Controls.Add(tools); layout.Controls.Add(target);
        var targets = new Forms.GroupBox { Text = "Discovered instances — arming is performed inside the intended plugin", Dock = Forms.DockStyle.Fill };
        targets.Controls.Add(instances); layout.Controls.Add(targets);
        foreach (var name in new[] { "Hardware", "Control", "Actual value", "State" }) grid.Columns.Add(name, name);
        layout.Controls.Add(grid);
        var apply = new Forms.FlowLayoutPanel { Dock = Forms.DockStyle.Fill, AutoSize = true };
        apply.Controls.AddRange(new Forms.Control[] { autoApply, Button("Find visible Apply buttons", FindApply), applyCandidates, Button("Bind + enable Auto Apply", BindApply), Button("Clear binding", () => { binding.Clear(); autoApply.Checked = false; SetStatus("Manual Apply MIDI required."); }) });
        layout.Controls.Add(apply);
        var bottom = new Forms.TableLayoutPanel { Dock = Forms.DockStyle.Fill, RowCount = 2, ColumnCount = 1 };
        bottom.RowStyles.Add(new(Forms.SizeType.Absolute, 45)); bottom.RowStyles.Add(new(Forms.SizeType.Percent, 100)); bottom.Controls.Add(status); bottom.Controls.Add(log); layout.Controls.Add(bottom);
        Controls.Add(layout);
    }
    private static Forms.Label Label(string text) => new() { Text = text, AutoSize = true, Margin = new Forms.Padding(5, 8, 3, 3) };
    private static Forms.Button Button(string text, Action click)
    {
        var b = new Forms.Button { Text = text, AutoSize = true }; b.Click += (_, _) => click(); return b;
    }
    private void UI(Action action)
    {
        if (IsDisposed || Disposing) return;
        if (!IsHandleCreated) return;
        if (InvokeRequired) { try { BeginInvoke(action); } catch (InvalidOperationException) { } } else action();
    }
    private void SetStatus(string text)
    {
        status.Text = text;
        if (lastStatus == text) return;
        lastStatus = text;
        log.AppendText(DateTime.Now.ToString("HH:mm:ss") + " " + text + Environment.NewLine);
        if (log.TextLength > 40000) log.Text = log.Text[^25000..];
    }
    private void RefreshDevices()
    {
        var old = (midiDevices.SelectedItem as MidiInput.Device)?.Name;
        midiDevices.Items.Clear(); midiDevices.Items.AddRange(MidiInput.Devices().Cast<object>().ToArray());
        var index = midiDevices.Items.Cast<MidiInput.Device>().ToList().FindIndex(d => d.Name == old);
        if (midiDevices.Items.Count > 0) midiDevices.SelectedIndex = Math.Max(index, 0);
    }
    private void RefreshBanks()
    {
        refreshing = true; banks.Items.Clear(); banks.Items.AddRange(engine.Profile.Banks.Cast<object>().ToArray()); banks.SelectedItem = engine.Bank; refreshing = false;
    }
    private async Task ConnectAsync()
    {
        if (connecting) return;
        connecting = true; Disconnect();
        try
        {
            switch (adapter.SelectedItem as string)
            {
                case "MIDI":
                    if (midiDevices.SelectedItem is not MidiInput.Device device) throw new InvalidOperationException("Select a connected MIDI device first.");
                    midi = new MidiInput(device.Id, (MidiEncoding)encoding.SelectedItem!, (int)channel.Value);
                    midi.Input += ReceiveInput; midi.Status += s => UI(() => SetStatus(s));
                    SetStatus("MIDI connected: " + device.Name + ". CC0–23, notes0–23 reset, notes32–68 mapped buttons."); break;
                case "OSC":
                    osc = new OscInput((int)oscPort.Value); osc.Input += ReceiveInput; osc.Status += s => UI(() => SetStatus(s));
                    SetStatus("OSC listening on 127.0.0.1:" + oscPort.Value + ". Native Tangent input is disconnected to avoid duplicate movement."); break;
                case "Tangent Hub":
                    var userPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "TangentMidi", "Spektrafilm", "TangentMaps"); Directory.CreateDirectory(userPath);
                    var currentTangent = tangent = new TangentConnection(engine.Profile, Path.Combine(profilesPath, "tangent"), userPath);
                    tangent.Input += ReceiveInput; tangent.Status += s => UI(() => SetStatus(s)); tangent.FeedbackRequested += () => UI(() => feedbackDirty = true);
                    tangent.Disconnected += () => UI(() => { if (tangent != currentTangent) return; heldFineNotes.Clear(); engine.Action("fine", false); engine.Action("disarm"); binding.Clear(); autoApply.Checked = false; applyScheduler.Clear(); SetStatus("Tangent panel/connection lost; control disarmed. Restore connection, then Arm MIDI again."); });
                    await tangent.ConnectAsync(); feedbackDirty = true; break;
                default: SetStatus("Controller input is off. Plugin discovery remains active."); break;
            }
        }
        catch (Exception e) when (e is InvalidOperationException or SocketException or IOException or UnauthorizedAccessException or OperationCanceledException or ObjectDisposedException) { Disconnect(); SetStatus("Connection failed: " + e.Message); }
        finally { connecting = false; }
    }
    private void Disconnect()
    {
        midi?.Dispose(); midi = null; osc?.Dispose(); osc = null; tangent?.Dispose(); tangent = null;
        inputCount = 0; lastInputUtc = null; lastMovement = null;
        RefreshInputStatus();
        heldFineNotes.Clear(); engine.Action("fine", false);
        // An adapter disconnect invalidates queued movement in the plugin.
        foreach (var t in plugin.Registry.Instances.Where(t => t.Armed)) plugin.Send(t, Wire.Command(t, "DISARM"));
        binding.Clear(); boundIdentity = null; autoApply.Checked = false; applyScheduler.Clear();
        lastApplyResult = "No host Apply confirmed.";
    }
    private void ReceiveInput(ControlInput input) => UI(() =>
    {
        inputCount++; lastInputUtc = DateTime.UtcNow;
        if (input.Kind == InputKind.Relative)
        {
            var label = engine.Displays().FirstOrDefault(d => d.Index == input.Index)?.Label ?? "Unavailable";
            lastMovement = HardwareName(input.Index) + " (" + label + ") • input " + input.Value.ToString("G6", System.Globalization.CultureInfo.InvariantCulture);
        }
        if (input.Action?.StartsWith("midi-note:", StringComparison.Ordinal) == true)
        {
            if (int.TryParse(input.Action[10..], out var note))
            {
                var button = engine.Profile.Buttons.FirstOrDefault(b => b.MidiNote == note);
                if (button != null)
                {
                    var pressed = input.Pressed;
                    if (button.Action == "fine") { if (pressed) heldFineNotes.Add(note); else heldFineNotes.Remove(note); pressed = heldFineNotes.Count > 0; }
                    input = input with { Action = button.Action, Pressed = pressed };
                }
            }
        }
        engine.Handle(input); RefreshView();
    });
    private void RefreshView()
    {
        var active = plugin.Registry.ArmedTarget;
        var rawArmed = plugin.Registry.Instances.Where(t => t.Armed && t.Fresh(DateTime.UtcNow)).Take(2).ToArray();
        var armedIdentity = rawArmed.Length == 1 ? rawArmed[0].Identity : null;
        instances.Items.Clear();
        foreach (var t in plugin.Registry.Instances)
            instances.Items.Add((t.Fresh(DateTime.UtcNow) ? (t.Armed ? "ARMED  " : "Ready  ") : "Offline  ") + t.Label + "  [" + t.Instance[..Math.Min(8, t.Instance.Length)] + "]  " + (t.Complete ? t.Parameters.Count + " controls" : "waiting for state"));
        target.Text = active == null ? "No unique, fresh armed target. Press Arm MIDI in the intended effect; automatic selection is disabled." : "Armed: " + active.Label + "  •  " + active.Instance + "  •  revision " + active.Revision;
        if (armedIdentity != boundIdentity && binding.IsBound) { binding.Clear(); autoApply.Checked = false; applyScheduler.Clear(); SetStatus("Target changed. Apply binding cleared; manual Apply MIDI required."); }
        var availability = active == null ? null : active.Identity + ":" + string.Join(',', active.Parameters.Where(p => p.Value.Available).Select(p => p.Key).OrderBy(x => x));
        if (active != null && catalogIdentity != availability)
        {
            var wasCatalog = engine.Bank.Name == "all-parameters";
            engine.AddCatalogBank();
            if (wasCatalog && engine.Profile.Banks.FirstOrDefault(b => b.Name == "all-parameters") is { } catalog) engine.SelectBank(catalog);
            RefreshBanks(); catalogIdentity = availability;
        }
        if (availability != focusIdentity)
        {
            refreshing = true; focus.Items.Clear();
            if (active != null) focus.Items.AddRange(active.Parameters.Values.Where(p => p.Available).OrderBy(p => p.Label).Select(p => new FocusItem(p.Key, p.Label + (p.Component > 0 ? " [" + p.Component + "]" : ""))).Cast<object>().ToArray());
            focusIdentity = availability; refreshing = false;
        }
        refreshing = true; focus.SelectedItem = focus.Items.Cast<FocusItem>().FirstOrDefault(x => x.Key == engine.FocusedKey); refreshing = false;
        page.Text = "Page " + (engine.Page + 1) + "/" + engine.Bank.Pages.Count + (engine.Fine ? " • Fine" : "");
        grid.Rows.Clear();
        foreach (var display in engine.Displays())
        {
            grid.Rows.Add(HardwareName(display.Index), display.Label, display.Text, display.Available ? display.AtDefault ? "Default" : "Active" : "Unavailable");
        }
    }
    private static string HardwareName(int axis) => axis is >= 0 and < 12 ? "Kb knob " + (axis + 1)
        : axis is >= 12 and < 21 ? "Tk " + new[] { "ball 1 X", "ball 1 Y", "ring 1", "ball 2 X", "ball 2 Y", "ring 2", "ball 3 X", "ball 3 Y", "ring 3" }[axis - 12]
        : axis is >= 21 and < 24 ? "Mf " + new[] { "ball X", "ball Y", "ring" }[axis - 21] : "Axis " + axis;
    private async Task TickAsync()
    {
        RefreshInputStatus();
        RefreshView();
        RefreshApplyStatus();
        var applyNow = DateTime.UtcNow;
        if (applyScheduler.ExpireIfStale(applyNow)) SetStatus("Pending Apply expired while Resolve was unavailable. Turn a control again with Resolve active.");
        if (!applyInProgress && applyScheduler.IsDue(applyNow))
        {
            if (autoApply.Checked)
            {
                var active = plugin.Registry.ArmedTarget;
                var raw = plugin.Registry.Instances.Where(t => t.Armed && t.Fresh(DateTime.UtcNow)).Take(2).ToArray();
                if (active == null && raw.Length == 1 && raw[0].Identity == boundIdentity)
                { SetStatus("Waiting for complete authoritative state before Apply."); }
                else
                {
                    var requestVersion = applyScheduler.RequestVersion;
                    applyInProgress = true;
                    try
                    {
                        var invoked = binding.Invoke(active, out var reason, out var retryable);
                        // UI Automation may pump messages. Preserve input queued
                        // during the host callback for the next dispatch.
                        if (invoked || !retryable) applyScheduler.ClearIfUnchanged(requestVersion);
                        if (invoked) lastApplyResult = "Host button invoked; awaiting confirmation.";
                        if (!binding.IsBound) autoApply.Checked = false;
                        SetStatus(reason);
                    }
                    finally { applyInProgress = false; }
                }
            }
            else applyScheduler.Clear();
        }
        if (feedbackDirty && !feedbackSending && tangent?.Registered == true && DateTime.UtcNow - lastFeedback > TimeSpan.FromMilliseconds(120))
        {
            feedbackDirty = false; feedbackSending = true; lastFeedback = DateTime.UtcNow;
            try
            {
                var active = plugin.Registry.ArmedTarget;
                await tangent.UpdateDisplaysAsync(engine.Displays(), MappingProfile.Id(engine.Bank.Id), engine.Bank.Label + " " + (engine.Page + 1), active == null ? "DISARMED" : binding.IsBound && autoApply.Checked ? "ARMED / AUTO APPLY" : "ARMED / MANUAL APPLY");
            }
            finally { feedbackSending = false; }
        }
    }
    private void RefreshApplyStatus()
    {
        var automatic = autoApply.Checked && binding.IsBound;
        var ready = automatic && binding.ResolveInForeground;
        hostApplyStatus.ForeColor = ready ? Color.DarkGreen : Color.DarkOrange;
        hostApplyStatus.Text = !automatic ? "Host Apply: OFF — edits only queue. Find the Apply button, then Bind + enable Auto Apply."
            : "Host Apply: " + (ready ? "AUTO enabled (Resolve active)" : "AUTO waiting for Resolve foreground") + " • " + lastApplyResult;
    }
    private void ApplyNow()
    {
        if (applyInProgress) { SetStatus("A host Apply is already in progress."); return; }
        if (!binding.IsBound) { SetStatus("Bind the effect's Apply button first, or click Apply MIDI directly in the effect."); return; }
        // This explicit click commits through Resolve's verified host button even
        // while the companion has focus. Automatic input still requires Resolve focus.
        var requestVersion = applyScheduler.RequestVersion;
        applyInProgress = true;
        try
        {
            if (binding.Invoke(plugin.Registry.ArmedTarget, out var reason, out _, allowBackground: true))
                lastApplyResult = "Host button invoked; awaiting confirmation.";
            if (!binding.IsBound) autoApply.Checked = false;
            applyScheduler.ClearIfUnchanged(requestVersion); SetStatus(reason); RefreshApplyStatus();
        }
        finally { applyInProgress = false; }
    }
    private void RefreshInputStatus()
    {
        movementStatus.Text = lastMovement == null ? "Last movement: none. Relative speed affects continuous values; hold Fine for another 10× slower."
            : "Last movement: " + lastMovement + " • relative speed ×" + relativeSpeed.Value.ToString("0.00", System.Globalization.CultureInfo.InvariantCulture);
        if (tangent != null)
        {
            var d = tangent.Diagnostics;
            inputStatus.Text = "Tangent: " + (d.SocketConnected ? "TCP connected" : "disconnected")
                + " • " + (d.RegistrationReady ? "definition sent (protocol " + d.ProtocolRevision + ")" : "waiting for Hub handshake")
                + " • panels " + d.ConnectedPanels + " connected"
                + " • input " + d.InputCount + InputAge(d.LastInputUtc);
            routingHint.Text = "Mapper > Select Application: Auto-select Application OFF, then Spektrafilm MIDI (checkmark). "
                + "Kb should show Film Exp / Print Exp. Turn a knob: the input count must increase to confirm routing.";
        }
        else
        {
            var connected = midi != null || osc != null;
            inputStatus.Text = connected ? (midi != null ? "MIDI connected" : "OSC listening") + " • input " + inputCount + InputAge(lastInputUtc)
                : "Controller disconnected. Choose an input and click Connect; keep this companion open.";
            routingHint.Text = connected ? "Confirm the input count increases, then Arm MIDI in Spektrafilm MIDI (Community Beta). "
                + "Queued edits need the effect's Apply MIDI button, or an explicitly bound Automatic Apply button."
                : "Element: choose Tangent Hub and click Connect. Mapper: Auto-select Application OFF, then Spektrafilm MIDI. "
                + "Arm the MIDI effect in Resolve.";
        }
    }
    private static string InputAge(DateTime? last) => last.HasValue ? " (last " + Math.Max(0, (int)(DateTime.UtcNow - last.Value).TotalSeconds) + "s ago)" : " (none received)";
    private void FindApply()
    {
        try
        {
            applyCandidates.Items.Clear(); applyCandidates.Items.AddRange(SafeApplyBinding.FindCandidates().Cast<object>().ToArray());
            if (applyCandidates.Items.Count > 0) applyCandidates.SelectedIndex = 0;
            SetStatus(applyCandidates.Items.Count == 0 ? "Resolve did not expose a visible InvokePattern Apply MIDI button. Manual Apply MIDI required." : "Select the intended Apply MIDI button, then explicitly bind it. Ownership marker verification is required.");
        }
        catch (Exception e) { SetStatus("UI Automation unavailable: " + e.Message + ". Manual Apply MIDI required."); }
    }
    private void BindApply()
    {
        var active = plugin.Registry.ArmedTarget;
        if (active == null || applyCandidates.SelectedItem is not SafeApplyBinding.Candidate candidate) { SetStatus("Arm the intended effect and find its visible Apply MIDI button first."); return; }
        try
        {
            SetStatus(binding.Bind(candidate, active)); boundIdentity = binding.IsBound ? active.Identity : null;
            autoApply.Checked = binding.IsBound; feedbackDirty = true; RefreshApplyStatus();
        }
        catch (Exception e) { binding.Clear(); SetStatus("Binding failed: " + e.Message + ". Manual Apply MIDI required."); }
    }
    private void LoadSettings()
    {
        try
        {
            if (!File.Exists(settingsPath)) return;
            var s = JsonSerializer.Deserialize<Settings>(File.ReadAllText(settingsPath)); if (s == null) return;
            adapter.SelectedItem = s.Adapter; encoding.SelectedItem = s.Encoding; channel.Value = Math.Clamp(s.Channel, 0, 16); oscPort.Value = Math.Clamp(s.OscPort, 1024, 65535);
            relativeSpeed.Value = double.IsFinite(s.RelativeSensitivity) ? (decimal)Math.Clamp(s.RelativeSensitivity, 0.01, 4) : 1;
            midiDevices.SelectedItem = midiDevices.Items.Cast<MidiInput.Device>().FirstOrDefault(x => x.Name == s.MidiDevice);
            if (engine.Profile.Banks.FirstOrDefault(b => b.Name == s.Bank) is { } bank) { engine.SelectBank(bank); banks.SelectedItem = bank; }
            // Never restore arm state, device connections or UIA bindings automatically.
        }
        catch (Exception e) when (e is IOException or JsonException or UnauthorizedAccessException) { SetStatus("Settings were ignored: " + e.Message); }
    }
    private void SaveSettings()
    {
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(settingsPath)!);
            File.WriteAllText(settingsPath, JsonSerializer.Serialize(new Settings(adapter.SelectedItem as string ?? "Off", (midiDevices.SelectedItem as MidiInput.Device)?.Name ?? "", (MidiEncoding)encoding.SelectedItem!, (int)channel.Value, (int)oscPort.Value, engine.Bank.Name, (double)relativeSpeed.Value), new JsonSerializerOptions { WriteIndented = true }));
        }
        catch (Exception e) when (e is IOException or UnauthorizedAccessException) { System.Diagnostics.Debug.WriteLine(e); }
    }
}
