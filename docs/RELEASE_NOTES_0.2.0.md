# Spektrafilm MIDI 0.2.0 — simpler setup

This release reduces the setup needed to use Element with Spektrafilm MIDI. Start the companion, show the intended MIDI effect, click **Control this effect**, then return to Resolve and grade.

- The Windows download includes its .NET runtime. Extract the whole ZIP and use **Start Spektrafilm MIDI.cmd**.
- **Install MIDI Effect.cmd** handles the one-time elevated OFX install and shows the result. Close Resolve first. Existing 0.1.x users can skip installation: the OFX binary is unchanged.
- The companion connects to Tangent Hub on first launch or reconnects the saved input route, retrying unavailable Tangent Hub connections about every five seconds.
- **Control this effect** explicitly arms the uniquely identified visible MIDI effect. Once fresh armed state arrives, the companion automatically links its verified Apply button. Manual Find/Bind steps move to Advanced.
- The main **Controls** screen shows setup status, banks, speed and mapped controls. **Advanced** contains device encodings, ports, manual controls and diagnostics.
- The app attempts Spektrafilm routing in Tangent Mapper and explains the manual step if accessibility is unavailable. Pause and normal exit restore prior routing only when the companion made and still owns the change.
- **Pause** stops input and disarms. **Resume** reconnects; explicitly choose the effect again. Startup never restores cached arm ownership or follows selected Resolve nodes.
- Added an extensive [engineering handoff](https://github.com/nothing-complex/spektrafilm-midi/blob/main/docs/AGENT_HANDOFF.md) and [MIDI controller implementation workplan](https://github.com/nothing-complex/spektrafilm-midi/blob/main/docs/MIDI_CONTROLLER_WORKPLAN.md), plus an agent entry point. Arbitrary device profiles, Learn and MIDI feedback are roadmap work, not shipped features.

Keep the MIDI controls visible and Resolve foreground while moving the panels. Automatic host dispatch still requires the exact fresh armed target and its visible marker/button. Manual Arm/Apply remains the fallback when accessibility is unavailable. Queued input expires two seconds after the latest movement.

The earlier short physical test confirmed real Element input, nonempty Apply acknowledgments and changed values in Resolve. It also exposed sensitivity problems addressed in 0.1.3. The new startup/routing flow, one-click host Arm, automatic Apply binding and Pause/Resume passed a short live GUI check in Resolve Studio 21 with all four panels connected. Physical sensitivity and full acceptance for displays, undo, save/reopen, exports and long sessions remain to be checked. See [verified status](https://github.com/nothing-complex/spektrafilm-midi/blob/main/docs/BUILD_STATUS.md) for completed validation and remaining work.

Regular Spektrafilm remains separate. The source baseline and rendering limitations are unchanged. Matching source and licence notices accompany the free Windows prerelease.
