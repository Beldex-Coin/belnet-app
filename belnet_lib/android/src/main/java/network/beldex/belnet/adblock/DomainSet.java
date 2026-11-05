package network.beldex.belnet.adblock;

import java.util.Arrays;

/**
 * Immutable compiled blocklist: sorted, de-duplicated domain hashes for
 * blocked domains and for exceptions (allowlist).
 *
 * <p>A name is blocked when it, or any parent domain, is on the blocklist and
 * neither it nor any parent domain is on the allowlist (exceptions win, as in
 * AdGuard's {@code @@||domain^} rules). The top-level label alone is never
 * matched, so a list can never block a whole TLD.
 *
 * <p>Instances are immutable and safe to share between threads; a new list
 * is published by swapping the reference.
 */
final class DomainSet {
  static final DomainSet EMPTY = new DomainSet(new long[0], new long[0], 0L);

  private final long[] blocked;
  private final long[] allowed;
  private final long createdAtMs;

  private DomainSet(long[] blockedSortedUnique, long[] allowedSortedUnique, long createdAtMs) {
    this.blocked = blockedSortedUnique;
    this.allowed = allowedSortedUnique;
    this.createdAtMs = createdAtMs;
  }

  /** Builds a set from unsorted hashes (copies, sorts and de-duplicates). */
  static DomainSet of(long[] blockedHashes, long[] allowedHashes, long createdAtMs) {
    return new DomainSet(
        LongArrayBuilder.sortedUnique(Arrays.copyOf(blockedHashes, blockedHashes.length)),
        LongArrayBuilder.sortedUnique(Arrays.copyOf(allowedHashes, allowedHashes.length)),
        createdAtMs);
  }

  /** Wraps arrays that are already sorted and unique (e.g. from disk). */
  static DomainSet ofSorted(long[] blockedSortedUnique, long[] allowedSortedUnique, long createdAtMs) {
    return new DomainSet(blockedSortedUnique, allowedSortedUnique, createdAtMs);
  }

  int blockedCount() {
    return blocked.length;
  }

  int allowedCount() {
    return allowed.length;
  }

  long createdAtMs() {
    return createdAtMs;
  }

  long[] blockedHashes() {
    return blocked;
  }

  long[] allowedHashes() {
    return allowed;
  }

  /**
   * @param normalizedName output of {@link DomainHash#normalize(String)}.
   */
  boolean isBlocked(String normalizedName) {
    if (normalizedName == null || blocked.length == 0) return false;
    long[] suffixes = new long[DomainHash.labelCount(normalizedName)];
    int n = DomainHash.suffixHashes(normalizedName, suffixes);
    boolean hit = false;
    // i = 0 is the bare TLD: never matched.
    for (int i = 1; i < n; i++) {
      long h = suffixes[i];
      if (allowed.length != 0 && Arrays.binarySearch(allowed, h) >= 0) return false;
      if (!hit && Arrays.binarySearch(blocked, h) >= 0) hit = true;
    }
    return hit;
  }
}
