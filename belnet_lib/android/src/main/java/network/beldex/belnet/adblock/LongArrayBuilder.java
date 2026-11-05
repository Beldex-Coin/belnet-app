package network.beldex.belnet.adblock;

import java.util.Arrays;

/** Growable primitive long array (avoids boxing 100k+ hashes). */
final class LongArrayBuilder {
  private long[] data;
  private int size;

  LongArrayBuilder() {
    this(1024);
  }

  LongArrayBuilder(int initialCapacity) {
    data = new long[Math.max(16, initialCapacity)];
  }

  void add(long v) {
    if (size == data.length) {
      data = Arrays.copyOf(data, data.length + (data.length >> 1));
    }
    data[size++] = v;
  }

  void addAll(long[] values) {
    for (long v : values) add(v);
  }

  int size() {
    return size;
  }

  /** Sorted copy with duplicates removed. */
  long[] toSortedUnique() {
    return sortedUnique(Arrays.copyOf(data, size));
  }

  /** Sorts {@code values} in place and returns the de-duplicated prefix. */
  static long[] sortedUnique(long[] values) {
    if (values.length == 0) return values;
    Arrays.sort(values);
    int w = 1;
    for (int r = 1; r < values.length; r++) {
      if (values[r] != values[w - 1]) values[w++] = values[r];
    }
    return w == values.length ? values : Arrays.copyOf(values, w);
  }
}
