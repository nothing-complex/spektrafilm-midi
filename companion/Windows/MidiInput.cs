using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using Spektrafilm.Control;

namespace Spektrafilm.Control.Windows;

public sealed class MidiInput : IDisposable
{
    private IntPtr handle;
    private readonly MidiCallback callback;
    public MidiDecoder Decoder { get; } = new();
    public event Action<ControlInput>? Input;
    public event Action<string>? Status;
    public sealed record Device(uint Id, string Name) { public override string ToString() => Name; }
    public static IReadOnlyList<Device> Devices()
    {
        var result = new List<Device>();
        for (uint i = 0; i < midiInGetNumDevs(); i++)
            if (midiInGetDevCapsW((UIntPtr)i, out var capabilities, (uint)Marshal.SizeOf<MidiCapabilities>()) == 0) result.Add(new(i, capabilities.Name));
        return result;
    }
    public MidiInput(uint device, MidiEncoding encoding, int channel)
    {
        Decoder.Encoding = encoding; Decoder.Channel = channel; callback = Receive;
        Check(midiInOpen(out handle, device, callback, UIntPtr.Zero, 0x00030000));
        try { Check(midiInStart(handle)); }
        catch { midiInClose(handle); handle = IntPtr.Zero; throw; }
    }
    private void Receive(IntPtr input, uint message, UIntPtr instance, UIntPtr parameter1, UIntPtr parameter2)
    {
        try
        {
            if (message == 0x3C3)
            {
                var packed = parameter1.ToUInt64();
                foreach (var control in Decoder.Decode((byte)(packed & 255), (byte)((packed >> 8) & 255), (byte)((packed >> 16) & 255))) Input?.Invoke(control);
            }
            else if (message == 0x3C5) Status?.Invoke("MIDI device reported invalid input.");
        }
        catch (Exception e) { Status?.Invoke("MIDI input: " + e.Message); } // Never unwind into WinMM.
    }
    private static void Check(uint code)
    {
        if (code == 0) return;
        var text = new System.Text.StringBuilder(256); midiInGetErrorTextW(code, text, (uint)text.Capacity);
        throw new InvalidOperationException(text.ToString());
    }
    public void Dispose()
    {
        var opened = handle; handle = IntPtr.Zero;
        if (opened != IntPtr.Zero) { midiInStop(opened); midiInReset(opened); midiInClose(opened); }
        GC.KeepAlive(callback);
    }
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct MidiCapabilities
    {
        public ushort Manufacturer; public ushort Product; public uint Version;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string Name;
        public uint Support;
    }
    private delegate void MidiCallback(IntPtr input, uint message, UIntPtr instance, UIntPtr parameter1, UIntPtr parameter2);
    [DllImport("winmm.dll")] private static extern uint midiInGetNumDevs();
    [DllImport("winmm.dll", CharSet = CharSet.Unicode)] private static extern uint midiInGetDevCapsW(UIntPtr device, out MidiCapabilities capabilities, uint size);
    [DllImport("winmm.dll")] private static extern uint midiInOpen(out IntPtr handle, uint device, MidiCallback callback, UIntPtr instance, uint flags);
    [DllImport("winmm.dll")] private static extern uint midiInStart(IntPtr handle);
    [DllImport("winmm.dll")] private static extern uint midiInStop(IntPtr handle);
    [DllImport("winmm.dll")] private static extern uint midiInReset(IntPtr handle);
    [DllImport("winmm.dll")] private static extern uint midiInClose(IntPtr handle);
    [DllImport("winmm.dll", CharSet = CharSet.Unicode)] private static extern uint midiInGetErrorTextW(uint code, System.Text.StringBuilder text, uint length);
}
