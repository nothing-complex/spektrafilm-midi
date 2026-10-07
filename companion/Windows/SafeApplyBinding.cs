using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Runtime.InteropServices;
using System.Windows.Automation;

namespace Spektrafilm.Control.Windows;

/// <summary>Optional host action pump. No coordinate clicks, keystrokes or private OFX calls.</summary>
public sealed class SafeApplyBinding
{
    public sealed record Candidate(AutomationElement Element, int ProcessId, string Description)
    { public override string ToString() => Description; }
    private Candidate? bound;
    private string? targetIdentity;
    private int[]? runtimeId;
    private string? instance;
    public bool IsBound => bound != null;
    public void Clear() { bound = null; targetIdentity = null; runtimeId = null; instance = null; }
    public static IReadOnlyList<Candidate> FindCandidates()
    {
        var result = new List<Candidate>();
        foreach (var process in Process.GetProcessesByName("Resolve"))
        {
            using (process)
            {
                var windows = AutomationElement.RootElement.FindAll(TreeScope.Children, new PropertyCondition(AutomationElement.ProcessIdProperty, process.Id));
                foreach (AutomationElement window in windows)
                {
                    var elements = window.FindAll(TreeScope.Descendants, new AndCondition(new PropertyCondition(AutomationElement.NameProperty, "Apply MIDI"), new PropertyCondition(AutomationElement.ControlTypeProperty, ControlType.Button)));
                    foreach (AutomationElement element in elements)
                        if (element.Current.IsEnabled && !element.Current.IsOffscreen && element.TryGetCurrentPattern(InvokePattern.Pattern, out _)) result.Add(new(element, process.Id, "Resolve " + process.Id + " — " + window.Current.Name + " / Apply MIDI"));
                }
            }
        }
        return result;
    }
    public string Bind(Candidate candidate, Target target)
    {
        Clear();
        if (!OwnerConfirmed(candidate.Element, target.Instance)) return "Binding refused: Resolve did not expose this armed instance's MIDI target marker beside the button. Manual Apply MIDI required.";
        bound = candidate; targetIdentity = target.Identity; instance = target.Instance; runtimeId = candidate.Element.GetRuntimeId();
        return "Bound Apply MIDI for this armed target. Automatic invocation requires foreground Resolve and one matching visible button.";
    }
    private static bool OwnerConfirmed(AutomationElement button, string id)
    {
        // Plugin exposes the exact unique marker in its MIDI group. Never infer ownership from visual position.
        var parent = TreeWalker.ControlViewWalker.GetParent(button);
        for (var i = 0; parent != null && i < 3 && parent.Current.ControlType != ControlType.Window; i++, parent = TreeWalker.ControlViewWalker.GetParent(parent))
        {
            var descendants = parent.FindAll(TreeScope.Descendants, System.Windows.Automation.Condition.TrueCondition);
            if (descendants.Count > 500) return false;
            foreach (AutomationElement marker in descendants)
            {
                if (marker.Current.IsOffscreen) continue;
                if (marker.Current.Name == "MIDI target: " + id || marker.TryGetCurrentPattern(ValuePattern.Pattern, out var pattern) && ((ValuePattern)pattern).Current.Value == "MIDI target: " + id) return true;
            }
        }
        return false;
    }
    public bool Invoke(Target? target, out string reason)
    {
        reason = "Manual Apply MIDI required.";
        if (target == null || bound == null || target.Identity != targetIdentity || !target.Fresh(DateTime.UtcNow)) { Clear(); return false; }
        try
        {
            GetWindowThreadProcessId(GetForegroundWindow(), out var foreground);
            if (foreground != bound.ProcessId) { reason = "Waiting for foreground Resolve; manual Apply MIDI remains available."; return false; }
            var candidates = FindCandidates();
            if (candidates.Count != 1 || !candidates[0].Element.GetRuntimeId().SequenceEqual(runtimeId ?? Array.Empty<int>()) || !OwnerConfirmed(candidates[0].Element, instance!))
            { Clear(); reason = "Apply binding invalidated by inspector/selection change. Manual Apply MIDI required."; return false; }
            if (!candidates[0].Element.TryGetCurrentPattern(InvokePattern.Pattern, out var pattern)) { Clear(); return false; }
            ((InvokePattern)pattern).Invoke(); reason = "Invoked Apply MIDI through Resolve UI Automation; awaiting authoritative state."; return true;
        }
        catch (Exception e) when (e is ElementNotAvailableException or InvalidOperationException or COMException)
        { Clear(); reason = "Apply binding unavailable: " + e.Message + ". Manual Apply MIDI required."; return false; }
    }
    [DllImport("user32.dll")] private static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr window, out int processId);
}
