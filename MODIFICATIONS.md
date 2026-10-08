# Community modifications — 7 October 2026

This repository contains a modified version of public Spektrafilm OFX, baseline commit `86476afc5b077de77e2278e3658d1ba9309892a1`. Changes described here were made on **2026-10-07** for the community Tangent/MIDI prototype.

Modified upstream files:

- `plugin/CMakeLists.txt`: adds a separately identified MIDI OFX build target, resources/manifest handling and broker tests.
- `plugin/src/SpektraFilmPlugin.cpp`: adds MIDI host controls, per-instance lifecycle and host-owned parameter application; isolates defaults, presets, clipboard and LUT state; shares the existing semantic dependency handling with MIDI edits. Conditional changes preserve the regular target's behavior.
- `plugin/tools/SpektraVulkanCopyHarness.cpp`: corrects the smoke harness's expected print/scan dispatch count to include the existing frame-constants pass. Rendering code and parity tolerances were not changed.

New native integration files:

- `plugin/src/SpektraMidiControl.h`
- `plugin/src/SpektraMidiControl.cpp`
- `plugin/src/SpektraMidiHost.inc`
- `plugin/tests/MidiControlTests.cpp`

The surrounding companion, panel profiles, root build/package scripts, tests and community documentation are new project additions. The unchanged baseline source under `profiles/reference/` is retained for repeatable catalogue extraction.

Companion 0.1.2 adds bounded foreground retries, preserves input received during a host invocation, enables automatic Apply after verified binding, and adds explicit Apply now and persistent dispatch status. A short live Element test has since confirmed physical input, nonempty host Apply acknowledgments and changed values in Resolve.

Companion 0.1.3 adds a persistent relative speed multiplier for continuous controls and reports the last input axis/raw increment. Native Tangent profiles use a bounded generic movement range of `−100` to `100` and step `0.01`, replacing the excessive range and step `1`; this also improves fractional numeric feedback. Discrete parameters, absolute MIDI and resets retain their existing behavior. The native OFX binary is unchanged from 0.1.0–0.1.2. Physical sensitivity calibration and full host/hardware acceptance remain open.

Companion 0.2.0 adds a simple Controls screen with Advanced settings, automatic connection/retry for the default or saved input route, a user-triggered Control this effect action, and automatic Apply-button binding after fresh explicit arm state. It attempts Tangent Mapper application selection through accessibility and restores only routing changes it still owns on Pause/normal exit. Pause disarms and disconnects; Resume reconnects without restoring cached arm ownership. The distribution now includes the .NET runtime and double-click start/one-time installer launchers. Native OFX and corrected panel profiles are unchanged from 0.1.3. The new startup/routing flow and full hardware/host acceptance remain to be checked.

The prototype is a separate community effect, not a replacement for or current-feature-equivalent version of the official plugin. See [README](README.md) and [build status](docs/BUILD_STATUS.md) for supported behavior and open acceptance conditions.
