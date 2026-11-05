package network.beldex.belnet.adblock;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Properties;

/**
 * On-disk layout of the ad blocker (all under {@code <files>/adblock/}):
 *
 * <pre>
 *   sources/&lt;id&gt;.txt         last downloaded copy of each list that passed validation
 *   sources/&lt;id&gt;.properties  etag, last-modified, fetch time, rule count, last error
 *   compiled.bin                sorted hash arrays loaded by the Ad Blocker
 *   state.properties            last check/success/error for the whole update
 * </pre>
 *
 * Every file is written to a temporary name and atomically renamed, so a
 * crash or a failed download can never leave a half-written list behind:
 * the previous working copy stays in place.
 */
final class FilterStore {
  private static final int MAGIC = 0x424e4142; // "BNAB"
  private static final int VERSION = 1;
  /** Upper bound on hashes accepted from disk (guards against corrupt files). */
  private static final int MAX_ENTRIES = 5_000_000;

  final File dir;
  final File sourcesDir;
  final File compiledFile;
  final File stateFile;

  FilterStore(File dir) {
    this.dir = dir;
    this.sourcesDir = new File(dir, "sources");
    this.compiledFile = new File(dir, "compiled.bin");
    this.stateFile = new File(dir, "state.properties");
  }

  void ensureDirs() throws IOException {
    if (!sourcesDir.isDirectory() && !sourcesDir.mkdirs()) {
      throw new IOException("cannot create " + sourcesDir);
    }
  }

  File rawFile(FilterSource s) {
    return new File(sourcesDir, s.id + ".txt");
  }

  File tempRawFile(FilterSource s) {
    return new File(sourcesDir, s.id + ".download");
  }

  File metaFile(FilterSource s) {
    return new File(sourcesDir, s.id + ".properties");
  }

  // ---------------------------------------------------------------------
  // Compiled set

  void writeCompiled(DomainSet set) throws IOException {
    ensureDirs();
    File tmp = new File(dir, "compiled.bin.tmp");
    try (DataOutputStream out =
        new DataOutputStream(new BufferedOutputStream(new FileOutputStream(tmp), 1 << 16))) {
      long[] b = set.blockedHashes();
      long[] a = set.allowedHashes();
      out.writeInt(MAGIC);
      out.writeInt(VERSION);
      out.writeLong(set.createdAtMs());
      out.writeInt(b.length);
      out.writeInt(a.length);
      long check = 0;
      for (long v : b) {
        out.writeLong(v);
        check = check * 31 + v;
      }
      for (long v : a) {
        out.writeLong(v);
        check = check * 31 + v;
      }
      out.writeLong(check);
    }
    replace(tmp, compiledFile);
  }

  /** Returns the stored set, or null when missing or corrupt. */
  DomainSet readCompiled() {
    if (!compiledFile.isFile()) return null;
    try (DataInputStream in =
        new DataInputStream(new BufferedInputStream(new FileInputStream(compiledFile), 1 << 16))) {
      if (in.readInt() != MAGIC || in.readInt() != VERSION) return null;
      long createdAt = in.readLong();
      int nb = in.readInt();
      int na = in.readInt();
      if (nb < 0 || na < 0 || nb > MAX_ENTRIES || na > MAX_ENTRIES) return null;
      long[] b = new long[nb];
      long[] a = new long[na];
      long check = 0;
      for (int i = 0; i < nb; i++) {
        b[i] = in.readLong();
        check = check * 31 + b[i];
      }
      for (int i = 0; i < na; i++) {
        a[i] = in.readLong();
        check = check * 31 + a[i];
      }
      if (in.readLong() != check) return null;
      if (!isStrictlyAscending(b) || !isStrictlyAscending(a)) return null;
      return DomainSet.ofSorted(b, a, createdAt);
    } catch (IOException | RuntimeException e) {
      return null;
    }
  }

  private static boolean isStrictlyAscending(long[] v) {
    for (int i = 1; i < v.length; i++) if (v[i] <= v[i - 1]) return false;
    return true;
  }

  // ---------------------------------------------------------------------
  // Compilation

  static final class CompileResult {
    DomainSet set;
    int sourcesUsed;
  }

  /**
   * Builds the compiled set from every cached source plus the built-in
   * lists. Sources without a cached copy are skipped. When no source is
   * cached at all, the result is the built-in seed list.
   */
  CompileResult compile(List<FilterSource> sources, long nowMs) {
    LongArrayBuilder block = new LongArrayBuilder(1 << 18);
    LongArrayBuilder allow = new LongArrayBuilder(1 << 10);
    CompileResult res = new CompileResult();
    for (FilterSource s : sources) {
      File raw = rawFile(s);
      if (!raw.isFile()) continue;
      try {
        if (parseFile(raw, block, allow).rules() > 0) res.sourcesUsed++;
      } catch (IOException e) {
        // Unreadable cache: ignore this source; the others still apply.
      }
    }
    if (res.sourcesUsed == 0) block.addAll(BuiltinLists.hashes(BuiltinLists.SEED_BLOCK));
    allow.addAll(BuiltinLists.hashes(BuiltinLists.ESSENTIAL_ALLOW));
    res.set = DomainSet.ofSorted(block.toSortedUnique(), allow.toSortedUnique(), nowMs);
    return res;
  }

  static FilterListParser.Result parseFile(File f, LongArrayBuilder block, LongArrayBuilder allow)
      throws IOException {
    try (BufferedReader r =
        new BufferedReader(
            new InputStreamReader(new FileInputStream(f), StandardCharsets.UTF_8), 1 << 16)) {
      return FilterListParser.parse(r, block, allow);
    }
  }

  // ---------------------------------------------------------------------
  // Properties helpers

  Properties readProps(File f) {
    Properties p = new Properties();
    if (f.isFile()) {
      try (FileInputStream in = new FileInputStream(f)) {
        p.load(in);
      } catch (IOException | IllegalArgumentException ignored) {
        // Corrupt metadata only costs a re-download.
      }
    }
    return p;
  }

  void writeProps(File f, Properties p) {
    try {
      ensureDirs();
      File tmp = new File(f.getPath() + ".tmp");
      try (OutputStream out = new FileOutputStream(tmp)) {
        p.store(out, null);
      }
      replace(tmp, f);
    } catch (IOException ignored) {
      // Metadata is advisory.
    }
  }

  static long getLong(Properties p, String key, long def) {
    try {
      return Long.parseLong(p.getProperty(key, Long.toString(def)).trim());
    } catch (NumberFormatException e) {
      return def;
    }
  }

  static void replace(File from, File to) throws IOException {
    if (!from.renameTo(to)) {
      // renameTo over an existing file works on Android/Linux; this is a fallback.
      if (to.exists() && !to.delete()) throw new IOException("cannot replace " + to);
      if (!from.renameTo(to)) throw new IOException("cannot rename " + from + " to " + to);
    }
  }
}
