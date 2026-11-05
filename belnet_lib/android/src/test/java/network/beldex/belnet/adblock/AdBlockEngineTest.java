package network.beldex.belnet.adblock;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.RandomAccessFile;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;

/** Engine, updater and store behaviour with a fake HTTP layer. */
public class AdBlockEngineTest {
  private File dir;
  private FakeHttp http;
  private final boolean[] pref = {false};
  private AdBlockEngine engine;

  private static final AdBlockEngine.Log QUIET =
      new AdBlockEngine.Log() {
        @Override
        public void info(String msg) {}

        @Override
        public void warn(String msg) {}
      };

  /** Serves canned bodies per URL; supports ETag/304 and failures. */
  static final class FakeHttp implements FilterUpdater.Http {
    final Map<String, String> bodies = new HashMap<>();
    final Map<String, String> etags = new HashMap<>();
    final Map<String, Integer> statuses = new HashMap<>();
    final AtomicInteger requests = new AtomicInteger();
    volatile boolean offline;

    @Override
    public int get(
        String url, String etag, String lastModified, File dest, long maxBytes, Properties out)
        throws IOException {
      requests.incrementAndGet();
      if (offline) throw new IOException("network unreachable");
      Integer forced = statuses.get(url);
      if (forced != null) return forced;
      String body = bodies.get(url);
      if (body == null) return 404;
      String tag = etags.get(url);
      if (tag != null && tag.equals(etag)) return 304;
      try (OutputStream o = new FileOutputStream(dest)) {
        o.write(body.getBytes(StandardCharsets.UTF_8));
      }
      if (tag != null) out.setProperty("etag", tag);
      return 200;
    }
  }

  private static String bigList(String prefix, int n, String format) {
    StringBuilder sb = new StringBuilder();
    for (int i = 0; i < n; i++) {
      String d = prefix + i + ".adnet.example";
      switch (format) {
        case "hosts":
          sb.append("0.0.0.0 ").append(d).append('\n');
          break;
        case "abp":
          sb.append("||").append(d).append("^\n");
          break;
        default:
          sb.append(d).append('\n');
      }
    }
    return sb.toString();
  }

  private static final String ADGUARD = FilterSource.defaults().get(0).urls.get(0);
  private static final String OISD = FilterSource.defaults().get(1).urls.get(0);
  private static final String OISD_MIRROR = FilterSource.defaults().get(1).urls.get(1);
  private static final String STEVEN = FilterSource.defaults().get(2).urls.get(0);
  private static final String HAGEZI = FilterSource.defaults().get(3).urls.get(0);
  private static final String HAGEZI_TIF = FilterSource.defaults().get(4).urls.get(0);
  private static final int SOURCES = FilterSource.defaults().size();

  @Before
  public void setUp() throws Exception {
    dir = Files.createTempDirectory("adblock-test").toFile();
    http = new FakeHttp();
    http.bodies.put(ADGUARD, bigList("ag", 6000, "abp") + "||shared.adnet.example^\n@@||ok.shared.adnet.example^\n");
    http.etags.put(ADGUARD, "\"v1\"");
    http.bodies.put(OISD, bigList("oi", 6000, "plain") + "shared.adnet.example\n");
    http.bodies.put(STEVEN, bigList("sb", 12000, "hosts"));
    http.bodies.put(HAGEZI, "# Title: HaGeZi's Normal DNS Blocklist\n" + bigList("hz", 60000, "plain"));
    http.bodies.put(HAGEZI_TIF, "# Title: HaGeZi's TIF Mini\n" + bigList("tif", 55000, "plain"));
    engine = newEngine();
  }

  private AdBlockEngine newEngine() throws Exception {
    AdBlockEngine e =
        new AdBlockEngine(
            dir,
            new AdBlockEngine.Settings() {
              @Override
              public boolean loadEnabled() {
                return pref[0];
              }

              @Override
              public void saveEnabled(boolean enabled) {
                pref[0] = enabled;
              }
            },
            QUIET,
            http);
    e.awaitIdle();
    return e;
  }

  @After
  public void tearDown() {

    deleteRecursively(dir);
  }

  private static void deleteRecursively(File f) {
    File[] kids = f.listFiles();
    if (kids != null) for (File k : kids) deleteRecursively(k);
    //noinspection ResultOfMethodCallIgnored
    f.delete();
  }

  private boolean blocks(String name) {
    return engine.currentSet().isBlocked(DomainHash.normalize(name));
  }

  @Test
  public void startsWithBuiltinListAndIsOffByDefault() {
    assertFalse(engine.isEnabled());
    assertTrue(engine.isLoaded());
    assertTrue(blocks("ad.doubleclick.net"));
    assertTrue(engine.statusJson("").contains("\"usingBuiltinList\":true"));
  }

