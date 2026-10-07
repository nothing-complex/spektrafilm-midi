# Spektrafilm MIDI 0.1.3 — finer Tangent movement and adjustable speed

This companion/profile patch addresses excessive sensitivity during the first successful physical Element test in Resolve. Continuous OFX parameters already accepted fractional values; the old generic Tangent profile used an excessively broad movement range and step `1`, which also rounded numeric feedback on the panel.

- Native Tangent generic controls now use range `−100` to `100` and step `0.01` for finer movement and fractional numeric feedback.
- **Relative speed ×** scales continuous relative controls across native Tangent, MIDI and OSC. It defaults to `1`, accepts `0.01–4` and persists between sessions. Try `0.25` for one quarter of normal movement; held **Fine** gives another tenfold reduction.
- Choices, integers and booleans keep their discrete steps. Absolute MIDI positions and resets are unaffected by the speed setting.
- Input diagnostics show the last axis, label, raw increment and speed so unexpected incoming movement can be distinguished from parameter scaling.

The preceding live test recorded 178 hardware inputs, repeated nonempty **APPLY: APPLIED** acknowledgments, and changes to Film Exposure, Print Exposure and Film Push/Pull in Resolve. It also drove those values to their limits. This confirms the short physical-input/host-dispatch path; it does not complete acceptance for panel screen layout, undo/redo, save/reopen, exports or long sessions. The physical feel of the 0.1.3 sensitivity changes still needs testing.

All 28 companion checks and 12 profile/OSC bridge checks pass, including continuous speed scaling and isolation of discrete, absolute and reset behavior.

The OFX binary is unchanged. Existing 0.1.0–0.1.2 users can keep their installed MIDI effect and run the updated companion with this package's bundled profiles. Reconnect Tangent Hub to register the corrected controls, keep Mapper Auto-select off and Spektrafilm MIDI selected, then arm the intended MIDI effect and use **Bind + enable Auto Apply**. Return to Resolve before moving hardware controls.

Windows x64, .NET 9 Desktop Runtime and a compatible Vulkan GPU/driver are required. Binary and corresponding source packages include the GPL notices. See [setup](https://github.com/nothing-complex/spektrafilm-midi/blob/main/docs/SETUP.md) and [build status](https://github.com/nothing-complex/spektrafilm-midi/blob/main/docs/BUILD_STATUS.md) for verification and remaining limits.
