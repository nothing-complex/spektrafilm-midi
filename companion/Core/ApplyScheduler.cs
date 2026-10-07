namespace Spektrafilm.Control;

/// <summary>Bounds dispatch latency and retries only while at least the latest input remains within the plugin's two-second queue lifetime.</summary>
public sealed class ApplyScheduler
{
    private static readonly TimeSpan queueLifetime = TimeSpan.FromSeconds(2);
    private readonly TimeSpan interval;
    public DateTime DueUtc { get; private set; } = DateTime.MaxValue;
    public DateTime ExpiresUtc { get; private set; } = DateTime.MaxValue;
    public long RequestVersion { get; private set; }
    public bool Pending => DueUtc != DateTime.MaxValue;
    public ApplyScheduler(TimeSpan? interval = null)
    {
        this.interval = interval ?? TimeSpan.FromMilliseconds(65);
        if (this.interval < TimeSpan.Zero) throw new ArgumentOutOfRangeException(nameof(interval));
    }
    public void Request(DateTime now)
    {
        RequestVersion++;
        // An expired batch starts afresh. Its old deadline must not turn a new
        // gesture into an immediate dispatch after the user returns to Resolve.
        ExpireIfStale(now);
        var due = now + interval;
        if (due < DueUtc) DueUtc = due;
        var expires = now + queueLifetime;
        if (ExpiresUtc == DateTime.MaxValue || expires > ExpiresUtc) ExpiresUtc = expires;
    }
    public bool IsDue(DateTime now) => Pending && now >= DueUtc && now < ExpiresUtc;
    public bool ExpireIfStale(DateTime now)
    {
        if (!Pending || now < ExpiresUtc) return false;
        Clear(); return true;
    }
    public bool TryTakeDue(DateTime now, bool ready = true)
    {
        if (ExpireIfStale(now)) return false;
        if (!ready || !IsDue(now)) return false;
        Clear(); return true;
    }
    /// <summary>Completes a dispatch without discarding input received while its host action was running.</summary>
    public bool ClearIfUnchanged(long requestVersion)
    {
        if (requestVersion != RequestVersion) return false;
        Clear(); return true;
    }
    // Keep the version across clears: a late completion must never match a new gesture.
    public void Clear() { DueUtc = DateTime.MaxValue; ExpiresUtc = DateTime.MaxValue; }
}
