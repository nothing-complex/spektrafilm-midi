# Spektrafilm MIDI 0.1.1 — Tangent setup and diagnostics

This patch addresses the first reported setup failure: the Element panels stayed on Resolve's default controls. Tangent Mapper's **Auto-select Application** must be turned off before selecting **Spektrafilm MIDI**, otherwise returning to Resolve restores its usual mapping. The companion must remain running with **Tangent Hub** connected.

- Adds a persistent controller-routing panel showing TCP connection, application-definition progress, connected panel count, and received hardware input count/time. A TCP connection does not prove panel ownership.
- Keeps the necessary Mapper steps visible in the companion and corrects setup/acceptance instructions. Resolve's A+B shortcut does not select this separate application.
- Holds display feedback until the Hub handshake completes, and resends the current mode after Hub re-initiation.
- Adds two simulated Hub TCP regression checks. All 20 companion checks pass.

Checked against the installed Hub: protocol-14 handshake completed and all four Element panels reported connected. The companion discovers live MIDI effect snapshots in Resolve. Physical knob input, manual application switching, and automatic Apply remain unverified.

The OFX binary is unchanged from 0.1.0. Existing users can keep the installed MIDI effect and use the new companion with the new package's profiles. Regular Spektrafilm remains independently installed.

**Still a prototype:** physical panel input and continuous Apply inside Resolve require acceptance testing. The effect needs explicit **Arm MIDI**, then its **Apply MIDI** button or a deliberately bound automatic Apply route. Manual input expires after two seconds. This update does not establish automatic selected-node following or a working continuous host event pump.

See [setup](https://github.com/nothing-complex/spektrafilm-midi/blob/main/docs/SETUP.md) and [build status](https://github.com/nothing-complex/spektrafilm-midi/blob/main/docs/BUILD_STATUS.md). Windows x64, .NET 9 Desktop Runtime and a compatible Vulkan GPU/driver are required. Source and retained GPL notices accompany the binary.
