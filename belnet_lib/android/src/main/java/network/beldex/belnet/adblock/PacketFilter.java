package network.beldex.belnet.adblock;

import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Decides, per IP packet leaving the TUN (i.e. sent by an app routed through
 * BelNet), whether the packet goes on to the BelNet daemon unchanged, is
 * dropped, or is answered locally.
 *
 * <ul>
 *   <li><b>Plain DNS</b> (IPv4 UDP to port 53, any resolver): a query for a
 *       blocked domain is answered with NXDOMAIN, written straight back to
 *       the app; every other query is forwarded unchanged, so it takes the
 *       exact path it took before (daemon, exit node, upstream resolver).
 *   <li><b>Encrypted DNS to well-known public resolvers</b> (DoT on 853, DoH
 *       on 443, TCP and UDP/QUIC): refused, a TCP connection attempt with a
 *       RST so the client gives up at once. Android's "Automatic" Private
 *       DNS and browsers' automatic Secure DNS then fall back to plain DNS,
 *       which can be filtered. Only these specific resolver addresses are
 *       affected.
 *   <li>Everything else, and everything while the Ad Blocker is switched
 *       off, is forwarded untouched.
 * </ul>
 *
 * <p>Not thread-safe: one instance is used by the single thread that reads
 * from the TUN. Malformed packets are forwarded, never parsed beyond their
 * real length.
 */
final class PacketFilter {

  /** Decision source, backed by the {@link AdBlockEngine}. */
  interface Decider {
    boolean isEnabled();

    boolean isBlocked(String normalizedName);
  }

  static final int FORWARD = 0;
  static final int DROP = 1;
  static final int REPLY = 2;

  private static final int PROTO_TCP = 6;
  private static final int PROTO_UDP = 17;
  private static final int PROTO_UDP_V6 = 17;

  /**
   * Addresses of public resolvers that browsers / Android upgrade to
   * encrypted DNS automatically (Quad9, Cloudflare, Google, AdGuard),
   * including every resolver the app itself uses (9.9.9.9, 1.1.1.1,
   * 8.8.8.8, 1.1.1.3 for Block malware, 94.140.14.14 for the Ad Blocker).
   */
  static final String[] ENCRYPTED_DNS_IPV4 = {
    "9.9.9.9", "149.112.112.112", "9.9.9.10", "149.112.112.10", "9.9.9.11", "149.112.112.11",
    "1.1.1.1", "1.0.0.1", "1.1.1.2", "1.0.0.2", "1.1.1.3", "1.0.0.3",
    "8.8.8.8", "8.8.4.4",
    "94.140.14.14", "94.140.15.15", "94.140.14.15", "94.140.15.16",
  };

  static final String[] ENCRYPTED_DNS_IPV6 = {
    "2620:fe::fe", "2620:fe::9", "2620:fe::10", "2620:fe::fe:10", "2620:fe::11", "2620:fe::fe:11",
    "2606:4700:4700::1111", "2606:4700:4700::1001",
    "2606:4700:4700::1112", "2606:4700:4700::1002",
    "2606:4700:4700::1113", "2606:4700:4700::1003",
    "2001:4860:4860::8888", "2001:4860:4860::8844",
    "2a10:50c0::ad1:ff", "2a10:50c0::ad2:ff", "2a10:50c0::bad1:ff", "2a10:50c0::bad2:ff",
  };

  private final Decider decider;
  private final Set<Integer> encryptedV4 = new HashSet<>();
  private final Set<String> encryptedV6 = new HashSet<>();

  final AtomicLong dnsQueries = new AtomicLong();
  final AtomicLong dnsBlocked = new AtomicLong();
  final AtomicLong encryptedDnsRefused = new AtomicLong();

  /** Reply written by {@link #process} when it returns {@link #REPLY}. */
  byte[] reply;

  PacketFilter(Decider decider) {
    this.decider = decider;
    for (String ip : ENCRYPTED_DNS_IPV4) encryptedV4.add(parseIpv4(ip));
    for (String ip : ENCRYPTED_DNS_IPV6) encryptedV6.add(canonicalV6(parseIpv6(ip), 0));
  }

  /** Classifies one packet read from the TUN. */
  int process(byte[] p, int len) {
    reply = null;
    if (len < 20 || !decider.isEnabled()) return FORWARD;
    int version = (p[0] & 0xff) >>> 4;
    if (version == 4) return processV4(p, len);
    if (version == 6) return processV6(p, len);
    return FORWARD;
  }

  // ---------------------------------------------------------------------
  // IPv4