  @Test
  public void enablingDownloadsCompilesAndPersists() throws Exception {
    engine.setEnabled(true);
    engine.awaitIdle();
    assertTrue(pref[0]);
    assertTrue(blocks("ag5.adnet.example"));
    assertTrue(blocks("x.oi17.adnet.example"));
    assertTrue(blocks("sb11999.adnet.example"));
    assertTrue(blocks("deep.sub.hz59999.adnet.example")); // wildcard-domains format
    assertTrue(blocks("tif123.adnet.example"));
    assertTrue(blocks("shared.adnet.example"));
    assertFalse(blocks("ok.shared.adnet.example")); // exception across lists
    assertFalse(blocks("deb.beldex.io")); // essential allowlist
    assertEquals(
        6000 + 6000 + 12000 + 60000 + 55000 + 1, engine.currentSet().blockedCount()); // de-duplicated
    assertTrue(new File(dir, "compiled.bin").isFile());

    // A new process loads the compiled list from disk without the network.
    http.offline = true;
    AdBlockEngine second = newEngine();
    assertTrue(second.isEnabled());
    assertEquals(engine.currentSet().blockedCount(), second.currentSet().blockedCount());
    assertTrue(second.currentSet().isBlocked("ag5.adnet.example"));
  }

  @Test
  public void freshListsAreNotDownloadedAgainAndStaleOnesUseConditionalGet() throws Exception {
    engine.setEnabled(true);
    engine.awaitIdle();
    int afterFirst = http.requests.get();
    assertEquals(SOURCES, afterFirst);

    engine.refreshAsync(false); // all lists < 24h old
    engine.awaitIdle();
    assertEquals(afterFirst, http.requests.get());

    engine.refreshAsync(true); // forced: AdGuard answers 304 via ETag
    engine.awaitIdle();
    assertEquals(afterFirst + SOURCES, http.requests.get());
    String status = engine.statusJson("");
    assertTrue(status, status.contains("\"status\":\"not_modified\""));
    assertTrue(status, status.contains("\"lastError\":null"));
  }

  @Test
  public void failedUpdateKeepsPreviousWorkingList() throws Exception {
    engine.setEnabled(true);
    engine.awaitIdle();
    int before = engine.currentSet().blockedCount();

    // Broken update: AdGuard now serves an HTML error page, OISD is down,
    // StevenBlack returns 500.
    http.bodies.put(ADGUARD, "<html><body>503 Service Unavailable</body></html>");
    http.etags.remove(ADGUARD);
    http.statuses.put(OISD, 502);
    http.statuses.put(OISD_MIRROR, 502);
    http.statuses.put(STEVEN, 500);
    engine.refreshAsync(true);
    engine.awaitIdle();

    assertEquals(before, engine.currentSet().blockedCount());
    assertTrue(blocks("ag5.adnet.example"));
    String status = engine.statusJson("");
    assertTrue(status, status.contains("rejected: only"));
    assertTrue(status, status.contains("HTTP 502"));
    assertTrue(status, status.contains("\"usingBuiltinList\":false"));
  }

  @Test
  public void mirrorIsUsedWhenPrimaryFails() throws Exception {
    http.statuses.put(OISD, 503);
    http.bodies.put(OISD_MIRROR, bigList("mirror", 5500, "plain"));
    engine.setEnabled(true);
    engine.awaitIdle();
    assertTrue(blocks("mirror42.adnet.example"));
  }

  @Test
  public void offlineFirstEnableKeepsBuiltinList() throws Exception {
    http.offline = true;
    engine.setEnabled(true);
    engine.awaitIdle();
    assertTrue(blocks("ad.doubleclick.net"));
    String status = engine.statusJson("");
    assertTrue(status, status.contains("\"usingBuiltinList\":true"));
    assertTrue(status, status.contains("network unreachable"));
    // Coming back online, the next refresh installs the real lists.
    http.offline = false;
    engine.refreshAsync(false);
    engine.awaitIdle();
    assertTrue(blocks("ag1.adnet.example"));
  }

  @Test
  public void corruptCompiledFileIsRebuiltFromCachedLists() throws Exception {
    engine.setEnabled(true);
    engine.awaitIdle();
    File compiled = new File(dir, "compiled.bin");
    try (RandomAccessFile raf = new RandomAccessFile(compiled, "rw")) {
      raf.seek(40);
      raf.write(0xff);
      raf.write(0x00);
    }
    assertNull(new FilterStore(dir).readCompiled());
    http.offline = true;
    AdBlockEngine second = newEngine();
    assertTrue(second.currentSet().isBlocked("sb3.adnet.example"));
    assertNotNull(new FilterStore(dir).readCompiled()); // rewritten
  }

