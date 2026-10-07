"""Optional Windows Element OSC -> MIDI bridge. No driver is installed.

Select an already installed virtual MIDI output port, then select that port in
the companion with RelativeBinaryOffset encoding. Native Tangent is preferred.
The generated OSC Mapper profile uses relative integer input and zero resets.
"""
from __future__ import annotations

import argparse
import ctypes
import math
import socket
import struct
import sys


def osc_messages(packet: bytes, depth=0):
    if depth > 4 or len(packet) > 65507:
        raise ValueError("OSC size/nesting limit")
    if packet.startswith(b"#bundle\x00"):
        if len(packet) < 16 or struct.unpack_from(">Q", packet, 8)[0] not in (0, 1):
            raise ValueError("Only immediate OSC bundles are supported")
        at = 16
        while at < len(packet):
            if at+4 > len(packet):
                raise ValueError("Truncated OSC bundle")
            size = struct.unpack_from(">I", packet, at)[0]
            at += 4
            if not size or at+size > len(packet):
                raise ValueError("Invalid OSC bundle member")
            yield from osc_messages(packet[at:at+size], depth+1)
            at += size
        return
    def string_at(at):
        end = packet.find(b"\x00", at)
        if end < 0:
            raise ValueError("Missing OSC string terminator")
        next_at = (end+4) & ~3
        if next_at > len(packet) or any(packet[end:next_at]):
            raise ValueError("Invalid OSC string padding")
        return packet[at:end].decode("utf-8", errors="strict"), next_at
    address, at = string_at(0)
    kind, at = string_at(at)
    if kind in (",i", ",f"):
        if at+4 != len(packet):
            raise ValueError("Expected exactly one OSC value")
        value = struct.unpack_from(">i" if kind == ",i" else ">f", packet, at)[0]
    elif kind in (",T", ",F") and at == len(packet):
        value = int(kind == ",T")
    else:
        raise ValueError("Expected integer, float, or boolean OSC value")
    if not math.isfinite(value):
        raise ValueError("Non-finite OSC value")
    yield address, value


class Encoder:
    def __init__(self, channel=1):
        if not 1 <= channel <= 16:
            raise ValueError("MIDI channel must be 1..16")
        self.channel = channel-1
        self.remainders = {}
        self.buttons = set()

    def encode(self, address, value):
        if not math.isfinite(value):
            raise ValueError("Non-finite input")
        if address.startswith("/spektrafilm/axis/"):
            axis = int(address.rsplit("/", 1)[1])
        elif address.startswith("/1/knob"):
            axis = int(address[len("/1/knob"):])-1
        else:
            axis = None
        if axis is not None:
            if not 0 <= axis < 24:
                raise ValueError("Axis outside full Element range")
            if value == 0:  # Tangent relative OSC associated-reset convention.
                self.remainders.pop(axis, None)
                return [(0x90+self.channel, axis, 127), (0x80+self.channel, axis, 0)]
            if abs(value) > 1000000:
                raise ValueError("Unreasonable encoder delta")
            total = self.remainders.get(axis, 0)+value
            whole = math.trunc(total)
            self.remainders[axis] = total-whole
            output = []
            while whole:
                part = min(63, whole) if whole > 0 else max(-64, whole)
                output.append((0xB0+self.channel, axis, 64+part))
                whole -= part
            return output
        if address.startswith("/spektrafilm/reset/"):
            axis = int(address.rsplit("/", 1)[1])
            if not 0 <= axis < 24:
                raise ValueError("Reset axis outside full Element range")
            if value <= 0:
                return []
            self.remainders.pop(axis, None)
            return [(0x90+self.channel, axis, 127), (0x80+self.channel, axis, 0)]
        if address.startswith("/spektrafilm/button/"):
            note = int(address.rsplit("/", 1)[1])
            if not 32 <= note <= 68:
                raise ValueError("Unknown full-panel action note")
            if value > 0:
                self.buttons.add(note)
                return [(0x90+self.channel, note, 127)]
            self.buttons.discard(note)
            return [(0x80+self.channel, note, 0)]
        raise ValueError("Unknown OSC address")

    def release_all(self):
        output = [(0x80+self.channel, note, 0) for note in sorted(self.buttons)]
        self.buttons.clear()
        return output


