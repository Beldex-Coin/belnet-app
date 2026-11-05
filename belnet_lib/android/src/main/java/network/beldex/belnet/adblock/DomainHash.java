package network.beldex.belnet.adblock;

/**
 * Domain-name normalisation and 64-bit hashing.
 *
 * <p>Filter lists hold hundreds of thousands of names. Storing them as
 * {@code HashSet<String>} costs roughly 100 bytes per entry; storing a 64-bit
 * hash in a sorted {@code long[]} costs 8 bytes, so a 250k-domain blocklist
 * fits in about 2 MB. With 64-bit hashes the chance that an unrelated name
 * collides with a blocked one is about {@code n / 2^64} per lookup, which is
 * negligible.
 *
 * <p>The hash is computed over the characters <em>from right to left</em>,
 * so that one pass over a query name yields the hash of every parent domain
 * ("com", "example.com", "ads.example.com", ...). That makes subdomain
 * matching O(length of the name).
 */
final class DomainHash {
  private DomainHash() {}

  private static final long FNV_OFFSET = 0xcbf29ce484222325L;
  private static final long FNV_PRIME = 0x100000001b3L;

  /** Longest legal DNS name in presentation form (without trailing dot). */
  static final int MAX_NAME_LENGTH = 253;

  /** murmur3 fmix64 finaliser: spreads FNV's weak low bits. */
  private static long mix(long h) {
    h ^= h >>> 33;
    h *= 0xff51afd7ed558ccdL;
    h ^= h >>> 33;
    h *= 0xc4ceb9fe1a85ec53L;
    h ^= h >>> 33;
    return h;
  }

  /** Hash of an already-normalised name. */
  static long hash(String name) {
    long h = FNV_OFFSET;
    for (int i = name.length() - 1; i >= 0; i--) {
      h ^= name.charAt(i);
      h *= FNV_PRIME;
    }
    return mix(h);
  }

  /**
   * Writes the hashes of every suffix of {@code name} that starts at a label
   * boundary, shortest first: for "a.b.com" -> h("com"), h("b.com"),
   * h("a.b.com"). Returns the number written. {@code out} must hold at least
   * {@code labelCount(name)} entries.
   */
  static int suffixHashes(String name, long[] out) {
    long h = FNV_OFFSET;
    int n = 0;
    for (int i = name.length() - 1; i >= 0; i--) {
      char c = name.charAt(i);
      if (c == '.') {
        out[n++] = mix(h);
      }
      h ^= c;
      h *= FNV_PRIME;
    }
    out[n++] = mix(h);
    return n;
  }

  static int labelCount(String name) {
    int n = 1;
    for (int i = 0; i < name.length(); i++) {
      if (name.charAt(i) == '.') n++;
    }
    return n;
  }

  /**
   * Normalises a domain from a filter list or a DNS query: lower-case, no
   * trailing dot, ASCII hostname characters only, at least two labels, a
   * non-numeric top-level label (rejects IP literals) and RFC length limits.
   * Returns null when the input is not a usable domain.
   */
  static String normalize(String raw) {
    if (raw == null) return null;
    int start = 0;
    int end = raw.length();
    while (start < end && raw.charAt(start) == '.') start++;
    while (end > start && raw.charAt(end - 1) == '.') end--;
    int len = end - start;
    if (len < 3 || len > MAX_NAME_LENGTH) return null;

    char[] out = new char[len];
    int labelLen = 0;
    int labels = 1;
    boolean lastLabelHasLetter = false;
    for (int i = 0; i < len; i++) {
      char c = raw.charAt(start + i);
      if (c >= 'A' && c <= 'Z') c = (char) (c + 32);
      if (c == '.') {
        if (labelLen == 0) return null; // empty label ("a..b")
        labels++;
        labelLen = 0;
        lastLabelHasLetter = false;
      } else if ((c >= 'a' && c <= 'z') || c == '-' || c == '_') {
        if (++labelLen > 63) return null;
        if (c != '-' && c != '_') lastLabelHasLetter = true;
      } else if (c >= '0' && c <= '9') {
        if (++labelLen > 63) return null;
      } else {
        return null; // wildcard, URL syntax, unicode, whitespace, ...
      }
      out[i] = c;
    }
    if (labelLen == 0 || labels < 2 || !lastLabelHasLetter) return null;
    return new String(out);
  }
}
