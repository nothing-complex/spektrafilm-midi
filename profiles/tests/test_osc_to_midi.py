import importlib.util
from pathlib import Path
import struct
import unittest

spec = importlib.util.spec_from_file_location("osc_to_midi", Path(__file__).resolve().parents[1] / "tools/osc_to_midi.py")
bridge = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bridge)


def message(address, value, kind="i"):
    def string(s):
        raw = s.encode()+b"\0"
        return raw+b"\0"*((-len(raw)) % 4)
    return string(address)+string(","+kind)+struct.pack(">"+kind, value)


class OscMidiTest(unittest.TestCase):
    def test_large_delta_is_split_without_losing_movement(self):
        encoder = bridge.Encoder(2)
        for delta in (1000, -1000, 63, -64):
            output = encoder.encode("/spektrafilm/axis/23", delta)
            self.assertTrue(all(s == 0xB1 and c == 23 and 0 <= v <= 127 for s,c,v in output))
            self.assertEqual(sum(v-64 for s,c,v in output), delta)

    def test_fractional_movements_accumulate_per_axis_and_reset_clears(self):
        encoder = bridge.Encoder()
        self.assertEqual(encoder.encode("/spektrafilm/axis/0", .25), [])
        self.assertEqual(encoder.encode("/spektrafilm/axis/1", .75), [])
        self.assertEqual(encoder.encode("/spektrafilm/axis/0", .75), [(0xB0, 0, 65)])
        self.assertEqual(encoder.encode("/spektrafilm/axis/1", 0), [(0x90, 1, 127),(0x80, 1, 0)])
        self.assertEqual(encoder.encode("/spektrafilm/axis/1", .25), [])

    def test_button_release_and_exit_release_fine_modifiers(self):
        encoder = bridge.Encoder(16)
        self.assertEqual(encoder.encode("/spektrafilm/button/56", 1), [(0x9F, 56, 127)])
        self.assertEqual(encoder.release_all(), [(0x8F, 56, 0)])
        self.assertEqual(encoder.release_all(), [])

    def test_parser_handles_immediate_bundles_and_rejects_truncation(self):
        one = message("/spektrafilm/axis/0", 3)
        two = message("/spektrafilm/axis/23", -.5, "f")
        packet = b"#bundle\0"+struct.pack(">Q", 1)+struct.pack(">I", len(one))+one+struct.pack(">I",len(two))+two
        self.assertEqual(list(bridge.osc_messages(packet)), [("/spektrafilm/axis/0",3),("/spektrafilm/axis/23",-.5)])
        for broken in (one[:-1], packet[:-1], b"/unterminated", message("/spektrafilm/axis/0", float("nan"), "f")):
            with self.assertRaises(ValueError):
                list(bridge.osc_messages(broken))

    def test_unknown_or_unsafe_inputs_never_generate_midi(self):
        encoder = bridge.Encoder()
        for address, value in [("/spektrafilm/axis/24", 1),("/spektrafilm/button/69",1),("/spektrafilm/axis/0",float("inf")),("/unknown",1)]:
            with self.assertRaises(ValueError):
                encoder.encode(address, value)


if __name__ == "__main__":
    unittest.main()
