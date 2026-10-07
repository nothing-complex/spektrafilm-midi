# Resolve and full Element acceptance checklist

Status: **physical acceptance pending**. Automated source/protocol tests do not establish Resolve responsiveness, rendering parity, undo, project persistence or screen layout. Record Resolve/Windows versions, exact sibling build manifest, GPU/driver, Tangent Hub version, panel types, MIDI port and chosen encoding with results. Use a disposable project.

## Coexistence and state isolation

- Record the regular plugin bundle hashes before and after sibling installation/removal. Confirm no regular bundle or regular defaults/presets changed.
- Load one regular and one sibling effect on different nodes; also test two instances and same-node stacking where Resolve allows it.
- Save/reopen with both identities. Removing the sibling must not prevent the regular node from resolving normally.
- Compare rendering only against the same source/data baseline. A different current official release is not a parity reference for this older community source.
- Change/save defaults in the sibling and confirm the regular version's defaults remain independent.

## Host changes and targeting

- Arm exactly one intended sibling, stationary playhead, inspector visible. Move one axis, commit, and verify inspector/image/confirmed feedback.
- Verify undo/redo through Resolve's normal controls, save/reopen, cache invalidation and exported frames. Repeat with presets and mouse edits.
- Verify queued changes never reach regular nodes, unarmed sibling nodes, stale tokens or copied/render-clone instances.
- Switch target while movement is queued; delete the armed node; reload project; close/restart companion. Confirm safe disarm and no stale command replay.
- Test manual Apply first. Separately test experimental automatic UI Automation Apply with wrong foreground app, hidden inspector, two Apply buttons, scroll position changes and modal dialogs. Ambiguous targeting must refuse activation.
- Test concurrent Kb movements and simultaneous Tk XY/ring movement. Confirm all net relative deltas survive coalescing and one intended grouped host transaction results.
- Test printer gang/group, HDR presets/manual changes and stock calibration dependencies. Calibration action currently remains in the inspector.
- Keep keyframed use outside supported claims until animated parameter behavior is explicitly verified.

## Hardware inventory

`profiles/coverage.json` and its automated tests establish the logical allocation: **24 continuous axes, 24 programmable buttons, 8 modifiers, 18 resets and 5 reserved transport roles**. Exercise each physical control separately and record its logical index/action; do not infer physical success from a synthetic packet.

- Kb: turn all twelve knobs both ways; reset all twelve; verify bank/page changes, fine movement and short-page inactive slots.
- Tk: exercise X/Y/ring for all three balls, both directions, and all six associated resets. In this build, verify M/Y/C fallback on the first ball/ring.
- Mf: exercise ball X/Y, focused ring, twelve programmable buttons, A/B and all five transport buttons. Transport/undo/redo must report unavailable rather than emit global input.
- Bt: verify all twelve feature-bank buttons and A/B. Lens/Motion must be visibly unavailable; stage toggle must act only where implemented.
- Hold/release modifiers, including overlapping holds, disconnection while held and Tangent's reserved A+B application switch. No fine modifier may remain stuck.
- Switch the entire panel set between native Resolve and the sibling custom application. Do not claim split ownership unless separately proven.

## Screens and input formats

- Confirm all bank/page names, slot labels, real values and current choice names fit each screen. Check off/unavailable, disarmed, reconnecting and target state.
- Change values with the mouse, load a preset, undo, change modes and rearm another target. Confirm screen values follow acknowledged host state.
- Check compound feedback and constrained resets against actual channel values when a future build offers printer density.
- Test actual MIDI positive/negative/fine/reset traffic for every declared encoding; channel rejection, note-off, velocity-zero, 14-bit pair isolation and absolute soft takeover.
- Test optional OSC→MIDI conversion separately, including large and fractional movement and paired resets. Document its static-label limitation.
- Measure controller→accepted-state latency separately from accepted-state→render/display latency. Test exposure, stock switches, grain and spatial effects at representative image sizes.

An unchecked item is an open acceptance condition. The profile's complete logical coverage does not convert reserved unavailable functions or a pending physical test into a release claim.