class MidiOut:
    def __init__(self):
        if sys.platform != "win32":
            raise RuntimeError("The MIDI output adapter requires Windows")
        self.api = ctypes.WinDLL("winmm")
        self.api.midiOutGetNumDevs.restype = ctypes.c_uint
        self.api.midiOutGetDevCapsW.argtypes = [ctypes.c_size_t, ctypes.c_void_p, ctypes.c_uint]
        self.api.midiOutOpen.argtypes = [ctypes.POINTER(ctypes.c_void_p), ctypes.c_uint, ctypes.c_size_t, ctypes.c_size_t, ctypes.c_uint]
        self.api.midiOutShortMsg.argtypes = [ctypes.c_void_p, ctypes.c_uint]
        self.api.midiOutClose.argtypes = [ctypes.c_void_p]
        self.handle = ctypes.c_void_p()

    def ports(self):
        class Caps(ctypes.Structure):
            _fields_ = [("manufacturer", ctypes.c_ushort), ("product", ctypes.c_ushort), ("version", ctypes.c_uint), ("name", ctypes.c_wchar*32), ("technology", ctypes.c_ushort), ("voices", ctypes.c_ushort), ("notes", ctypes.c_ushort), ("channels", ctypes.c_ushort), ("support", ctypes.c_uint)]
        result = []
        for i in range(self.api.midiOutGetNumDevs()):
            caps = Caps()
            error = self.api.midiOutGetDevCapsW(i, ctypes.byref(caps), ctypes.sizeof(caps))
            if error == 0:
                result.append((i, caps.name))
        return result

    def open(self, index):
        error = self.api.midiOutOpen(ctypes.byref(self.handle), index, 0, 0, 0)
        if error:
            raise RuntimeError(f"MIDI output open failed ({error})")

    def send(self, messages):
        for status, data1, data2 in messages:
            error = self.api.midiOutShortMsg(self.handle, status | data1 << 8 | data2 << 16)
            if error:
                raise RuntimeError(f"MIDI output failed ({error})")

    def close(self):
        if self.handle.value:
            self.api.midiOutClose(self.handle)
            self.handle = ctypes.c_void_p()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--list", action="store_true", help="List existing MIDI output ports")
    parser.add_argument("--port", type=int, help="Explicit output-port index from --list")
    parser.add_argument("--listen", type=int, default=9000, help="Loopback OSC input port")
    parser.add_argument("--channel", type=int, default=1, help="Output MIDI channel, 1..16")
    args = parser.parse_args()
    output = MidiOut()
    ports = output.ports()
    if args.list:
        if not ports:
            print("No MIDI output ports are available to this process. The optional OSC-to-MIDI route needs an existing virtual MIDI output port.")
        for index, name in ports:
            print(f"{index}: {name}")
        return
    if args.port is None or args.port not in {index for index, _ in ports}:
        parser.error("Choose an existing MIDI output index with --port; use --list first")
    if not 1 <= args.listen <= 65535:
        parser.error("OSC listen port must be 1..65535")
    encoder = Encoder(args.channel)
    output.open(args.port)
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as listener:
            listener.bind(("127.0.0.1", args.listen))
            print(f"OSC 127.0.0.1:{args.listen} -> MIDI output {args.port}, channel {args.channel}; Ctrl+C stops")
            while True:
                packet, remote = listener.recvfrom(65507)
                if remote[0] != "127.0.0.1":
                    continue
                try:
                    for address, value in osc_messages(packet):
                        output.send(encoder.encode(address, value))
                except (ValueError, UnicodeError, struct.error) as error:
                    print("Ignored OSC:", error, file=sys.stderr)
    except KeyboardInterrupt:
        pass
    finally:
        try:
            output.send(encoder.release_all())
        finally:
            output.close()


if __name__ == "__main__":
    main()
