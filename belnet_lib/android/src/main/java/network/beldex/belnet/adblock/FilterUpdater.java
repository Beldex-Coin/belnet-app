package network.beldex.belnet.adblock;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

/**
 * Downloads, validates and caches filter lists.
 *
 * <ul>
 *   <li>A list younger than {@link #MAX_AGE_MS} is not re-fetched.
 *   <li>Stale lists are fetched with {@code If-None-Match} /
 *       {@code If-Modified-Since}, so an unchanged list costs one small 304.
 *   <li>A download goes to a temporary file and only replaces the cached
 *       copy after it parses into at least {@link FilterSource#minRules}
 *       rules (an HTML error page, a truncated transfer or an emptied list
 *       is rejected).
 *   <li>Any failure keeps the previous cached copy, so the last working
 *       blocklist always stays in force.
 * </ul>
 */
final class FilterUpdater {
  static final long MAX_AGE_MS = 24L * 60 * 60 * 1000;
  static final long MAX_DOWNLOAD_BYTES = 40L * 1024 * 1024;

  /** HTTP abstraction (real implementation below; tests inject fakes). */
  interface Http {
    /**
     * GET {@code url} into {@code dest}. Returns the HTTP status; on 200 the
     * body is in {@code dest} and the validators are in {@code out}.
     */
    int get(String url, String etag, String lastModified, File dest, long maxBytes, Properties out)
        throws IOException;
  }

  static final class SourceOutcome {
    final String id;
    final String name;
    /** updated | not_modified | fresh | failed */
    String status;
    int rules;
    long fetchedAt;
    String error;

    SourceOutcome(FilterSource s) {
      this.id = s.id;
      this.name = s.name;
    }
  }

  static final class Outcome {
    /** At least one cached list changed, so the compiled set must be rebuilt. */
    boolean changed;
    final List<SourceOutcome> sources = new ArrayList<>();
  }

  private final FilterStore store;
  private final Http http;

  FilterUpdater(FilterStore store, Http http) {
    this.store = store;
    this.http = http;
  }

  Outcome update(List<FilterSource> sources, boolean force, long nowMs) {
    Outcome outcome = new Outcome();
    try {
      store.ensureDirs();
    } catch (IOException e) {
      for (FilterSource s : sources) {
        SourceOutcome so = new SourceOutcome(s);
        so.status = "failed";
        so.error = e.getMessage();
        outcome.sources.add(so);
      }
      return outcome;
    }
    for (FilterSource s : sources) {
      outcome.sources.add(updateOne(s, force, nowMs, outcome));
    }
    return outcome;
  }

  private SourceOutcome updateOne(FilterSource s, boolean force, long now, Outcome outcome) {
    SourceOutcome so = new SourceOutcome(s);
    File meta = store.metaFile(s);
    Properties p = store.readProps(meta);
    File raw = store.rawFile(s);
    boolean haveCopy = raw.isFile() && raw.length() > 0;
    long fetchedAt = FilterStore.getLong(p, "fetchedAt", 0);
    so.rules = (int) FilterStore.getLong(p, "rules", 0);
    so.fetchedAt = fetchedAt;

    if (!force && haveCopy && now - fetchedAt < MAX_AGE_MS && now >= fetchedAt) {
      so.status = "fresh";
      return so;
    }

    String lastError = null;
    File tmp = store.tempRawFile(s);
    for (String url : s.urls) {
      Properties validators = new Properties();
      try {
        String etag = haveCopy && url.equals(p.getProperty("url")) ? p.getProperty("etag") : null;
        String lastMod =
            haveCopy && url.equals(p.getProperty("url")) ? p.getProperty("lastModified") : null;
        int status = http.get(url, etag, lastMod, tmp, MAX_DOWNLOAD_BYTES, validators);
        if (status == 304 && haveCopy) {
          p.setProperty("fetchedAt", Long.toString(now));
          p.remove("error");
          store.writeProps(meta, p);
          so.status = "not_modified";
          so.fetchedAt = now;
          return so;
        }
        if (status != 200) {
          lastError = "HTTP " + status;
          continue;
        }
        FilterListParser.Result parsed =
            FilterStore.parseFile(tmp, new LongArrayBuilder(), new LongArrayBuilder());
        if (parsed.rules() < s.minRules) {
          lastError = "rejected: only " + parsed.rules() + " valid rules";
          continue;
        }
        FilterStore.replace(tmp, raw);
        p.setProperty("url", url);
        p.setProperty("fetchedAt", Long.toString(now));
        p.setProperty("rules", Integer.toString(parsed.rules()));
        setOrRemove(p, "etag", validators.getProperty("etag"));
        setOrRemove(p, "lastModified", validators.getProperty("lastModified"));
        p.remove("error");
        store.writeProps(meta, p);
        so.status = "updated";
        so.rules = parsed.rules();
        so.fetchedAt = now;
        outcome.changed = true;
        return so;
      } catch (IOException | RuntimeException e) {
        lastError = e.getClass().getSimpleName() + (e.getMessage() == null ? "" : ": " + e.getMessage());
      } finally {
        if (tmp.exists()) //noinspection ResultOfMethodCallIgnored
          tmp.delete();
      }
    }
    // Every mirror failed: keep the previous copy (if any) in force.
    p.setProperty("error", lastError == null ? "unknown error" : lastError);
    p.setProperty("lastFailure", Long.toString(now));
    store.writeProps(meta, p);
    so.status = "failed";
    so.error = lastError;
    return so;
  }

  private static void setOrRemove(Properties p, String key, String value) {
    if (value == null || value.isEmpty()) p.remove(key);
    else p.setProperty(key, value);
  }

  /** {@link HttpURLConnection}-based implementation (HTTPS only). */
  static final class UrlConnectionHttp implements Http {
    static final int CONNECT_TIMEOUT_MS = 15_000;
    static final int READ_TIMEOUT_MS = 30_000;

    @Override
    public int get(
        String url, String etag, String lastModified, File dest, long maxBytes, Properties out)
        throws IOException {
      if (!url.startsWith("https://")) throw new IOException("refusing non-HTTPS list URL");
      HttpURLConnection c = (HttpURLConnection) new URL(url).openConnection();
      try {
        c.setConnectTimeout(CONNECT_TIMEOUT_MS);
        c.setReadTimeout(READ_TIMEOUT_MS);
        c.setInstanceFollowRedirects(true); // same-protocol only, i.e. HTTPS -> HTTPS
        c.setUseCaches(false);
        c.setRequestProperty("User-Agent", "BelNet-AdBlocker/1.0 (Android)");
        if (etag != null) c.setRequestProperty("If-None-Match", etag);
        if (lastModified != null) c.setRequestProperty("If-Modified-Since", lastModified);
        int code = c.getResponseCode();
        if (!"https".equals(c.getURL().getProtocol())) throw new IOException("redirected off HTTPS");
        if (code != 200) return code;
        long declared = c.getContentLengthLong();
        if (declared > maxBytes) throw new IOException("list too large: " + declared + " bytes");
        try (InputStream in = c.getInputStream();
            OutputStream o = new FileOutputStream(dest)) {
          byte[] buf = new byte[1 << 16];
          long total = 0;
          int n;
          while ((n = in.read(buf)) > 0) {
            total += n;
            if (total > maxBytes) throw new IOException("list too large");
            o.write(buf, 0, n);
          }
        }
        String e = c.getHeaderField("ETag");
        String lm = c.getHeaderField("Last-Modified");
        if (e != null) out.setProperty("etag", e);
        if (lm != null) out.setProperty("lastModified", lm);
        return 200;
      } finally {
        c.disconnect();
      }
    }
  }
}
