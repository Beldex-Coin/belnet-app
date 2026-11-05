package network.beldex.belnet.adblock;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.StringReader;
import org.junit.Test;

public class DomainMatchingTest {

  private static DomainSet setOf(String list) throws IOException {
    LongArrayBuilder block = new LongArrayBuilder();
    LongArrayBuilder allow = new LongArrayBuilder();
    FilterListParser.parse(new BufferedReader(new StringReader(list)), block, allow);
    return DomainSet.of(block.toSortedUnique(), allow.toSortedUnique(), 1);
  }

  private static boolean blocked(DomainSet s, String name) {
    return s.isBlocked(DomainHash.normalize(name));
  }

  @Test
  public void normalize() {
    assertEquals("ads.example.com", DomainHash.normalize("Ads.Example.COM."));
    assertEquals("x_y.example.com", DomainHash.normalize("x_y.example.com"));
    assertNull(DomainHash.normalize("localhost")); // single label
    assertNull(DomainHash.normalize("0.0.0.0")); // IP literal
    assertNull(DomainHash.normalize("a..b.com"));
    assertNull(DomainHash.normalize("*.ads.com"));
    assertNull(DomainHash.normalize("ads.com/path"));
    assertNull(DomainHash.normalize("bücher.de"));
    assertNull(DomainHash.normalize(""));
    StringBuilder longLabel = new StringBuilder();
    for (int i = 0; i < 64; i++) longLabel.append('a');
    assertNull(DomainHash.normalize(longLabel + ".com"));
  }

  @Test
  public void suffixHashesMatchFullHashes() {
    long[] out = new long[3];
    assertEquals(3, DomainHash.suffixHashes("a.b.com", out));
    assertEquals(DomainHash.hash("com"), out[0]);
    assertEquals(DomainHash.hash("b.com"), out[1]);
    assertEquals(DomainHash.hash("a.b.com"), out[2]);
  }

  @Test
  public void subdomainsAreBlockedButNotParentsOrSiblings() throws IOException {
    DomainSet s = setOf("ads.example.com\n");
    assertTrue(blocked(s, "ads.example.com"));
    assertTrue(blocked(s, "x.ads.example.com"));
    assertTrue(blocked(s, "a.b.c.ads.example.com"));
    assertFalse(blocked(s, "example.com"));
    assertFalse(blocked(s, "www.example.com"));
    assertFalse(blocked(s, "notads.example.com"));
    assertFalse(blocked(s, "ads.example.com.evil.org"));
  }

  @Test
  public void exceptionsWin() throws IOException {
    DomainSet s = setOf("||tracker.net^\n@@||ok.tracker.net^\n");
    assertTrue(blocked(s, "tracker.net"));
    assertTrue(blocked(s, "bad.tracker.net"));
    assertFalse(blocked(s, "ok.tracker.net"));
    assertFalse(blocked(s, "cdn.ok.tracker.net"));
  }

  @Test
  public void neverMatchesBareTld() throws IOException {
    // A hash collision with a TLD-only entry must not block a whole TLD; the
    // parser already rejects single-label names, so nothing blocks "com".
    DomainSet s = setOf("com\nexample.com\n");
    assertFalse(blocked(s, "other.com"));
    assertTrue(blocked(s, "example.com"));
  }

  @Test
  public void hostsFormat() throws IOException {
    DomainSet s =
        setOf(
            "# StevenBlack style\n"
                + "127.0.0.1 localhost\n"
                + "127.0.0.1 localhost.localdomain\n"
                + "255.255.255.255 broadcasthost\n"
                + "::1 localhost ip6-localhost ip6-loopback\n"
                + "0.0.0.0 0.0.0.0\n"
                + "0.0.0.0 ad.doubleclick.net   # Google ads\n"
                + "0.0.0.0\tpixel.tracker.io metrics.tracker.io\n"
                + "192.168.1.10 my.nas.example.com\n");
    assertTrue(blocked(s, "ad.doubleclick.net"));
    assertTrue(blocked(s, "pixel.tracker.io"));
    assertTrue(blocked(s, "metrics.tracker.io"));
    assertFalse(blocked(s, "my.nas.example.com")); // override, not a block
    assertFalse(blocked(s, "doubleclick.net"));
  }

