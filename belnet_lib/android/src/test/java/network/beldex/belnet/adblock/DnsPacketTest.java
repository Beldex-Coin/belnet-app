package network.beldex.belnet.adblock;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import java.util.Arrays;
import java.util.Random;
import org.junit.Test;

public class DnsPacketTest {

  @Test
  public void parsesQueryWithEdns() {
    byte[] q = DnsTestUtil.query(0x1234, "Ads.Example.com", DnsTestUtil.TYPE_AAAA, true);
    DnsPacket.Query p = DnsPacket.parseQuery(q, q.length);
    assertNotNull(p);
    assertEquals(0x1234, p.id);
    assertEquals("ads.example.com", p.name);
    assertEquals(DnsTestUtil.TYPE_AAAA, p.qtype);
    assertEquals(1, p.qclass);
    assertTrue(p.hasOpt);
    assertTrue(p.dnssecOk);
  }

  @Test
  public void nxDomainEchoesQuestionAndOpt() {
    byte[] q = DnsTestUtil.query(0xbeef, "ads.example.com", DnsTestUtil.TYPE_A, true);
    DnsPacket.Query p = DnsPacket.parseQuery(q, q.length);
    byte[] r = DnsPacket.buildNxDomain(q, p);
    assertEquals(0xbeef, DnsPacket.id(r));
    assertTrue(DnsPacket.isResponse(r, r.length));
    assertEquals(DnsPacket.RCODE_NXDOMAIN, DnsTestUtil.rcode(r));
    assertEquals(0x0100, DnsPacket.u16(r, 2) & 0x0100); // RD copied
    assertEquals(0x0080, DnsPacket.u16(r, 2) & 0x0080); // RA set
    assertEquals(1, DnsPacket.u16(r, 4));
    assertEquals(0, DnsTestUtil.ancount(r));
    assertEquals(1, DnsPacket.u16(r, 10)); // OPT echoed
    assertArrayEquals(
        Arrays.copyOfRange(q, 12, p.questionEnd), Arrays.copyOfRange(r, 12, p.questionEnd));
    // The reply is itself parseable as a well-formed message.
    int nameEnd = DnsPacket.skipName(r, r.length, p.questionEnd);
    assertEquals(DnsPacket.TYPE_OPT, DnsPacket.u16(r, nameEnd));
    assertEquals(r.length, nameEnd + 10);
  }

  @Test
  public void nxDomainWithoutEdns() {
    byte[] q = DnsTestUtil.query(7, "ads.example.com", DnsTestUtil.TYPE_A, false);
    DnsPacket.Query p = DnsPacket.parseQuery(q, q.length);
    assertFalse(p.hasOpt);
    byte[] r = DnsPacket.buildNxDomain(q, p);
    assertEquals(0, DnsPacket.u16(r, 10));
    assertEquals(p.questionEnd, r.length);
  }

  @Test
  public void rejectsNonQueries() {
    byte[] q = DnsTestUtil.query(1, "a.example.com", DnsTestUtil.TYPE_A, false);
    byte[] resp = q.clone();
    resp[2] |= (byte) 0x80;
    assertNull(DnsPacket.parseQuery(resp, resp.length)); // response
    byte[] notify = q.clone();
    notify[2] |= (byte) (4 << 3);
    assertNull(DnsPacket.parseQuery(notify, notify.length)); // opcode NOTIFY
    byte[] twoQ = q.clone();
    twoQ[5] = 2;
    assertNull(DnsPacket.parseQuery(twoQ, twoQ.length)); // QDCOUNT=2, truncated
    assertNull(DnsPacket.parseQuery(q, 11)); // shorter than a header
  }

  @Test
  public void unprintableNamesAreNotMatchableButStillParse() {
    byte[] q = DnsTestUtil.query(1, "ab.example.com", DnsTestUtil.TYPE_A, false);
    q[13] = 0x00; // NUL inside the first label
    DnsPacket.Query p = DnsPacket.parseQuery(q, q.length);
    assertNotNull(p);
    assertNull(p.name);
  }

  @Test
  public void compressionLoopsAreRejected() {
    byte[] q = DnsTestUtil.query(1, "a.example.com", DnsTestUtil.TYPE_A, false);
    q[12] = (byte) 0xc0; // pointer to itself
    q[13] = 12;
    assertNull(DnsPacket.parseQuery(q, q.length));
  }

  @Test
  public void fuzzNeverThrows() {
    Random rnd = new Random(42);
    byte[] base = DnsTestUtil.query(1, "ads.example.com", DnsTestUtil.TYPE_A, true);
    for (int i = 0; i < 200_000; i++) {
      byte[] b;
      if (i % 2 == 0) {
        b = new byte[rnd.nextInt(64)];
        rnd.nextBytes(b);
      } else {
        b = base.clone();
        for (int k = 0; k < 1 + rnd.nextInt(4); k++) b[rnd.nextInt(b.length)] = (byte) rnd.nextInt();
      }
      DnsPacket.Query p = DnsPacket.parseQuery(b, rnd.nextInt(b.length + 1));
      if (p != null) DnsPacket.buildNxDomain(b, p);
    }
  }
}
