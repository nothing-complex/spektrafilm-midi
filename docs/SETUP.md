# Prototype setup and operating sequence

This is a separately identified community build. Read the root README for the current build/install commands and host-dispatch status. The regular Spektrafilm bundle is not a deployment target. Close Resolve before installing/removing an OFX binary.

1. Build/package the sibling and companion using the root scripts. Preview the installer first; its explicit apply option installs only `spektrafilm_midi.ofx.bundle`.
2. Restart Resolve. Confirm that regular Spektrafilm and **Spektrafilm MIDI (Community Beta)** both appear. Add the MIDI variant to a disposable test grade; keep a regular instance for coexistence checks. The regular effect has no MIDI controls.
3. Start the companion, choose one input route and click **Connect** each session. For Element's native route, choose **Tangent Hub** and complete the application-switching steps below before arming. Choosing an adapter alone does not connect it.
4. In the intended MIDI effect, click **Arm MIDI**. Confirm the companion identifies one fresh armed target. There is no automatic selected-node following.
5. Bind automatic Apply as described below, return to Resolve and turn Kb 1. Confirm **Host Apply: AUTO enabled (Resolve active)** and an **APPLIED** acknowledgment. For a manual test, turn Kb 1 and click the effect's **Apply MIDI** button within two seconds. **DELTA: QUEUED** confirms input receipt only; the host Apply action must run before OFX state changes.
6. Confirm the inspector value, image, companion value and panel feedback agree. Then test undo, save/reopen and rendered output before using a real project.
7. Disarm before switching targets or returning the panels to native Resolve operation. Select DaVinci Resolve in Mapper and restore Auto-select if wanted. The regular plugin remains independently usable.

The automatic Apply path locates the actual Apply MIDI inspector button through Windows UI Automation. With the intended inspector visible, use **Find visible Apply buttons**, select its button, then **Bind + enable Auto Apply**. This enables the checkbox after binding succeeds. Binding requires the armed instance's target marker beside that button; a matching name alone is insufficient. Automatic hardware dispatch requires foreground Resolve and the still-valid ownership marker. Bindings are cleared on target/inspector changes and are never restored automatically.

The persistent **Host Apply** line shows whether automatic Apply is **OFF**, **AUTO waiting for Resolve foreground**, or **AUTO enabled (Resolve active)**, plus the last Apply acknowledgment. Earlier settings can leave automatic Apply off despite a working controller connection. When Resolve is in the background, automatic application waits for it to regain focus, for up to two seconds after the latest input. Return to Resolve within that interval, or move a control again after returning. Expired input is discarded.

For explicit manual dispatch from the companion, click **Apply now** after binding. It immediately invokes the same verified host button even while Resolve is in the background; automatic Apply need not be enabled. The fresh armed target, unique button and exact instance-marker checks still apply. Queued input must still be less than two seconds old. A short live Element test has confirmed nonempty host Apply acknowledgments and changing Film Exposure, Print Exposure and Film Push/Pull in Resolve. Sensitivity calibration and the full hardware/host acceptance checklist remain open.

A transport request alone cannot manufacture an OFX UI-thread callback. If the button or ownership marker is not accessible, keep manual Apply. This capability is a prototype aid; physical Resolve acceptance is still required.

## Switching Element from Resolve to Spektrafilm

The panels must be assigned to the companion's separate application. Resolve's default setup keeps controlling Resolve, even when a Spektrafilm effect is visible.

1. In the companion, choose **Tangent Hub** and click **Connect**. Leave the companion running.
2. In Tangent Mapper, open **Select Application** and turn **Auto-select Application** off. With Auto-select enabled, bringing Resolve forward selects its usual application again; manually choosing Spektrafilm while Mapper has focus is not enough.
3. In the same menu, select **Spektrafilm MIDI** so the checkmark moves to it. The arrow beside an application opens its map choices; it does not activate that application.
4. Select **Essentials** in the companion. Check the Kb screens for **Film Exp**, **Print Exp** and the other Spektrafilm labels. Before an effect is armed, they may have an `[off]` prefix. Check the labels again after returning to Resolve: they should remain Spektrafilm labels.
5. Add the distinct **Spektrafilm MIDI (Community Beta)** effect, click its **Arm MIDI** button, and confirm a fresh target in the companion. Then turn Kb 1 and click **Apply MIDI** promptly for the first test.

The companion advertises its bundled `profiles/tangent` directory as the system map location, with a separate user-map location. There is no need to copy these files over Resolve's installed maps. If **Spektrafilm MIDI** is missing from Mapper, check the companion's connection status and that the package's `profiles/tangent` folder is present.

Version 0.1.3 includes a corrected native Tangent movement range and step. Existing users can keep their installed MIDI OFX binary, run the updated companion with its bundled profiles, then reconnect Tangent Hub so it registers the new controls. Confirm the intended application remains selected after reconnecting.

Resolve's A+B shortcut switches its native/mappable modes; it does not select the companion's application. Use Mapper to switch the full panel set. When finished, disarm the effect, select DaVinci Resolve again, and re-enable Auto-select if that is how you normally work.

## Adjusting sensitivity

Use **Relative speed ×** in the companion to adjust continuous relative movement. The default is `1`, with a `0.01–4` range. Start with `0.25` if the knobs still feel too fast; it produces one quarter of normal movement. The setting persists between sessions and affects native Tangent, relative MIDI and OSC input. Hold a mapped **Fine** modifier for another tenfold reduction.

Continuous OFX values already support fractions. Earlier native profiles used a generic step of `1` and an excessively broad movement range; that also rounded numeric feedback on the panel. The updated profile uses range `−100` to `100` and step `0.01`. The companion applies the parameter's own mapping step and the relative speed multiplier after receiving the movement. Choice, integer and boolean controls remain discrete and ignore the speed multiplier; absolute MIDI positions and resets are unaffected.

