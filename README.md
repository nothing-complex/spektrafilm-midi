# Spektrafilm MIDI for Tangent Element

A free, open-source Windows prototype for controlling a community build of Spektrafilm OFX from a full Tangent Element set or a MIDI controller. Includes a desktop companion, native Tangent screen feedback and an optional OSC route.

**Early prototype, looking for testers.** The software builds and automated tests pass. A short live Element test now confirms physical input, automatic host Apply and changed values in Resolve. Sensitivity calibration and the full acceptance checklist remain open. Continuous automatic control depends on Resolve exposing the effect's **Apply MIDI** button and target marker through Windows accessibility. Manual Apply is the fallback. Please start with a disposable project.

[Download the Windows prototype and matching source](https://github.com/nothing-complex/spektrafilm-midi/releases/tag/v0.2.0-prototype) · [Setup](docs/SETUP.md) · [Controls](docs/CONTROLS.md) · [Verified status](docs/BUILD_STATUS.md)

## What it does

- Maps all **24 continuous axes** on an Element Kb/Tk/Bt/Mf set: twelve knobs, three Tk ball/ring sets, and the Mf ball/ring.
- Provides feature banks, parameter pages, resets, adjustable relative speed, fine adjustment, a focused Mf ring and temporary A/B snapshots.
- Starts with a simple **Controls** screen, reconnects your chosen input automatically, and links the visible effect without manual Apply-button binding. Device settings and diagnostics live under **Advanced**.
- Sends control labels, actual values, choice names and bank information to panel screens through native Tangent Hub support. Physical formatting still needs checking.
- Accepts WinMM MIDI, native Tangent Hub TCP or loopback OSC input, with one physical input route active at a time.
- Supports relative MIDI formats, absolute 7-bit and 14-bit input, and soft takeover.
- Uses explicit instance arming, fresh target generations, bounded queues, input expiry and heartbeat disarming.

The source catalogue covers 140 editable parameters / 160 components, including features conditional on the public build. Live OFX descriptors decide which controls are actually available. Five transport roles, Resolve undo/redo commands and whole-gesture undo grouping remain unimplemented; unavailable roles are labelled accordingly.

## Keep regular Spektrafilm alongside it

This is a separate effect, **Spektrafilm MIDI (Community Beta)**:

| Item | MIDI sibling |
|---|---|
| OFX ID | `local.tangentmidi.spektrafilm` |
| Bundle | `spektrafilm_midi.ofx.bundle` |
| Defaults and presets | Separate `%APPDATA%/TangentMidi/Spektrafilm/v1/` namespace |
| Companion settings | `%APPDATA%/TangentMidi/Spektrafilm/companion-v1.json` |

The installer targets only the MIDI bundle. Existing regular Spektrafilm nodes keep their own identity and state. Installation/update/removal tests preserve a regular test bundle byte for byte. Actual coexistence in Resolve projects is part of the [acceptance checklist](docs/ACCEPTANCE.md).

## Download and try it

Requirements: **Windows x64**, a Vulkan-capable GPU/driver supported by the public renderer, and Tangent Hub/Mapper for the native Element route. **The Windows download includes its .NET runtime.** No separate .NET installation or virtual MIDI driver is needed for native Element control.

1. Download and extract `Spektrafilm-MIDI-0.2.0-prototype.zip` from the [prerelease](https://github.com/nothing-complex/spektrafilm-midi/releases/tag/v0.2.0-prototype).
2. **First installation only:** close Resolve and double-click **Install MIDI Effect.cmd**. Approve the Windows permission prompt, then reopen Resolve. Existing 0.1.x users can skip this: the OFX binary is unchanged.
3. Add **Spektrafilm MIDI (Community Beta)** to a test node and show its MIDI controls in the inspector.
4. Double-click **Start Spektrafilm MIDI.cmd**. The companion connects to Tangent Hub on first launch, or reconnects the input route you last chose.
5. Click **Control this effect** in the companion. This explicitly arms the uniquely identified visible MIDI effect. You can also click **Arm MIDI** directly in the effect. Once fresh armed state arrives, the companion links its Apply button automatically.
6. Return to Resolve and turn Kb knob 1. Film Exposure should change. Use the bank and speed controls on the companion's **Controls** screen to adjust the mapping and feel.

Keep the intended effect's MIDI controls visible and Resolve in front while turning the panels. The companion tries to select **Spektrafilm MIDI** in Mapper and keep it selected across focus changes. If Mapper does not expose the required accessibility controls, the setup message explains the short [manual switching step](docs/SETUP.md#switching-element-from-resolve-to-spektrafilm). The Kb screens should show Spektrafilm labels such as **Film Exp** and **Print Exp**.

**Pause** stops input, disarms live control and restores the Mapper routing the companion changed when that routing is still its own. **Resume** reconnects; explicitly choose the effect again. The companion never restores arm ownership from saved settings or follows selected Resolve nodes automatically. Manual connection, binding, MIDI encodings, ports and detailed status remain under **Advanced**.

If the knobs move too quickly, lower the speed: `0.25` gives one quarter of normal movement. The default is `1`, with a `0.01–4` range, and the setting is saved. Hold a mapped **Fine** button for another tenfold reduction. Continuous parameters retain fractional values; choices and integer controls keep their discrete steps.

**DELTA: QUEUED confirms receipt, not a completed effect change.** Check for an **APPLIED** result and matching inspector/image feedback if troubleshooting. When automatic linking is unavailable, move a control and click **Apply MIDI** in the effect within two seconds. See [setup](docs/SETUP.md) and [companion details](companion/README.md) for the fallback.

Pause before export or returning the full panel set to Resolve's normal controls. If routing was selected manually, restore DaVinci Resolve and Auto-select yourself in Mapper. Use the [acceptance checklist](docs/ACCEPTANCE.md) to check undo, persistence, cache invalidation and renders before using a real job.

## Public-source limits

The OFX fork is based on [Spektrafilm](https://github.com/chaert-s/spektrafilm-ofx) commit [`86476af`](https://github.com/chaert-s/spektrafilm-ofx/tree/86476afc5b077de77e2278e3658d1ba9309892a1), public Windows version **0.1.9**. It does not match the latest official release. Lens and Motion features absent from that source are unavailable.

Licensed Academy printer-density tables are absent from the public source. The build uses existing filtered-enlarger C/M/Y controls and contains no data copied from an installed official plugin. RGB printer-point mapping is conditional on a future descriptor exposing it.

The upstream experimental tiled half-precision path has a known dither parity difference. This package retains the default full-frame path. GPU smoke tests do not independently validate the entire film model. Full details are in [build status](docs/BUILD_STATUS.md).

## Build from source

Use **PowerShell 7**, VS 2022 C++ tools, CMake, Vulkan SDK (`VULKAN_SDK` set), .NET 9 SDK, Git and Python 3.12. The root workflow builds and tests Release configuration.

```powershell
git clone https://github.com/nothing-complex/spektrafilm-midi.git
cd spektrafilm-midi
./Build.ps1 -Bootstrap
./Test.ps1
./Package.ps1 -Zip
```

Bootstrap creates an isolated Python environment with pinned data-generation dependencies and fetches the pinned OpenFX SDK. Close Resolve and the companion before `Test.ps1`: installer contracts require Resolve closed, and integration tests use ports 55051 and 9000.

The build includes a regular baseline for coexistence tests; the distribution packages the MIDI sibling alone. Build/package scripts do not install OFX binaries or change Tangent user maps. Output goes into `.build/` and `dist/`. Packaging downloads the Microsoft Windows x64 runtime packs on its first run and includes them in the Windows companion.

Automated verification covers native OFX host-action/thread boundaries, targeting, HDR dependencies, animation protection, queue expiry, companion state/protocol tests, 12 profile/bridge tests, cross-language integration, installer isolation and Vulkan core/print-scan smoke tests. [Build status](docs/BUILD_STATUS.md) separates those results from outstanding host/hardware work.

## Feedback and contributions

For development, start with [the agent/contributor handoff](docs/AGENT_HANDOFF.md) and [the MIDI controller workplan](docs/MIDI_CONTROLLER_WORKPLAN.md). They describe source entry points, protocol and host constraints, reproducible checks, and staged work for adding device profiles and feedback.

If you try it, please [open an issue](https://github.com/nothing-complex/spektrafilm-midi/issues) with your Windows/Resolve/Tangent Hub versions, GPU/driver, panel set or MIDI encoding, what you did and what happened. Testing the automatic Apply path and actual panel displays is especially useful. Code, mapping and documentation contributions are welcome.

## Credits and licence

Spektrafilm OFX is by **Aedan Diez**, based on work by **Andrea Volpato** and **Johannes Hanika**. This community project builds on that public source; it is not an official Spektrafilm release and is not affiliated with Spektrafilm, Tangent or Blackmagic Design.

The OFX source retains upstream GPL-3.0 licensing and notices. New companion, profiles, scripts and tests use GPL-3.0-or-later. See [LICENSE](LICENSE.txt), [third-party notices](THIRD_PARTY_NOTICES.md) and [modification record](MODIFICATIONS.md). Matching source is supplied alongside the binary prerelease. No payment or subscription is required for this project.
