package network.beldex.belnet.adblock;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Properties;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * The ad blocker: owns the user preference, the compiled blocklist, the
 * per-connection {@link PacketFilter} used by the TUN relay, and
 * filter-list updates. Plain Java (no Android APIs), so it is unit-tested
 * on the JVM; {@link AdBlocker} adapts it to Android.
 *
 * <p>Threading: the relay runs on its own threads and reads only volatile
 * state ({@link #enabled}, {@link #set}). Loading, compiling and downloading
 * run on one background executor thread. Public methods are safe to call
 * from any thread (the Flutter platform thread or the VPN service).
 */
public final class AdBlockEngine {

  /** Persistent storage for the on/off preference. */
  public interface Settings {
    boolean loadEnabled();

    void saveEnabled(boolean enabled);
  }

  public interface Log {
    void info(String msg);

    void warn(String msg);
  }

  /** First list check after the tunnel comes up (lets path-building finish). */
  static final long FIRST_CHECK_DELAY_MS = 45_000;
  /** How often lists are checked while connected (each list refreshes daily). */
  static final long CHECK_INTERVAL_MS = 6L * 60 * 60 * 1000;
  /** Retry delay after a failed scheduled update. */
  static final long RETRY_DELAY_MS = 15L * 60 * 1000;

  private final FilterStore store;
  private final Settings settings;
  private final Log log;
  private final FilterUpdater updater;
  private final ScheduledExecutorService exec;

  private volatile boolean enabled;
  private volatile DomainSet set;
  private volatile boolean usingBuiltinList = true;
  private volatile boolean loaded;
  private final AtomicBoolean updating = new AtomicBoolean();

  private volatile long lastCheckMs;
  private volatile long lastSuccessMs;
  private volatile String lastError;
  private volatile List<FilterUpdater.SourceOutcome> sourceInfo = Collections.emptyList();

  // Guarded by this.
  private PacketFilter session;
  private ScheduledFuture<?> periodic;
  private ScheduledFuture<?> retry;

  /** Live decision source for the relay: reads the current flag and list per packet. */
  private final PacketFilter.Decider decider =
      new PacketFilter.Decider() {
        @Override
        public boolean isEnabled() {
          return enabled;
        }

        @Override
        public boolean isBlocked(String normalizedName) {
          return set.isBlocked(normalizedName);
        }
      };

  public AdBlockEngine(File dataDir, Settings settings, Log log) {
    this(dataDir, settings, log, new FilterUpdater.UrlConnectionHttp());
  }

  AdBlockEngine(File dataDir, Settings settings, Log log, FilterUpdater.Http http) {
    this.store = new FilterStore(dataDir);
    this.settings = settings;
    this.log = log;
    this.updater = new FilterUpdater(store, http);
    this.enabled = settings.loadEnabled();
    this.set = builtinSet();
    this.exec =
        Executors.newSingleThreadScheduledExecutor(
            r -> {
              Thread t = new Thread(r, "belnet-adblock");
              t.setDaemon(true);
              t.setPriority(Thread.MIN_PRIORITY);
              return t;
            });
    exec.execute(this::loadFromDisk);
  }

  private static DomainSet builtinSet() {
    return DomainSet.ofSorted(
        BuiltinLists.hashes(BuiltinLists.SEED_BLOCK),
        BuiltinLists.hashes(BuiltinLists.ESSENTIAL_ALLOW),
        0L);
  }

  // ---------------------------------------------------------------------
  // Preference

  public boolean isEnabled() {
    return enabled;
  }

  /**
   * Applies immediately to a running relay (it checks this flag on every
   * packet). A tunnel that was started with the Ad Blocker off has no relay,
   * so switching it on takes effect from the next connection.
   */
  public void setEnabled(boolean value) {
    enabled = value;
    settings.saveEnabled(value);
    log.info("Ad Blocker " + (value ? "enabled" : "disabled"));
    if (value && usingBuiltinList) refreshAsync(false);
  }

  // ---------------------------------------------------------------------
  // Relay session (called by the VPN service)

  /** A filter for a new TUN relay session, registered for status reporting. */
  public synchronized PacketFilter beginSession() {
    session = new PacketFilter(decider);
    return session;
  }

  /** The relay of {@code filter} has stopped. */
  public synchronized void endSession(PacketFilter filter) {
    if (session == filter) session = null;
  }

  /** True while VPN traffic flows through a filtering relay. */
  public synchronized boolean isSessionActive() {
    return session != null;
  }

  /** Tunnel is up: keep lists fresh through the tunnel. */
  public synchronized void onTunnelUp() {
    if (periodic != null) periodic.cancel(false);
    periodic =
        exec.scheduleWithFixedDelay(
            () -> runUpdate(false, true),
            FIRST_CHECK_DELAY_MS,
            CHECK_INTERVAL_MS,
            TimeUnit.MILLISECONDS);
  }

  /** Tunnel is down: no background list traffic outside the tunnel. */
  public synchronized void onTunnelDown() {
    if (periodic != null) {
      periodic.cancel(false);
      periodic = null;
    }
    if (retry != null) {
      retry.cancel(false);
      retry = null;
    }
  }

  // ---------------------------------------------------------------------
  // Lists

  /** Checks and downloads lists in the background ({@code force}: ignore list age). */
  public void refreshAsync(boolean force) {
    exec.execute(() -> runUpdate(force, false));
  }

  boolean isUpdating() {
    return updating.get();
  }

  /** Test hook: true once the on-disk list has been loaded. */
  boolean isLoaded() {
    return loaded;
  }

  /** Test hook: runs queued background work and waits for it. */
  void awaitIdle() throws Exception {
    exec.submit(() -> {}).get(30, TimeUnit.SECONDS);
  }

  DomainSet currentSet() {
    return set;
  }

  private void loadFromDisk() {
    try {
      Properties state = store.readProps(store.stateFile);
      lastCheckMs = FilterStore.getLong(state, "lastCheck", 0);
      lastSuccessMs = FilterStore.getLong(state, "lastSuccess", 0);
      lastError = state.getProperty("lastError");

      DomainSet disk = store.readCompiled();
      if (disk != null && disk.blockedCount() > 0) {
        set = disk;
        usingBuiltinList = false;
      } else {
        // No (valid) compiled file: rebuild from whatever lists are cached.
        FilterStore.CompileResult r = store.compile(FilterSource.load(store.dir), now());
        set = r.set;
        usingBuiltinList = r.sourcesUsed == 0;
        if (!usingBuiltinList) {
          try {
            store.writeCompiled(r.set);
          } catch (IOException e) {
            log.warn("Ad Blocker: cannot save compiled list: " + e);
          }
        }
      }
      sourceInfo = readSourceInfo();
      log.info("Ad Blocker: " + set.blockedCount() + " blocked domains loaded"
          + (usingBuiltinList ? " (built-in list)" : ""));
    } catch (RuntimeException e) {
      log.warn("Ad Blocker: loading lists failed, using built-in list: " + e);
    } finally {
      loaded = true;
    }
  }

  private void runUpdate(boolean force, boolean scheduled) {
    if (scheduled && !enabled) return; // nothing to keep fresh
    if (!updating.compareAndSet(false, true)) return;
    try {
      List<FilterSource> sources = FilterSource.load(store.dir);
      long now = now();
      FilterUpdater.Outcome out = updater.update(sources, force, now);
      boolean anyFailed = false;
      boolean anyUsable = false;
      for (FilterUpdater.SourceOutcome so : out.sources) {
        if ("failed".equals(so.status)) anyFailed = true;
        if (so.rules > 0) anyUsable = true;
      }
      if (out.changed || (usingBuiltinList && anyUsable)) {
        FilterStore.CompileResult r = store.compile(sources, now);
        if (r.sourcesUsed > 0) {
          try {
            store.writeCompiled(r.set);
          } catch (IOException e) {
            log.warn("Ad Blocker: cannot save compiled list: " + e);
          }
          set = r.set; // atomic swap; in-flight lookups finish on the old set
          usingBuiltinList = false;
          log.info("Ad Blocker: blocklist updated, " + r.set.blockedCount() + " domains");
        }
      }
      lastCheckMs = now;
      if (!anyFailed) {
        lastSuccessMs = now;
        lastError = null;
      } else {
        StringBuilder sb = new StringBuilder();
        for (FilterUpdater.SourceOutcome so : out.sources) {
          if (!"failed".equals(so.status)) continue;
          if (sb.length() > 0) sb.append("; ");
          sb.append(so.name).append(": ").append(so.error);
        }
        lastError = sb.toString();
        log.warn("Ad Blocker: list update incomplete (" + lastError + "), keeping previous lists");
        if (scheduled) scheduleRetry();
      }
      sourceInfo = out.sources;
      Properties state = new Properties();
      state.setProperty("lastCheck", Long.toString(lastCheckMs));
      state.setProperty("lastSuccess", Long.toString(lastSuccessMs));
      if (lastError != null) state.setProperty("lastError", lastError);
      store.writeProps(store.stateFile, state);
    } catch (RuntimeException e) {
      lastError = e.toString();
      log.warn("Ad Blocker: update failed: " + e);
    } finally {
      updating.set(false);
    }
  }

  private synchronized void scheduleRetry() {
    if (periodic == null) return; // tunnel went down meanwhile
    if (retry != null && !retry.isDone()) return;
    retry = exec.schedule(() -> runUpdate(false, true), RETRY_DELAY_MS, TimeUnit.MILLISECONDS);
  }

  private List<FilterUpdater.SourceOutcome> readSourceInfo() {
    List<FilterUpdater.SourceOutcome> list = new ArrayList<>();
    for (FilterSource s : FilterSource.load(store.dir)) {
      Properties p = store.readProps(store.metaFile(s));
      FilterUpdater.SourceOutcome so = new FilterUpdater.SourceOutcome(s);
      so.rules = (int) FilterStore.getLong(p, "rules", 0);
      so.fetchedAt = FilterStore.getLong(p, "fetchedAt", 0);
      so.error = p.getProperty("error");
      so.status = so.rules > 0 ? "cached" : (so.error != null ? "failed" : "missing");
      list.add(so);
    }
    return list;
  }

  // ---------------------------------------------------------------------
  // Status

  /**
   * JSON status for the UI. {@code extraJsonFields} (already-encoded
   * {@code "k":v} pairs, may be empty) is appended for platform-specific
   * details such as Private DNS.
   */
  public String statusJson(String extraJsonFields) {
    boolean active;
    long q = 0;
    long b = 0;
    long enc = 0;
    synchronized (this) {
      active = session != null;
      if (session != null) {
        q = session.dnsQueries.get();
        b = session.dnsBlocked.get();
        enc = session.encryptedDnsRefused.get();
      }
    }
    DomainSet s = set;
    StringBuilder j = new StringBuilder(512);
    j.append('{');
    field(j, "enabled", enabled).append(',');
    field(j, "sessionActive", active).append(',');
    field(j, "filteringActive", enabled && active).append(',');
    field(j, "systemDnsProtected", enabled && active).append(',');
    field(j, "domains", s.blockedCount()).append(',');
    field(j, "usingBuiltinList", usingBuiltinList).append(',');
    field(j, "loaded", loaded).append(',');
    field(j, "updating", updating.get()).append(',');
    field(j, "listsUpdatedAt", usingBuiltinList ? 0 : Math.max(s.createdAtMs(), lastSuccessMs))
        .append(',');
    field(j, "lastCheckAt", lastCheckMs).append(',');
    field(j, "lastError", lastError).append(',');
    field(j, "sessionQueries", q).append(',');
    field(j, "sessionBlocked", b).append(',');
    field(j, "sessionEncryptedDnsRefused", enc).append(',');
    j.append("\"sources\":[");
    boolean first = true;
    for (FilterUpdater.SourceOutcome so : sourceInfo) {
      if (!first) j.append(',');
      first = false;
      j.append('{');
      field(j, "id", so.id).append(',');
      field(j, "name", so.name).append(',');
      field(j, "status", so.status).append(',');
      field(j, "rules", so.rules).append(',');
      field(j, "fetchedAt", so.fetchedAt).append(',');
      field(j, "error", so.error);
      j.append('}');
    }
    j.append(']');
    if (extraJsonFields != null && !extraJsonFields.isEmpty()) j.append(',').append(extraJsonFields);
    j.append('}');
    return j.toString();
  }

  static StringBuilder field(StringBuilder j, String k, Object v) {
    quote(j, k).append(':');
    if (v == null) return j.append("null");
    if (v instanceof Boolean || v instanceof Number) return j.append(v);
    return quote(j, v.toString());
  }

  static StringBuilder quote(StringBuilder j, String s) {
    j.append('"');
    for (int i = 0; i < s.length(); i++) {
      char c = s.charAt(i);
      switch (c) {
        case '"':
          j.append("\\\"");
          break;
        case '\\':
          j.append("\\\\");
          break;
        case '\n':
          j.append("\\n");
          break;
        case '\r':
          j.append("\\r");
          break;
        case '\t':
          j.append("\\t");
          break;
        default:
          if (c < 0x20) j.append(String.format("\\u%04x", (int) c));
          else j.append(c);
      }
    }
    return j.append('"');
  }

  // ---------------------------------------------------------------------

  private static long now() {
    return System.currentTimeMillis();
  }
}