  private int processV4(byte[] p, int len) {
    int ihl = (p[0] & 0x0f) * 4;
    int total = u16(p, 2);
    if (ihl < 20 || total < ihl || total > len) return FORWARD;
    int frag = u16(p, 6);
    if ((frag & 0x1fff) != 0) return FORWARD; // non-first fragment
    boolean moreFragments = (frag & 0x2000) != 0;
    int proto = p[9] & 0xff;
    int dst = (int) readU32(p, 16);

    if (proto == PROTO_UDP) {
      if (total < ihl + 8) return FORWARD;
      int dport = u16(p, ihl + 2);
      if (dport == 53 && !moreFragments) return dnsQueryV4(p, ihl, total);
      if ((dport == 443 || dport == 853) && encryptedV4.contains(dst)) {
        encryptedDnsRefused.incrementAndGet();
        return DROP; // DoH3 / DoQ: clients fall back to TCP, which is refused below
      }
      return FORWARD;
    }
    if (proto == PROTO_TCP && total >= ihl + 20) {
      int dport = u16(p, ihl + 2);
      if ((dport == 443 || dport == 853) && encryptedV4.contains(dst)) {
        encryptedDnsRefused.incrementAndGet();
        int flags = p[ihl + 13] & 0xff;
        boolean syn = (flags & 0x02) != 0;
        boolean rst = (flags & 0x04) != 0;
        if (rst) return DROP;
        reply = tcpResetV4(p, ihl, total, syn);
        return REPLY;
      }
    }
    return FORWARD;
  }

  private int dnsQueryV4(byte[] p, int ihl, int total) {
    int udpLen = u16(p, ihl + 4);
    int dnsOff = ihl + 8;
    int dnsLen = Math.min(udpLen - 8, total - dnsOff);
    if (dnsLen < DnsPacket.HEADER_SIZE) return FORWARD;
    byte[] dns = new byte[dnsLen];
    System.arraycopy(p, dnsOff, dns, 0, dnsLen);
    DnsPacket.Query q = DnsPacket.parseQuery(dns, dnsLen);
    if (q == null) return FORWARD;
    dnsQueries.incrementAndGet();
    if (q.name == null || !isBlocked(q.name)) return FORWARD;
    dnsBlocked.incrementAndGet();
    reply = udpReplyV4(p, ihl, DnsPacket.buildNxDomain(dns, q));
    return REPLY;
  }

  /**
   * Firefox's canary domain: an NXDOMAIN answer tells Firefox not to enable
   * DNS-over-HTTPS automatically, so its lookups stay on the filtered path.
   */
  static final String FIREFOX_DOH_CANARY = "use-application-dns.net";

  private boolean isBlocked(String name) {
    if (FIREFOX_DOH_CANARY.equals(name)) return true;
    try {
      return decider.isBlocked(name);
    } catch (RuntimeException e) {
      return false; // a filter bug must never break resolution
    }
  }

  /** UDP reply from the query's destination back to its source. */
  static byte[] udpReplyV4(byte[] q, int ihl, byte[] payload) {
    int total = 20 + 8 + payload.length;
    byte[] r = new byte[total];
    r[0] = 0x45;
    put16(r, 2, total);
    put16(r, 6, 0x4000); // DF
    r[8] = 64; // TTL
    r[9] = PROTO_UDP;
    System.arraycopy(q, 16, r, 12, 4); // src = original dst
    System.arraycopy(q, 12, r, 16, 4); // dst = original src
    put16(r, 10, checksum(r, 0, 20, 0));
    put16(r, 20, u16(q, ihl + 2)); // sport = original dport (53)
    put16(r, 22, u16(q, ihl)); // dport = original sport
    put16(r, 24, 8 + payload.length);
    System.arraycopy(payload, 0, r, 28, payload.length);
    int sum = pseudoV4(r, PROTO_UDP, 8 + payload.length);
    int c = checksum(r, 20, 8 + payload.length, sum);
    put16(r, 26, c == 0 ? 0xffff : c);
    return r;
  }

