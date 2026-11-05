package network.beldex.belnet.adblock;

import java.io.Closeable;
import java.io.IOException;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.ClosedSelectorException;
import java.nio.channels.DatagramChannel;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.util.ArrayDeque;
import java.util.Iterator;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Loopback DNS gateway between the BelNet daemon's resolver (libunbound) and
 * the configured upstream DNS server.
 *
 * <pre>
 *   app --udp/53--> TUN --> belnet daemon (l3 DNS intercept)
 *                               |  .bdx / .mnode answered by the daemon
 *                               v
 *                           libunbound --udp--> 127.0.0.1:port (this gateway)
 *                                                  | blocked -> NXDOMAIN
 *                                                  v allowed
 *                                              upstream DNS (e.g. 9.9.9.9)
 * </pre>
 *
 * <p>The gateway never protects its sockets, so upstream queries take exactly
 * the route libunbound's own queries took before (same process, same UID).
 * It adds no new path around the tunnel.
 *
 * <p>Design: one thread, one {@link Selector}. Each forwarded query gets its
 * own connected UDP channel (fresh random source port, replies accepted
 * only from the upstream address, matched by DNS ID), with a hard timeout
 * and a cap on in-flight queries. The filter decision is a few binary
 * searches, so doing it inline on the selector thread adds microseconds.
 */
final class DnsGateway implements Closeable {

  /** Decides whether a normalised query name is blocked. Must be thread-safe and fast. */
  interface Filter {
    boolean isBlocked(String normalizedName);
  }

  interface Log {
    void info(String msg);

    void warn(String msg);
  }

  static final long QUERY_TIMEOUT_MS = 5_000;
  static final int MAX_IN_FLIGHT = 1024;
  private static final int MAX_PACKET = 4096;

  final AtomicLong queries = new AtomicLong();
  final AtomicLong blocked = new AtomicLong();
  final AtomicLong forwarded = new AtomicLong();
  final AtomicLong timedOut = new AtomicLong();
  final AtomicLong dropped = new AtomicLong();

  private final InetSocketAddress upstream;
  private final Filter filter;
  private final Log log;

  private Selector selector;
  private DatagramChannel listener;
  private Thread thread;
  private volatile boolean running;
  private int port = -1;

  /** In-flight forwarded queries, oldest first (timeouts are monotonic). */
  private final ArrayDeque<Pending> inFlight = new ArrayDeque<>();
  private int openPending;

  private static final class Pending {
    final DatagramChannel channel;
    final SocketAddress client;
    final int id;
    final long deadline;
    boolean done;

    Pending(DatagramChannel channel, SocketAddress client, int id, long deadline) {
      this.channel = channel;
      this.client = client;
      this.id = id;
      this.deadline = deadline;
    }
  }

  DnsGateway(InetSocketAddress upstream, Filter filter, Log log) {
    this.upstream = upstream;
    this.filter = filter;
    this.log = log;
  }

  /**
   * Binds 127.0.0.1 on an ephemeral port and starts the gateway thread.
   *
   * @return the bound port
   */
  synchronized int start() throws IOException {
    if (running) return port;
    selector = Selector.open();
    try {
      listener = DatagramChannel.open();
      listener.configureBlocking(false);
      listener.bind(new InetSocketAddress(InetAddress.getByName("127.0.0.1"), 0));
      listener.register(selector, SelectionKey.OP_READ);
      port = ((InetSocketAddress) listener.getLocalAddress()).getPort();
    } catch (IOException | RuntimeException e) {
      closeQuietly(listener);
      closeQuietly(selector);
      throw e;
    }
    running = true;
    thread = new Thread(this::loop, "belnet-dns-gateway");
    thread.setDaemon(true);
    thread.start();
    log.info("DNS gateway listening on 127.0.0.1:" + port + " -> " + upstream);
    return port;
  }

  int port() {
    return port;
  }

  boolean isRunning() {
    return running;
  }

