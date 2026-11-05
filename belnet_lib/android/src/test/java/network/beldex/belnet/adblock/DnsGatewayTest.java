package network.beldex.belnet.adblock;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.atomic.AtomicBoolean;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;

/** Real UDP round trips through the gateway against a fake upstream resolver. */
public class DnsGatewayTest {
  private DnsTestUtil.FakeUpstream upstream;
  private DnsGateway gateway;
  private int port;
  private final AtomicBoolean enabled = new AtomicBoolean(true);

  private static final DnsGateway.Log QUIET =
      new DnsGateway.Log() {
        @Override
        public void info(String msg) {}

        @Override
        public void warn(String msg) {}
      };

  @Before
  public void setUp() throws Exception {
    upstream = new DnsTestUtil.FakeUpstream();
    DomainSet set = DomainSet.of(new long[] {DomainHash.hash("ads.example.com")}, new long[0], 0);
    gateway =
        new DnsGateway(
            AdBlockEngine.parseUpstream(upstream.address()),
            name -> enabled.get() && set.isBlocked(name),
            QUIET);
    port = gateway.start();
  }

  @After
  public void tearDown() {
    gateway.close();
    upstream.close();
  }

  @Test
  public void blockedNameGetsNxDomainWithoutReachingUpstream() throws Exception {
    byte[] r =
        DnsTestUtil.ask(port, DnsTestUtil.query(11, "x.ads.example.com", DnsTestUtil.TYPE_A, true), 2000);
    assertNotNull(r);
    assertEquals(11, DnsPacket.id(r));
    assertEquals(DnsPacket.RCODE_NXDOMAIN, DnsTestUtil.rcode(r));
    assertEquals(0, upstream.received.get());
    assertEquals(1, gateway.blocked.get());
  }

  @Test
  public void allowedNameIsForwardedAndRelayedUnchanged() throws Exception {
    byte[] q = DnsTestUtil.query(22, "www.example.com", DnsTestUtil.TYPE_A, false);
    byte[] r = DnsTestUtil.ask(port, q, 2000);
    assertNotNull(r);
    assertEquals(22, DnsPacket.id(r));
    assertEquals(0, DnsTestUtil.rcode(r));
    assertEquals(1, DnsTestUtil.ancount(r));
    assertEquals(1, upstream.received.get());
  }

  @Test
  public void disablingStopsFilteringImmediately() throws Exception {
    byte[] q = DnsTestUtil.query(33, "ads.example.com", DnsTestUtil.TYPE_A, false);
    assertEquals(DnsPacket.RCODE_NXDOMAIN, DnsTestUtil.rcode(DnsTestUtil.ask(port, q, 2000)));
    enabled.set(false);
    byte[] r = DnsTestUtil.ask(port, q, 2000);
    assertEquals(0, DnsTestUtil.rcode(r));
    assertEquals(1, DnsTestUtil.ancount(r));
    enabled.set(true);
    assertEquals(DnsPacket.RCODE_NXDOMAIN, DnsTestUtil.rcode(DnsTestUtil.ask(port, q, 2000)));
  }

  @Test
  public void spoofedRepliesAreIgnored() throws Exception {
    upstream.spoofFirst = true;
    byte[] r =
        DnsTestUtil.ask(port, DnsTestUtil.query(44, "www.example.com", DnsTestUtil.TYPE_A, false), 2000);
    assertNotNull(r);
    assertEquals(44, DnsPacket.id(r));
  }

  @Test
  public void upstreamTimeoutIsCleanedUp() throws Exception {
    upstream.silent = true;
    byte[] r =
        DnsTestUtil.ask(port, DnsTestUtil.query(55, "www.example.com", DnsTestUtil.TYPE_A, false), 300);
    assertNull(r);
    Thread.sleep(DnsGateway.QUERY_TIMEOUT_MS + 600);
    assertEquals(1, gateway.timedOut.get());
    upstream.silent = false;
    byte[] ok =
        DnsTestUtil.ask(port, DnsTestUtil.query(56, "www.example.com", DnsTestUtil.TYPE_A, false), 2000);
    assertNotNull(ok);
  }

  @Test
  public void malformedPacketsDoNotBreakTheGateway() throws Exception {
    try (DatagramSocket s = new DatagramSocket()) {
      InetAddress lo = InetAddress.getLoopbackAddress();
      byte[][] junk = {
        new byte[0], new byte[] {1, 2, 3}, new byte[12], new byte[600], "hello world".getBytes()
      };
      for (byte[] j : junk) s.send(new DatagramPacket(j, j.length, lo, port));
      byte[] resp = DnsTestUtil.query(1, "x.example.com", DnsTestUtil.TYPE_A, false);
      resp[2] |= (byte) 0x80; // a response sent to the gateway is dropped
      s.send(new DatagramPacket(resp, resp.length, lo, port));
    }
    byte[] r =
        DnsTestUtil.ask(port, DnsTestUtil.query(66, "ads.example.com", DnsTestUtil.TYPE_A, false), 2000);
    assertEquals(DnsPacket.RCODE_NXDOMAIN, DnsTestUtil.rcode(r));
    assertTrue(gateway.isRunning());
    assertEquals("junk must not be forwarded upstream", 0, upstream.received.get());
    assertTrue(gateway.dropped.get() >= 6);
  }

  @Test
  public void handlesConcurrentQueries() throws Exception {
    ExecutorService pool = Executors.newFixedThreadPool(32);
    try {
      List<Future<byte[]>> futures = new ArrayList<>();
      for (int i = 0; i < 600; i++) {
        final int id = i;
        final String name = (i % 3 == 0) ? "t" + i + ".ads.example.com" : "host" + i + ".example.org";
        futures.add(
            pool.submit(
                () -> DnsTestUtil.ask(port, DnsTestUtil.query(id, name, DnsTestUtil.TYPE_A, true), 4000)));
      }
      int blocked = 0;
      int answered = 0;
      for (int i = 0; i < futures.size(); i++) {
        byte[] r = futures.get(i).get();
        assertNotNull("query " + i + " got no reply", r);
        assertEquals(i, DnsPacket.id(r));
        if (DnsTestUtil.rcode(r) == DnsPacket.RCODE_NXDOMAIN) blocked++;
        else answered++;
      }
      assertEquals(200, blocked);
      assertEquals(400, answered);
    } finally {
      pool.shutdownNow();
    }
  }

  @Test
  public void closeIsIdempotentAndRestartable() throws Exception {
    gateway.close();
    gateway.close();
    int p2 = gateway.start();
    assertTrue(p2 > 0);
    byte[] r =
        DnsTestUtil.ask(p2, DnsTestUtil.query(77, "www.example.com", DnsTestUtil.TYPE_A, false), 2000);
    assertNotNull(r);
  }
}
