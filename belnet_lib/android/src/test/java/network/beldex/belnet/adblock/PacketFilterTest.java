package network.beldex.belnet.adblock;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import java.util.Arrays;
import java.util.Random;
import org.junit.Before;
import org.junit.Test;

public class PacketFilterTest {
  private boolean enabled = true;
  private DomainSet set;
  private PacketFilter filter;

  @Before
  public void setUp() {
    set = DomainSet.of(new long[] {DomainHash.hash("ads.example.com")}, new long[0], 0);
    filter =
        new PacketFilter(
            new PacketFilter.Decider() {
              @Override
              public boolean isEnabled() {
                return enabled;
              }

              @Override
              public boolean isBlocked(String n) {
                return set.isBlocked(n);
              }
            });
  }

  private static byte[] dnsPacket(String resolver, String name, boolean edns) {
    return DnsTestUtil.ipv4Udp(
        resolver, 41234, 53, DnsTestUtil.query(0x4242, name, DnsTestUtil.TYPE_A, edns));
  }

  @Test
  public void blockedQueryGetsValidNxDomainPacketBackToTheApp() {
    byte[] q = dnsPacket("9.9.9.9", "x.ads.example.com", true);
    assertEquals(PacketFilter.REPLY, filter.process(q, q.length));
    byte[] r = filter.reply;
    assertEquals(4, (r[0] & 0xff) >>> 4);
    assertEquals(17, r[9]);
    assertArrayEquals(Arrays.copyOfRange(q, 16, 20), Arrays.copyOfRange(r, 12, 16)); // from resolver
    assertArrayEquals(Arrays.copyOfRange(q, 12, 16), Arrays.copyOfRange(r, 16, 20)); // to the app
    assertEquals(53, PacketFilter.u16(r, 20));
    assertEquals(41234, PacketFilter.u16(r, 22));
    assertEquals(r.length, PacketFilter.u16(r, 2));
    assertEquals(r.length - 20, PacketFilter.u16(r, 24));
    assertTrue("IP/UDP checksums", DnsTestUtil.checksumsValid(r));
    byte[] dns = Arrays.copyOfRange(r, 28, r.length);
    assertEquals(0x4242, DnsPacket.id(dns));
    assertEquals(DnsPacket.RCODE_NXDOMAIN, DnsTestUtil.rcode(dns));
    assertEquals(1, filter.dnsBlocked.get());
    assertEquals(1, filter.dnsQueries.get());
  }

  @Test
  public void blockingWorksForAnyResolverAddress() {
    for (String resolver : new String[] {"9.9.9.9", "8.8.8.8", "1.1.1.1", "10.67.255.254", "203.0.113.5"}) {
      byte[] q = dnsPacket(resolver, "ads.example.com", false);
      assertEquals(resolver, PacketFilter.REPLY, filter.process(q, q.length));
      assertTrue(DnsTestUtil.checksumsValid(filter.reply));
    }
  }

  @Test
  public void allowedQueriesAndOtherTrafficAreForwardedUnchanged() {
    byte[] q = dnsPacket("9.9.9.9", "www.example.com", true);
    byte[] copy = q.clone();
    assertEquals(PacketFilter.FORWARD, filter.process(q, q.length));
    assertArrayEquals(copy, q);
    assertNull(filter.reply);

    byte[] web = DnsTestUtil.ipv4("10.67.0.1", "93.184.216.34", 6, DnsTestUtil.tcp(50000, 443, 1, 0, 0x02));
    assertEquals(PacketFilter.FORWARD, filter.process(web, web.length));
    byte[] quad9Web = DnsTestUtil.ipv4("10.67.0.1", "9.9.9.9", 6, DnsTestUtil.tcp(50000, 80, 1, 0, 0x02));
    assertEquals(PacketFilter.FORWARD, filter.process(quad9Web, quad9Web.length));
    byte[] udp = DnsTestUtil.ipv4Udp("93.184.216.34", 5000, 5001, new byte[40]);
    assertEquals(PacketFilter.FORWARD, filter.process(udp, udp.length));
  }

  @Test
  public void disabledForwardsEverything() {
    enabled = false;
    byte[] q = dnsPacket("9.9.9.9", "ads.example.com", false);
    assertEquals(PacketFilter.FORWARD, filter.process(q, q.length));
    byte[] dot = DnsTestUtil.ipv4("10.67.0.1", "9.9.9.9", 6, DnsTestUtil.tcp(50000, 853, 7, 0, 0x02));
    assertEquals(PacketFilter.FORWARD, filter.process(dot, dot.length));
  }

