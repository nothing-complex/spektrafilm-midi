"""Build the catalogue and Element maps from the public OFX descriptors.

Only the Python standard library is used. This audits source; live OFX descriptor
values remain authoritative. Run from any directory, with --check in CI.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
REFERENCE_SOURCE = ROOT / "profiles/reference/SpektraFilmPlugin.cpp"
UPSTREAM = "86476afc5b077de77e2278e3658d1ba9309892a1"


def arguments(text: str) -> list[str]:
    """Split a C++ argument list without splitting nested casts/expressions."""
    result, start, depth, quoted, escape = [], 0, 0, False, False
    for i, c in enumerate(text):
        if quoted:
            if escape:
                escape = False
            elif c == "\\":
                escape = True
            elif c == '"':
                quoted = False
        elif c == '"':
            quoted = True
        elif c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        elif c == "," and depth == 0:
            result.append(text[start:i].strip())
            start = i + 1
    result.append(text[start:].strip())
    return result


def calls(text: str, names: str):
    for match in re.finditer(r"\b(" + names + r")\s*\(", text):
        start, depth, quoted, escape = match.end(), 1, False, False
        for i in range(start, len(text)):
            c = text[i]
            if quoted:
                if escape:
                    escape = False
                elif c == "\\":
                    escape = True
                elif c == '"':
                    quoted = False
            elif c == '"':
                quoted = True
            elif c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    yield match.group(1), arguments(text[start:i]), text.count("\n", 0, match.start()) + 1
                    break


def string(value: str) -> str | None:
    if value.startswith('"'):
        return json.loads(value)
    return {"kGrainSeedParamName": "grainSeed"}.get(value)


def number(value: str):
    if value in ("true", "false"):
        return int(value == "true")
    if value == "kGrainSeedMin":
        return 0
    if value == "kGrainSeedMax":
        return 1000000
    try:
        return float(value)
    except ValueError:
        return None


def extract_catalog(source: str) -> dict:
    metadata_text = source.split("kParamMetadata[] = {", 1)[1].split("\n};", 1)[0]
    metadata = {n: {"group": g, "development": "development" in t.lower(), "flow": "flow" in t.lower()}
                for n, g, t in re.findall(r'\{"([^"]+)",\s*"([^"]+)",\s*([^}]+)\}', metadata_text)}
    defaults_text = source.split("kParamDefaults[] = {", 1)[1].split("\n};", 1)[0]
    defaults = {}
    for kind, args, _ in calls(defaults_text, "intDefault|boolDefault|doubleDefault|double2DDefault|double3DDefault"):
        name = string(args[0])
        defaults[name] = {"default": [number(x) for x in args[1:]], "defaultExpression": args[1:], "kind": kind}
    arrays = {name: re.findall(r'"((?:[^"\\]|\\.)*)"', content)
              for name, content in re.findall(r'const char \*(\w+)\[\]\s*=\s*\{(.*?)\};', source, re.S)}
    descriptors = {}
    kinds = "defineDouble3DRange|defineDouble2DRange|defineDouble3D|defineDouble2D|defineDouble|defineInt|defineBool|defineRGB|defineChoice|definePushButton|defineHiddenBool|defineLabel|defineString"
    for kind, a, line in calls(source, kinds):
        if len(a) < 3 or a[0] != "paramSet":
            continue
        name = string(a[1])
        if not name:
            continue
        label = string(a[2]) or name
        entry = {"id": name, "label": label, "sourceLine": line, "group": metadata.get(name, {}).get("group", string(a[-1]) or "management"),
                 "metadata": name in metadata, "development": metadata.get(name, {}).get("development", False),
                 "components": 1, "minimum": None, "maximum": None, "choices": [], "runtimeAuthoritative": True}
        if "3D" in kind or kind == "defineRGB":
            entry["components"] = 3
        elif "2D" in kind:
            entry["components"] = 2
        if kind in ("defineBool", "defineHiddenBool"):
            entry.update(type="boolean", minimum=0, maximum=1)
        elif kind == "defineInt":
            entry.update(type="integer", minimum=number(a[4]), maximum=number(a[5]))
        elif kind == "defineChoice":
            entry.update(type="choice", choices=arrays.get(a[3], []), minimum=0)
            if entry["choices"]:
                entry["maximum"] = len(entry["choices"]) - 1
        elif kind == "definePushButton":
            entry["type"] = "action"
        elif kind in ("defineLabel", "defineString"):
            entry["type"] = "text"
        else:
            entry["type"] = "double"
            if kind == "defineDouble":
                entry.update(minimum=number(a[4]), maximum=number(a[5]))
            elif "Range" in kind:
                ix = 3 + entry["components"]
                entry.update(minimum=number(a[ix]), maximum=number(a[ix + 1]))
        entry.update(defaults.get(name, {"default": [], "defaultExpression": []}))
        if kind == "defineHiddenBool":
            entry["excludedReason"] = "Internal stock-calibration ownership; use the calibration action."
        elif entry["type"] == "action":
            entry["excludedReason"] = "Requires an explicit semantic host action; this numeric control protocol does not implement it."
        elif entry["type"] == "text":
            entry["excludedReason"] = "Read-only information or text management; use the OFX inspector."
        elif name not in metadata:
            entry["excludedReason"] = "Preset/LUT/controller management remains in the OFX inspector."
        else:
            entry["excludedReason"] = None
        descriptors[name] = entry
    missing = sorted(set(metadata) - set(descriptors))
    if missing:
        raise ValueError("Unparsed source metadata: " + ", ".join(missing))
    return {"schemaVersion": 1, "upstreamCommit": UPSTREAM, "pluginFlavor": "FilmDev", "metadataCount": len(metadata),
            "sourceSha256": hashlib.sha256(source.encode()).hexdigest(), "parameters": list(descriptors.values())}


def short(name: str) -> str:
    return re.sub(r"\s+", " ", name).strip()[:12]


def default_step(p: dict) -> float:
    if p["type"] in ("integer", "boolean", "choice"):
        return 1
    explicit = {"filmExposureEv": .025, "printExposureEv": .025, "filmPushPullStops": .01, "printPushPullStops": .01,
                "printerLightR": .1, "printerLightG": .1, "printerLightB": .1, "printShadowShape": .005,
                "printHighlightShape": .005, "grainAmount": .01, "halationAmount": .01,
                "cameraDiffusionStrength": .01, "enlargerScale": .01,
                "enlargerOffsetXPercent": .1, "enlargerOffsetYPercent": .1,
                "preflashMFilterShift": .1, "preflashYFilterShift": .1, "preflashExposure": .005}
    if p["id"] in explicit:
        return explicit[p["id"]]
    if p["minimum"] is not None and p["maximum"] is not None:
        return float(f"{(p['maximum'] - p['minimum']) / 400:.6g}")
    return .01


def profiles(catalog: dict) -> dict:
    params = {p["id"]: p for p in catalog["parameters"]}
    def slot(name: str, component=0, label=None):
        p = params[name]
        suffix = (" RGB"[component + 1] if p["components"] == 3 else "XY"[component]) if p["components"] > 1 else ""
        return {"parameter": name, "component": component, "label": short(label or p["label"] + (" " + suffix if suffix else "")), "step": default_step(p)}
    essentials_names = ["filmExposureEv", "printExposureEv", "filmPushPullStops", "printPushPullStops", "printerLightR", "printerLightG", "printerLightB", "printShadowShape", "printHighlightShape", "grainAmount", "halationAmount", "cameraDiffusionStrength"]
    essentials_labels = ["Film Exp", "Print Exp", "Film Push", "Print Push", "Printer R", "Printer G", "Printer B", "Print Shadow", "Print Hi", "Grain", "Halation", "Cam Diffuse"]
    essentials = [slot(n, label=l) for n, l in zip(essentials_names, essentials_labels)]
    # Academy printer density requires standards data absent from the public
    # checkout. Keep every physical input useful with the filtered enlarger.
    for index, name, label in [(4, "filterC", "C Filter"), (5, "filterMShift", "M Filter"), (6, "filterYShift", "Y Filter")]:
        essentials[index]["fallbacks"] = [slot(name, label=label)]
    terms = lambda scales: [{"parameter": p, "component": 0, "scale": s} for p, s in zip(["printerLightR", "printerLightG", "printerLightB"], scales)]
    permanent = [
        {"operation": "printer-x", "label": "Print R/B", "step": .1, "terms": terms([1, 0, -1]), "reset": "printer-chroma"},
        {"operation": "printer-y", "label": "Print G/RB", "step": .1, "terms": terms([-.5, 1, -.5]), "reset": "printer-chroma"},
        {"operation": "printer-neutral", "label": "Print Level", "step": .1, "terms": terms([1, 1, 1]), "reset": "printer-neutral"},
        slot("enlargerOffsetXPercent", label="Enlarge X"), slot("enlargerOffsetYPercent", label="Enlarge Y"), slot("enlargerScale", label="Enlarge Size"),
        slot("preflashMFilterShift", label="Preflash M"), slot("preflashYFilterShift", label="Preflash Y"), slot("preflashExposure", label="Preflash Exp"),
        slot("printShadowShape", label="Print Shadow"), slot("printHighlightShape", label="Print Hi"),
        {"operation": "focused", "label": "Focus Trim", "step": 1}]
    for index, name, label in [(0, "filterMShift", "M Filter"), (1, "filterYShift", "Y Filter"), (2, "filterC", "C Filter")]:
        permanent[index]["fallbacks"] = [slot(name, label=label)]
    axes = []
    for panel, count, start, offset in [("Kb", 12, 0x1001, 0), ("Tk", 9, 0x1101, 12), ("Mf", 3, 0x1201, 21)]:
        for i in range(count):
            default_slot = (essentials+permanent)[offset+i]
            initial_label = default_slot.get("fallbacks", [default_slot])[0]["label"]
            axes.append({"id": f"0x{start+i:04X}", "index": offset+i, "label": initial_label, "panel": panel, "physicalType": "Encoder", "number": i, "midiCC": offset+i, "midiResetNote": offset+i})
    bank_defs = [("essentials", "Essentials", []), ("film", "Film", ["filmGroup", "filteringGroup", "couplerGroup"]),
                 ("print", "Print", ["printGroup"]), ("printer", "Printer", ["enlargerGroup"]),
                 ("grain", "Grain", ["grainGroup", "grainSynthesisGroup"]), ("halation", "Halation", ["halationGroup"]),
                 ("diffusion", "Diffusion", ["diffusionGroup"]), ("scanner", "Scanner", ["scannerGroup"]),
                 ("lens", "Lens N/A", []), ("motion", "Motion N/A", []), ("color", "Color / I-O", ["colorGroup", "manageGroup"]),
                 ("favorites", "Favorites", [])]
    banks = []
    for index, (name, label, groups) in enumerate(bank_defs):
        supported = name not in ("lens", "motion")
        entries = [slot(p["id"], c) for p in params.values() if p["group"] in groups and not p["excludedReason"] for c in range(p["components"])]
        if name in ("essentials", "favorites"):
            entries = essentials
        elif name == "printer":
            entries = [slot(n) for n in ["printerLightR", "printerLightG", "printerLightB", "printerLightsGang", "printerLightsGroup", "printerLightCalibration", "filterC", "filterMShift", "filterYShift", "preflashExposure", "preflashMFilterShift", "preflashYFilterShift"]] + entries
        pages = []
        for page in range(max(1, (len(entries)+11)//12)):
            slots = entries[page*12:(page+1)*12]
            slots += [{"operation": "unavailable", "label": "--", "reason": "No additional parameter on this page."}] * (12-len(slots))
            slots += permanent if supported else [{"operation": "unavailable", "label": "N/A", "reason": "Absent from the public source baseline."}] * 12
            stage = {"grain": "grainEnabled", "halation": "halationEnabled", "scanner": "scannerEnabled"}.get(name)
            if name == "diffusion":
                stage = "cameraDiffusionEnabled" if page == 0 else "printDiffusionEnabled"
            pages.append({"name": label if page == 0 else f"{label} {page+1}", "stageParameter": stage, "slots": slots})
        banks.append({"id": f"0x{0x2001+index:04X}", "name": name, "label": label, "supported": supported,
                      "unavailableReason": None if supported else "This baseline has no newer Lens / Gate / Motion effects.", "pages": pages})
    buttons = []
    def button(id_, panel, number_, action, label, kind="programmable", **extra):
        buttons.append({"id": f"0x{id_:04X}", "panel": panel, "physicalType": "Button", "number": number_, "action": action, "label": label, "kind": kind, "midiNote": 32+len(buttons), **extra})
    for i, b in enumerate(banks):
        button(0x3001+i, "Bt", i, "bank:"+b["name"], b["label"])
    mf_actions = [("disarm", "Disarm"), ("refresh", "Refresh"), ("page:prev", "Prev Page"), ("page:next", "Next Page"),
                  ("focus:prev", "Prev Focus"), ("focus:next", "Next Focus"), ("unsupported:undo", "Undo N/A"),
                  ("unsupported:redo", "Redo N/A"), ("capture:A", "Capture A"), ("capture:B", "Capture B"), ("recall:toggle", "Recall A/B"), ("apply", "Apply")]
    for i, (a, l) in enumerate(mf_actions):
        button(0x3011+i, "Mf", i, a, l)
    for i, (panel, a, b, action, label) in enumerate([("Kb",12,13,"page:next","Next Page"), ("Tk",0,7,"page:prev","Prev Page"), ("Bt",12,13,"toggle:stage","Stage On/Off"), ("Mf",12,18,"focus:next","Next Focus")]):
        button(0x3021+i*2, panel, a, "fine", "Fine (hold)", "modifier", momentary=True)
        button(0x3022+i*2, panel, b, action, label, "modifier")
    for i, (a,l) in enumerate([("unsupported:play-reverse","Reverse N/A"), ("unsupported:stop","Stop N/A"), ("unsupported:play-forward","Play N/A"), ("unsupported:frame-prev","Frame- N/A"), ("unsupported:frame-next","Frame+ N/A")]):
        button(0x3031+i, "Mf", 13+i, a, l, "transport")
    resets = [{"panel": "Kb", "knobNumber": i+1, "kind": "encoder-press", "axes": [i], "via": "Hub ParameterReset of mapped encoder"} for i in range(12)]
    for i in range(3):
        resets += [{"panel": "Tk", "ballNumber": i+1, "kind": "ball-reset", "axes": [12+i*3, 13+i*3], "via": "Hub ParameterReset of mapped XY encoders"},
                   {"panel": "Tk", "ringNumber": i+1, "kind": "ring-reset", "axes": [14+i*3], "via": "Hub ParameterReset of mapped ring"}]
    return {"schemaVersion": 1, "appName": "Spektrafilm MIDI", "tangentPort": 64246, "defaultBank": "essentials", "fineScale": .1,
            "axes": axes, "banks": banks, "buttons": buttons, "resets": resets,
            "notes": ["Live OFX schema and explicit arming control availability.", "Reset buttons are associated with encoders by Tangent Hub, not remapped as action buttons.", "Undo and transport are deliberately unavailable until a foreground Resolve command adapter is validated.", "All source-development controls are exposed by the sibling FilmDev flavor; conditional processing/stage availability still applies.", "Source-only Academy printer density requires standards data missing from this checkout. Slots fall back to filtered-enlarger C/M/Y when printer points are absent from the live schema."]}


def xml_bytes(root):
    ET.indent(root, space="    ")
    return b'<?xml version="1.0" encoding="utf-8" standalone="yes"?>\n' + ET.tostring(root, encoding="utf-8") + b"\n"


def tangent_xml(mapping):
    root = ET.Element("TangentWave", fileType="ControlSystem", fileVersion="3.0")
    caps = ET.SubElement(root, "Capabilities")
    ET.SubElement(caps, "Jog", enabled="false")
    ET.SubElement(caps, "Shuttle", enabled="false")
    ET.SubElement(caps, "StatusDisplay", lineCount="3")
    settings = ET.SubElement(root, "DefaultGlobalSettings")
    for t in ("KnobSensitivity", "JogDialSensitivity", "TrackerballSensitivity", "TrackerballDialSensitivity"):
        ET.SubElement(settings, t, std="1", alt="1")
    ET.SubElement(settings, "IndependentPanelBanks", enabled="false")
    modes = ET.SubElement(root, "Modes")
    # The companion creates this catalogue bank only after receiving a live
    # schema. Hub must still know its mode and physical maps in advance.
    native_modes = mapping["banks"] + [{"id": "0x20FF", "label": "All Parameters"}]
    for b in native_modes:
        ET.SubElement(ET.SubElement(modes, "Mode", id=b["id"]), "Name").text = b["label"]
    controls = ET.SubElement(root, "Controls")
    for a in mapping["axes"]:
        p = ET.SubElement(controls, "Parameter", id=a["id"])
        ET.SubElement(p, "Name").text = a["label"]
        # These are abstract Hub movement units, converted by the companion's
        # parameter-specific step; the OFX schema supplies the real edit bounds.
        # Hub uses the range for sensitivity, so an effectively unbounded range
        # makes small physical movements excessively large. A fractional step
        # also lets its Number displays show decimals instead of whole numbers.
        ET.SubElement(p, "MinValue").text = "-100"
        ET.SubElement(p, "MaxValue").text = "100"
        ET.SubElement(p, "StepSize").text = "0.01"
    for b in mapping["buttons"]:
        ET.SubElement(ET.SubElement(controls, "Action", id=b["id"]), "Name").text = b["label"]
    outputs = {"tangent/controls.xml": xml_bytes(root)}
    for panel in ("Kb", "Tk", "Bt", "Mf"):
        root = ET.Element("TangentWave", fileType="PanelMap", fileVersion="3.0")
        p = ET.SubElement(ET.SubElement(root, "Panels"), "Panel", type="Element-"+panel)
        for bank in native_modes:
            mode = ET.SubElement(p, "Mode", id=bank["id"])
            groups = {}
            for axis in mapping["axes"]:
                if axis["panel"] != panel:
                    continue
                group = "Encoder" if panel == "Kb" else "Trackerball"
                groups.setdefault(group, []).append((axis, True))
            for button in mapping["buttons"]:
                if button["panel"] != panel:
                    continue
                group = "Button" if button["kind"] == "programmable" else "Standard"
                groups.setdefault(group, []).append((button, False))
            for group, entries in groups.items():
                b = ET.SubElement(ET.SubElement(mode, "ControlBank", id=group), "Bank")
                for item, encoder in entries:
                    control = ET.SubElement(b, "Control", type="Encoder" if encoder else "Button", number=str(item["number"]))
                    for layer in ("Std", "Alt"):
                        m = ET.SubElement(control, "Mapping", mode=layer)
                        ET.SubElement(m, "Key").text = item["id"]
                        if encoder:
                            ET.SubElement(m, "Display").text = "Number"
                        else:
                            ET.SubElement(m, "CustomName").text = item["label"]
        outputs[f"tangent/element-{panel.lower()}-map.xml"] = xml_bytes(root)
    return outputs


def osc_xml(mapping):
    """A separate optional Mapper profile; never replaces native default maps."""
    root = ET.Element("TangentWave", fileType="PanelMap", fileVersion="3.0")
    modes = ET.SubElement(root, "UserModes")
    ET.SubElement(ET.SubElement(modes, "Mode", id="0x83001001"), "Name").text = "Spektrafilm MIDI OSC"
    panels = ET.SubElement(root, "Panels")
    for panel in ("Kb", "Tk", "Bt", "Mf"):
        mode = ET.SubElement(ET.SubElement(panels, "Panel", type="Element-"+panel, number="1"), "Mode", id="0x83001001")
        groups = {}
        for axis in mapping["axes"]:
            if axis["panel"] == panel:
                groups.setdefault("Encoder" if panel == "Kb" else "Trackerball", []).append((axis, True))
        for button in mapping["buttons"]:
            if button["panel"] == panel:
                groups.setdefault("Button" if button["kind"] == "programmable" else "Standard", []).append((button, False))
        for group, entries in groups.items():
            bank = ET.SubElement(ET.SubElement(mode, "ControlBank", id=group), "Bank")
            for item, encoder in entries:
                control = ET.SubElement(bank, "Control", type="Encoder" if encoder else "Button", number=str(item["number"]))
                for layer in ("Std", "Alt"):
                    m = ET.SubElement(control, "Mapping", mode=layer)
                    ET.SubElement(m, "Key").text = "0x81000007" if encoder else "0x80000014"
                    address = f"/spektrafilm/axis/{item['index']}" if encoder else f"/spektrafilm/button/{item['midiNote']}"
                    ET.SubElement(m, "CustomControl").text = address
                    ET.SubElement(m, "CustomName").text = item["label"]
                    ET.SubElement(m, "Argument").text = "0x00000000"
                    if encoder:
                        ET.SubElement(m, "Display").text = "Number"
                        ET.SubElement(m, "Value1").text = "-1000.000000"
                        ET.SubElement(m, "Value2").text = "1000.000000"
                        ET.SubElement(m, "Value3").text = "1.000000"
    settings = ET.SubElement(root, "GlobalSettings")
    for t in ("KnobSensitivity", "JogDialSensitivity", "TrackerballSensitivity", "TrackerballDialSensitivity"):
        ET.SubElement(settings, t, std="1", alt="1")
    ET.SubElement(settings, "IndependentPanelBanks", enabled="false")
    ET.SubElement(settings, "OSCPort").text = "9000"
    return xml_bytes(root)


def coverage(catalog, mapping):
    expected = {(p["id"], c) for p in catalog["parameters"] if not p["excludedReason"] for c in range(p["components"])}
    actual = {(s["parameter"], s.get("component", 0)) for b in mapping["banks"] for page in b["pages"] for s in page["slots"] if "parameter" in s}
    missing = sorted(expected-actual)
    if missing:
        raise ValueError("Unmapped public parameter components: " + repr(missing))
    return {"schemaVersion": 1, "continuousAxes": len(mapping["axes"]), "programmableButtons": sum(b["kind"] == "programmable" for b in mapping["buttons"]),
            "modifiers": sum(b["kind"] == "modifier" for b in mapping["buttons"]), "transportButtons": sum(b["kind"] == "transport" for b in mapping["buttons"]),
            "resetButtons": len(mapping["resets"]), "metadataParameters": catalog["metadataCount"], "mappedParameters": len({n for n,c in expected}),
            "mappedParameterComponents": len(expected), "missingComponents": missing,
            "excluded": [{"id": p["id"], "reason": p["excludedReason"]} for p in catalog["parameters"] if p["excludedReason"]],
            "buildConditional": [{"ids": ["printerLightR", "printerLightG", "printerLightB", "printerLightsGang", "printerLightsGroup", "printerLightCalibration"], "reason": "Academy printer-density standards data is absent from the public checkout; numeric aliases fall back to filtered-enlarger C/M/Y where provided."}],
            "hardwareValidation": "Pending physical Hub/panel verification; this report validates IDs and source coverage only."}


def build(check=False):
    # Pin catalogue extraction to the inspected upstream baseline, not additions
    # such as companion management controls in the sibling source.
    source = REFERENCE_SOURCE.read_text(encoding="utf-8")
    catalog = extract_catalog(source)
    mapping = profiles(catalog)
    audit = coverage(catalog, mapping)
    outputs = tangent_xml(mapping)
    outputs["midi/element-osc-map.xml"] = osc_xml(mapping)
    outputs["midi/default-midi.json"] = (json.dumps({"schemaVersion": 1, "channel": 1, "encoding": "RelativeBinaryOffset", "axes": [{"axis": a["index"], "cc": a["midiCC"], "resetNote": a["midiResetNote"]} for a in mapping["axes"]], "buttons": [{"note": b["midiNote"], "action": b["action"], "label": b["label"]} for b in mapping["buttons"]]}, indent=2) + "\n").encode()
    for name, content in [("catalog.json", catalog), ("mappings.json", mapping), ("coverage.json", audit)]:
        outputs[name] = (json.dumps(content, indent=2, ensure_ascii=True) + "\n").encode()
    changed = []
    for rel, content in outputs.items():
        path = ROOT / "profiles" / rel
        if not path.exists() or path.read_bytes() != content:
            changed.append(rel)
            if not check:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(content)
    if check and changed:
        raise SystemExit("Generated profiles differ: " + ", ".join(changed))
    print(f"Validated {audit['continuousAxes']} axes, {audit['programmableButtons']} programmable buttons, {audit['modifiers']} modifiers, {audit['resetButtons']} resets, {audit['transportButtons']} transport roles; {audit['mappedParameterComponents']} parameter components, no omissions.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    build(parser.parse_args().check)
