# Build status — 7 October 2026

**Built Windows x64 prototype. A short live Element test confirms physical input, automatic host dispatch and changed values in Resolve.** The test also exposed excessive sensitivity; version 0.1.3 corrects the native movement configuration and adds a speed setting. Physical calibration of the fix and full acceptance remain open. The binary package contains the separately identified MIDI sibling and its desktop companion. The installed MIDI binary matches the tested build; the regular plugin remains separate. During live diagnosis, Tangent Mapper was switched to manual application selection and Spektrafilm MIDI was selected.

## Implemented

- Separate OFX target, bundle, identity, label, defaults/preset namespace, clipboard format and LUT folder. The regular baseline and MIDI binary load simultaneously in the test host with distinct IDs.
- Loopback instance discovery, explicit host-side arm ownership, fresh generations, bounded queue, two-second input expiry, companion heartbeat and disarm on timeout. No background/network/render callback calls OFX setters.
- Native host Apply transaction, descriptor bounds/defaults, disabled/hidden/animated parameter rejection and shared stock/HDR/printer semantics. Each Apply batch is one OFX edit group; a physical gesture may span multiple groups.
- Windows companion with WinMM MIDI input, loopback OSC input and native Tangent Hub TCP input/feedback. Relative and absolute formats, 14-bit pairs, soft takeover, fine modifiers, resets, feature banks, temporary A/B snapshots, focus and dynamic schema coverage.
- Persistent relative speed multiplier for continuous controls (`0.01–4`, default `1`), applied before an additional tenfold Fine reduction. Discrete parameters, absolute MIDI positions and resets are unaffected. Native Tangent generic movement uses range `−100` to `100` and step `0.01`; input diagnostics show the last axis/raw increment.
- Full Element allocation: 24 axes, 24 programmable buttons, 8 modifiers, 18 associated resets. Panel labels/values, choice names and bank feedback are implemented in the native route.
- Installer/uninstaller preview and explicit apply modes. They validate the separate MIDI identity and refuse conflicting bundles. Installation/update/removal contracts preserve a regular test bundle byte for byte.

## Executed verification

| Check | Result and scope |
|---|---|
| C++ and Windows companion build | Success; companion 0 warnings, 0 errors |
| Native broker tests | Parser, finite values, targeting, lifecycle and stale generation checks pass |
| Minimal OFX host harness | Host action/thread boundaries, bounds, animation/expression rejection, HDR dependency semantics, hidden/internal rejection, queue expiry, heartbeat disarm, exclusive arm, defaults isolation, balanced edits and unload pass |
| Companion tests | 28 pass, including continuous relative speed scaling, discrete/absolute/reset isolation, full 24-axis bursts, loopback discovery/reconnection, sustained-input scheduling, foreground retry/expiry, input during dispatch, snapshots, MIDI formats, OSC, Tangent framing, handshake/re-initiation and stage toggles |
| Installed Tangent Hub | Companion completes the real protocol-14 handshake and receives four connected Element panel reports. Mapper Auto-select was disabled and Spektrafilm MIDI selected. A short live test recorded 178 hardware inputs |
| Actual Resolve UI | Companion discovers three live effect instances and their 155-component snapshots. Exact-marker binding succeeds. After the initial empty callback test, physical Element movement produced repeated nonempty APPLY: APPLIED acknowledgments and changed Film Exposure, Print Exposure and Film Push/Pull values. Sensitivity was excessive and reached parameter bounds; the 0.1.3 sensitivity changes still require physical testing |
| Profile/OSC bridge tests | 12 pass; 160 editable source components mapped without omissions; bounded fractional Tangent controls and generated artifacts match their expectations and the bundled upstream reference |
| Cross-language integration | Real C# companion receives the DLL snapshot, OSC movement reaches the DLL, synthetic legal host Apply changes exposure and authoritative state |
| Installer contract | Preview, install, repeat update, conflict rejection, uninstall and regular-bundle preservation pass within workspace |
| Vulkan full-frame core | Six 1920×1080 cases pass: half/float RGBA and three spectral upsamplers |
| Vulkan full-frame print/scan | Six cases pass; checks include finite pixels, alpha, padding, expected dispatches and allocation reuse |
| Experimental tiled GPU path | Core/print-scan smoke pass; tested float32 tiled/full-frame RGB parity is exact; multi-tile float16 parity exceeds the upstream one-ULP gate |

