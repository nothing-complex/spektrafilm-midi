# Spektrafilm MIDI companion

Windows .NET 9 desktop companion for the separately identified community OFX build. The normal Spektrafilm effect does not participate in this protocol.

Run `companion/Launch.ps1` after the project build, or run the packaged `SpektrafilmMidi.exe`. The .NET 9 Windows Desktop runtime is required for the framework-dependent package. No third-party NuGet libraries, virtual MIDI driver, background service or registry installation are used by the companion.

## First connection

1. Launch the companion and select **one** input adapter: Tangent Hub, MIDI, or OSC. Click **Connect** each session before arming the effect; selecting the adapter alone does not connect it. Connecting or disconnecting adapters disarms live control and clears the optional Apply binding.
2. For native Element control, open Tangent Mapper's **Select Application** menu, turn **Auto-select Application** off, and select **Spektrafilm MIDI** so it has the checkmark. The arrow beside the application only opens its maps. Auto-select otherwise restores the default Resolve setup when Resolve gains focus. On the Essentials bank, check for Kb labels such as Film Exp and Print Exp, possibly marked off while unarmed. See the [switching guide](../docs/SETUP.md#switching-element-from-resolve-to-spektrafilm).
3. Add **Spektrafilm MIDI (Community Beta)** to the intended Resolve node. In its MIDI controls, click **Arm MIDI**. Existing regular Spektrafilm nodes remain independent.
4. Wait for the companion to show one armed instance and its authoritative parameter state. Select a feature bank, or **All available parameters** for automatic coverage of the current schema.
5. Bind automatic Apply as described below, return to Resolve, then move a controller. Check **Host Apply: AUTO enabled (Resolve active)** and the last Apply acknowledgment. For manual testing, move a controller and **click Apply MIDI in the plugin within two seconds**. A stopped playhead does not itself dispatch queued edits.

**DELTA: QUEUED means the plugin received an edit; it does not mean a parameter changed.** The companion's persistent Host Apply line separately shows dispatch status and the last Apply result. Confirm an **APPLIED** acknowledgment and matching inspector/image feedback.

This is a feasibility build. Actual Resolve redraw, undo, project persistence, device behavior, and realtime performance still require host/hardware validation. The program never sets OFX parameters from MIDI, network or render callbacks.

## Optional automatic Apply

In the companion, click **Find visible Apply buttons**, explicitly select the intended button, then **Bind + enable Auto Apply**. Binding requires the exact `MIDI target: <full instance ID>` marker exposed next to that button. A successful bind also enables the automatic Apply checkbox. Automatic Apply starts off and bindings are not restored each session, even when a previous controller connection worked.

The Host Apply line shows **OFF**, **AUTO waiting for Resolve foreground**, or **AUTO enabled (Resolve active)**, plus the last Apply acknowledgment. Move a controller with Resolve foreground. If input arrives while another window is active, automatic application waits for Resolve for up to two seconds after the latest input, matching the plugin's input expiry. Return to Resolve promptly or move the control again once Resolve is foreground.

After binding, **Apply now** provides explicit manual dispatch from the companion. It immediately invokes the verified host button, including while Resolve is in the background and automatic Apply is off. It still requires the fresh armed target, unique bound button and exact target marker. Input older than two seconds has already expired.

Automatic application uses UI Automation `InvokePattern`, with all of these conditions checked again before each invocation:

- One unique, fresh, armed target with the same instance and generation as the binding.
- Resolve is foreground.
- Exactly one visible, enabled `Apply MIDI` button with the same runtime identity.
- The exact instance marker remains in that button's nearby accessible group.

If Resolve does not expose an accessible button or marker, the companion remains in manual Apply mode. It does not fall back to mouse coordinates, global keystrokes or private host calls. Bindings are never saved or restored, and selection/target changes invalidate them.

The button and target marker have been found and bound in an installed Resolve inspector. A short live Element test recorded 178 hardware inputs, repeated nonempty `APPLY: APPLIED` acknowledgments, and changes to Film Exposure, Print Exposure and Film Push/Pull. Sensitivity was excessive in that test. Version 0.1.3 corrects the native movement configuration and adds relative speed adjustment; the physical feel of those changes and the full acceptance checklist remain unverified.

## Input routes

