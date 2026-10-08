using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Automation;

namespace Spektrafilm.Control.Windows;

/// <summary>
/// Uses the Mapper's documented Select Application menu rather than rewriting Hub configuration.
/// Only settings changed by this session are restored, and only while they still match our selection.
/// </summary>
public sealed class TangentApplicationRouting
{
    public sealed record Result(bool Success, string Message);
    private sealed record Menu(AutomationElement Header, AutomationElement Container, AutomationElement AutoSelect,
        IReadOnlyList<AutomationElement> Applications, bool Automatic, string? Selected);
    private sealed record Ownership(int ProcessId, DateTime ProcessStartUtc, bool PreviousAutomatic, string? PreviousApplication,
        bool ExpectedAutomatic, string? ExpectedApplication);
    private sealed class MenuSettlingException(string message) : InvalidOperationException(message);
    private const string ApplicationName = "Spektrafilm MIDI";
    private const string ManualHelp = "In Tangent Mapper, open Select Application, switch Auto-select Application off, then choose Spektrafilm MIDI.";
    private readonly SemaphoreSlim operation = new(1, 1);
    private Ownership? ownership;

    public bool OwnsSelection => ownership != null;

    /// <summary>Call after the native Tangent client has registered its application with Hub.</summary>
    public async Task<Result> TryAcquireAsync(CancellationToken cancellationToken = default)
    {
        await operation.WaitAsync(cancellationToken).ConfigureAwait(false);
        try { return await Task.Run(() => Acquire(cancellationToken), cancellationToken).ConfigureAwait(false); }
        finally { operation.Release(); }
    }

    /// <summary>Call before disconnecting the native client; a user's later Mapper selection is preserved.</summary>
    public async Task<Result> TryRestoreAsync()
    {
        await operation.WaitAsync().ConfigureAwait(false);
        try { return await Task.Run(Restore).ConfigureAwait(false); }
        finally { operation.Release(); }
    }

    private Result Acquire(CancellationToken cancellationToken)
    {
        AutomationElement? window = null;
        try
        {
            using var mapper = FindMapper(launch: true, cancellationToken);
            if (mapper == null) return new(false, "Tangent Mapper was not found. Install Tangent Hub, then retry setup. " + ManualHelp);
            window = FindWindow(mapper, cancellationToken);
            if (window == null) return new(false, "Tangent Mapper did not expose one usable main window. Close any Mapper dialogs, then retry. " + ManualHelp);
            var menu = OpenMenu(window);
            // Application registration may take a moment after TCP connects. Do not guess an item or mutate
            // automatic selection until the exact registered application can be invoked and verified.
            AutomationElement? target = null;
            for (var attempt = 0; attempt < 12; attempt++)
            {
                cancellationToken.ThrowIfCancellationRequested();
                target = UniqueApplication(menu, ApplicationName);
                if (target != null) break;
                Thread.Sleep(150);
                menu = OpenMenu(window);
            }
            if (target == null || !target.Current.IsEnabled || !target.TryGetCurrentPattern(InvokePattern.Pattern, out _))
                return new(false, "Spektrafilm MIDI is not available in Tangent Mapper yet. Check that Tangent Hub is connected, then retry setup. " + ManualHelp);
            if (!TryChecked(target, out _)) return new(false, "This Mapper version does not expose its selected application to accessibility. " + ManualHelp);

            var start = mapper.StartTime.ToUniversalTime();
            if (ownership != null && (ownership.ProcessId != mapper.Id || ownership.ProcessStartUtc != start)) ownership = null;
            if (ownership != null && (menu.Automatic || menu.Selected != ApplicationName)) ownership = null;
            if (!menu.Automatic && menu.Selected == ApplicationName)
                return new(true, ownership == null
                    ? "Panels are assigned to Spektrafilm MIDI and will stay assigned when Resolve is active."
                    : "Panels are assigned to Spektrafilm MIDI. Your previous Mapper selection will be restored on exit.");

            var previous = new Ownership(mapper.Id, start, menu.Automatic, menu.Selected, menu.Automatic, menu.Selected);
            // Record ownership before the first mutation so a failed verification can undo our own change.
            ownership = previous;
            if (menu.Automatic)
            {
                SetAutomatic(menu, false);
                ownership = previous with { ExpectedAutomatic = false };
                menu = WaitForMenu(window, value => !value.Automatic,
                    "Mapper did not confirm manual application selection.");
                ownership = previous with { ExpectedAutomatic = false, ExpectedApplication = menu.Selected };
            }
            cancellationToken.ThrowIfCancellationRequested();
            target = UniqueApplication(menu, ApplicationName);
            if (target == null || !target.Current.IsEnabled) throw new InvalidOperationException("Spektrafilm MIDI disappeared from Mapper's menu.");
            Invoke(target);
            ownership = previous with { ExpectedAutomatic = false, ExpectedApplication = ApplicationName };
            WaitForMenu(window, value => !value.Automatic && value.Selected == ApplicationName,
                "Mapper did not confirm that Spektrafilm MIDI owns the panels.");
            return new(true, "Panels are assigned to Spektrafilm MIDI. Your previous Mapper selection will be restored on exit.");
        }
        catch (Exception e) when (IsRoutingException(e))
        {
            // Restore only a verifiable session-owned selection. If the user has switched elsewhere,
            // leave it alone. No configuration file or executable association is edited.
            var restore = Restore();
            return new(false, "Panel setup could not finish: " + e.Message + " " + restore.Message + " " + ManualHelp);
        }
        finally { CloseMenu(window); }
    }

