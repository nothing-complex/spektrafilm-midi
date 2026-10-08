# Contributor entry point

This repository contains a **community prototype**, not the official Spektrafilm product. Start with [README.md](README.md), [docs/AGENT_HANDOFF.md](docs/AGENT_HANDOFF.md), and [docs/BUILD_STATUS.md](docs/BUILD_STATUS.md). For new controllers, use [docs/MIDI_CONTROLLER_WORKPLAN.md](docs/MIDI_CONTROLLER_WORKPLAN.md). The handoff distinguishes working code, actual hardware evidence and open acceptance work.

## Preserve the working boundary

- Keep the sibling's OFX ID `local.tangentmidi.spektrafilm`, label `Spektrafilm MIDI (Community Beta)` and bundle `spektrafilm_midi.ofx.bundle` separate from regular Spektrafilm. Never install over the regular bundle or import licensed installed-only data.
- MIDI, OSC, Tangent, network and render callbacks must never call OFX parameter setters. They queue intent. The real host's **Apply MIDI** InstanceChanged action commits it legally.
- Preserve exact session/instance/generation targeting, one fresh complete armed target, finite values, bounded queues, two-second input expiry, heartbeat disarming, descriptor constraints and animated/disabled/hidden parameter rejection.
- **Control this effect** may invoke a verified host Arm button only on explicit user action. Startup and timers must not arm effects or infer the selected Resolve node. Automatic binding must retain the exact nearby target marker and unique visible enabled host button checks.
- Automatic host Apply requires foreground Resolve. Avoid guessed coordinates, global keystrokes and private host calls in the product.
- Restore Mapper routing only if this companion changed it and still owns the expected state. Preserve later user changes. Document Qt accessibility workarounds rather than weakening checks silently.
- Continuous values must retain fractions. Keep discrete/reset behavior and absolute pickup distinct from continuous relative speed. Do not quantize all controls to integers.

## Work and verify

Read the source around a change before editing. Keep controller-specific protocol quirks in adapters/profiles; the core engine uses normalized `ControlInput`. Do not promise hardware support based only on codec tests. Record tested device/firmware/encoding and actual returned OFX values.

The source workflow needs PowerShell 7, VS 2022 C++ tools, CMake, Vulkan SDK, .NET 9 SDK, Git and Python 3.12. `./Build.ps1 -Bootstrap` prepares the workspace. `./Test.ps1` is the full native/companion/integration/GPU/installer suite; **close Resolve and the companion before running it**, because some checks use fixed live ports and require Resolve closed. The isolated companion/profile commands in the handoff can run without disrupting an active host.

`./Package.ps1 -Zip` creates the Windows self-contained binary and matching source archives. It does not install the effect. Verify manifest hashes, runtime notices, separate OFX identity, source completeness and ZIP contents before publication. Use a new version for a changed release; do not silently replace a published artifact. Keep generated profiles synchronized with their generator and run its `--check` mode.

Update handoff/build-status/setup documentation for behavior changes. Preserve candid outstanding acceptance conditions. Reddit copy is provided privately in chat; do not re-add a marketing draft to the repository or release archives.
