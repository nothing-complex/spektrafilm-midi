# Build status — 7 October 2026

**Built Windows x64 prototype. Physical Element and actual Resolve acceptance remain pending.** The binary package contains only the separately identified MIDI sibling and its desktop companion. No system OFX installation, original plugin replacement, or Tangent user-map change was performed during this build.

## Implemented

- Separate OFX target, bundle, identity, label, defaults/preset namespace, clipboard format and LUT folder. The regular baseline and MIDI binary load simultaneously in the test host with distinct IDs.
- Loopback instance discovery, explicit host-side arm ownership, fresh generations, bounded queue, two-second input expiry, companion heartbeat and disarm on timeout. No background/network/render callback calls OFX setters.
- Native host Apply transaction, descriptor bounds/defaults, disabled/hidden/animated parameter rejection and shared stock/HDR/printer semantics. Each Apply batch is one OFX edit group; a physical gesture may span multiple groups.
- Windows companion with WinMM MIDI input, loopback OSC input and native Tangent Hub TCP input/feedback. Relative and absolute formats, 14-bit pairs, soft takeover, fine modifiers, resets, feature banks, temporary A/B snapshots, focus and dynamic schema coverage.
- Full Element allocation: 24 axes, 24 programmable buttons, 8 modifiers, 18 associated resets. Panel labels/values, choice names and bank feedback are implemented in the native route.
- Installer/uninstaller preview and explicit apply modes. They validate the separate MIDI identity and refuse conflicting bundles. Installation/update/removal contracts preserve a regular test bundle byte for byte.

## Executed verification

| Check | Result and scope |
|---|---|
| C++ and Windows companion build | Success; companion 0 warnings, 0 errors |
| Native broker tests | Parser, finite values, targeting, lifecycle and stale generation checks pass |
| Minimal OFX host harness | Host action/thread boundaries, bounds, animation/expression rejection, HDR dependency semantics, hidden/internal rejection, queue expiry, heartbeat disarm, exclusive arm, defaults isolation, balanced edits and unload pass |
| Companion tests | 18 pass, including full 24-axis bursts, actual loopback discovery/reconnection, sustained-input Apply scheduling, snapshots, MIDI formats, OSC, Tangent framing and stage toggles |
| Profile/OSC bridge tests | 11 pass; 160 editable source components mapped without omissions; generated artifacts match the bundled upstream reference |
| Cross-language integration | Real C# companion receives the DLL snapshot, OSC movement reaches the DLL, synthetic legal host Apply changes exposure and authoritative state |
| Installer contract | Preview, install, repeat update, conflict rejection, uninstall and regular-bundle preservation pass within workspace |
| Vulkan full-frame core | Six 1920×1080 cases pass: half/float RGBA and three spectral upsamplers |
| Vulkan full-frame print/scan | Six cases pass; checks include finite pixels, alpha, padding, expected dispatches and allocation reuse |
| Experimental tiled GPU path | Core/print-scan smoke pass; tested float32 tiled/full-frame RGB parity is exact; multi-tile float16 parity exceeds the upstream one-ULP gate |

Logs for the reproducible root suite are in `.build/validation/`. The host harness supplies legal synthetic actions; it does not establish an equivalent event pump inside Resolve. MIDI codec tests do not substitute for WinMM/driver/hardware tests. GPU smoke checks do not independently validate the entire film model.

The print/scan smoke harness's stale expected dispatch count was corrected to include the renderer's existing separate frame-constants pass. The renderer and comparison tolerances were not changed. The experimental half-precision tile difference comes from tile-local dither indices; the shipped plugin uses its existing default full-frame path.

## Open acceptance conditions

The key remaining condition is **continuous host dispatch in Resolve**. Manual Apply is implemented. The optional Windows accessibility adapter requires Resolve to expose the exact armed-instance marker and its Apply MIDI button, a unique explicit binding, and foreground Resolve. It refuses ambiguous targets. This adapter has not been validated against the installed Resolve UI. If accessibility does not expose those controls, continuous automatic operation is unavailable with this adapter.

Actual panel movement, dynamic display layout, native application switching, hardware disconnect behavior, MIDI port traffic, Resolve redraw/cache invalidation, undo/redo, project save/reopen and exports still need [the acceptance procedure](ACCEPTANCE.md). Visual companion GUI verification is also pending. Automated and headless companion verification completed independently.

Five transport buttons and the planned Resolve undo/redo command adapter are unimplemented and report unavailable. Calibration, presets and LUT management stay in the effect inspector. Animated parameters are rejected rather than edited. Explicitly disarm before export; automatic offline-render disarming is not claimed. One full gesture per undo entry is not implemented.

## Baseline

Public Spektrafilm commit `86476afc5b077de77e2278e3658d1ba9309892a1`, public Windows version `0.1.9`; OpenFX commit `e40728885390ec16276d11e00025de9b4282060c`. The available source is older than the installed official release. Lens/Motion and licensed Academy printer-density data are absent. Mapping uses filtered-enlarger C/M/Y where appropriate. Current-release render/feature parity is not claimed.

The live descriptor is authoritative: the source coverage catalogue includes conditional parameters that this particular build omits. The cross-language test received 155 live component rows; unavailable/hidden controls remain labelled accordingly. A future build that adds RGB printer points needs additional burst-at-boundary tests for compound printer movement before those conditional mappings are release-ready.
