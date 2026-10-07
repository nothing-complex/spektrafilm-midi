using System.Text.Json;

namespace Spektrafilm.Control;

public sealed class MappingProfile
{
    public int SchemaVersion { get; set; } = 1;
    public string AppName { get; set; } = "Spektrafilm MIDI";
    public int TangentPort { get; set; } = 64246;
    public List<AxisDefinition> Axes { get; set; } = new();
    public List<BankDefinition> Banks { get; set; } = new();
    public List<ButtonDefinition> Buttons { get; set; } = new();
    public static MappingProfile Load(string path)
    {
        var result = JsonSerializer.Deserialize<MappingProfile>(File.ReadAllText(path), new JsonSerializerOptions { PropertyNameCaseInsensitive = true }) ?? throw new InvalidDataException("Empty mapping");
        if (result.SchemaVersion != 1 || result.Axes.Count != 24 || result.Axes.Select(x => x.Index).Distinct().Count() != 24 || result.Axes.Any(x => x.Index is < 0 or > 23) || result.Banks.Count == 0) throw new InvalidDataException("Unsupported/incomplete mapping profile");
        return result;
    }
    public static uint Id(string id) => id.StartsWith("0x", StringComparison.OrdinalIgnoreCase) ? Convert.ToUInt32(id[2..], 16) : uint.Parse(id, System.Globalization.CultureInfo.InvariantCulture);
}
public sealed class AxisDefinition { public string Id { get; set; } = "0"; public int Index { get; set; } public string Label { get; set; } = ""; }
public sealed class ButtonDefinition { public string Id { get; set; } = "0"; public string Action { get; set; } = ""; public string Label { get; set; } = ""; public int? MidiNote { get; set; } }
public sealed class BankDefinition { public string Id { get; set; } = "0"; public string Name { get; set; } = ""; public string Label { get; set; } = ""; public List<PageDefinition> Pages { get; set; } = new(); public override string ToString() => Label; }
public sealed class PageDefinition { public string Name { get; set; } = ""; public string? StageParameter { get; set; } public List<SlotDefinition> Slots { get; set; } = new(); }
public sealed class SlotDefinition
{
    public string? Parameter { get; set; }
    public int Component { get; set; }
    public string Label { get; set; } = "";
    public double? Step { get; set; }
    public string? Operation { get; set; }
    public string? Reset { get; set; }
    public List<SlotDefinition> Fallbacks { get; set; } = new();
    public List<TermDefinition> Terms { get; set; } = new();
}
public sealed class TermDefinition { public string Parameter { get; set; } = ""; public int Component { get; set; } public double Scale { get; set; } = 1; }
public sealed record AxisDisplay(int Index, uint Id, string Label, string Text, double Value, bool AtDefault, bool Available);
public enum InputKind { Relative, Absolute, Reset, Button, Mode }
public sealed record ControlInput(InputKind Kind, int Index, double Value = 0, string? Action = null, bool Pressed = true);

