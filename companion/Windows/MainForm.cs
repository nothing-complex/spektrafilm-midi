using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Net.Sockets;
using System.Text.Json;
using System.Threading;
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
    private readonly Forms.CheckBox autoApply = new() { Text = "Automatic Apply", AutoSize = true };
    private readonly Forms.CheckBox autoConnect = new() { Text = "Connect automatically when opened; retry Tangent Hub if disconnected", AutoSize = true, Checked = true };
    private readonly Forms.CheckBox autoSetup = new() { Text = "Find and bind the armed effect's Apply button automatically", AutoSize = true, Checked = true };
    private readonly Forms.CheckBox autoRoute = new() { Text = "Switch Element panels to Spektrafilm; restore the previous app on pause or exit", AutoSize = true, Checked = true };
    private readonly Forms.Label headline = new() { Dock = Forms.DockStyle.Fill, Font = new Font("Segoe UI", 19, FontStyle.Bold), Text = "Welcome to Spektrafilm MIDI" };
    private readonly Forms.Label nextStep = new() { Dock = Forms.DockStyle.Fill, Text = "Connecting your panels…" };
    private readonly Forms.Label liveSummary = new() { Dock = Forms.DockStyle.Fill };
    private readonly Forms.Button primary = new() { AutoSize = true, MinimumSize = new Size(180, 38), Text = "Connect your panels" };
    private readonly TangentApplicationRouting routing = new();
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
    private bool bindingSearchInProgress;
    private bool routeInProgress;
    private bool routeAttempted;
    private bool routingReady;
    private bool primaryInProgress;
    private bool controlsPaused;
    private bool closing;
    private bool closeReady;
    private int connectionGeneration;
    private CancellationTokenSource? controlRequest;
    private DateTime nextConnectAttempt;
    private DateTime nextBindingSearch;
    private string setupMessage = "Open Spektrafilm MIDI (Community Beta) in Resolve and expand its MIDI controls.";
    private string? controlMessage;
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
    private sealed record Settings(string Adapter, string MidiDevice, MidiEncoding Encoding, int Channel, int OscPort, string Bank, double RelativeSensitivity = 1,
        bool AutoConnect = true, bool AutoSetup = true, bool AutoRoute = true);
    private sealed record FocusItem(string Key, string Label) { public override string ToString() => Label; }
    public MainForm(string profilesPath, MappingProfile profile)
    {
        this.profilesPath = profilesPath;
        Text = "Spektrafilm MIDI — Element Companion";
        Width = 1080; Height = 850; MinimumSize = new Size(900, 700); StartPosition = Forms.FormStartPosition.CenterScreen;
        Font = new Font("Segoe UI", 10);
        plugin = new PluginConnection(); engine = new ControlEngine(plugin.Registry, profile);
        engine.CommandReady += plugin.Send;
        plugin.Status += s => UI(() => { if (s.StartsWith("APPLY:", StringComparison.Ordinal)) lastApplyResult = s; SetStatus(s); }); engine.Status += s => UI(() => SetStatus(s));
        engine.ApplySuggested += () => UI(() => { applyScheduler.Request(DateTime.UtcNow); SetStatus("Edits queued. " + (autoApply.Checked && binding.IsBound ? "Automatic Apply pending." : "Press Apply MIDI in the armed plugin within two seconds.")); });
        engine.DisplaysChanged += () => UI(() => feedbackDirty = true);
        BuildLayout();
        adapter.Items.AddRange(new object[] { "Off", "MIDI", "OSC", "Tangent Hub" }); adapter.SelectedIndex = 3;
        encoding.Items.AddRange(Enum.GetValues<MidiEncoding>().Cast<object>().ToArray()); encoding.SelectedItem = MidiEncoding.RelativeBinaryOffset;
        RefreshDevices(); RefreshBanks(); LoadSettings();
        engine.RelativeSensitivity = (double)relativeSpeed.Value;
        relativeSpeed.ValueChanged += (_, _) => { engine.RelativeSensitivity = (double)relativeSpeed.Value; RefreshInputStatus(); };
        autoApply.CheckedChanged += (_, _) => { feedbackDirty = true; RefreshApplyStatus(); };
        autoSetup.CheckedChanged += (_, _) => { nextBindingSearch = DateTime.MinValue; };
        autoRoute.CheckedChanged += async (_, _) =>
        {
            if (closing) return;
            if (!autoRoute.Checked) { await routing.TryRestoreAsync(); routingReady = false; }
            routeAttempted = false;
        };
        primary.Click += async (_, _) => await PrimaryActionAsync();
        banks.SelectedIndexChanged += (_, _) => { if (!refreshing && banks.SelectedItem is BankDefinition bank) { engine.SelectBank(bank); RefreshView(); } };
        focus.SelectedIndexChanged += (_, _) => { if (!refreshing && focus.SelectedItem is FocusItem item) { engine.FocusedKey = item.Key; feedbackDirty = true; } };
        grid.CellDoubleClick += (_, e) => { if (e.RowIndex >= 0) { engine.Handle(new(InputKind.Reset, e.RowIndex)); } };
        timer.Tick += async (_, _) => await TickAsync(); timer.Start();
        Shown += async (_, _) => { if (autoConnect.Checked && adapter.SelectedItem as string != "Off") await ConnectAsync(); if (!closing) RefreshOverview(); };
        FormClosing += async (_, e) =>
        {
            if (closeReady) return;
            e.Cancel = true;
            if (closing) return;
            closing = true; controlsPaused = true; timer.Stop(); primary.Enabled = false;
            SaveSettings(); ClearLiveControl();
            await routing.TryRestoreAsync();
            closeReady = true; Close();
        };
        FormClosed += (_, _) => { SaveSettings(); timer.Stop(); Disconnect(); plugin.Dispose(); };
    }
    private void BuildLayout()
    {
        var layout = new Forms.TableLayoutPanel { Dock = Forms.DockStyle.Fill, ColumnCount = 1, RowCount = 2, Padding = new Forms.Padding(14) };
        layout.ColumnStyles.Add(new(Forms.SizeType.Percent, 100));
        layout.RowStyles.Add(new(Forms.SizeType.Absolute, 166)); layout.RowStyles.Add(new(Forms.SizeType.Percent, 100));
        var overview = new Forms.TableLayoutPanel { Dock = Forms.DockStyle.Fill, ColumnCount = 2, RowCount = 3, BackColor = Color.FromArgb(242, 246, 250), Padding = new Forms.Padding(12) };
        overview.ColumnStyles.Add(new(Forms.SizeType.Percent, 100)); overview.ColumnStyles.Add(new(Forms.SizeType.AutoSize));
        overview.RowStyles.Add(new(Forms.SizeType.Absolute, 42)); overview.RowStyles.Add(new(Forms.SizeType.Percent, 100)); overview.RowStyles.Add(new(Forms.SizeType.Absolute, 28));
        overview.Controls.Add(headline, 0, 0); overview.Controls.Add(nextStep, 0, 1); overview.Controls.Add(liveSummary, 0, 2);
        overview.Controls.Add(primary, 1, 0); overview.SetRowSpan(primary, 2);
        layout.Controls.Add(overview);
        var tabs = new Forms.TabControl { Dock = Forms.DockStyle.Fill };
        var controlsTab = new Forms.TabPage("Controls") { Padding = new Forms.Padding(8) };
        var advancedTab = new Forms.TabPage("Advanced") { Padding = new Forms.Padding(8), AutoScroll = true };
        tabs.TabPages.AddRange(new[] { controlsTab, advancedTab }); layout.Controls.Add(tabs);
        var basic = new Forms.TableLayoutPanel { Dock = Forms.DockStyle.Fill, ColumnCount = 1, RowCount = 5 };
        basic.ColumnStyles.Add(new(Forms.SizeType.Percent, 100));
        basic.RowStyles.Add(new(Forms.SizeType.Absolute, 44)); basic.RowStyles.Add(new(Forms.SizeType.Absolute, 44));
        basic.RowStyles.Add(new(Forms.SizeType.Absolute, 36)); basic.RowStyles.Add(new(Forms.SizeType.Percent, 100)); basic.RowStyles.Add(new(Forms.SizeType.Absolute, 36));
        var tools = new Forms.FlowLayoutPanel { Dock = Forms.DockStyle.Fill, WrapContents = false };
        tools.Controls.AddRange(new Forms.Control[] { Label("Bank"), banks, Button("‹ Page", () => engine.SelectPage(engine.Page - 1)), Button("Page ›", () => engine.SelectPage(engine.Page + 1)), page });
        basic.Controls.Add(tools);
        var speed = new Forms.FlowLayoutPanel { Dock = Forms.DockStyle.Fill, WrapContents = false };
        speed.Controls.AddRange(new Forms.Control[] { Label("Knob speed ×"), relativeSpeed, Button("Slow", () => relativeSpeed.Value = 0.25m), Button("Normal", () => relativeSpeed.Value = 1), Button("Fast", () => relativeSpeed.Value = 2), Label("Hold Fine on the panel for another 10× slower.") });
        basic.Controls.Add(speed);
        var ringFocus = new Forms.FlowLayoutPanel { Dock = Forms.DockStyle.Fill, WrapContents = false };
        ringFocus.Controls.AddRange(new Forms.Control[] { Label("Mf ring controls"), focus }); basic.Controls.Add(ringFocus);
        foreach (var name in new[] { "Hardware", "Control", "Actual value", "State" }) grid.Columns.Add(name, name);
        grid.AllowUserToResizeRows = false; grid.MultiSelect = false; grid.BackgroundColor = Color.White; grid.BorderStyle = Forms.BorderStyle.None;
        basic.Controls.Add(grid);
        basic.Controls.Add(new Forms.Label { Dock = Forms.DockStyle.Fill, Text = "All 24 Element axes are mapped by bank. Knob presses reset values. Double-click a row to reset it.", Padding = new Forms.Padding(0, 8, 0, 0) });
        controlsTab.Controls.Add(basic);
        var advanced = new Forms.TableLayoutPanel { Dock = Forms.DockStyle.Top, Height = 900, ColumnCount = 1, RowCount = 7 };
        advanced.ColumnStyles.Add(new(Forms.SizeType.Percent, 100));
        advanced.RowStyles.Add(new(Forms.SizeType.Absolute, 100)); advanced.RowStyles.Add(new(Forms.SizeType.Absolute, 110)); advanced.RowStyles.Add(new(Forms.SizeType.Absolute, 145));
        advanced.RowStyles.Add(new(Forms.SizeType.Absolute, 32)); advanced.RowStyles.Add(new(Forms.SizeType.Absolute, 90)); advanced.RowStyles.Add(new(Forms.SizeType.Absolute, 150)); advanced.RowStyles.Add(new(Forms.SizeType.Percent, 100));
        var inputs = new Forms.FlowLayoutPanel { AutoSize = true, Dock = Forms.DockStyle.Fill, WrapContents = true };
        inputs.Controls.AddRange(new Forms.Control[] { Label("Input"), adapter, Button("Reconnect", async () => { controlsPaused = false; await ConnectAsync(); }), Button("Pause", async () => await PauseAsync()), Label("MIDI port"), midiDevices, Button("Refresh ports", RefreshDevices), encoding, Label("Ch (0=all)"), channel, Label("OSC port"), oscPort });
        advanced.Controls.Add(inputs);
        var preferences = new Forms.FlowLayoutPanel { Dock = Forms.DockStyle.Fill, FlowDirection = Forms.FlowDirection.TopDown, WrapContents = false };
        preferences.Controls.AddRange(new Forms.Control[] { autoConnect, autoSetup, autoRoute }); advanced.Controls.Add(preferences);
        var routingGroup = new Forms.GroupBox { Text = "Connection details", Dock = Forms.DockStyle.Fill, Padding = new Forms.Padding(8) };
        var routingRows = new Forms.TableLayoutPanel { Dock = Forms.DockStyle.Fill, RowCount = 4, ColumnCount = 1 };
        routingRows.ColumnStyles.Add(new(Forms.SizeType.Percent, 100));
        routingRows.RowStyles.Add(new(Forms.SizeType.Absolute, 22)); routingRows.RowStyles.Add(new(Forms.SizeType.Absolute, 22)); routingRows.RowStyles.Add(new(Forms.SizeType.Absolute, 22)); routingRows.RowStyles.Add(new(Forms.SizeType.Percent, 100));
        inputStatus.Dock = Forms.DockStyle.Fill;
        routingRows.Controls.Add(inputStatus); routingRows.Controls.Add(hostApplyStatus); routingRows.Controls.Add(movementStatus); routingRows.Controls.Add(routingHint); routingGroup.Controls.Add(routingRows); advanced.Controls.Add(routingGroup);
        advanced.Controls.Add(target);
        var targets = new Forms.GroupBox { Text = "Discovered effects", Dock = Forms.DockStyle.Fill };
        targets.Controls.Add(instances); advanced.Controls.Add(targets);
        var apply = new Forms.FlowLayoutPanel { Dock = Forms.DockStyle.Fill, AutoSize = true };
        apply.Controls.AddRange(new Forms.Control[] { autoApply, Button("Find Apply buttons", FindApply), applyCandidates, Button("Bind selected", BindApply), Button("Clear binding", () => { autoSetup.Checked = false; binding.Clear(); autoApply.Checked = false; SetStatus("Automatic setup disabled. Manual Apply MIDI required."); }), Button("Apply now", ApplyNow), Button("Refresh state", () => engine.Action("refresh")), Button("Disarm", () => engine.Action("disarm")) });
        advanced.Controls.Add(apply);
        var bottom = new Forms.TableLayoutPanel { Dock = Forms.DockStyle.Fill, RowCount = 2, ColumnCount = 1 };
        bottom.ColumnStyles.Add(new(Forms.SizeType.Percent, 100));
        bottom.RowStyles.Add(new(Forms.SizeType.Absolute, 45)); bottom.RowStyles.Add(new(Forms.SizeType.Percent, 100)); bottom.Controls.Add(status); bottom.Controls.Add(log); advanced.Controls.Add(bottom);
        advancedTab.Controls.Add(advanced);
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
        if (IsDisposed || Disposing) return;
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
        if (connecting || closing) return;
        connecting = true;
        ClearLiveControl();
        await routing.TryRestoreAsync();
        if (closing) { connecting = false; return; }
        Disconnect();
        routeAttempted = false; routingReady = false;
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
                    tangent.Disconnected += () => UI(() => { if (tangent != currentTangent) return; ClearLiveControl(); routeAttempted = false; routingReady = false; SetStatus("Tangent connection lost. Reconnecting automatically; click Control this effect again after it returns."); });
                    await tangent.ConnectAsync(); feedbackDirty = true; break;
                default: SetStatus("Controller input is off. Plugin discovery remains active."); break;
            }
        }
        catch (Exception e) when (e is InvalidOperationException or SocketException or IOException or UnauthorizedAccessException or OperationCanceledException or ObjectDisposedException) { Disconnect(); SetStatus("Connection failed: " + e.Message); }
        finally { connecting = false; nextConnectAttempt = DateTime.UtcNow.AddSeconds(5); if (!closing) RefreshOverview(); }
    }
    private void ClearLiveControl()
    {
        connectionGeneration++;
        controlRequest?.Cancel();
        controlMessage = null;
        heldFineNotes.Clear(); engine.Action("fine", false);
        foreach (var t in plugin.Registry.Instances.Where(t => t.Armed)) plugin.Send(t, Wire.Command(t, "DISARM"));
        binding.Clear(); boundIdentity = null; autoApply.Checked = false; applyScheduler.Clear();
    }
    private void Disconnect()
    {
        midi?.Dispose(); midi = null; osc?.Dispose(); osc = null; tangent?.Dispose(); tangent = null;
        inputCount = 0; lastInputUtc = null; lastMovement = null;
        RefreshInputStatus();
        ClearLiveControl();
        lastApplyResult = "No host Apply confirmed.";
    }
    private bool ControllerReady => tangent?.Registered == true || midi != null || osc != null;
    private async Task PauseAsync()
    {
        controlsPaused = true; ClearLiveControl(); RefreshOverview();
        var result = await routing.TryRestoreAsync();
        if (closing) return;
        Disconnect(); routeAttempted = false; routingReady = false;
        SetStatus(result.Message); RefreshOverview();
    }
    private async Task PrimaryActionAsync()
    {
        if (primaryInProgress || closing) return;
        primaryInProgress = true; RefreshOverview();
        try
        {
            if (controlsPaused || !ControllerReady || tangent?.Registered == true && tangent.Diagnostics.ConnectedPanels == 0)
            {
                controlsPaused = false;
                if (adapter.SelectedItem as string == "Off") adapter.SelectedItem = "Tangent Hub";
                await ConnectAsync();
            }
            else if (tangent != null && autoRoute.Checked && !routingReady)
            { routeAttempted = false; await SetupRoutingAsync(); }
            else if (plugin.Registry.ArmedTarget != null && binding.IsBound && autoApply.Checked)
            { await PauseAsync(); }
            else
            {
                connectionGeneration++;
                binding.Clear(); autoApply.Checked = false; applyScheduler.Clear();
                controlRequest?.Cancel(); controlRequest?.Dispose(); controlRequest = new();
                var token = controlRequest.Token;
                var generation = connectionGeneration;
                var targets = plugin.Registry.Instances;
                controlMessage = "Finding the visible effect's MIDI controls…";
                var result = await Task.Run(() => { var success = SafeApplyBinding.ArmVisibleEffect(targets, out var reason, token); return (success, reason); });
                if (closing || controlsPaused || generation != connectionGeneration) return;
                controlMessage = result.reason; setupMessage = result.reason; SetStatus(result.reason); nextBindingSearch = DateTime.MinValue;
            }
        }
        finally { primaryInProgress = false; if (!closing) RefreshOverview(); }
    }
    private async Task SetupRoutingAsync()
    {
        if (routeInProgress || closing || controlsPaused || tangent?.Registered != true || !autoRoute.Checked) return;
        routeInProgress = true; routeAttempted = true;
        var generation = connectionGeneration;
        try
        {
            var result = await routing.TryAcquireAsync();
            if (closing || controlsPaused || generation != connectionGeneration || !autoRoute.Checked) return;
            routingReady = result.Success; setupMessage = result.Message; routingHint.Text = result.Message; SetStatus(result.Message);
        }
        finally { routeInProgress = false; if (!closing) RefreshOverview(); }
    }
    private async Task SetupBindingAsync()
    {
        var active = plugin.Registry.ArmedTarget;
        if (bindingSearchInProgress || primaryInProgress || closing || controlsPaused || connecting || !ControllerReady || !autoSetup.Checked || binding.IsBound || active == null || DateTime.UtcNow < nextBindingSearch) return;
        bindingSearchInProgress = true; nextBindingSearch = DateTime.UtcNow.AddSeconds(1);
        var generation = connectionGeneration;
        try
        {
            var search = await Task.Run(() => SafeApplyBinding.FindAutomaticBinding(active));
            if (closing || controlsPaused || primaryInProgress || generation != connectionGeneration || !autoSetup.Checked || !ControllerReady || binding.IsBound) return;
            var current = plugin.Registry.ArmedTarget;
            var success = binding.TryBindAutomatically(search, current, out var reason);
            boundIdentity = success ? current?.Identity : null;
            autoApply.Checked = success; setupMessage = reason; SetStatus(reason); feedbackDirty = true;
        }
        finally { bindingSearchInProgress = false; if (!closing) RefreshOverview(); }
    }
    private void RefreshOverview()
    {
        var active = plugin.Registry.ArmedTarget;
        var fresh = plugin.Registry.Instances.Count(t => t.Fresh(DateTime.UtcNow));
        var panels = tangent?.Diagnostics.ConnectedPanels ?? 0;
        liveSummary.Text = (ControllerReady ? tangent != null ? "Element connected • " + panels + " panels" : adapter.Text + " connected" : "Panels disconnected")
            + "   |   " + (active == null ? fresh == 0 ? "Waiting for the MIDI effect" : fresh + " MIDI effect" + (fresh == 1 ? " found" : "s found") : "Effect armed")
            + (inputCount > 0 ? "   |   " + inputCount + " inputs received" : "");
        primary.Enabled = !closing && !connecting && !routeInProgress && !primaryInProgress;
        headline.ForeColor = Color.FromArgb(35, 45, 60);
        if (controlsPaused)
        { headline.Text = "Controls paused"; nextStep.Text = "Your previous Tangent application is restored where available. Resume, then choose the MIDI effect to control."; primary.Text = "Resume"; }
        else if (connecting || routeInProgress)
        { headline.Text = "Setting up your panels…"; nextStep.Text = "Connecting to Tangent Hub and assigning the panels to Spektrafilm MIDI."; primary.Text = "Connecting…"; }
        else if (primaryInProgress)
        { headline.Text = "Connecting to your effect…"; nextStep.Text = "Checking the visible effect's MIDI controls in Resolve."; primary.Text = "Connecting…"; }
        else if (!ControllerReady)
        { headline.Text = "Connect your panels"; nextStep.Text = adapter.SelectedItem as string == "Tangent Hub" ? "Plug in your Element panels and make sure Tangent Hub is running. The companion retries every five seconds. MIDI and OSC are available in Advanced." : "Choose your input and device in Advanced, then connect. Make sure your controller is plugged in."; primary.Text = "Connect your panels"; }
        else if (tangent?.Registered == true && panels == 0)
        { headline.Text = "Plug in your Element panels"; nextStep.Text = "Tangent Hub is connected, but no panels are available yet. Plug them in and check that Hub can see them."; primary.Text = "Reconnect panels"; }
        else if (tangent != null && autoRoute.Checked && routeAttempted && !routingReady)
        { headline.Text = "Finish panel setup"; nextStep.Text = "In Tangent Mapper, open Select Application, switch Auto-select Application off and choose Spektrafilm MIDI. Then retry setup. Details are in Advanced."; primary.Text = "Retry panel setup"; }
        else if (active == null)
        { headline.Text = fresh == 0 ? "Open the MIDI effect in Resolve" : "Choose the effect to control"; nextStep.Text = controlMessage ?? "Add Spektrafilm MIDI (Community Beta) to your node, open its controls and expand MIDI. Then click Control this effect. You can also press Arm MIDI in the effect."; primary.Text = "Control this effect"; }
        else if (!binding.IsBound || !autoApply.Checked)
        { headline.Text = "Connecting to your effect…"; nextStep.Text = autoSetup.Checked ? setupMessage : "Automatic setup is disabled in Advanced. Enable it, or bind the visible Apply MIDI button there."; primary.Text = "Control this effect"; }
        else
        { headline.ForeColor = Color.DarkGreen; headline.Text = "Ready — turn a knob"; nextStep.Text = binding.ResolveInForeground ? "The panels control your armed effect. Change banks and pages on the panel or below. Keep the effect's MIDI controls open." : "Return to Resolve to start adjusting. Leave the armed effect's MIDI controls open; the companion can stay in the background."; primary.Text = "Pause controls"; }
    }
    private void ReceiveInput(ControlInput input) => UI(() =>
    {
        if (closing || controlsPaused || connecting || primaryInProgress || tangent?.Registered == true && tangent.Diagnostics.ConnectedPanels == 0) return;
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
        var discovered = plugin.Registry.Instances.Select(t => (t.Fresh(DateTime.UtcNow) ? (t.Armed ? "ARMED  " : "Ready  ") : "Offline  ") + t.Label + "  [" + t.Instance[..Math.Min(8, t.Instance.Length)] + "]  " + (t.Complete ? t.Parameters.Count + " controls" : "waiting for state")).ToArray();
        if (!instances.Items.Cast<string>().SequenceEqual(discovered))
        { instances.BeginUpdate(); instances.Items.Clear(); instances.Items.AddRange(discovered); instances.EndUpdate(); }
        target.Text = active == null ? "No unique, fresh armed target. Press Arm MIDI in the intended effect; automatic selection is disabled." : "Armed: " + active.Label + "  •  " + active.Instance + "  •  revision " + active.Revision;
        if (armedIdentity != boundIdentity && binding.IsBound) { binding.Clear(); autoApply.Checked = false; applyScheduler.Clear(); nextBindingSearch = DateTime.MinValue; SetStatus("Effect changed. Finding its matching MIDI controls."); }
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
        var displays = engine.Displays();
        if (grid.Rows.Count != displays.Count) { grid.Rows.Clear(); foreach (var _ in displays) grid.Rows.Add(); }
        for (var i = 0; i < displays.Count; i++)
        {
            var display = displays[i];
            var values = new[] { HardwareName(display.Index), display.Label, display.Text, display.Available ? display.AtDefault ? "Default" : "Active" : "Unavailable" };
            for (var col = 0; col < values.Length; col++)
                if (!Equals(grid.Rows[i].Cells[col].Value, values[col])) grid.Rows[i].Cells[col].Value = values[col];
        }
        RefreshOverview();
    }
    private static string HardwareName(int axis) => axis is >= 0 and < 12 ? "Kb knob " + (axis + 1)
        : axis is >= 12 and < 21 ? "Tk " + new[] { "ball 1 X", "ball 1 Y", "ring 1", "ball 2 X", "ball 2 Y", "ring 2", "ball 3 X", "ball 3 Y", "ring 3" }[axis - 12]
        : axis is >= 21 and < 24 ? "Mf " + new[] { "ball X", "ball Y", "ring" }[axis - 21] : "Axis " + axis;
    private async Task TickAsync()
    {
        if (closing) return;
        RefreshInputStatus();
        RefreshView();
        RefreshApplyStatus();
        if (!controlsPaused && !connecting && autoConnect.Checked && adapter.SelectedItem as string == "Tangent Hub" && !ControllerReady && DateTime.UtcNow >= nextConnectAttempt)
            await ConnectAsync();
        if (closing) return;
        if (!routeAttempted && autoRoute.Checked) await SetupRoutingAsync();
        if (closing) return;
        await SetupBindingAsync();
        if (closing || controlsPaused || connecting) return;
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
        hostApplyStatus.Text = !automatic ? "Host Apply: waiting for a matching armed effect. Automatic setup finds its visible Apply MIDI button."
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
            routingHint.Text = routingReady ? "Panels assigned to Spektrafilm MIDI. Pause or exit restores the previous Mapper selection."
                : "Mapper > Select Application: Auto-select Application OFF, then Spektrafilm MIDI. Use Retry panel setup after selecting manually.";
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
            autoConnect.Checked = s.AutoConnect; autoSetup.Checked = s.AutoSetup; autoRoute.Checked = s.AutoRoute;
            midiDevices.SelectedItem = midiDevices.Items.Cast<MidiInput.Device>().FirstOrDefault(x => x.Name == s.MidiDevice);
            if (engine.Profile.Banks.FirstOrDefault(b => b.Name == s.Bank) is { } bank) { engine.SelectBank(bank); banks.SelectedItem = bank; }
            // Restore preferences only. An effect still needs explicit user arming each session.
        }
        catch (Exception e) when (e is IOException or JsonException or UnauthorizedAccessException) { SetStatus("Settings were ignored: " + e.Message); }
    }
    private void SaveSettings()
    {
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(settingsPath)!);
            File.WriteAllText(settingsPath, JsonSerializer.Serialize(new Settings(adapter.SelectedItem as string ?? "Tangent Hub", (midiDevices.SelectedItem as MidiInput.Device)?.Name ?? "", (MidiEncoding)encoding.SelectedItem!, (int)channel.Value, (int)oscPort.Value, engine.Bank.Name, (double)relativeSpeed.Value, autoConnect.Checked, autoSetup.Checked, autoRoute.Checked), new JsonSerializerOptions { WriteIndented = true }));
        }
        catch (Exception e) when (e is IOException or UnauthorizedAccessException) { System.Diagnostics.Debug.WriteLine(e); }
    }
}
