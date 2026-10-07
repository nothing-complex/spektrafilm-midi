# Prototype setup and operating sequence

This is a separately identified community build. Read the root README for the current build/install commands and host-dispatch status. The regular Spektrafilm bundle is not a deployment target. Close Resolve before installing/removing an OFX binary.

1. Build/package the sibling and companion using the root scripts. Preview the installer first; its explicit apply option installs only `spektrafilm_midi.ofx.bundle`.
2. Restart Resolve. Confirm that regular Spektrafilm and **Spektrafilm MIDI** both appear. Add the MIDI variant to a disposable test grade; keep a regular instance for coexistence checks.
3. Start the companion. For Element, select its native Tangent connection and select **Spektrafilm MIDI** in Tangent Hub/Mapper. The companion advertises its bundled `profiles/tangent` directory as the system map location, with a separate user-map location. Do not copy these files over Resolve's installed maps.
4. In the intended MIDI effect, click **Arm MIDI**. Confirm the companion identifies one fresh armed target. There is no automatic selected-node following.
5. Turn Kb 1. Input is queued for the armed instance. Use the plugin's **Apply MIDI** action promptly (the prototype expires stale queued input after two seconds) to commit through a permitted host action unless the companion's experimental automatic Apply option has been deliberately enabled and validated. A queued acknowledgment is not evidence of changed OFX state.
6. Confirm the inspector value, image, companion value and panel feedback agree. Then test undo, save/reopen and rendered output before using a real project.
7. Disarm before switching targets or returning the panels to native Resolve operation. The regular plugin remains independently usable.

The optional automatic Apply path locates the actual Apply MIDI inspector button through Windows UI Automation. With the intended inspector visible, use **Find visible Apply buttons**, select its button, then **Bind selected button**. Binding requires the armed instance's target marker beside that button; a matching name alone is insufficient. Only then enable **Automatic Apply**. Activation requires foreground Resolve and the still-valid ownership marker. Bindings are cleared on target/inspector changes and are never restored automatically.

A transport request alone cannot manufacture an OFX UI-thread callback. If the button or ownership marker is not accessible, keep manual Apply. This capability is a prototype aid; physical Resolve acceptance is still required.

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
5. Select the custom Tangent profile, arm the intended MIDI effect, then verify the host commit path as above.

The converter binds loopback only, accepts immediate OSC messages/bundles, splits large deltas without clipping net movement, accumulates fractional deltas, and releases held action notes on normal exit. The supplied Mapper XML chooses relative integer OSC values; that setting can quantize hardware movement before the converter sees it. Its associated reset sends zero, which the converter translates into a separate reset note. Native Tangent avoids this quantization and provides the intended dynamic displays.

The bridge's WinMM device-open/output path and the imported OSC map still require actual hardware/driver validation. Offline tests exercise encoding/parsing; they do not establish a working virtual MIDI driver or physical display feedback.

## Troubleshooting

- **No target:** click Arm MIDI on the intended sibling instance; disarm other instances and wait for a fresh snapshot.
- **Values queue but image does not change:** the host Apply action has not run. Use Apply MIDI in the inspector and inspect the companion status.
- **A control is off:** it may be hidden by processing mode or stage state. Select the appropriate mode/enable switch through a mapped parameter or the inspector.
- **Printer balance is inactive:** this public build falls back to C/M/Y. If a later schema offers RGB printer points, disable Gang/Group before opponent movements.
- **Labels do not change after a bank switch:** use native Tangent rather than the static OSC/MIDI profile; verify the active application is Spektrafilm MIDI.
- **Resolve's usual panel controls stop:** switch the full set back to DaVinci Resolve in Tangent Hub/Mapper. Split-panel ownership has not been established.
- **MIDI direction is wrong:** select the controller's actual relative encoding. Do not compensate for an encoding mismatch by changing parameter bounds.
- **Undo/transport buttons report unavailable:** the prototype reserves them but does not implement the required Resolve command adapter.