Check the input status line for the last axis and raw increment if movement is unexpectedly large. Judge the result against the inspector and companion value as well as the panel display. Physical calibration of the new default remains part of acceptance testing.

## Conventional MIDI

Select an existing MIDI input port in the companion and the controller's actual relative/absolute encoding. The default profile is documented by `profiles/midi/default-midi.json`:

| Message | Assignment |
|---|---|
| CC 0–23 | Continuous axes 0–23, in Kb/Tk/Mf order |
| Note 0–23 | Reset corresponding axis on note-on |
| Note 32–43 | Bt's twelve feature-bank buttons |
| Note 44–55 | Mf's twelve programmable buttons |
| Note 56–63 | Kb/Tk/Bt/Mf A/B pairs, including momentary Fine |
| Note 64–68 | Reserved transport buttons, currently unavailable |

The default relative encoding is **binary offset**: 64 is no movement, 65 is +1, 63 is −1. The companion also supports explicitly selected two's complement, sign magnitude, absolute 7-bit and absolute 14-bit input. A 14-bit axis uses MSB CC 0–23 plus LSB CC 32–55 on the same channel. Choose channel 1 for the included optional bridge; use the companion's filter for other devices. Do not select multiple adapters that process the same physical input.

Absolute input uses soft takeover. Compound printer axes require relative input. Full-precision parameter changes are independent of MIDI's 7-bit message resolution; selected encoding and mapping steps determine increments.

## Optional Element → OSC → MIDI

This route tests real MIDI ingress with Element on Windows. It needs an already installed virtual MIDI port; this repository installs no driver.

1. Create/select a virtual MIDI port using the user's chosen existing MIDI software.
2. Import `profiles/midi/element-osc-map.xml` into a separate custom Tangent application/profile. It maps all 24 axes and 37 action buttons. Do not import it over a valued Resolve map. Its OSC destination is localhost port 9000.
3. Run `python profiles/tools/osc_to_midi.py --list` to list existing MIDI outputs. Start `python profiles/tools/osc_to_midi.py --port INDEX --channel 1` with the selected output index.
4. In the companion, disable native/other OSC input for these controls, select the virtual MIDI input, channel 1 and RelativeBinaryOffset encoding. Do not simultaneously bind the companion OSC listener to port 9000.
5. Turn **Auto-select Application** off in Mapper and select the custom Tangent application so it has the checkmark. Arm the intended MIDI effect, then verify the host commit path as above.

The converter binds loopback only, accepts immediate OSC messages/bundles, splits large deltas without clipping net movement, accumulates fractional deltas, and releases held action notes on normal exit. The supplied Mapper XML chooses relative integer OSC values; that setting can quantize hardware movement before the converter sees it. Its associated reset sends zero, which the converter translates into a separate reset note. Native Tangent avoids this quantization and provides the intended dynamic displays.

The bridge's WinMM device-open/output path and the imported OSC map still require actual hardware/driver validation. Offline tests exercise encoding/parsing; they do not establish a working virtual MIDI driver or physical display feedback.

## Troubleshooting

- **Panels still show the default Resolve setup:** choose Tangent Hub and click Connect in the companion, turn Mapper's Auto-select Application off, then checkmark Spektrafilm MIDI. Check the Kb labels before testing OFX changes. A+B does not select this application.
- **Spektrafilm MIDI is absent from Mapper:** confirm the companion is connected to Tangent Hub and its bundled `profiles/tangent` folder is present. The application is registered by the running companion.
- **There is no Arm MIDI button:** confirm you added Spektrafilm MIDI (Community Beta), rather than regular Spektrafilm.
- **No target:** click Arm MIDI on the intended sibling instance; disarm other instances and wait for a fresh snapshot.
- **DELTA: QUEUED but image does not change:** receipt succeeded, but the host Apply action has not run. Check the persistent Host Apply line. If it says OFF, find the intended Apply button and use **Bind + enable Auto Apply**. If it is waiting for Resolve foreground, return to Resolve and move a control again. Confirm an APPLIED acknowledgment. Manual fallback: move a control, then click Apply MIDI in the effect within two seconds.
- **Panels work only while Mapper/Hub is active:** turn Mapper's **Auto-select Application** off and checkmark **Spektrafilm MIDI**, then check the panel labels again with Resolve foreground. An executable association does not keep the companion application selected when Resolve gains focus.
- **Knobs are too sensitive or values appear to jump by integers:** use the 0.1.3 companion with its bundled Tangent profiles and reconnect the Hub. Lower **Relative speed ×** (for example to `0.25`) or hold **Fine**. Continuous parameters retain fractions; choices and integer parameters intentionally move in discrete steps. Check the inspector and last raw increment to distinguish display rounding from actual parameter changes.
- **A control is off:** it may be hidden by processing mode or stage state. Select the appropriate mode/enable switch through a mapped parameter or the inspector.
- **Printer balance is inactive:** this public build falls back to C/M/Y. If a later schema offers RGB printer points, disable Gang/Group before opponent movements.
- **Labels do not change after a bank switch:** use native Tangent rather than the static OSC/MIDI profile; verify the active application is Spektrafilm MIDI.
- **Resolve's usual panel controls stop:** switch the full set back to DaVinci Resolve in Tangent Hub/Mapper. Split-panel ownership has not been established.
- **MIDI direction is wrong:** select the controller's actual relative encoding. Do not compensate for an encoding mismatch by changing parameter bounds.
- **Undo/transport buttons report unavailable:** the prototype reserves them but does not implement the required Resolve command adapter.
