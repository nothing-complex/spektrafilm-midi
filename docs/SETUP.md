# Setup and everyday use

Download the [Windows 0.2.0 prototype](https://github.com/nothing-complex/spektrafilm-midi/releases/tag/v0.2.0-prototype) and extract the whole ZIP into a folder you can keep. The companion includes its .NET runtime. You need Windows x64, a compatible Vulkan GPU/driver, and Tangent Hub/Mapper with your Element panels connected.

## First installation

1. Close DaVinci Resolve.
2. Double-click **Install MIDI Effect.cmd** in the extracted folder. Approve the Windows permission prompt; the installer shows its result and waits for Enter.
3. Reopen Resolve and add **Spektrafilm MIDI (Community Beta)** to a disposable test node. Regular Spektrafilm remains independently available.

The installer targets only spektrafilm_midi.ofx.bundle and checks its separate identity. It refuses to install while Resolve is running. It does not close Resolve or change user presets. For a command-line preview, run ./Install.ps1; ./Install.ps1 -Apply performs installation.

**Updating from 0.1.x?** The OFX binary is unchanged. Skip the installer and run the new companion with the new package's bundled profiles.

## Connect and grade

1. Show the intended MIDI effect's controls in Resolve's inspector.
2. Double-click **Start Spektrafilm MIDI.cmd**. On first launch it connects to Tangent Hub; later it reconnects your saved route. An unavailable Tangent Hub connection is retried about every five seconds. The headline setup status explains what is missing.
3. Click **Control this effect** in the companion. It invokes the uniquely identified visible effect's real **Arm MIDI** button. If that button is inaccessible, click **Arm MIDI** directly in Resolve.
4. Wait for linked/ready status. Once one fresh armed target and its exact visible target marker are available, the companion links **Apply MIDI** automatically. Normal setup does not require Find/Bind steps.
5. Return to Resolve and turn Kb knob 1. On Essentials this changes Film Exposure. Confirm the inspector value, image, companion value and panel feedback agree.

Keep the intended effect's MIDI controls visible and Resolve in front while turning the panels. There is no automatic selected-node following. The app never arms from saved settings or silently arms on startup. If it cannot distinguish the visible effect, show only the intended effect's MIDI controls and use its Arm MIDI button.

The **Controls** screen has setup status, feature bank, speed and mapped controls. Ports, encodings, manual connection/binding and diagnostics are under **Advanced**. Lower speed to 0.25 for quarter-speed movement; hold a mapped **Fine** modifier for another tenfold reduction. Speed is saved, ranges from 0.01–4, and defaults to 1. Choices, integers, booleans, absolute MIDI positions and resets retain their behavior.

## Pause, resume and finish

Click **Pause** before switching targets, exporting or returning the panels to Resolve's usual controls. This disconnects input, disarms live control and restores the previous Mapper routing when the companion changed it and still owns that change. Normal app exit attempts the same restoration. If routing was selected manually, restore it manually in Mapper.

**Resume** reconnects input. Click **Control this effect** again, or explicitly arm the intended MIDI effect in Resolve. Fresh target state is always required; cached arm state is never restored.

Test undo, save/reopen and rendered output using [the acceptance checklist](ACCEPTANCE.md) before a real project. A short earlier live test confirmed actual Element input, host Apply and changed values; the setup flow passed a short live GUI check; full physical/host acceptance remains open.

## Switching Element from Resolve to Spektrafilm

The companion attempts to choose its separate **Spektrafilm MIDI** application in Tangent Mapper and disable **Auto-select Application** while controlling the panels. It records the prior routing so it can restore its own change on Pause or normal exit. It leaves user maps intact. This depends on Mapper exposing the required accessibility controls; the setup status reports when manual selection is needed.

If asked to switch manually:

1. Leave the companion connected to **Tangent Hub**. Use **Advanced** if you need to change or reconnect the route.
2. Open Tangent Mapper's **Select Application** menu and turn **Auto-select Application** off.
3. Select **Spektrafilm MIDI** so it has the checkmark. The arrow beside an application opens maps; it does not activate the application.
4. On Essentials, check Kb screens for **Film Exp** and **Print Exp**. They may have an [off] prefix before arming. Check that Spektrafilm labels remain when Resolve is foreground.

The companion registers its bundled profiles/tangent directory. Do not copy those files over Resolve's maps. If the application is absent, confirm the connection and that the whole package was extracted. Resolve's A+B shortcut changes native/mappable modes; it does not select this separate application.

If you selected routing manually, restore **DaVinci Resolve** and your preferred Auto-select setting after pausing. Automatic restoration is limited to changes the companion made and still owns.

## When an edit is queued but nothing changes

**DELTA: QUEUED confirms receipt only.** A real host **Apply MIDI** callback must run to change OFX state. Look for **APPLY: APPLIED** and matching inspector/image feedback in Advanced diagnostics.

Automatic linking needs one fresh armed target, complete state, a unique visible/enabled Apply MIDI button and the exact nearby instance marker. Keep the MIDI controls visible. Target or inspector changes invalidate the binding. Automatic dispatch requires foreground Resolve; pending input expires two seconds after the latest movement. Return to Resolve and turn again if it expired.

If automatic linking is unavailable, **Advanced** retains **Find Apply buttons** and **Bind selected** with the same exact-marker checks. **Apply now** explicitly invokes a verified bound button while Resolve is in the background. Manual fallback: turn a control and click **Apply MIDI** directly in the effect within two seconds.

The app does not synthesize an OFX callback from a network request or use guessed mouse coordinates/global keys. Hosts without the required accessibility controls need manual Apply.

## Conventional MIDI

Under **Advanced**, choose **MIDI**, an existing input port and the controller's actual encoding. The default profile is profiles/midi/default-midi.json:

| Message | Assignment |
|---|---|
| CC 0–23 | Continuous axes 0–23, in Kb/Tk/Mf order |
| Note 0–23 | Reset corresponding axis on note-on |
| Note 32–43 | Bt's twelve feature-bank buttons |
| Note 44–55 | Mf's twelve programmable buttons |
| Note 56–63 | Kb/Tk/Bt/Mf A/B pairs, including momentary Fine |
| Note 64–68 | Reserved transport buttons, currently unavailable |

Binary offset uses 64 for no movement, 65 for +1 and 63 for −1. Two's complement, sign/magnitude, absolute 7-bit and absolute 14-bit are supported. A 14-bit axis pairs MSB CC 0–23 with LSB CC 32–55 on the same channel. Channel 0 accepts all; 1–16 filters one. The included optional bridge uses channel 1.

Absolute input uses soft takeover. Compound printer axes require relative input. Continuous OFX values retain fractions; encoding and mapping determine increments. Only one input adapter connects, preventing duplicate events.

## Optional Element → OSC → MIDI

Native Tangent provides dynamic displays without a virtual MIDI driver. The optional bridge tests MIDI ingress and requires an already installed virtual MIDI port; this repository installs no driver.

1. Create/select a virtual MIDI port in your existing MIDI software.
2. Import profiles/midi/element-osc-map.xml into a separate custom Tangent application/profile. It maps all 24 axes and 37 actions to loopback port 9000. Do not replace a valued Resolve map.
3. List outputs with python profiles/tools/osc_to_midi.py --list, then run python profiles/tools/osc_to_midi.py --port INDEX --channel 1.
4. In Advanced, choose that virtual MIDI input, channel 1 and RelativeBinaryOffset. Do not also connect native Tangent or the companion's OSC listener to the same controls/port.
5. Turn Mapper Auto-select off and select the custom application manually. Arm the MIDI effect and verify host Apply as above.

The loopback-only converter supports immediate OSC messages/bundles, preserves net large/fractional deltas and releases held actions on normal exit. The optional XML's integer movement can quantize input before conversion, and its labels are static. Driver/hardware validation remains open.

## Troubleshooting

- **Panels show Resolve controls:** follow setup status. If automatic Mapper selection is unavailable, disable Auto-select and checkmark Spektrafilm MIDI manually. Check labels with Resolve foreground.
- **Connection unavailable:** confirm Tangent Hub is running, panels are connected and the whole package is extracted. The app retries while running; use Advanced to select another route.
- **Control this effect cannot find it:** show the intended MIDI effect's controls. Confirm Spektrafilm MIDI (Community Beta). Click its Arm MIDI button if accessibility is unavailable; disarm other instances.
- **Queued edits do not change the image:** keep Resolve foreground and MIDI controls visible; check linked/Apply status. Turn again after returning to Resolve. Use manual Apply when needed.
- **Knobs too sensitive:** lower speed or hold Fine. Advanced shows raw increments. Use the current bundled profiles; earlier profiles rounded numeric feedback to whole numbers.
- **A control is off:** its processing mode or stage may hide it. Change the mode/enable control in the inspector.
- **Printer balance inactive:** the public build uses available C/M/Y controls. A future RGB printer-point schema needs Gang/Group disabled for opponent movement.
- **Labels do not change with banks:** native Tangent provides dynamic feedback; the OSC/MIDI profile has static labels.
- **Resolve controls do not return:** pause, then select DaVinci Resolve and your preferred Auto-select setting manually in Mapper. Split-panel ownership is not established.
- **MIDI direction wrong:** select the actual relative encoding in Advanced.
- **Undo/transport unavailable:** the Resolve command adapter is not implemented.