  @Test
  public void encryptedDnsToPublicResolversIsRefusedWithReset() {
    long seq = 0xfffffff0L; // wraps
    byte[] syn = DnsTestUtil.ipv4("10.67.0.1", "9.9.9.9", 6, DnsTestUtil.tcp(50001, 853, seq, 0, 0x02));
    assertEquals(PacketFilter.REPLY, filter.process(syn, syn.length));
    byte[] rst = filter.reply;
    assertTrue(DnsTestUtil.checksumsValid(rst));
    assertEquals(6, rst[9]);
    assertEquals(853, PacketFilter.u16(rst, 20));
    assertEquals(50001, PacketFilter.u16(rst, 22));
    assertEquals(0x14, rst[33] & 0xff); // RST|ACK
    assertEquals((seq + 1) & 0xffffffffL, PacketFilter.readU32(rst, 28));

    byte[] doh = DnsTestUtil.ipv4("10.67.0.1", "8.8.4.4", 6, DnsTestUtil.tcp(50002, 443, 5, 0, 0x02));
    assertEquals(PacketFilter.REPLY, filter.process(doh, doh.length));
    byte[] doh3 = DnsTestUtil.ipv4Udp("1.1.1.1", 50003, 443, new byte[100]);
    assertEquals(PacketFilter.DROP, filter.process(doh3, doh3.length));
    byte[] rstIn = DnsTestUtil.ipv4("10.67.0.1", "9.9.9.9", 6, DnsTestUtil.tcp(50001, 853, 1, 1, 0x04));
    assertEquals(PacketFilter.DROP, filter.process(rstIn, rstIn.length)); // never answer a RST
    assertEquals(4, filter.encryptedDnsRefused.get());
  }

  @Test
  public void ipv6EncryptedDnsIsDroppedOtherIpv6Forwarded() {
    byte[] doh6 = DnsTestUtil.ipv6("fd00::1", "2620:fe::fe", 6, DnsTestUtil.tcp(50000, 443, 1, 0, 0x02));
    assertEquals(PacketFilter.DROP, filter.process(doh6, doh6.length));
    byte[] cf6 = DnsTestUtil.ipv6("fd00::1", "2606:4700:4700::1111", 17, DnsTestUtil.udp(50000, 853, new byte[20]));
    assertEquals(PacketFilter.DROP, filter.process(cf6, cf6.length));
    byte[] web6 = DnsTestUtil.ipv6("fd00::1", "2001:db8::1", 6, DnsTestUtil.tcp(50000, 443, 1, 0, 0x02));
    assertEquals(PacketFilter.FORWARD, filter.process(web6, web6.length));
  }

  @Test
  public void fragmentsAndMalformedPacketsAreForwarded() {
    byte[] q = dnsPacket("9.9.9.9", "ads.example.com", false);
    byte[] mf = q.clone();
    mf[6] |= 0x20; // more fragments
    assertEquals(PacketFilter.FORWARD, filter.process(mf, mf.length));
    byte[] truncated = Arrays.copyOf(q, 30);
    assertEquals(PacketFilter.FORWARD, filter.process(truncated, truncated.length));
    byte[] badTotal = q.clone();
    PacketFilter.put16(badTotal, 2, 9999);
    assertEquals(PacketFilter.FORWARD, filter.process(badTotal, badTotal.length));
    assertEquals(PacketFilter.FORWARD, filter.process(new byte[10], 10));
  }

  @Test
  public void fuzzNeverThrows() {
    Random rnd = new Random(7);
    byte[] base = dnsPacket("9.9.9.9", "ads.example.com", true);
    for (int i = 0; i < 300_000; i++) {
      byte[] b;
      if (i % 3 == 0) {
        b = new byte[rnd.nextInt(120)];
        rnd.nextBytes(b);
      } else {
        b = base.clone();
        for (int k = 0; k < 1 + rnd.nextInt(5); k++) b[rnd.nextInt(b.length)] = (byte) rnd.nextInt();
      }
      int r = filter.process(b, rnd.nextInt(b.length + 1));
      if (r == PacketFilter.REPLY) assertTrue(filter.reply.length >= 28);
    }
  }

  @Test
  public void firefoxDohCanaryIsAnsweredNxDomain() {
    byte[] q = dnsPacket("9.9.9.9", "use-application-dns.net", false);
    assertEquals(PacketFilter.REPLY, filter.process(q, q.length));
  }

  @Test
  public void checksumMatchesKnownVector() {
    // RFC 1071 example data.
    byte[] d = {0x00, 0x01, (byte) 0xf2, 0x03, (byte) 0xf4, (byte) 0xf5, (byte) 0xf6, (byte) 0xf7};
    assertEquals(~0xddf2 & 0xffff, PacketFilter.checksum(d, 0, d.length, 0));
  }
}