  @Test
  public void adguardFormat() throws IOException {
    String list =
        "! Title: AdGuard DNS filter\n"
            + "[Adblock Plus 2.0]\n"
            + "||ads.example.org^\n"
            + "||important.example.org^$important\n"
            + "||client-only.example.org^$client=192.168.0.1\n"
            + "||dnstype.example.org^$dnstype=AAAA\n"
            + "/^ad[0-9]+\\.example\\.net$/\n"
            + "|https://url.example.net/path\n"
            + "||wild*card.example.net^\n"
            + "||path.example.net/ads\n"
            + "example.com##.banner\n"
            + "@@||safe.ads.example.org^|\n"
            + "||*.wild.example.net^\n";
    DomainSet s = setOf(list);
    assertTrue(blocked(s, "ads.example.org"));
    assertTrue(blocked(s, "x.ads.example.org"));
    assertTrue(blocked(s, "important.example.org"));
    assertFalse(blocked(s, "safe.ads.example.org"));
    assertTrue(blocked(s, "a.wild.example.net"));
    // Scoped / regex / URL / cosmetic rules are skipped, not approximated.
    assertFalse(blocked(s, "client-only.example.org"));
    assertFalse(blocked(s, "dnstype.example.org"));
    assertFalse(blocked(s, "ad1.example.net"));
    assertFalse(blocked(s, "url.example.net"));
    assertFalse(blocked(s, "path.example.net"));
    assertFalse(blocked(s, "example.com"));
  }

  @Test
  public void oisdWildcardFormat() throws IOException {
    DomainSet s = setOf("# oisd\n*.adtech.example\n.metrics.example\nplain.example\n");
    assertTrue(blocked(s, "adtech.example"));
    assertTrue(blocked(s, "x.adtech.example"));
    assertTrue(blocked(s, "metrics.example"));
    assertTrue(blocked(s, "plain.example"));
  }

  @Test
  public void parserCountsAndIgnoresJunk() throws IOException {
    LongArrayBuilder b = new LongArrayBuilder();
    LongArrayBuilder a = new LongArrayBuilder();
    FilterListParser.Result r =
        FilterListParser.parse(
            new BufferedReader(
                new StringReader(
                    "<!DOCTYPE html>\n<html><body>Not found</body></html>\nads.com\n")),
            b,
            a);
    assertEquals(1, r.blockRules);
    assertEquals(0, r.allowRules);
  }

  @Test
  public void builtinListsAreSane() {
    DomainSet s =
        DomainSet.ofSorted(
            BuiltinLists.hashes(BuiltinLists.SEED_BLOCK),
            BuiltinLists.hashes(BuiltinLists.ESSENTIAL_ALLOW),
            0);
    assertEquals(BuiltinLists.SEED_BLOCK.length, s.blockedCount());
    assertEquals(BuiltinLists.ESSENTIAL_ALLOW.length, s.allowedCount());
    assertTrue(blocked(s, "securepubads.g.doubleclick.net"));
    assertTrue(blocked(s, "pagead2.googlesyndication.com"));
    assertFalse(blocked(s, "www.google.com"));
    assertFalse(blocked(s, "deb.beldex.io"));
  }

  @Test
  public void essentialAllowOverridesDownloadedLists() throws IOException {
    LongArrayBuilder b = new LongArrayBuilder();
    LongArrayBuilder a = new LongArrayBuilder();
    FilterListParser.parse(
        new BufferedReader(new StringReader("beldex.io\nraw.githubusercontent.com\n")), b, a);
    a.addAll(BuiltinLists.hashes(BuiltinLists.ESSENTIAL_ALLOW));
    DomainSet s = DomainSet.of(b.toSortedUnique(), a.toSortedUnique(), 0);
    assertFalse(blocked(s, "deb.beldex.io"));
    assertFalse(blocked(s, "raw.githubusercontent.com"));
  }
}
