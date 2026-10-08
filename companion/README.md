# Spektrafilm MIDI companion

Windows desktop companion for the separately identified community OFX build. Regular Spektrafilm does not participate in this protocol. The Windows release includes its .NET runtime and starts from **Start Spektrafilm MIDI.cmd**; **Launch Companion.cmd** remains available for existing users. Source builds require the .NET 9 SDK.

## Everyday use

1. Add **Spektrafilm MIDI (Community Beta)** to the intended Resolve node and show its MIDI controls.
2. Start the companion. It connects to Tangent Hub on first launch, or reconnects your saved input route. Unavailable Tangent Hub connections are retried about every five seconds while running.
3. Click **Control this effect**. This explicitly arms the uniquely identified visible MIDI effect through its real host button. If Resolve cannot expose that button, click **Arm MIDI** in the effect instead.
4. Wait for the setup status to confirm the effect is linked. The companion binds automatic Apply when it has one fresh armed target and that target's uniquely identified visible Apply button. No Find/Bind sequence is needed for normal setup.
5. Return to Resolve and turn a control. Kb knob 1 changes Film Exposure on Essentials. Choose a bank and adjust speed on the **Controls** screen.

Keep the effect's MIDI controls visible and Resolve foreground while moving the panels. The companion tries to select **Spektrafilm MIDI** in Tangent Mapper and suspend Auto-select while it owns the routing. When Mapper does not expose the required accessibility controls, the app explains the manual step. See [setup](../docs/SETUP.md#switching-element-from-resolve-to-spektrafilm).

**Pause** disconnects input, disarms live control and restores the prior Mapper routing when the companion changed it and still owns that change. Normal app exit also attempts that restoration. **Resume** reconnects; click **Control this effect** again before grading. If you selected Mapper's routing manually, restore it manually. The app never arms automatically on startup, restores cached arm ownership or follows Resolve's selected node.

The main **Controls** screen shows setup status, mapped controls, banks and speed. **Advanced** contains input selection, MIDI settings, ports, manual connection/binding controls and diagnostics.

## Host application and fallback

**DELTA: QUEUED means the plugin received an edit; it does not mean a parameter changed.** A completed host callback returns **APPLY: APPLIED**. The companion shows the latest Apply result separately from receipt acknowledgments. Compare the inspector/image and actual returned value when checking a setup.

Automatic Apply uses Windows UI Automation InvokePattern. Before binding and each invocation, it verifies fresh armed state, complete authoritative state, a unique visible/enabled Apply MIDI button and the exact nearby MIDI target marker. The binding also tracks button runtime identity and target generation. Ambiguous or changed inspectors invalidate it. No OFX setter runs from a network, MIDI or render callback.

Automatic dispatch requires foreground Resolve. If another window becomes active, pending application waits for up to two seconds after the latest input, matching plugin expiry. Return to Resolve promptly or turn the control again after returning. Stale input is discarded.

If automatic linking is unavailable, show the effect's MIDI controls and follow the setup status. **Advanced** retains **Find Apply buttons** and **Bind selected** for manual binding with the same exact-marker checks. After binding, **Apply now** explicitly invokes the verified host button even while Resolve is in the background. You can also turn a control and click **Apply MIDI** directly in the effect within two seconds. The app does not fall back to guessed mouse coordinates, global keystrokes or private host calls.

A short live Element test before this UX release recorded 178 hardware inputs, repeated nonempty Apply acknowledgments, and changing Film Exposure, Print Exposure and Film Push/Pull in Resolve. It exposed excessive sensitivity; the corrected movement profile and saved speed setting were added in 0.1.3. The 0.2.0 startup/routing, one-click host Arm, automatic Apply binding and Pause/Resume flow passed a short installed Resolve/Mapper GUI check. Physical sensitivity and full acceptance remain open. See [verified status](../docs/BUILD_STATUS.md).

## Input routes

