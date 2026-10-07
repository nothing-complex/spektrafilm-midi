"""Source-coverage, wire-ID and native-map checks; no device is accessed."""
import copy
import importlib.util
import json
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("generate_profiles", ROOT / "profiles/tools/generate_profiles.py")
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)


class ProfilesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.mapping = json.loads((ROOT / "profiles/mappings.json").read_text())
        cls.catalog = json.loads((ROOT / "profiles/catalog.json").read_text())

    def test_generated_files_match_source(self):
        generator.build(check=True)

    def test_descriptor_parser_preserves_nested_choices_and_vectors(self):
        self.assertEqual(generator.arguments('paramSet, "film", "Stock", films.data(), static_cast<int>(films.size()), static_cast<int>(defaultIndex), "filmGroup"')[4], "static_cast<int>(films.size())")
        p = {p["id"]: p for p in self.catalog["parameters"]}
        self.assertEqual(p["dirGammaRToGb"]["components"], 2)
        self.assertEqual(p["dirGammaSameLayerRgb"]["components"], 3)
        self.assertEqual(p["grainMicroStructure"]["components"], 2)
        self.assertEqual(p["filmExposureEv"]["minimum"], -8)
        self.assertEqual(p["filmExposureEv"]["maximum"], 8)
        self.assertEqual(p["filmFormat"]["choices"][4], "35mm")
        self.assertIsNone(p["film"]["default"][0])  # Runtime stock catalogue decides index.

    def test_every_editable_component_has_a_reachable_slot(self):
        audit = generator.coverage(self.catalog, self.mapping)
        self.assertEqual(audit["missingComponents"], [])
        # A component can disappear even when the parameter name remains mapped.
        broken = copy.deepcopy(self.mapping)
        for bank in broken["banks"]:
            for page in bank["pages"]:
                for slot in page["slots"]:
                    if slot.get("parameter") == "grainParticleScale" and slot.get("component") == 2:
                        slot.clear()
                        slot.update(operation="unavailable", label="--")
        with self.assertRaisesRegex(ValueError, "grainParticleScale"):
            generator.coverage(self.catalog, broken)

    def test_full_hardware_and_midi_address_space(self):
        axes = self.mapping["axes"]
        self.assertEqual([a["index"] for a in axes], list(range(24)))
        self.assertEqual([a["midiCC"] for a in axes], list(range(24)))
        self.assertEqual(len({a["id"] for a in axes}), 24)
        self.assertEqual({p: sum(a["panel"] == p for a in axes) for p in ("Kb", "Tk", "Mf")}, {"Kb": 12, "Tk": 9, "Mf": 3})
        buttons = self.mapping["buttons"]
        self.assertEqual(len(buttons), 37)
        self.assertEqual([b["midiNote"] for b in buttons], list(range(32, 69)))
        self.assertEqual(len({(b["panel"], b["number"]) for b in buttons}), 37)
        self.assertEqual(len(self.mapping["resets"]), 18)
        self.assertEqual(sum(len(r["axes"]) for r in self.mapping["resets"]), 21)
        self.assertEqual(len({b["id"] for b in buttons} | {a["id"] for a in axes} | {b["id"] for b in self.mapping["banks"]}), 73)

    def test_page_shapes_and_conditional_standards_fallbacks(self):
        for bank in self.mapping["banks"]:
            for page in bank["pages"]:
                self.assertEqual(len(page["slots"]), 24, page["name"])
        first = self.mapping["banks"][0]["pages"][0]["slots"]
        for axis, parameter in [(4,"filterC"),(5,"filterMShift"),(6,"filterYShift"),(12,"filterMShift"),(13,"filterYShift"),(14,"filterC")]:
            self.assertEqual(first[axis]["fallbacks"][0]["parameter"], parameter)
        for bank in self.mapping["banks"]:
            if bank["name"] in ("lens", "motion"):
                self.assertFalse(bank["supported"])
        banks = {b["name"]: b for b in self.mapping["banks"]}
        self.assertEqual(banks["scanner"]["pages"][0]["stageParameter"], "scannerEnabled")
        self.assertEqual(banks["diffusion"]["pages"][0]["stageParameter"], "cameraDiffusionEnabled")
        self.assertEqual(banks["diffusion"]["pages"][1]["stageParameter"], "printDiffusionEnabled")

    def test_native_maps_reference_every_registered_control_in_each_mode(self):
        controls = ET.parse(ROOT / "profiles/tangent/controls.xml").getroot()
        registered = {c.attrib["id"] for c in controls.find("Controls")}
        mode_ids = {b["id"] for b in self.mapping["banks"]} | {"0x20FF"}
        self.assertEqual({m.attrib["id"] for m in controls.findall("./Modes/Mode")}, mode_ids)
        for panel in ("Kb", "Tk", "Bt", "Mf"):
            root = ET.parse(ROOT / f"profiles/tangent/element-{panel.lower()}-map.xml").getroot()
            modes = root.findall("./Panels/Panel/Mode")
            self.assertEqual({m.attrib["id"] for m in modes}, mode_ids)
            expected = {x["id"] for x in self.mapping["axes"] + self.mapping["buttons"] if x["panel"] == panel}
            for mode in modes:
                keys = {key.text for key in mode.findall(".//Key")}
                self.assertEqual(keys, expected)
                self.assertTrue(keys <= registered)
                # Resets are Hub associations. Mapping explicit reset buttons
                # here would override the managed ParameterReset path.
                for control in mode.findall(".//Control"):
                    self.assertEqual({m.attrib["mode"] for m in control.findall("Mapping")}, {"Std", "Alt"})


if __name__ == "__main__":
    unittest.main()
