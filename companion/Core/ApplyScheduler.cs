namespace Spektrafilm.Control;

/// <summary>Bounds the delay of a pending batch without postponing it during continuous input.</summary>
public sealed class ApplyScheduler
{
    private readonly TimeSpan interval;
    public DateTime DueUtc { get; private set; } = DateTime.MaxValue;
    public bool Pending => DueUtc != DateTime.MaxValue;
    public ApplyScheduler(TimeSpan? interval = null)
    {
        this.interval = interval ?? TimeSpan.FromMilliseconds(65);
        if (this.interval < TimeSpan.Zero) throw new ArgumentOutOfRangeException(nameof(interval));
    }
    public void Request(DateTime now)
    {
        var due = now + interval;
        if (due < DueUtc) DueUtc = due;
    }
    public bool IsDue(DateTime now) => Pending && now >= DueUtc;
    public bool TryTakeDue(DateTime now, bool ready = true)
    {
        if (!ready || !IsDue(now)) return false;
        Clear(); return true;
    }
    public void Clear() => DueUtc = DateTime.MaxValue;
}