- **Tangent Hub:** TCP loopback port 64246. The bundled profiles/tangent application defines all 24 continuous axes, 37 action buttons and associated encoder/ball/ring resets. Labels, values, choice names, bank/mode and arm status return to the panels. A+B changes Resolve's native/mappable mode; it does not choose this application. Dynamic screen layout still needs physical verification.
- **MIDI:** Windows WinMM input. CC 0–23 map to axes 0–23; notes 0–23 reset; notes 32–68 use the profile's action mapping. Choose the actual encoding: binary offset 64, two's complement, sign/magnitude, absolute 7-bit or absolute 14-bit. For 14-bit, MSB CC 0–23 pairs with LSB CC 32–55. Channel 0 accepts all channels; 1–16 filters one. Absolute input requires pickup and re-latches after external authoritative changes.
- **OSC:** UDP loopback 9000 by default. /spektrafilm/axis/0 through /spektrafilm/axis/23 accept relative float/int deltas; zero is the supplied Mapper profile's associated-reset message. /spektrafilm/reset/<axis> with nonzero value resets explicitly. /spektrafilm/button/<MIDI note> handles mapped buttons; zero releases. /spektrafilm/bank/<name> selects banks and /spektrafilm/action/<action> supports named actions. Legacy /1/knob1 through 24 accepts relative deltas. Only immediate bundles are accepted.

Only one physical input route connects at a time. The companion installs no virtual MIDI driver, service or registry entry. Conventional MIDI feedback is not sent blindly to devices. Native Tangent supplies dynamic displays; the optional OSC-to-MIDI profile has static Mapper labels.

## Controls and saved settings

All 24 axes have current labels, values and availability. Double-clicking a row resets its mapped parameter. Kb exposes twelve feature controls per page. Tk uses paired controls and vector components where appropriate; missing Academy printer controls fall back to available filtered-enlarger controls. Mf supplies paired shaping and a focused ring parameter. Buttons select banks/pages/focus, hold Fine, reset, refresh/disarm/apply and capture/recall temporary A/B snapshots. Unsupported Resolve transport/undo roles report unavailable.

Speed scales continuous relative movement across Tangent, MIDI and OSC: default 1, range 0.01–4. A value of 0.25 gives quarter speed; a held **Fine** modifier adds a tenfold reduction. Choices, integers, booleans, absolute MIDI positions and resets are unaffected. Continuous parameter values retain fractions. The native Tangent movement range is −100 to 100 with step 0.01; diagnostics show the incoming axis/raw increment.

Only complete snapshots become authoritative. Schema/session/instance/generation checks reject stale targets. Heartbeats are sent every 700 ms; losing the companion disarms the plugin. Zero or multiple armed targets, incomplete state or stale discovery disable input. Actual values replace predictions after host application. Generated pages cover every currently available catalogue parameter; unavailable controls remain labelled and receive no writes.

Settings live under %APPDATA%/TangentMidi/Spektrafilm/companion-v1.json. Route, device settings, bank and speed persist. Connections are re-established; arm ownership and UI Automation bindings always require fresh host state.

## Build and verification

Use the root Build.ps1, or run these commands from the project directory:

~~~powershell
dotnet restore companion/Windows/SpektrafilmMidi.csproj --configfile companion/NuGet.Config
dotnet build companion/Windows/SpektrafilmMidi.csproj -c Release --no-restore
dotnet restore companion.tests/Spektrafilm.Control.Tests.csproj --configfile companion/NuGet.Config
dotnet run --project companion.tests/Spektrafilm.Control.Tests.csproj -c Release --no-restore
~~~

Source builds start with companion/Launch.ps1. Package.ps1 publishes a self-contained Windows x64 companion, downloading Microsoft runtime packs once into the project cache. Packaging artifacts stay separate from normal development outputs.

Automated checks cover parsing, malformed input, generation isolation, snapshot completeness, MIDI formats/pickup, OSC, Tangent framing, mapping coverage and live loopback discovery. They do not simulate a physical controller or Resolve UI.

The executable supports --self-test (writes self-test-result.txt beside the executable), --headless --seconds 12 --output <log path>, and --profiles <directory>. Headless mode has no automatic host dispatch; use a host harness or manual Apply. It listens for OSC on 9000 and uses the exclusive discovery socket on 55051.
