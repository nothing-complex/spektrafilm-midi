# Spektrafilm MIDI 0.1.2 — queued edits and foreground routing

This companion patch addresses edits stopping at **DELTA: QUEUED** and panels only responding while the companion is active. QUEUED confirms receipt; **APPLY: APPLIED** confirms that Resolve ran the host Apply action.

- **Bind + enable Auto Apply** now enables automatic dispatch after a successful explicit binding. A persistent Host Apply line shows whether it is off, waiting for Resolve foreground, or enabled, alongside the latest Apply result.
- Pending automatic Apply survives a temporary foreground/readiness interruption. It retains the earliest dispatch deadline and expires two seconds after the latest input, matching the native queue lifetime. New movement extends that lifetime without postponing dispatch.
- Input arriving during a host invocation remains scheduled for the next batch; nested host invocations are blocked.
- **Apply now** immediately invokes the explicitly bound, verified Resolve button, including while the companion has focus. Automatic hardware dispatch still requires foreground Resolve and a fresh, unique armed target with a visible matching inspector.
- Tangent Mapper must have **Select Application > Auto-select Application** off and **Spektrafilm MIDI** selected. Associating only the companion executable makes the mapping follow its window instead of remaining available in Resolve.

On the test machine, Mapper was set to manual application selection, the Hub completed protocol 14 with all four Element panels connected, and the installed Resolve inspector passed exact-marker binding. Explicit invocation returned **APPLY: APPLIED 0**, confirming the real host callback with an empty queue. This does not establish continuous physical knob operation; that acceptance test remains pending.

All 24 companion checks pass, including foreground retry, input expiry and input arriving during dispatch.

The OFX binary is unchanged. Existing 0.1.0/0.1.1 users can keep their installed MIDI effect and run this package's companion with its profiles. Regular Spektrafilm remains separately installed. Reconnect Tangent Hub, arm the intended MIDI effect, find its visible Apply button, then **Bind + enable Auto Apply** and return to Resolve.

Windows x64, .NET 9 Desktop Runtime and a compatible Vulkan GPU/driver are required. Binary and corresponding source packages include the GPL notices. See [setup](https://github.com/nothing-complex/spektrafilm-midi/blob/main/docs/SETUP.md) and [build status](https://github.com/nothing-complex/spektrafilm-midi/blob/main/docs/BUILD_STATUS.md).