  @Test
  public void relaySessionAppliesToggleLive() throws Exception {
    engine.setEnabled(true);
    engine.awaitIdle();
    PacketFilter f = engine.beginSession();
    assertTrue(engine.isSessionActive());
    byte[] pkt =
        DnsTestUtil.ipv4Udp(
            "9.9.9.9", 40000, 53, DnsTestUtil.query(9, "ag1.adnet.example", DnsTestUtil.TYPE_A, true));
    assertEquals(PacketFilter.REPLY, f.process(pkt, pkt.length));

    engine.setEnabled(false); // switched off while connected: next query passes
    assertEquals(PacketFilter.FORWARD, f.process(pkt, pkt.length));

    engine.setEnabled(true);
    assertEquals(PacketFilter.REPLY, f.process(pkt, pkt.length));
    String status = engine.statusJson("\"extra\":1");
    assertTrue(status, status.contains("\"filteringActive\":true"));
    assertTrue(status, status.contains("\"sessionBlocked\":2"));
    assertTrue(status, status.contains("\"sessionQueries\":2"));
    assertTrue(status, status.endsWith(",\"extra\":1}"));

    engine.endSession(f);
    assertFalse(engine.isSessionActive());
    assertTrue(engine.statusJson("").contains("\"filteringActive\":false"));
  }

  @Test
  public void endingAStaleSessionDoesNotEndTheCurrentOne() {
    PacketFilter first = engine.beginSession();
    PacketFilter second = engine.beginSession();
    engine.endSession(first);
    assertTrue(engine.isSessionActive());
    engine.endSession(second);
    assertFalse(engine.isSessionActive());
  }

  @Test
  public void sourcesConfCanAddAndDisableLists() throws Exception {
    try (OutputStream o = new FileOutputStream(new File(dir, "sources.conf"))) {
      o.write(
          ("# custom\n-stevenblack\n"
                  + "mine\tMy list\t2\thttps://lists.example/mine.txt\n"
                  + "bad id\tX\t1\thttps://x.example/\n"
                  + "plain\tPlain HTTP\t1\thttp://insecure.example/list.txt\n")
              .getBytes(StandardCharsets.UTF_8));
    }
    http.bodies.put("https://lists.example/mine.txt", "custom.example\nother.example\n");
    engine.setEnabled(true);
    engine.refreshAsync(false);
    engine.awaitIdle();
    assertTrue(blocks("custom.example"));
    assertFalse(blocks("sb1.adnet.example")); // disabled source not downloaded
    String status = engine.statusJson("");
    assertFalse(status, status.contains("Plain HTTP"));
    assertFalse(status, status.contains("bad id"));
  }

  @Test
  public void defaultSourcesAreWellFormed() {
    java.util.Set<String> ids = new java.util.HashSet<>();
    for (FilterSource src : FilterSource.defaults()) {
      assertTrue(src.id, FilterSource.isSafeId(src.id));
      assertTrue("duplicate id " + src.id, ids.add(src.id));
      assertTrue(src.minRules >= 1000);
      assertFalse(src.urls.isEmpty());
      for (String u : src.urls) assertTrue(u, u.startsWith("https://"));
    }
    assertEquals(5, ids.size());
  }

  @Test
  public void listHostsStayReachable() {
    // Every host a default list is downloaded from is on the essential
    // allowlist, so a bad list can never block its own updates.
    DomainSet allowOnly =
        DomainSet.ofSorted(
            BuiltinLists.hashes(FilterSourceHosts.all()),
            BuiltinLists.hashes(BuiltinLists.ESSENTIAL_ALLOW),
            0);
    for (String host : FilterSourceHosts.all()) {
      assertFalse(host, allowOnly.isBlocked(DomainHash.normalize(host)));
    }
  }

  /** Host names of all default list URLs. */
  static final class FilterSourceHosts {
    static String[] all() {
      java.util.List<String> hosts = new java.util.ArrayList<>();
      for (FilterSource src : FilterSource.defaults()) {
        for (String u : src.urls) hosts.add(java.net.URI.create(u).getHost());
      }
      return hosts.toArray(new String[0]);
    }
  }

  @Test
  public void statusJsonEscapesErrors() {
    StringBuilder sb = new StringBuilder();
    AdBlockEngine.field(sb, "e", "a\"b\\c\nd\u0001");
    assertEquals("\"e\":\"a\\\"b\\\\c\\nd\\u0001\"", sb.toString());
  }
}