  @Override
  public synchronized void close() {
    if (!running) return;
    running = false;
    Selector s = selector;
    if (s != null) s.wakeup();
    Thread t = thread;
    if (t != null && t != Thread.currentThread()) {
      try {
        t.join(1000);
      } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
      }
    }
    thread = null;
    log.info("DNS gateway stopped");
  }

  private void loop() {
    ByteBuffer buf = ByteBuffer.allocate(MAX_PACKET);
    byte[] scratch = new byte[MAX_PACKET];
    try {
      while (running) {
        try {
          selector.select(250);
          Iterator<SelectionKey> it = selector.selectedKeys().iterator();
          while (it.hasNext()) {
            SelectionKey key = it.next();
            it.remove();
            if (!key.isValid()) continue;
            if (key.channel() == listener) {
              drainClients(buf, scratch);
            } else {
              onUpstreamReadable(key, buf, scratch);
            }
          }
          expire(System.currentTimeMillis());
        } catch (ClosedSelectorException e) {
          break;
        } catch (IOException | RuntimeException e) {
          // Never let one bad packet or socket error end DNS for the session.
          log.warn("DNS gateway iteration failed: " + e);
        }
      }
    } finally {
      for (Pending p : inFlight) closeQuietly(p.channel);
      inFlight.clear();
      openPending = 0;
      closeQuietly(listener);
      closeQuietly(selector);
      running = false;
    }
  }

  private void drainClients(ByteBuffer buf, byte[] scratch) throws IOException {
    // Bounded drain so upstream replies are not starved under a burst.
    for (int i = 0; i < 64; i++) {
      buf.clear();
      SocketAddress client = listener.receive(buf);
      if (client == null) return;
      buf.flip();
      int len = buf.remaining();
      buf.get(scratch, 0, len);
      handleQuery(client, scratch, len);
    }
  }

  private void handleQuery(SocketAddress client, byte[] pkt, int len) throws IOException {
    if (len < DnsPacket.HEADER_SIZE || DnsPacket.isResponse(pkt, len)) {
      dropped.incrementAndGet();
      return;
    }
    DnsPacket.Query q = DnsPacket.parseQuery(pkt, len);
    if (q == null) {
      // Not a well-formed standard query. libunbound only sends those, so
      // this is junk (or a probe from another local process): drop it
      // rather than forwarding something that was never filtered.
      dropped.incrementAndGet();
      return;
    }
    queries.incrementAndGet();
    if (q.name != null) {
      boolean block;
      try {
        block = filter.isBlocked(q.name);
      } catch (RuntimeException e) {
        block = false; // a filter bug must never break resolution
      }
      if (block) {
        blocked.incrementAndGet();
        listener.send(ByteBuffer.wrap(DnsPacket.buildNxDomain(pkt, q)), client);
        return;
      }
    }
    forward(client, pkt, len);
  }

  private void forward(SocketAddress client, byte[] pkt, int len) {
    if (openPending >= MAX_IN_FLIGHT) {
      // libunbound retries; dropping is safer than unbounded growth.
      dropped.incrementAndGet();
      return;
    }
    DatagramChannel ch = null;
    try {
      ch = DatagramChannel.open();
      ch.configureBlocking(false);
      ch.connect(upstream);
      ch.write(ByteBuffer.wrap(pkt, 0, len));
      Pending p =
          new Pending(ch, client, DnsPacket.id(pkt), System.currentTimeMillis() + QUERY_TIMEOUT_MS);
      ch.register(selector, SelectionKey.OP_READ, p);
      inFlight.addLast(p);
      openPending++;
      forwarded.incrementAndGet();
    } catch (IOException | RuntimeException e) {
      // Upstream unreachable right now (e.g. network handover): let the
      // resolver retry.
      closeQuietly(ch);
      dropped.incrementAndGet();
    }
  }

  private void onUpstreamReadable(SelectionKey key, ByteBuffer buf, byte[] scratch) {
    Pending p = (Pending) key.attachment();
    if (p == null || p.done) {
      key.cancel();
      return;
    }
    try {
      buf.clear();
      // Connected channel: the kernel only delivers datagrams from upstream.
      int n = p.channel.read(buf);
      if (n <= 0) return;
      buf.flip();
      buf.get(scratch, 0, n);
      if (n < DnsPacket.HEADER_SIZE
          || !DnsPacket.isResponse(scratch, n)
          || DnsPacket.id(scratch) != p.id) {
        return; // stray or spoofed datagram: keep waiting for the real reply
      }
      listener.send(ByteBuffer.wrap(scratch, 0, n), p.client);
    } catch (IOException e) {
      // ICMP port unreachable etc.: the resolver will retry.
    }
    finish(p);
  }

  private void finish(Pending p) {
    if (p.done) return;
    p.done = true;
    openPending--;
    closeQuietly(p.channel);
  }

  private void expire(long now) {
    while (!inFlight.isEmpty()) {
      Pending head = inFlight.peekFirst();
      if (head.done) {
        inFlight.pollFirst();
        continue;
      }
      if (head.deadline > now) break;
      inFlight.pollFirst();
      timedOut.incrementAndGet();
      finish(head);
    }
  }

  private static void closeQuietly(Closeable c) {
    if (c == null) return;
    try {
      c.close();
    } catch (IOException ignored) {
    }
  }
}
