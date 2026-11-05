package network.beldex.belnet.adblock;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;

/** Builds DNS packets (and IP packets carrying them) for tests. */
final class DnsTestUtil {
  private DnsTestUtil() {}

  static final int TYPE_A = 1;
  static final int TYPE_AAAA = 28;

  static byte[] query(int id, String name, int qtype, boolean edns) {
    ByteArrayOutputStream o = new ByteArrayOutputStream();
    write16(o, id);
    write16(o, 0x0100); // RD
    write16(o, 1);
    write16(o, 0);
    write16(o, 0);
    write16(o, edns ? 1 : 0);
    for (String label : name.split("\\.")) {
      byte[] l = label.getBytes(StandardCharsets.US_ASCII);
      o.write(l.length);
      o.write(l, 0, l.length);
    }
    o.write(0);
    write16(o, qtype);
    write16(o, 1);
    if (edns) {
      o.write(0);
      write16(o, 41);
      write16(o, 1232);
      o.write(0);
      o.write(0);
      write16(o, 0x8000); // DO
      write16(o, 0);
    }
    return o.toByteArray();
  }

  /** A minimal answer: echoes the question with one A record 93.184.216.34. */
  static byte[] answerFor(byte[] q, int len) {
    DnsPacket.Query parsed = DnsPacket.parseQuery(q, len);
    int qEnd = parsed.questionEnd;
    ByteArrayOutputStream o = new ByteArrayOutputStream();
    write16(o, parsed.id);
    write16(o, 0x8180); // QR RD RA
    write16(o, 1);
    write16(o, 1);
    write16(o, 0);
    write16(o, 0);
    o.write(q, 12, qEnd - 12);
    write16(o, 0xc00c); // pointer to the question name
    write16(o, TYPE_A);
    write16(o, 1);
    write16(o, 0);
    write16(o, 300);
    write16(o, 4);
    o.write(93);
    o.write(184);
    o.write(216);
    o.write(34);
    return o.toByteArray();
  }

  static void write16(ByteArrayOutputStream o, int v) {
    o.write((v >>> 8) & 0xff);
    o.write(v & 0xff);
  }

  static int rcode(byte[] resp) {
    return resp[3] & 0x0f;
  }

  static int ancount(byte[] resp) {
    return DnsPacket.u16(resp, 6);
  }

  /** IPv4 + UDP packet from 10.67.0.1:sport to dst:dport carrying payload. */
  static byte[] ipv4Udp(String dst, int sport, int dport, byte[] payload) {
    return ipv4("10.67.0.1", dst, 17, udp(sport, dport, payload));
  }

  static byte[] udp(int sport, int dport, byte[] payload) {
    byte[] u = new byte[8 + payload.length];
    PacketFilter.put16(u, 0, sport);
    PacketFilter.put16(u, 2, dport);
    PacketFilter.put16(u, 4, u.length);
    System.arraycopy(payload, 0, u, 8, payload.length);
    return u;
  }

  /** TCP segment with the given flags (no options, no payload). */
  static byte[] tcp(int sport, int dport, long seq, long ack, int flags) {
    byte[] t = new byte[20];
    PacketFilter.put16(t, 0, sport);
    PacketFilter.put16(t, 2, dport);
    PacketFilter.putU32(t, 4, seq);
    PacketFilter.putU32(t, 8, ack);
    t[12] = 0x50;
    t[13] = (byte) flags;
    PacketFilter.put16(t, 14, 65535);
    return t;
  }

  static byte[] ipv4(String src, String dst, int proto, byte[] l4) {
    byte[] p = new byte[20 + l4.length];
    p[0] = 0x45;
    PacketFilter.put16(p, 2, p.length);
    p[8] = 64;
    p[9] = (byte) proto;
    PacketFilter.putU32(p, 12, PacketFilter.parseIpv4(src) & 0xffffffffL);
    PacketFilter.putU32(p, 16, PacketFilter.parseIpv4(dst) & 0xffffffffL);
    System.arraycopy(l4, 0, p, 20, l4.length);
    PacketFilter.put16(p, 10, PacketFilter.checksum(p, 0, 20, 0));
    return p;
  }

  /** IPv6 packet (next header = proto, no extension headers). */
  static byte[] ipv6(String src, String dst, int proto, byte[] l4) {
    byte[] p = new byte[40 + l4.length];
    p[0] = 0x60;
    PacketFilter.put16(p, 4, l4.length);
    p[6] = (byte) proto;
    p[7] = 64;
    System.arraycopy(PacketFilter.parseIpv6(src), 0, p, 8, 16);
    System.arraycopy(PacketFilter.parseIpv6(dst), 0, p, 24, 16);
    System.arraycopy(l4, 0, p, 40, l4.length);
    return p;
  }

  /** True when the IPv4 header and TCP/UDP checksums of p verify. */
  static boolean checksumsValid(byte[] p) {
    int ihl = (p[0] & 0x0f) * 4;
    if (PacketFilter.checksum(p, 0, ihl, 0) != 0) return false;
    int total = PacketFilter.u16(p, 2);
    int l4len = total - ihl;
    long sum = 0;
    for (int i = 12; i < 20; i += 2) sum += PacketFilter.u16(p, i);
    sum += p[9] & 0xff;
    sum += l4len;
    return PacketFilter.checksum(p, ihl, l4len, (int) sum) == 0;
  }
}