    private Result Restore()
    {
        var owned = ownership;
        if (owned == null) return new(true, "No Mapper settings need restoring.");
        AutomationElement? window = null;
        try
        {
            using var mapper = FindMapper(launch: false, CancellationToken.None);
            if (mapper == null || mapper.Id != owned.ProcessId || mapper.StartTime.ToUniversalTime() != owned.ProcessStartUtc)
            { ownership = null; return new(false, "Mapper restarted or closed; its current settings were left alone."); }
            window = FindWindow(mapper, CancellationToken.None);
            if (window == null) return new(false, "Mapper could not be reached to restore its previous selection.");
            var menu = OpenMenu(window);
            if (menu.Automatic != owned.ExpectedAutomatic || menu.Selected != owned.ExpectedApplication)
            { ownership = null; return new(true, "Mapper selection changed outside this companion; it was left alone."); }

            if (owned.PreviousAutomatic)
            {
                SetAutomatic(menu, true);
                WaitForMenu(window, value => value.Automatic,
                    "Mapper did not confirm Auto-select Application was restored.");
            }
            else if (owned.PreviousApplication != null && owned.PreviousApplication != ApplicationName)
            {
                var previous = UniqueApplication(menu, owned.PreviousApplication);
                if (previous == null || !previous.Current.IsEnabled)
                    return new(false, "The previously selected Tangent application is no longer running; Mapper was left unchanged.");
                Invoke(previous);
                WaitForMenu(window, value => !value.Automatic && value.Selected == owned.PreviousApplication,
                    "Mapper did not confirm the previous application was restored.");
            }
            else if (owned.PreviousApplication == null)
            {
                // Manual mode with no active app is a legitimate first-launch state. There is no
                // previous application to invoke; Hub removes our selection when our client exits.
                ownership = null;
                return new(true, "No Tangent application was active before setup. Disconnecting Spektrafilm MIDI releases its panel selection.");
            }
            ownership = null;
            return new(true, "Previous Tangent Mapper selection restored.");
        }
        catch (Exception e) when (IsRoutingException(e))
        { return new(false, "Previous Mapper selection could not be restored: " + e.Message); }
        finally { CloseMenu(window); }
    }

    private static Process? FindMapper(bool launch, CancellationToken cancellationToken)
    {
        var processes = Process.GetProcessesByName("TangentMapper");
        if (processes.Length > 1) { foreach (var process in processes) process.Dispose(); throw new InvalidOperationException("More than one Tangent Mapper process is running."); }
        if (processes.Length == 1) return processes[0];
        if (!launch) return null;
        var executable = new[] { Environment.SpecialFolder.ProgramFiles, Environment.SpecialFolder.ProgramFilesX86 }
            .Select(folder => Path.Combine(Environment.GetFolderPath(folder), "Tangent", "TangentMapper.exe"))
            .FirstOrDefault(File.Exists);
        if (executable == null) return null;
        using var started = Process.Start(new ProcessStartInfo(executable) { UseShellExecute = false, WindowStyle = ProcessWindowStyle.Hidden });
        for (var attempt = 0; attempt < 20; attempt++)
        {
            cancellationToken.ThrowIfCancellationRequested();
            processes = Process.GetProcessesByName("TangentMapper");
            if (processes.Length == 1) return processes[0];
            foreach (var process in processes) process.Dispose();
            if (processes.Length > 1) throw new InvalidOperationException("More than one Tangent Mapper process is running.");
            Thread.Sleep(150);
        }
        return null;
    }

