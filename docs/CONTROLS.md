# Element control layout

The community sibling uses the public Spektrafilm source at `86476afc5b077de77e2278e3658d1ba9309892a1`, with its FilmDev controls exposed. It does not reproduce the newer installed 0.3.x product. The live OFX schema decides whether each control is present and usable. The native Tangent adapter updates names and values after a host snapshot; pending changes are not confirmed values.

## All continuous controls

| Input | Essentials assignment |
|---|---|
| Kb 1–4 | Film exposure, print exposure, film push/pull, print push/pull |
| Kb 5–7 | Enlarger C, M, Y filters; RGB printer points if the build/schema supports them |
| Kb 8–9 | Print shadow and highlight shape |
| Kb 10–12 | Grain amount, halation amount, camera diffusion strength |
| Tk ball 1 X/Y and ring 1 | M/Y balance and C filter; opponent printer balance and neutral trim if supported |
| Tk ball 2 X/Y and ring 2 | Enlarger horizontal/vertical position and scale |
| Tk ball 3 X/Y and ring 3 | Preflash M/Y shift and exposure |
| Mf ball X/Y | Print shadow/highlight shape |
| Mf ring | Trim the explicitly focused parameter; focus follows the last adjusted scalar or Mf focus buttons |

This uses all **24 continuous axes**: 12 Kb, 9 Tk, 3 Mf. Kb changes by bank/page; Tk and Mf retain the assignments above on supported banks. Spare Kb slots on short pages show `--` and do not write a parameter. Lens and Motion banks show unavailable because these effects are absent from the source baseline.

Academy printer density is disabled in the supplied build because the public checkout does not include its required standards data. The six affected Essentials/Tk slots automatically fall back to actual C/M/Y filter controls. No installed commercial runtime data is copied into the community build.

When available, printer axes use ΔR = L + X − Y/2, ΔG = L + Y, ΔB = L − X − Y/2. Combined movement is scaled at bounds to retain its direction. Gang and Group must be off for opponent adjustments. This is a useful RGB transform, not a perceptually uniform wheel.

## Banks and pages

Bt buttons 1–12 select **Essentials, Film, Print, Printer, Grain, Halation, Diffusion, Scanner, Lens N/A, Motion N/A, Color/I-O, Favorites**. Film includes camera filtering and DIR couplers. Advanced groups and all vector components have additional pages. Favorites initially duplicates Essentials and can be edited in `profiles/mappings.json`.

The companion's bank menu also provides **All Parameters**, generated from the live available schema. Its native mode is declared in advance so selecting it retains functioning panel maps. This extra browser is not one of the twelve Bt feature buttons.

The source catalogue has 144 metadata entries. **140 numeric/choice/boolean parameters, expanded to 160 components, have explicit reachable slots.** This source-coverage figure includes build-conditional printer controls; it is not a claim that all 140 are visible in every processing mode. Read-only information and inspector management actions have explicit exclusions in `profiles/coverage.json`. The calibration pushbutton remains an inspector action; changing its hidden ownership flag is not an equivalent operation.

## Buttons, modifiers and resets

| Panel | A | B |
|---|---|---|
| Kb | Hold for fine adjustment | Next page |
| Tk | Hold for fine adjustment | Previous page |
| Bt | Hold for fine adjustment | Toggle current stage where implemented |
| Mf | Hold for fine adjustment | Next focused parameter |

Fine adjustment uses one tenth the normal step. Stage toggle follows the current Grain, Halation, Scanner or Diffusion page; the first Diffusion page toggles camera diffusion and the second toggles print diffusion. Other pages report no stage toggle. A+B remains reserved for Tangent/Resolve's native/mappable switching; it does not select Spektrafilm MIDI. Use Mapper's Select Application menu with Auto-select Application off to activate this separate app. Do not replace A+B with a grading reset.

All twelve Kb presses reset their assigned component. The six Tk reset buttons reset the associated ball XY pair or ring. Tangent Hub supplies these as managed `ParameterReset` events; the XML does not override them with fabricated raw button IDs. Printer-ball reset removes chromatic offsets while retaining mean level. Printer-ring reset removes mean level while retaining chromatic offsets, constrained to legal limits. These compound behaviors require physical validation.

Mf programmable buttons 1–12 are:

1. Disarm the current controller target.
2. Request authoritative state refresh.
3. Previous page.
4. Next page.
5. Previous focused parameter.
6. Next focused parameter.
7. Undo — currently unavailable.
8. Redo — currently unavailable.
9. Capture comparison A for this target.
10. Capture comparison B for this target.
11. Queue alternate A/B recall.
12. Request Apply.

Initial arming is deliberately an **Arm MIDI** action in the intended OFX instance. A panel cannot infer the selected Resolve node. Capture reads the last authoritative snapshot; apply any pending edits before capture. Comparison recall is queued and uses the same host commit mechanism as individual edits.

The five dedicated transport buttons have reserved, labelled roles for reverse, stop, forward, previous frame and next frame. They are **unavailable in this prototype** until a foreground Resolve transport adapter is validated. They never emit global keystrokes. The Mf Grade/Browse/Transport cycle from the plan is also not implemented; focus navigation supplies useful parameter browsing now.

## Displays

Native managed controls supply slot names and real numeric values; textual choices are included in refreshed names. Mf status text identifies bank and arm/connection state. Inactive/hidden fields are marked off. The physical screens have limited width: short labels and truncation must be checked on the actual panels.

No pixel graphics, arbitrary screen layout, reliable split ownership with native Resolve panels, or physical display acceptance is claimed. Switch the full set between the Spektrafilm MIDI application and DaVinci Resolve in Tangent Hub/Mapper.

The optional OSC-to-MIDI profile has static labels and is useful for verifying actual MIDI ingress. Use the native Tangent adapter for dynamic bank labels and authoritative display feedback.

## Profile maintenance

`profiles/mappings.json` is the companion's runtime mapping. Each page has 24 slots, and compound or focused operations are explicit. The generated source catalogue is an audit aid; runtime bounds, defaults, choices and availability are authoritative. Dynamic stock defaults and unconstrained vector bounds are not invented in the source catalogue.

To regenerate the pinned baseline profiles, run `python profiles/tools/generate_profiles.py`; to verify committed outputs, add `--check`. Regeneration overwrites mapping customizations, so save user changes separately first. Run `python -m unittest discover -s profiles/tests -v` for parser, coverage, native-map and optional OSC/MIDI checks.

XML syntax follows installed Tangent managed maps and [CommandPost's primary-source XML emitter](https://github.com/CommandPost/CommandPost/tree/develop/src/plugins/core/tangent/manager). Parameter resets and values follow the [Tangent protocol reference](https://www.hammerspoon.org/docs/hs.tangent.html). These tests validate structural consistency; Tangent Hub's live acceptance remains a hardware test.