  /** RST (+ACK) answering a TCP segment, so the client fails immediately. */
  static byte[] tcpResetV4(byte[] q, int ihl, int total, boolean syn) {
    int tcpHdr = ((q[ihl + 12] & 0xff) >>> 4) * 4;
    int segLen = Math.max(0, total - ihl - tcpHdr);
    long seq = readU32(q, ihl + 4);
    long ack = readU32(q, ihl + 8);
    boolean hasAck = (q[ihl + 13] & 0x10) != 0;
    boolean fin = (q[ihl + 13] & 0x01) != 0;
    byte[] r = new byte[40];
    r[0] = 0x45;
    put16(r, 2, 40);
    put16(r, 6, 0x4000);
    r[8] = 64;
    r[9] = PROTO_TCP;
    System.arraycopy(q, 16, r, 12, 4);
    System.arraycopy(q, 12, r, 16, 4);
    put16(r, 10, checksum(r, 0, 20, 0));
    put16(r, 20, u16(q, ihl + 2));
    put16(r, 22, u16(q, ihl));
    putU32(r, 24, hasAck ? ack : 0);
    putU32(r, 28, (seq + segLen + (syn ? 1 : 0) + (fin ? 1 : 0)) & 0xffffffffL);
    r[32] = 0x50; // 5 words
    r[33] = 0x14; // RST | ACK
    int sum = pseudoV4(r, PROTO_TCP, 20);
    put16(r, 36, checksum(r, 20, 20, sum));
    return r;
  }

  private static int pseudoV4(byte[] r, int proto, int l4len) {
    int sum = 0;
    for (int i = 12; i < 20; i += 2) sum += u16(r, i);
    return sum + proto + l4len;
  }

  // ---------------------------------------------------------------------
  // IPv6: encrypted-DNS refusal only (Android announces an IPv4 resolver,
  // so plain DNS travels over IPv4).

  private int processV6(byte[] p, int len) {
    if (len < 40) return FORWARD;
    int next = p[6] & 0xff;
    if (next != PROTO_TCP && next != PROTO_UDP_V6) return FORWARD; // ext. headers: leave alone
    if (len < 44) return FORWARD;
    int dport = u16(p, 42);
    if (dport != 443 && dport != 853) return FORWARD;
    if (!encryptedV6.contains(canonicalV6(p, 24))) return FORWARD;
    encryptedDnsRefused.incrementAndGet();
    return DROP;
  }

  // ---------------------------------------------------------------------
  // Helpers

  static int u16(byte[] b, int off) {
    return ((b[off] & 0xff) << 8) | (b[off + 1] & 0xff);
  }

  static void put16(byte[] b, int off, int v) {
    b[off] = (byte) (v >>> 8);
    b[off + 1] = (byte) v;
  }

  static long readU32(byte[] b, int off) {
    return ((long) (b[off] & 0xff) << 24) | ((b[off + 1] & 0xff) << 16)
        | ((b[off + 2] & 0xff) << 8) | (b[off + 3] & 0xff);
  }

  static void putU32(byte[] b, int off, long v) {
    b[off] = (byte) (v >>> 24);
    b[off + 1] = (byte) (v >>> 16);
    b[off + 2] = (byte) (v >>> 8);
    b[off + 3] = (byte) v;
  }

  /** Internet checksum of {@code b[off, off+len)} with an initial partial sum. */
  static int checksum(byte[] b, int off, int len, int initial) {
    long sum = initial & 0xffffffffL;
    int i = off;
    for (; i + 1 < off + len; i += 2) sum += u16(b, i);
    if (i < off + len) sum += (b[i] & 0xff) << 8;
    while ((sum >>> 16) != 0) sum = (sum & 0xffff) + (sum >>> 16);
    return (int) (~sum & 0xffff);
  }

  static int parseIpv4(String s) {
    String[] parts = s.split("\\.");
    int v = 0;
    for (String part : parts) v = (v << 8) | Integer.parseInt(part);
    return v;
  }

  /** 16 bytes of an IPv6 literal (no zone, no embedded IPv4). */
  static byte[] parseIpv6(String s) {
    String[] halves = s.split("::", -1);
    String[] head = halves[0].isEmpty() ? new String[0] : halves[0].split(":");
    String[] tail =
        halves.length > 1 && !halves[1].isEmpty() ? halves[1].split(":") : new String[0];
    byte[] out = new byte[16];
    int i = 0;
    for (String g : head) {
      int v = Integer.parseInt(g, 16);
      out[i++] = (byte) (v >>> 8);
      out[i++] = (byte) v;
    }
    int j = 16 - tail.length * 2;
    for (String g : tail) {
      int v = Integer.parseInt(g, 16);
      out[j++] = (byte) (v >>> 8);
      out[j++] = (byte) v;
    }
    return out;
  }

  private static String canonicalV6(byte[] b, int off) {
    StringBuilder sb = new StringBuilder(32);
    for (int i = 0; i < 16; i++) {
      int v = b[off + i] & 0xff;
      sb.append(Character.forDigit(v >>> 4, 16)).append(Character.forDigit(v & 0xf, 16));
    }
    return sb.toString();
  }
}
