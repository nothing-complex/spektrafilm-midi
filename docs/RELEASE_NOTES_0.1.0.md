# Spektrafilm MIDI 0.1.0 — Windows prototype

Free, open-source community OFX sibling and controller companion for Tangent Element, MIDI and OSC.

**This is a prerelease for early testing.** Actual Resolve integration and physical Element acceptance are pending. Automatic continuous control depends on the explicitly bound Windows accessibility Apply path; manual Apply is the fallback. Use a disposable test project.

Included:

- Separate OFX identity, bundle and defaults/preset namespace, designed to coexist with regular Spektrafilm.
- Full Element mapping for 24 continuous axes, feature banks, resets and fine controls.
- Native Tangent labels/values/bank feedback, WinMM MIDI and loopback OSC input.
- Explicit arm ownership, fresh instance generations, input expiry and heartbeat disarming.
- Installer/uninstaller with preview mode and an explicit `-Apply` option.

Verification: native host contracts and broker tests, 18 companion tests, 11 profile/bridge tests, real companion-to-DLL integration, installer isolation, and Vulkan core/print-scan smoke cases pass. These do not substitute for real Resolve and panel testing.

Known limits: older public Spektrafilm 0.1.9 baseline; Lens/Motion absent; licensed printer-density tables absent, using C/M/Y fallback; transport/Resolve undo commands and whole-gesture undo remain unimplemented. See [build status](https://github.com/nothing-complex/spektrafilm-midi/blob/main/docs/BUILD_STATUS.md).

Download the Windows ZIP, extract it, read README, and close Resolve before installation. The .NET 9 Windows Desktop runtime and a compatible Vulkan GPU/driver are required. The source ZIP contains matching build inputs; dependencies are fetched by the documented bootstrap workflow. See [setup](https://github.com/nothing-complex/spektrafilm-midi/blob/main/docs/SETUP.md).

Spektrafilm OFX is by Aedan Diez, based on work by Andrea Volpato and Johannes Hanika. This community build is unaffiliated with Spektrafilm, Tangent and Blackmagic Design. Upstream GPL notices are retained; matching source is supplied with the binary.