    private static AutomationElement? FindWindow(Process process, CancellationToken cancellationToken)
    {
        // Restrict every search to the verified process and the installed Mapper main-window ID.
        var installed = new[] { Environment.SpecialFolder.ProgramFiles, Environment.SpecialFolder.ProgramFilesX86 }
            .Select(folder => Path.GetFullPath(Path.Combine(Environment.GetFolderPath(folder), "Tangent", "TangentMapper.exe")));
        var executable = process.MainModule?.FileName;
        if (executable == null || !installed.Contains(Path.GetFullPath(executable), StringComparer.OrdinalIgnoreCase))
            throw new InvalidOperationException("The running Mapper is not the installed Tangent Mapper executable.");
        for (var attempt = 0; attempt < 12; attempt++)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var windows = AutomationElement.RootElement.FindAll(TreeScope.Children,
                new AndCondition(new PropertyCondition(AutomationElement.ProcessIdProperty, process.Id),
                    new PropertyCondition(AutomationElement.AutomationIdProperty, "MainWindow")));
            if (windows.Count > 1) return null;
            if (windows.Count == 1)
            {
                var window = windows[0];
                if (!window.Current.IsEnabled || !window.Current.Name.StartsWith("Tangent Mapper", StringComparison.Ordinal)) return null;
                if (window.TryGetCurrentPattern(WindowPattern.Pattern, out var pattern))
                {
                    var windowPattern = (WindowPattern)pattern;
                    if (windowPattern.Current.IsModal) return null;
                    if (windowPattern.Current.WindowVisualState == WindowVisualState.Minimized) windowPattern.SetWindowVisualState(WindowVisualState.Normal);
                }
                return window;
            }
            Thread.Sleep(150);
        }
        return null;
    }

    private static Menu OpenMenu(AutomationElement window) => WaitForMenu(window, _ => true,
        "Mapper's application selection did not settle.");

    private static Menu WaitForMenu(AutomationElement window, Func<Menu, bool> ready, string failure)
    {
        // Qt can return from Invoke before Hub selection, checked QAction, and title updates finish.
        // Re-read bounded fresh state rather than treating intermediate state as ownership.
        var elapsed = Stopwatch.StartNew();
        string? settling = null;
        do
        {
            try
            {
                var menu = ReadMenu(window);
                if (ready(menu)) return menu;
                settling = null;
            }
            catch (MenuSettlingException e) { settling = e.Message; }
            Thread.Sleep(100);
        } while (elapsed.Elapsed < TimeSpan.FromSeconds(2));
        throw new InvalidOperationException(failure + (settling == null ? "" : " " + settling));
    }

    private static Menu ReadMenu(AutomationElement window)
    {
        var headers = window.FindAll(TreeScope.Descendants, new AndCondition(
            new PropertyCondition(AutomationElement.ControlTypeProperty, ControlType.MenuItem),
            new PropertyCondition(AutomationElement.NameProperty, "Select Application")));
        if (headers.Count != 1) throw new InvalidOperationException("Mapper's Select Application menu is unavailable.");
        var header = headers[0];
        if (!header.Current.IsEnabled) throw new InvalidOperationException("Mapper's Select Application menu is disabled.");
        if (!header.TryGetCurrentPattern(ExpandCollapsePattern.Pattern, out var expandPattern))
            throw new InvalidOperationException("Mapper does not expose the application menu's accessibility action.");
        var expandable = (ExpandCollapsePattern)expandPattern;
        if (expandable.Current.ExpandCollapseState != ExpandCollapseState.Expanded) expandable.Expand();
        var containers = header.FindAll(TreeScope.Children, new PropertyCondition(AutomationElement.AutomationIdProperty, "MainWindow._menubar._selectApplicationMenu"));
        if (containers.Count != 1) throw new InvalidOperationException("Mapper's application menu could not be identified.");
        var container = containers[0];
        var elements = container.FindAll(TreeScope.Children, new PropertyCondition(AutomationElement.ControlTypeProperty, ControlType.MenuItem));
        if (elements.Count is < 1 or > 100) throw new InvalidOperationException("Mapper's application menu has an unexpected layout.");
        var items = elements.Cast<AutomationElement>().ToList();
        var autoItems = items.Where(item => item.Current.Name == "Auto-select Application").ToList();
        if (autoItems.Count != 1 || !TryChecked(autoItems[0], out var automatic))
            throw new InvalidOperationException("Mapper does not expose the Auto-select checked state.");
        var applications = items.Where(item => item.Current.Name != "Auto-select Application").ToList();
        var selected = applications.Where(item => TryChecked(item, out var isChecked) && isChecked).Select(item => item.Current.Name).ToList();
        string? selectedApplication;
        if (selected.Count > 1)
        {
            // The installed Qt Mapper can retain stale checked flags for both applications even
            // after its visible checkmark and title have changed. Accept that provider state only
            // when the fresh main-window title corroborates exactly one full checked menu name.
            // Never infer the application from a loose substring or from an unchecked menu entry.
            var title = window.Current.Name;
            var corroborated = selected.Where(name =>
            {
                var prefix = "Tangent Mapper - " + name + " - ";
                return title.StartsWith(prefix, StringComparison.Ordinal) && title.Length > prefix.Length;
            }).ToList();
            if (corroborated.Count != 1)
                throw new MenuSettlingException("Mapper reported ambiguous selected applications: " + string.Join(", ", selected) + ".");
            selectedApplication = corroborated[0];
        }
        else selectedApplication = selected.SingleOrDefault();
        return new(header, container, autoItems[0], applications, automatic, selectedApplication);
    }

    private static AutomationElement? UniqueApplication(Menu menu, string name)
    {
        var matches = menu.Applications.Where(item => item.Current.Name == name).ToList();
        return matches.Count == 1 ? matches[0] : null;
    }

    private static bool TryChecked(AutomationElement element, out bool value)
    {
        value = false;
        if (!element.TryGetCurrentPattern(TogglePattern.Pattern, out var pattern)) return false;
        var state = ((TogglePattern)pattern).Current.ToggleState;
        if (state == ToggleState.Indeterminate) return false;
        value = state == ToggleState.On;
        return true;
    }

    private static void SetAutomatic(Menu menu, bool enabled)
    {
        if (!TryChecked(menu.AutoSelect, out var current) || !menu.AutoSelect.Current.IsEnabled)
            throw new InvalidOperationException("Mapper's Auto-select state could not be verified.");
        if (current == enabled) return;
        // Qt exposes TogglePattern for reading a checkable QAction, but its menu item
        // implements pressAction rather than toggleAction. Invoke the action once after
        // reading its checked state, then re-read the menu to verify the requested state.
        Invoke(menu.AutoSelect);
    }

    private static void Invoke(AutomationElement item)
    {
        if (!item.Current.IsEnabled || !item.TryGetCurrentPattern(InvokePattern.Pattern, out var pattern))
            throw new InvalidOperationException("The selected Mapper application cannot be activated.");
        ((InvokePattern)pattern).Invoke();
    }

    private static void CloseMenu(AutomationElement? window)
    {
        if (window == null) return;
        try
        {
            var headers = window.FindAll(TreeScope.Descendants, new AndCondition(
                new PropertyCondition(AutomationElement.ControlTypeProperty, ControlType.MenuItem),
                new PropertyCondition(AutomationElement.NameProperty, "Select Application")));
            if (headers.Count == 1 && headers[0].TryGetCurrentPattern(ExpandCollapsePattern.Pattern, out var pattern))
                ((ExpandCollapsePattern)pattern).Collapse();
        }
        catch (Exception e) when (IsRoutingException(e)) { }
    }

    private static bool IsRoutingException(Exception e) => e is ElementNotAvailableException or InvalidOperationException
        or COMException or System.ComponentModel.Win32Exception or UnauthorizedAccessException or IOException or OperationCanceledException;
}