public sealed class ControlEngine
{
    private readonly InstanceRegistry registry;
    private readonly object engineGate = new();
    private double relativeSensitivity = 1;
    public MappingProfile Profile { get; }
    public BankDefinition Bank { get; private set; }
    public int Page { get; private set; }
    public bool Fine { get; private set; }
    public double RelativeSensitivity
    {
        get { lock (engineGate) return relativeSensitivity; }
        set
        {
            if (!double.IsFinite(value) || value is < 0.01 or > 4) throw new ArgumentOutOfRangeException(nameof(value), "Relative sensitivity must be between 0.01 and 4.");
            lock (engineGate) relativeSensitivity = value;
        }
    }
    public string? FocusedKey { get; set; }
    private string? lastIdentity;
    private readonly Dictionary<int, double> previousAbsolute = new();
    private readonly HashSet<int> latched = new();
    private readonly Dictionary<string, double> discreteRemainders = new();
    private readonly Dictionary<string, Dictionary<string, double>> comparisons = new();
    private string nextComparison = "A";
    private readonly Dictionary<string, double> confirmedValues = new();
    private readonly Dictionary<int, (string Key, double Value)> expectedAbsolute = new();
    public event Action<Target, string>? CommandReady;
    public event Action? ApplySuggested;
    public event Action? DisplaysChanged;
    public event Action<string>? Status;
    public ControlEngine(InstanceRegistry registry, MappingProfile profile)
    {
        this.registry = registry; Profile = profile; Bank = profile.Banks[0];
        registry.Changed += () => { lock (engineGate) { RefreshTarget(); ReconcileAuthoritativeState(); DisplaysChanged?.Invoke(); } };
    }
    private void RefreshTarget()
    {
        var armed = registry.Instances.Where(t => t.Armed && t.Fresh(DateTime.UtcNow)).Take(2).ToArray();
        var identity = armed.Length == 1 ? armed[0].Identity : null;
        if (lastIdentity == identity) return;
        lastIdentity = identity; previousAbsolute.Clear(); latched.Clear(); discreteRemainders.Clear(); comparisons.Clear(); expectedAbsolute.Clear(); confirmedValues.Clear(); Fine = false;
        FocusedKey = registry.ArmedTarget?.Parameters.Values.FirstOrDefault(x => x.Id == "filmExposureEv" && x.Available)?.Key;
    }
    private void ReconcileAuthoritativeState()
    {
        var target = registry.ArmedTarget;
        if (target == null) return;
        foreach (var value in target.Parameters)
        {
            if (confirmedValues.TryGetValue(value.Key, out var old) && Math.Abs(old - value.Value.Value) > 1e-9)
                foreach (var axis in latched.ToArray())
                    if (!expectedAbsolute.TryGetValue(axis, out var expected) || expected.Key == value.Key && Math.Abs(expected.Value - value.Value.Value) > 1e-7)
                    { latched.Remove(axis); previousAbsolute.Remove(axis); expectedAbsolute.Remove(axis); }
            confirmedValues[value.Key] = value.Value.Value;
        }
    }
    public void SelectBank(BankDefinition bank)
    { lock (engineGate) SelectBankCore(bank); }
    private void SelectBankCore(BankDefinition bank)
    {
        Bank = bank; Page = 0; previousAbsolute.Clear(); latched.Clear(); discreteRemainders.Clear(); expectedAbsolute.Clear(); Fine = false; DisplaysChanged?.Invoke();
    }
    public void SelectPage(int page)
    { lock (engineGate) SelectPageCore(page); }
    private void SelectPageCore(int page)
    {
        if (Bank.Pages.Count == 0) return;
        Page = (page % Bank.Pages.Count + Bank.Pages.Count) % Bank.Pages.Count;
        previousAbsolute.Clear(); latched.Clear(); discreteRemainders.Clear(); expectedAbsolute.Clear(); Fine = false; DisplaysChanged?.Invoke();
    }
    public void AddCatalogBank()
    { lock (engineGate) AddCatalogBankCore(); }
    private void AddCatalogBankCore()
    {
        var target = registry.ArmedTarget;
        if (target == null) return;
        var existing = Profile.Banks.FirstOrDefault(x => x.Name == "all-parameters");
        if (existing != null) Profile.Banks.Remove(existing);
        var values = target.Parameters.Values.Where(x => x.Available).OrderBy(x => x.Label).ThenBy(x => x.Component).ToArray();
        var bank = new BankDefinition { Id = "0x20FF", Name = "all-parameters", Label = "All available parameters" };
        for (var n = 0; n < values.Length; n += 24)
            bank.Pages.Add(new PageDefinition { Name = "Parameters " + (n / 24 + 1), Slots = values.Skip(n).Take(24).Select(x => new SlotDefinition { Parameter = x.Id, Component = x.Component, Label = x.Label }).ToList() });
        if (bank.Pages.Count > 0) Profile.Banks.Add(bank);
    }
    private SlotDefinition? Slot(int axis)
    {
        if (axis is < 0 or > 23 || Page >= Bank.Pages.Count) return null;
        var slots = Bank.Pages[Page].Slots;
        if (axis >= slots.Count) return null;
        var slot = slots[axis];
        if (slot.Operation == "focused" && FocusedKey != null && registry.ArmedTarget?.Parameters.TryGetValue(FocusedKey, out var focused) == true)
            return new SlotDefinition { Parameter = focused.Id, Component = focused.Component, Label = focused.Label };
        var target = registry.ArmedTarget;
        bool Works(SlotDefinition candidate) => target != null && (ParameterFor(target, candidate) != null || candidate.Terms.Count > 0 && candidate.Terms.All(t => target.Parameters.TryGetValue(Wire.Key(t.Parameter, t.Component), out var p) && p.Available));
        return Works(slot) ? slot : slot.Fallbacks.FirstOrDefault(Works) ?? slot;
    }
    private static Parameter? ParameterFor(Target target, SlotDefinition slot) => slot.Parameter != null && target.Parameters.TryGetValue(Wire.Key(slot.Parameter, slot.Component), out var p) && p.Available ? p : null;
    public IReadOnlyList<AxisDisplay> Displays()
    { lock (engineGate) return DisplaysCore(); }
    private IReadOnlyList<AxisDisplay> DisplaysCore()
    {
        var target = registry.ArmedTarget;
        return Profile.Axes.OrderBy(x => x.Index).Select(axis =>
        {
            var slot = Slot(axis.Index);
            var p = target != null && slot != null ? ParameterFor(target, slot) : null;
            var compound = target != null && slot?.Terms.Count > 0 && slot.Terms.All(t => target.Parameters.TryGetValue(Wire.Key(t.Parameter, t.Component), out var term) && term.Available);
            var label = slot?.Label ?? axis.Label;
            var compoundValue = 0.0;
            if (compound && slot != null)
            {
                var channels = slot.Terms.Select(t => target!.Parameters[Wire.Key(t.Parameter, t.Component)].Value).ToArray();
                if (channels.Length == 3) compoundValue = slot.Operation switch { "printer-x" => (channels[0] - channels[2]) / 2, "printer-y" => (2 * channels[1] - channels[0] - channels[2]) / 3, _ => channels.Average() };
            }
            var text = p?.Display ?? (compound ? compoundValue.ToString("0.####", System.Globalization.CultureInfo.InvariantCulture) : "Inactive");
            return new AxisDisplay(axis.Index, MappingProfile.Id(axis.Id), label, text, p?.Value ?? compoundValue, p != null ? Math.Abs(p.Value - p.Default) < 1e-8 : compound && Math.Abs(compoundValue) < 1e-8, p != null || compound);
        }).ToArray();
    }
    private void Send(Target t, string op, params string[] args) => CommandReady?.Invoke(t, Wire.Command(t, op, args));
    public void Handle(ControlInput input)
    { lock (engineGate) HandleCore(input); }
    private void HandleCore(ControlInput input)
    {
        if (!double.IsFinite(input.Value)) return;
        if (input.Kind == InputKind.Button) { Action(input.Action ?? "", input.Pressed); return; }
        if (input.Kind == InputKind.Mode)
        {
            var b = Profile.Banks.FirstOrDefault(b => MappingProfile.Id(b.Id) == (uint)input.Value);
            if (b != null) SelectBank(b);
            return;
        }
        RefreshTarget();
        ReconcileAuthoritativeState();
        var target = registry.ArmedTarget;
        if (target == null) { Status?.Invoke("No unique, fresh armed target. Use Arm MIDI on the intended effect."); return; }
        var slot = Slot(input.Index);
        if (slot == null) return;
        var p = ParameterFor(target, slot);
        if (slot.Terms.Count > 0)
        {
            if (input.Kind == InputKind.Absolute) { Status?.Invoke("Compound axes require relative input."); return; }
            if (slot.Operation?.StartsWith("printer-", StringComparison.Ordinal) == true &&
                (target.Parameters.TryGetValue("printerLightsGang:0", out var gang) && gang.Value != 0 || target.Parameters.TryGetValue("printerLightsGroup:0", out var group) && group.Value != 0))
            { Status?.Invoke("Disable printer gang/group before using opponent printer axes."); return; }
            var terms = slot.Terms.Select(t => (Term: t, Param: target.Parameters.GetValueOrDefault(Wire.Key(t.Parameter, t.Component)))).ToArray();
            if (terms.Any(x => x.Param == null || !x.Param.Available)) return;
            if (input.Kind == InputKind.Reset)
            {
                if (slot.Reset is "printer-chroma" or "printer-neutral")
                {
                    var mean = terms.Average(t => t.Param!.Value);
                    var neutral = 0.0;
                    if (slot.Reset == "printer-neutral")
                    {
                        var low = terms.Max(t => t.Param!.Minimum - (t.Param.Value - mean));
                        var high = terms.Min(t => t.Param!.Maximum - (t.Param.Value - mean));
                        neutral = Math.Clamp(0, low, high);
                    }
                    foreach (var term in terms)
                    {
                        var value = slot.Reset == "printer-chroma" ? mean : term.Param!.Value - mean + neutral;
                        Send(target, "SET", Wire.Escape(term.Param!.Id), term.Param.Component.ToString(), Wire.Number(term.Param.Clamp(value)));
                    }
                }
                else foreach (var term in terms) Send(target, "RESET", Wire.Escape(term.Param!.Id), term.Param.Component.ToString());
            }
            else
            {
                // Scale all channels together at a boundary to preserve the intended direction.
                var movement = input.Value * (Fine ? 0.1 : 1);
                double Change(TermDefinition term, Parameter parameter) => movement * (slot.Step ?? parameter.Step) * term.Scale * (parameter.Type == "double" ? relativeSensitivity : 1);
                var scale = 1.0;
                foreach (var term in terms)
                {
                    var change = Change(term.Term, term.Param!);
                    if (change > 0) scale = Math.Min(scale, (term.Param!.Maximum - term.Param.Value) / change);
                    else if (change < 0) scale = Math.Min(scale, (term.Param!.Minimum - term.Param.Value) / change);
                }
                foreach (var term in terms)
                    Send(target, "DELTA", Wire.Escape(term.Param!.Id), term.Param.Component.ToString(), Wire.Number(Change(term.Term, term.Param) * Math.Max(0, scale)));
            }
            ApplySuggested?.Invoke(); return;
        }
        if (p == null) { Status?.Invoke((slot.Label.Length > 0 ? slot.Label : "Control") + " unavailable in this mode."); return; }
        FocusedKey = p.Key;
        if (input.Kind == InputKind.Reset) Send(target, "RESET", Wire.Escape(p.Id), p.Component.ToString());
        else if (input.Kind == InputKind.Absolute)
        {
            var normalized = Math.Clamp(input.Value, 0, 1);
            var current = p.Maximum > p.Minimum ? (p.Value - p.Minimum) / (p.Maximum - p.Minimum) : 0;
            var previous = previousAbsolute.GetValueOrDefault(input.Index, normalized);
            previousAbsolute[input.Index] = normalized;
            if (!latched.Contains(input.Index) && Math.Abs(normalized - current) > 0.015 && (previous - current) * (normalized - current) > 0)
            { Status?.Invoke(p.Label + ": move the MIDI control through " + p.Display + " to take over."); return; }
            latched.Add(input.Index);
            var requested = p.Clamp(p.Minimum + normalized * (p.Maximum - p.Minimum));
            expectedAbsolute[input.Index] = (p.Key, requested);
            Send(target, "SET", Wire.Escape(p.Id), p.Component.ToString(), Wire.Number(requested));
        }
        else
        {
            var amount = input.Value * (slot.Step ?? p.Step) * (Fine ? 0.1 : 1);
            if (p.Type == "double") amount *= relativeSensitivity;
            if (p.Type is "int" or "bool" or "choice")
            {
                amount += discreteRemainders.GetValueOrDefault(p.Key);
                var whole = Math.Truncate(amount); discreteRemainders[p.Key] = amount - whole; amount = whole;
            }
            if (amount == 0) return;
            Send(target, "DELTA", Wire.Escape(p.Id), p.Component.ToString(), Wire.Number(amount));
        }
        ApplySuggested?.Invoke();
    }
    public void Action(string action, bool pressed = true)
    { lock (engineGate) ActionCore(action, pressed); }
    private void ActionCore(string action, bool pressed)
    {
        if (action == "fine") { Fine = pressed; DisplaysChanged?.Invoke(); return; }
        if (!pressed) return;
        if (action.StartsWith("bank:", StringComparison.Ordinal))
        {
            var bank = Profile.Banks.FirstOrDefault(x => x.Name == action[5..]); if (bank != null) SelectBank(bank); return;
        }
        if (action is "page:next" or "page-next") { SelectPage(Page + 1); return; }
        if (action is "page:prev" or "page-prev") { SelectPage(Page - 1); return; }
        if (action.StartsWith("reset-axis:", StringComparison.Ordinal) && int.TryParse(action[11..], out var axis)) { Handle(new ControlInput(InputKind.Reset, axis)); return; }
        var t = registry.ArmedTarget;
        if (t == null) { Status?.Invoke("Arm MIDI in the intended effect first."); return; }
        if (action == "refresh") Send(t, "SNAPSHOT");
        else if (action == "disarm") Send(t, "DISARM");
        else if (action == "apply") { Send(t, "APPLY"); ApplySuggested?.Invoke(); }
        else if (action is "focus:next" or "focus:prev")
        {
            var parameters = t.Parameters.Values.Where(p => p.Available).OrderBy(p => p.Label).ThenBy(p => p.Component).ToArray();
            var index = Array.FindIndex(parameters, p => p.Key == FocusedKey);
            if (parameters.Length > 0) FocusedKey = parameters[(index + (action == "focus:next" ? 1 : -1) + parameters.Length) % parameters.Length].Key;
            DisplaysChanged?.Invoke();
        }
        else if (action is "capture:A" or "capture:B")
        {
            comparisons[action[8..]] = t.Parameters.Values.Where(p => p.Available).ToDictionary(p => p.Key, p => p.Value);
            Status?.Invoke("Captured comparison " + action[8..] + " for this armed instance.");
        }
        else if (action == "recall:toggle")
        {
            if (!comparisons.TryGetValue(nextComparison, out var values)) { Status?.Invoke("Capture comparison " + nextComparison + " first."); return; }
            foreach (var value in values)
                if (t.Parameters.TryGetValue(value.Key, out var parameter) && parameter.Available)
                    Send(t, "SET", Wire.Escape(parameter.Id), parameter.Component.ToString(), Wire.Number(parameter.Clamp(value.Value)));
            Status?.Invoke("Queued comparison " + nextComparison + ". Apply MIDI to commit.");
            nextComparison = nextComparison == "A" ? "B" : "A"; ApplySuggested?.Invoke();
        }
        else if (action == "toggle:stage")
        {
            var stage = Bank.Pages.ElementAtOrDefault(Page)?.StageParameter ?? (Bank.Name switch { "grain" => "grainEnabled", "halation" => "halationEnabled", "diffusion" => Page == 0 ? "cameraDiffusionEnabled" : "printDiffusionEnabled", "scanner" => "scannerEnabled", "preflash" => "preflashEnabled", _ => null });
            if (stage != null && t.Parameters.TryGetValue(Wire.Key(stage, 0), out var parameter) && parameter.Available)
            { Send(t, "SET", Wire.Escape(parameter.Id), "0", parameter.Value == 0 ? "1" : "0"); ApplySuggested?.Invoke(); }
            else Status?.Invoke("This bank has no available stage toggle; use All available parameters.");
        }
        else Status?.Invoke("Action unavailable: " + action + ". Host transport and undo require a validated Resolve command route.");
    }
}
