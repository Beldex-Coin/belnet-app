package network.beldex.belnet.adblock;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import java.io.IOException;
import java.util.Arrays;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;

/** The relay threads, with in-memory packet pipes standing in for the TUN and daemon. */
public class TunRelayTest {

  /** A pipe endpoint: reads from {@code in}, writes to {@code out}. */
  static final class QueuePipe implements TunRelay.PacketPipe {
    final BlockingQueue<byte[]> in = new LinkedBlockingQueue<>();
    final BlockingQueue<byte[]> out = new LinkedBlockingQueue<>();
    volatile boolean closed;

    @Override
    public int read(byte[] buf, int timeoutMs) throws IOException {
      if (closed) throw new IOException("closed");
      try {
        byte[] p = in.poll(timeoutMs, TimeUnit.MILLISECONDS);
        if (p == null) return 0;
        System.arraycopy(p, 0, buf, 0, p.length);
        return p.length;
      } catch (InterruptedException e) {
        throw new IOException(e);
      }
    }

    @Override
    public void write(byte[] buf, int off, int len) throws IOException {
      if (closed) throw new IOException("closed");
      out.add(Arrays.copyOfRange(buf, off, off + len));
    }
  }

  private QueuePipe tun;
  private QueuePipe daemon;
  private TunRelay relay;
  private volatile boolean enabled = true;

  @Before
  public void setUp() {
    tun = new QueuePipe();
    daemon = new QueuePipe();
    DomainSet set = DomainSet.of(new long[] {DomainHash.hash("ads.example.com")}, new long[0], 0);
    PacketFilter filter =
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
    relay =
        new TunRelay(
            tun,
            daemon,
            filter,
            new TunRelay.Log() {
              @Override
              public void info(String msg) {}

              @Override
              public void warn(String msg) {}
            });
    relay.start();
  }

  @After
  public void tearDown() {
    relay.stop();
  }

  private static byte[] dns(String name) {
    return DnsTestUtil.ipv4Udp("9.9.9.9", 40000, 53, DnsTestUtil.query(1, name, DnsTestUtil.TYPE_A, true));
  }

  @Test
  public void allowedTrafficReachesTheDaemonUnchanged() throws Exception {
    byte[] q = dns("www.example.com");
    tun.in.add(q);
    assertArrayEquals(q, daemon.out.poll(2, TimeUnit.SECONDS));
    assertNull(tun.out.poll(200, TimeUnit.MILLISECONDS));
  }

  @Test
  public void blockedQueryIsAnsweredOnTheTunAndNeverReachesTheDaemon() throws Exception {
    tun.in.add(dns("ads.example.com"));
    byte[] r = tun.out.poll(2, TimeUnit.SECONDS);
    assertNotNull(r);
    assertTrue(DnsTestUtil.checksumsValid(r));
    assertEquals(DnsPacket.RCODE_NXDOMAIN, DnsTestUtil.rcode(Arrays.copyOfRange(r, 28, r.length)));
    assertNull(daemon.out.poll(200, TimeUnit.MILLISECONDS));
  }

  @Test
  public void daemonTrafficReachesTheAppsUnchanged() throws Exception {
    byte[] p = DnsTestUtil.ipv4Udp("10.67.0.1", 53, 40000, new byte[300]);
    daemon.in.add(p);
    assertArrayEquals(p, tun.out.poll(2, TimeUnit.SECONDS));
  }

  @Test
  public void togglingOffWhileRunningStopsFiltering() throws Exception {
    enabled = false;
    byte[] q = dns("ads.example.com");
    tun.in.add(q);
    assertArrayEquals(q, daemon.out.poll(2, TimeUnit.SECONDS));
  }

  @Test
  public void keepsOrderUnderLoadInBothDirections() throws Exception {
    int n = 5000;
    for (int i = 0; i < n; i++) {
      byte[] up = DnsTestUtil.ipv4Udp("93.184.216.34", 1000, 2000, new byte[] {(byte) i, (byte) (i >> 8)});
      byte[] down = DnsTestUtil.ipv4Udp("10.67.0.1", 2000, 1000, new byte[] {(byte) i, (byte) (i >> 8)});
      tun.in.add(up);
      daemon.in.add(down);
    }
    for (int i = 0; i < n; i++) {
      byte[] up = daemon.out.poll(5, TimeUnit.SECONDS);
      byte[] down = tun.out.poll(5, TimeUnit.SECONDS);
      assertNotNull(up);
      assertNotNull(down);
      assertEquals((byte) i, up[28]);
      assertEquals((byte) i, down[28]);
    }
  }

  @Test
  public void stopsPromptlyAndWhenAnEndpointCloses() throws Exception {
    long t = System.nanoTime();
    relay.stop();
    assertFalse(relay.isRunning());
    assertTrue("stop took too long", System.nanoTime() - t < TimeUnit.SECONDS.toNanos(2));

    // A relay whose TUN closes underneath it exits its loop without throwing.
    setUp();
    tun.closed = true;
    Thread.sleep(TunRelay.POLL_MS * 2L);
    relay.stop();
  }
}
