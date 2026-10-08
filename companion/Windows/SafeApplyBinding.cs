using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Automation;

namespace Spektrafilm.Control.Windows;

/// <summary>Optional host action pump. No coordinate clicks, keystrokes or private OFX calls.</summary>
public sealed class SafeApplyBinding
{
    public sealed record Candidate(AutomationElement Element, int ProcessId, string Description)
    { public override string ToString() => Description; }
    // A scan can run on a worker thread; only the UI thread installs its result.
    // Invoke validates the live inspector again before it performs a host action.
    public sealed record AutomaticBindingSearch(string? TargetIdentity, Candidate? Match, int[]? RuntimeId, string Reason);
    private Candidate? bound;
    private string? targetIdentity;
    private int[]? runtimeId;
    private string? instance;
    public bool IsBound => bound != null;
    public bool ResolveInForeground
    {
        get { GetWindowThreadProcessId(GetForegroundWindow(), out var foreground); return bound != null && foreground == bound.ProcessId; }
    }
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
    public static AutomaticBindingSearch FindAutomaticBinding(Target? target)
    {
        if (!ReadyTarget(target))
            return new(target?.Identity, null, null, "Open Spektrafilm MIDI in Resolve and press Arm MIDI on the effect you want to control.");
        try
        {
            var candidates = FindCandidates();
            if (candidates.Count == 0)
                return new(target!.Identity, null, null, "Keep the armed effect's MIDI controls open in Resolve so Apply MIDI is visible.");
            if (candidates.Count != 1)
                return new(target!.Identity, null, null, "More than one Apply MIDI button is visible. Show only the armed effect's MIDI controls in Resolve.");
            var candidate = candidates[0];
            if (!OwnerConfirmed(candidate.Element, target!.Instance))
                return new(target.Identity, null, null, "Select the armed Spektrafilm MIDI effect and open its MIDI controls. Resolve has not exposed matching controls for this effect.");
            return new(target.Identity, candidate, candidate.Element.GetRuntimeId(), "Ready. Your panel now controls the armed Spektrafilm MIDI effect while Resolve is active.");
        }
        catch (Exception e) when (e is ElementNotAvailableException or InvalidOperationException or COMException)
        {
            return new(target!.Identity, null, null, "Waiting for Resolve's effect controls. Reopen the armed effect's MIDI controls if this continues.");
        }
    }
    public bool TryBindAutomatically(AutomaticBindingSearch search, Target? currentTarget, out string reason)
    {
        reason = search.Reason;
        if (!ReadyTarget(currentTarget) || search.TargetIdentity != currentTarget!.Identity)
        {
            // The user can change the intended effect while UI Automation is scanning.
            Clear();
            reason = "The armed effect changed. Waiting for its current MIDI controls.";
            return false;
        }
        if (search.Match == null || search.RuntimeId == null)
        {
            Clear();
            return false;
        }
        bound = search.Match;
        targetIdentity = currentTarget.Identity;
        instance = currentTarget.Instance;
        runtimeId = (int[])search.RuntimeId.Clone();
        return true;
    }
    /// <summary>Only call in response to the user's explicit "Control this effect" click.</summary>
    public static bool ArmVisibleEffect(IReadOnlyList<Target> discoveredTargets, out string reason, CancellationToken cancellationToken = default)
    {
        reason = "Open the intended Spektrafilm MIDI effect's MIDI controls in Resolve, then try Control this effect again.";
        try
        {
            cancellationToken.ThrowIfCancellationRequested();
            var candidates = FindCandidates();
            if (candidates.Count != 1)
            {
                reason = candidates.Count == 0
                    ? "Open the intended Spektrafilm MIDI effect's MIDI controls in Resolve. You can also press Arm MIDI directly in the effect."
                    : "More than one effect's MIDI controls are visible. Show only the effect you want to control, or press its Arm MIDI button directly in Resolve.";
                return false;
            }
            var apply = candidates[0];
            var targets = discoveredTargets.Where(t => t.Fresh(DateTime.UtcNow) && OwnerConfirmed(apply.Element, t.Instance)).Take(2).ToArray();
            if (targets.Length != 1)
            {
                reason = "Waiting for the visible effect to be discovered. Keep its MIDI controls open, then try again or press Arm MIDI directly in Resolve.";
                return false;
            }
            var target = targets[0];
            var armButtons = FindOwnedButtonsNear(apply.Element, target.Instance, "Arm MIDI");
            if (armButtons.Count != 1)
            {
                reason = "Resolve has not exposed one matching Arm MIDI button. Press Arm MIDI directly in the intended effect's MIDI controls.";
                return false;
            }
            var applyRuntime = apply.Element.GetRuntimeId();
            var armRuntime = armButtons[0].GetRuntimeId();

            // The inspector may change while discovery is running. Verify both live
            // buttons, their process and the exact instance marker again before arming.
            cancellationToken.ThrowIfCancellationRequested();
            candidates = FindCandidates();
            if (!target.Fresh(DateTime.UtcNow) || candidates.Count != 1 || candidates[0].ProcessId != apply.ProcessId || !candidates[0].Element.GetRuntimeId().SequenceEqual(applyRuntime) || !OwnerConfirmed(candidates[0].Element, target.Instance))
            {
                reason = "The visible effect changed. Open the intended effect's MIDI controls and try Control this effect again.";
                return false;
            }
            armButtons = FindOwnedButtonsNear(candidates[0].Element, target.Instance, "Arm MIDI");
            if (armButtons.Count != 1 || armButtons[0].Current.ProcessId != apply.ProcessId || !armButtons[0].GetRuntimeId().SequenceEqual(armRuntime) || !OwnerConfirmed(armButtons[0], target.Instance) || !target.Fresh(DateTime.UtcNow) || !armButtons[0].TryGetCurrentPattern(InvokePattern.Pattern, out var pattern))
            {
                reason = "The visible effect's controls changed. Try again or press Arm MIDI directly in the intended effect.";
                return false;
            }
            cancellationToken.ThrowIfCancellationRequested();
            ((InvokePattern)pattern).Invoke();
            reason = "Control requested for the visible Spektrafilm MIDI effect. Waiting for Resolve to confirm it is armed.";
            return true;
        }
        catch (OperationCanceledException)
        {
            reason = "Control request canceled.";
            return false;
        }
        catch (Exception e) when (e is ElementNotAvailableException or InvalidOperationException or COMException)
        {
            reason = "Resolve's effect controls are unavailable. Open the intended effect and press Arm MIDI directly in its MIDI controls.";
            return false;
        }
    }
    private static IReadOnlyList<AutomationElement> FindOwnedButtonsNear(AutomationElement apply, string id, string name)
    {
        var result = new List<AutomationElement>();
        var parent = TreeWalker.ControlViewWalker.GetParent(apply);
        for (var i = 0; parent != null && i < 3 && parent.Current.ControlType != ControlType.Window; i++, parent = TreeWalker.ControlViewWalker.GetParent(parent))
        {
            var descendants = parent.FindAll(TreeScope.Descendants, System.Windows.Automation.Condition.TrueCondition);
            if (descendants.Count > 500) break;
            if (!HasMarker(descendants, id)) continue;
            foreach (AutomationElement button in descendants)
            {
                if (button.Current.Name != name || button.Current.ControlType != ControlType.Button || button.Current.IsOffscreen || !button.Current.IsEnabled || !button.TryGetCurrentPattern(InvokePattern.Pattern, out _)) continue;
                var buttonRuntime = button.GetRuntimeId();
                if (!result.Any(found => found.GetRuntimeId().SequenceEqual(buttonRuntime))) result.Add(button);
            }
        }
        return result;
    }
    private static bool ReadyTarget(Target? target) => target is { Armed: true, Complete: true } && target.Fresh(DateTime.UtcNow);
    public string Bind(Candidate candidate, Target target)
    {
        Clear();
        if (!ReadyTarget(target)) return "Press Arm MIDI in the intended effect and wait for it to connect.";
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
            if (HasMarker(descendants, id)) return true;
        }
        return false;
    }
    private static bool HasMarker(AutomationElementCollection descendants, string id)
    {
        foreach (AutomationElement marker in descendants)
        {
            if (marker.Current.IsOffscreen) continue;
            if (marker.Current.Name == "MIDI target: " + id || marker.TryGetCurrentPattern(ValuePattern.Pattern, out var pattern) && ((ValuePattern)pattern).Current.Value == "MIDI target: " + id) return true;
        }
        return false;
    }
    public bool Invoke(Target? target, out string reason, out bool retryable, bool allowBackground = false)
    {
        retryable = false;
        reason = "Manual Apply MIDI required.";
        if (!ReadyTarget(target) || bound == null || target!.Identity != targetIdentity) { Clear(); return false; }
        try
        {
            GetWindowThreadProcessId(GetForegroundWindow(), out var foreground);
            // Automatic hardware dispatch requires foreground Resolve. An explicit
            // companion Apply click may invoke the same verified button in the background.
            if (!allowBackground && foreground != bound.ProcessId) { retryable = true; reason = "Waiting for foreground Resolve; pending Apply expires after two seconds without new input."; return false; }
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