- **Tangent Hub:** TCP loopback port64246. The supplied `profiles/tangent` app defines all24 continuous axes,37 action buttons and associated encoder/ball/ring resets. Select the Spektrafilm MIDI app in Mapper with Auto-select Application off. Resolve's A+B native/mappable shortcut does not select this separate app. Current labels, numeric values, choice names within refreshed labels, bank/mode and arm status are sent back. Actual panel display formatting remains subject to Hub/hardware verification. Four A modifiers can be held simultaneously without prematurely cancelling Fine when only one is released.
- **MIDI:** Windows WinMM device input. CC0–23 map to axes0–23; notes0–23 reset; notes32–68 follow the profile's explicit action mapping. Select the actual device encoding: binary offset64, two's complement, sign/magnitude, absolute7-bit, or absolute14-bit. For14-bit, MSB CC0–23 pairs with LSB CC32–55. Channel0 accepts all channels;1–16 selects one. Absolute inputs require pickup and are re-latched after an external authoritative change. Relative steps use the parameter's real units and preserve fractions.
- **OSC:** UDP loopback9000 by default. `/spektrafilm/axis/0` through `/spektrafilm/axis/23` accept a float/int relative delta; zero is the supplied Mapper profile's associated-reset message. `/spektrafilm/reset/<axis>` with nonzero value explicitly resets. `/spektrafilm/button/<MIDI note>` routes the mapped button; zero releases. `/spektrafilm/bank/<name>` switches feature banks, and `/spektrafilm/action/<action>` supports named actions. Legacy `/1/knob1` through24 accepts relative deltas. Only immediate OSC bundles are accepted.

The UI connects only one physical input route at a time to prevent native/OSC/MIDI duplication. Conventional MIDI feedback is not sent blindly to devices. Native Tangent provides the display return path; the optional OSC-to-MIDI profile has static Mapper labels.

## Controls and state

All24 axes are shown with current labels, values and availability. Double-clicking a displayed row resets its mapped parameter. Kb exposes twelve feature controls per page. Tk uses paired controls and vector components where appropriate; missing Academy printer controls fall back to the actual filtered-enlarger controls. Mf uses paired shaping and an explicitly focused parameter on the ring. Buttons change feature banks, pages, focus and fine movement, refresh/disarm/apply, and capture/recall temporary A/B snapshots for the current armed instance. Unsupported Resolve transport/undo routes produce an explicit status and do not synthesize input.

**Relative speed ×** scales relative movement for continuous parameters across the native Tangent, MIDI and OSC routes. The default is `1`; allowed values are `0.01–4`. For example, `0.25` gives one quarter of the normal movement. A held **Fine** modifier reduces it by another factor of ten. The speed setting is saved between sessions. It does not change choice/integer/boolean steps, absolute MIDI positions or resets. Fractional values are preserved through the continuous parameter path.

The native Tangent profile uses a bounded generic movement range of `−100` to `100` with step `0.01`, replacing the overly broad range and step `1` used in earlier packages. This also allows fractional numeric feedback on the panel; the old display rounding did not mean the OFX parameter itself only accepted integers. Reconnect Tangent Hub using the new package's profiles when updating. Input diagnostics include the last axis and raw increment to help identify unexpected movement before parameter scaling.

Only complete snapshots become authoritative. Schema/session/instance/generation checks reject stale targets. The companion sends a heartbeat at700ms; loss of the companion causes the plugin to disarm. Inputs are disabled with zero or multiple armed targets, incomplete state or stale discovery. Actual values replace predictions only after host application. Every available catalog parameter can be reached through generated pages; unavailable parameters are labelled and receive no writes.

Settings are stored separately under `%APPDATA%/TangentMidi/Spektrafilm/companion-v1.json`. Device connections, arm ownership and UIA bindings are never restored automatically.

## Build and verification

Use the root `Build.ps1`, or these individual commands from the project directory:

```powershell
dotnet restore companion/Windows/SpektrafilmMidi.csproj --configfile companion/NuGet.Config
dotnet build companion/Windows/SpektrafilmMidi.csproj -c Release --no-restore
dotnet restore companion.tests/Spektrafilm.Control.Tests.csproj --configfile companion/NuGet.Config
dotnet run --project companion.tests/Spektrafilm.Control.Tests.csproj -c Release --no-restore
```

The no-package test runner covers parsing, malformed input, source/generation isolation, snapshot completeness, relative/14-bit MIDI, absolute pickup after host changes, OSC, Tangent framing, actual mapping coverage and live loopback discovery. Tests use no physical controller or Resolve UI.

The executable supports `--self-test` (writes `self-test-result.txt` beside the executable), and `--headless --seconds 12 --output <log path>` for discovery/OSC integration checks. `--profiles <directory>` selects an explicit profile directory. Headless mode has no automatic host dispatch; use a host harness or the plugin's manual Apply action. It listens for OSC on9000 and uses the same exclusive discovery socket on55051.
