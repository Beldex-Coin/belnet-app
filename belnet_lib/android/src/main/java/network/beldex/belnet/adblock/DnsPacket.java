package network.beldex.belnet.adblock;

/**
 * Minimal, allocation-light DNS wire-format handling for the Ad Blocker: parse
 * the single question of a standard query and build an NXDOMAIN reply.
 *
 * <p>Every read is bounds-checked; malformed input yields null instead of
 * throwing, so a hostile or corrupt packet can never take the relay down.
 */
final class DnsPacket {
  private DnsPacket() {}

  static final int HEADER_SIZE = 12;
  static final int TYPE_OPT = 41;
  static final int RCODE_NXDOMAIN = 3;
  /** EDNS(0) UDP payload size advertised in replies (DNS Flag Day 2020). */
  static final int EDNS_UDP_SIZE = 1232;

  /** The parts of a query the filter needs. */
  static final class Query {
    int id;
    int flags;
    /** Lower-case presentation-form name without trailing dot; null if unusable. */
    String name;
    int qtype;
    int qclass;
    /** Offset just past the question section. */
    int questionEnd;
    /** Query carried an EDNS(0) OPT record. */
    boolean hasOpt;
    /** DNSSEC OK bit from the OPT record. */
    boolean dnssecOk;
  }

  static int u16(byte[] b, int off) {
    return ((b[off] & 0xff) << 8) | (b[off + 1] & 0xff);
  }

  static void put16(byte[] b, int off, int v) {
    b[off] = (byte) (v >>> 8);
    b[off + 1] = (byte) v;
  }

  /** Query ID of any DNS message of at least {@link #HEADER_SIZE} bytes. */
  static int id(byte[] b) {
    return u16(b, 0);
  }

  /** True when the header's QR bit marks a response. */
  static boolean isResponse(byte[] b, int len) {
    return len >= HEADER_SIZE && (b[2] & 0x80) != 0;
  }

  /**
   * Parses a standard query (QR=0, OPCODE=0, exactly one question).
   * Returns null for anything else or for malformed packets.
   */
  static Query parseQuery(byte[] b, int len) {
    if (b == null || len < HEADER_SIZE || len > b.length) return null;
    int flags = u16(b, 2);
    if ((flags & 0x8000) != 0) return null; // a response, not a query
    if (((flags >>> 11) & 0xf) != 0) return null; // only standard QUERY
    if (u16(b, 4) != 1) return null; // exactly one question

    Query q = new Query();
    q.id = u16(b, 0);
    q.flags = flags;

    StringBuilder name = new StringBuilder(64);
    int pos = readName(b, len, HEADER_SIZE, name);
    if (pos < 0 || pos + 4 > len) return null;
    q.qtype = u16(b, pos);
    q.qclass = u16(b, pos + 2);
    q.questionEnd = pos + 4;
    q.name = name.length() == 0 ? null : DomainHash.normalize(name.toString());

    // Look for an OPT record in the additional section (queries carry no
    // answer/authority records; if they do, skip them generically).
    int an = u16(b, 6), ns = u16(b, 8), ar = u16(b, 10);
    int p = q.questionEnd;
    for (int i = 0; i < an + ns + ar && p < len; i++) {
      int nameEnd = skipName(b, len, p);
      if (nameEnd < 0 || nameEnd + 10 > len) break;
      int type = u16(b, nameEnd);
      int rdLen = u16(b, nameEnd + 8);
      if (i >= an + ns && type == TYPE_OPT) {
        q.hasOpt = true;
        q.dnssecOk = (b[nameEnd + 6] & 0x80) != 0;
      }
      p = nameEnd + 10 + rdLen;
    }
    return q;
  }

  /**
   * Reads a (possibly compressed) name starting at {@code off}. Appends the
   * dotted name to {@code out}, or leaves {@code out} empty when a label
   * contains bytes that cannot be part of a hostname (the query is still
   * well-formed and will be forwarded, just never matched). Returns the
   * offset just past the name in the original position, or -1 if malformed.
   */
  static int readName(byte[] b, int len, int off, StringBuilder out) {
    int pos = off;
    int end = -1; // position after the name where parsing must resume
    int jumps = 0;
    int total = 0;
    boolean printable = true;
    while (true) {
      if (pos >= len) return -1;
      int l = b[pos] & 0xff;
      if (l == 0) {
        if (end < 0) end = pos + 1;
        break;
      }
      if ((l & 0xc0) == 0xc0) { // compression pointer
        if (pos + 1 >= len) return -1;
        if (++jumps > 16) return -1; // pointer loop
        int target = ((l & 0x3f) << 8) | (b[pos + 1] & 0xff);
        if (end < 0) end = pos + 2;
        if (target >= pos) return -1; // pointers must point backwards
        pos = target;
        continue;
      }
      if ((l & 0xc0) != 0) return -1; // reserved label types
      if (pos + 1 + l > len) return -1;
      total += l + 1;
      if (total > 255) return -1;
      if (out.length() > 0) out.append('.');
      for (int i = 0; i < l; i++) {
        int c = b[pos + 1 + i] & 0xff;
        if (c <= 0x20 || c >= 0x7f || c == '.') printable = false;
        out.append((char) c);
      }
      pos += 1 + l;
    }
    if (!printable) out.setLength(0);
    return end;
  }

  /** Offset just past the name at {@code off}, or -1 if malformed. */
  static int skipName(byte[] b, int len, int off) {
    int pos = off;
    int guard = 0;
    while (pos < len && guard++ < 128) {
      int l = b[pos] & 0xff;
      if (l == 0) return pos + 1;
      if ((l & 0xc0) == 0xc0) return pos + 2 <= len ? pos + 2 : -1;
      if ((l & 0xc0) != 0) return -1;
      pos += 1 + l;
    }
    return -1;
  }

  /**
   * Builds an NXDOMAIN answer to {@code query}: same ID and question, RD and
   * CD copied from the query, RA set, no answer records. An OPT record is
   * echoed when the query had one. No SOA is included, so Android's resolver
   * does not cache the negative answer and turning the Ad Blocker off takes
   * effect on the next lookup.
   */
  static byte[] buildNxDomain(byte[] request, Query query) {
    int qLen = query.questionEnd - HEADER_SIZE;
    int optLen = query.hasOpt ? 11 : 0;
    byte[] out = new byte[HEADER_SIZE + qLen + optLen];
    put16(out, 0, query.id);
    int flags = 0x8000 // QR
        | (query.flags & 0x0100) // RD
        | 0x0080 // RA
        | (query.flags & 0x0010) // CD
        | RCODE_NXDOMAIN;
    put16(out, 2, flags);
    put16(out, 4, 1); // QDCOUNT
    put16(out, 6, 0);
    put16(out, 8, 0);
    put16(out, 10, query.hasOpt ? 1 : 0);
    System.arraycopy(request, HEADER_SIZE, out, HEADER_SIZE, qLen);
    if (query.hasOpt) {
      int p = HEADER_SIZE + qLen;
      out[p] = 0; // root name
      put16(out, p + 1, TYPE_OPT);
      put16(out, p + 3, EDNS_UDP_SIZE);
      out[p + 5] = 0; // extended RCODE
      out[p + 6] = 0; // EDNS version
      out[p + 7] = (byte) (query.dnssecOk ? 0x80 : 0); // DO bit echoed
      out[p + 8] = 0;
      put16(out, p + 9, 0); // RDLEN
    }
    return out;
  }
}