Logs for the reproducible root suite are in `.build/validation/`. The host harness supplies legal synthetic actions; it does not establish an equivalent event pump inside Resolve. MIDI codec tests do not substitute for WinMM/driver/hardware tests. GPU smoke checks do not independently validate the entire film model.

The print/scan smoke harness's stale expected dispatch count was corrected to include the renderer's existing separate frame-constants pass. The renderer and comparison tolerances were not changed. The experimental half-precision tile difference comes from tile-local dither indices; the shipped plugin uses its existing default full-frame path.

## Open acceptance conditions

The key remaining conditions are **usable sensitivity and full host/hardware acceptance**. A short physical Element test now confirms live automatic dispatch and changed values in Resolve. The optional Windows accessibility adapter still requires the exact armed-instance marker, a unique visible Apply MIDI button, a fresh target and an explicit binding. Automatic dispatch requires foreground Resolve; an explicit companion **Apply now** click can invoke the same verified button while Resolve is in the background. Temporary foreground/readiness interruptions retain pending dispatch only within the native two-second input lifetime. Ambiguous or changed inspectors invalidate the binding. On hosts that do not expose these accessibility controls, use the effect's Apply MIDI button.

Physical sensitivity calibration, dynamic display layout, repeatable native application switching, hardware disconnect behavior, MIDI port traffic, Resolve redraw/cache invalidation, undo/redo, project save/reopen and exports still need [the acceptance procedure](ACCEPTANCE.md). The companion GUI was inspected with live Resolve discovery and a real Tangent Hub connection. Automated and headless companion verification completed independently.

The first user test reported that the panels retained Resolve's default mapping. Subsequent tests reported queued deltas without visible edits and input working only with the companion active. The Hub had Auto-select enabled, associated Resolve with its normal application and associated the companion executable with Spektrafilm MIDI. Mapper was changed to manual selection to keep Spektrafilm MIDI active across focus changes. The companion now shows persistent routing and Host Apply status, enables Auto Apply after successful binding, and retries pending work while it is fresh. A socket connection or QUEUED response alone does not prove a hardware event changed the effect.

The next short live test recorded 178 hardware inputs and multiple nonempty host Apply acknowledgments. Film Exposure reached −8, Print Exposure −5 and Film Push/Pull +2, demonstrating real parameter changes but also the excessive sensitivity reported by the user. Continuous OFX values already retained fractions; the earlier generic Tangent profile's step `1` also rounded native numeric feedback. Version 0.1.3 bounds that profile and uses step `0.01`, adds a saved continuous relative speed setting and exposes raw input increments. The resulting physical feel has not yet been checked.

Five transport buttons and the planned Resolve undo/redo command adapter are unimplemented and report unavailable. Calibration, presets and LUT management stay in the effect inspector. Animated parameters are rejected rather than edited. Explicitly disarm before export; automatic offline-render disarming is not claimed. One full gesture per undo entry is not implemented.

## Baseline

Public Spektrafilm commit `86476afc5b077de77e2278e3658d1ba9309892a1`, public Windows version `0.1.9`; OpenFX commit `e40728885390ec16276d11e00025de9b4282060c`. The available source is older than the installed official release. Lens/Motion and licensed Academy printer-density data are absent. Mapping uses filtered-enlarger C/M/Y where appropriate. Current-release render/feature parity is not claimed.

The live descriptor is authoritative: the source coverage catalogue includes conditional parameters that this particular build omits. The cross-language test received 155 live component rows; unavailable/hidden controls remain labelled accordingly. A future build that adds RGB printer points needs additional burst-at-boundary tests for compound printer movement before those conditional mappings are release-ready.
