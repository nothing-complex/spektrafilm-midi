"""Actual C# OSC -> loopback protocol -> OFX DLL integration.

The synthetic host dispatches Apply MIDI actions. This deliberately does not
claim that Resolve provides such a pump, or exercise physical MIDI hardware.
"""
from pathlib import Path
import os
import socket
import struct
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
LOGS = ROOT / ".build/validation"


def osc_string(value):
    encoded = value.encode("utf-8") + b"\0"
    return encoded + b"\0" * (-len(encoded) % 4)


def main():
    LOGS.mkdir(parents=True, exist_ok=True)
    companion_log = LOGS / "end-to-end-companion.txt"
    host_log = LOGS / "end-to-end-host.txt"
    companion_log.unlink(missing_ok=True)
    exe = ROOT / "companion/Windows/bin/Release/net9.0-windows/SpektrafilmMidi.exe"
    host = ROOT / ".build/host-tests/Release/HostHarness.exe"
    plugin = ROOT / ".build/plugin/spektrafilm_midi.ofx.bundle/Contents/Win64/spektrafilm_midi.ofx"
    hidden = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
    processes = []
    try:
        companion = subprocess.Popen(
            [str(exe), "--profiles", str(ROOT / "profiles"), "--headless",
             "--seconds", "12", "--output", str(companion_log)],
            cwd=ROOT, creationflags=hidden,
        )
        processes.append(companion)
        time.sleep(0.6)
        with host_log.open("w", encoding="utf-8") as output:
            native = subprocess.Popen([str(host), str(plugin), "--serve"],
                                      cwd=ROOT, stdout=output, stderr=subprocess.STDOUT,
                                      creationflags=hidden)
            processes.append(native)
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline:
                log = companion_log.read_text(encoding="utf-8") if companion_log.exists() else ""
                if "armed=True complete=True" in log:
                    break
                if native.poll() is not None or companion.poll() is not None:
                    raise AssertionError("Integration process stopped before discovery; inspect logs")
                time.sleep(0.1)
            else:
                raise AssertionError("No complete native snapshot received by the real companion")
            with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sender:
                packet = osc_string("/spektrafilm/axis/0") + osc_string(",f") + struct.pack(">f", 1.25)
                for _ in range(8):
                    sender.sendto(packet, ("127.0.0.1", 9000))
                    time.sleep(0.08)
            assert native.wait(timeout=12) == 0, host_log.read_text(encoding="utf-8")
        assert companion.wait(timeout=8) == 0, "Companion returned a failure"
        assert "end-to-end companion OSC input reaches native host-owned exposure" in host_log.read_text(encoding="utf-8")
        print("PASS real companion discovery/snapshot/OSC -> native queue -> legal host Apply -> authoritative state")
        print("Synthetic host only. Physical panels, WinMM devices and Resolve dispatch remain separate acceptance tests.")
    finally:
        for process in reversed(processes):
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=5)


if __name__ == "__main__":
    main()
