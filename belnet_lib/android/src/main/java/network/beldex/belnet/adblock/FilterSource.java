package network.beldex.belnet.adblock;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * A downloadable filter list. Sources are identified by a stable id (used
 * for cache file names), and may list several mirror URLs that are tried in
 * order.
 *
 * <p>The default set can be extended without code changes by placing a
 * {@code sources.conf} file in the ad-blocker data directory, one source
 * per line:
 *
 * <pre>
 *   # id &lt;TAB&gt; name &lt;TAB&gt; minimumDomains &lt;TAB&gt; url[,mirrorUrl...]
 *   mylist	My list	100	https://example.org/hosts.txt
 *   -stevenblack          # a leading '-' disables a default source
 * </pre>
 */
final class FilterSource {
  final String id;
  final String name;
  /** A download with fewer valid rules than this is rejected as broken. */
  final int minRules;
  final List<String> urls;

  FilterSource(String id, String name, int minRules, List<String> urls) {
    this.id = id;
    this.name = name;
    this.minRules = minRules;
    this.urls = Collections.unmodifiableList(new ArrayList<>(urls));
  }

  /**
   * Maintained, DNS-oriented lists with a low false-positive rate:
   * <ul>
   *   <li>AdGuard DNS filter - AdGuard's own list for DNS-level blocking
   *       (ads, trackers, analytics), with exception rules.
   *   <li>OISD small - curated to block ads/trackers/malware "without
   *       breaking anything"; wildcard (subdomain-inclusive) format.
   *   <li>StevenBlack unified hosts - adware + malware hosts (also merges
   *       Peter Lowe's ad server list).
   *   <li>HaGeZi Multi NORMAL - large, actively maintained (rebuilt several
   *       times a day) ads/tracking/analytics/badware list, rated "low"
   *       breakage by its author. "Wildcard domains" format: each line
   *       blocks the domain and its subdomains.
   *   <li>HaGeZi Threat Intelligence Feeds (mini) - malware, phishing, scam
   *       and malicious-advertising domains, size-optimised for blockers on
   *       phones.
   *   <li>AdAway default blocklist - mobile ad providers and analytics
   *       (CC BY 3.0). Overlaps with StevenBlack; duplicates are merged.
   * </ul>
   *
   * HaGeZi lists are published through jsDelivr (the project's documented
   * download links), with the GitHub raw file as the fallback mirror.
   */
  static List<FilterSource> defaults() {
    return Arrays.asList(
        new FilterSource(
            "adguard_dns",
            "AdGuard DNS filter",
            5_000,
            Arrays.asList("https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt")),
        new FilterSource(
            "oisd_small",
            "OISD small",
            5_000,
            Arrays.asList(
                "https://small.oisd.nl/domainswild2",
                "https://raw.githubusercontent.com/sjhgvr/oisd/main/domainswild2_small.txt")),
        new FilterSource(
            "stevenblack",
            "StevenBlack unified hosts",
            10_000,
            Arrays.asList("https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts")),
        new FilterSource(
            "hagezi_multi",
            "HaGeZi Multi Normal",
            50_000,
            Arrays.asList(
                "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/multi-onlydomains.txt",
                "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/multi-onlydomains.txt")),
        new FilterSource(
            "hagezi_tif_mini",
            "HaGeZi Threat Intelligence (mini)",
            50_000,
            Arrays.asList(
                "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/tif.mini-onlydomains.txt",
                "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/tif.mini-onlydomains.txt")),
        new FilterSource(
            "adaway",
            "AdAway default blocklist",
            2_000,
            Arrays.asList(
                "https://raw.githubusercontent.com/AdAway/adaway.github.io/master/hosts.txt")));
  }

  /** Defaults merged with {@code sources.conf} overrides from {@code dir}. */
  static List<FilterSource> load(File dir) {
    Map<String, FilterSource> byId = new LinkedHashMap<>();
    for (FilterSource s : defaults()) byId.put(s.id, s);
    File conf = new File(dir, "sources.conf");
    if (conf.isFile()) {
      try (BufferedReader r =
          new BufferedReader(
              new InputStreamReader(new FileInputStream(conf), StandardCharsets.UTF_8))) {
        String line;
        while ((line = r.readLine()) != null) {
          int hash = line.indexOf('#');
          if (hash >= 0) line = line.substring(0, hash);
          line = line.trim();
          if (line.isEmpty()) continue;
          if (line.startsWith("-")) {
            byId.remove(line.substring(1).trim());
            continue;
          }
          String[] f = line.split("\t");
          if (f.length < 4 || !isSafeId(f[0].trim())) continue;
          List<String> urls = new ArrayList<>();
          for (String u : f[3].split(",")) {
            u = u.trim();
            if (u.startsWith("https://")) urls.add(u); // never fetch lists over plain HTTP
          }
          if (urls.isEmpty()) continue;
          int min;
          try {
            min = Math.max(1, Integer.parseInt(f[2].trim()));
          } catch (NumberFormatException e) {
            min = 100;
          }
          byId.put(f[0].trim(), new FilterSource(f[0].trim(), f[1].trim(), min, urls));
        }
      } catch (IOException ignored) {
        // Unreadable overrides: fall back to the defaults.
      }
    }
    return new ArrayList<>(byId.values());
  }

  /** Ids become file names: keep them boring. */
  static boolean isSafeId(String id) {
    if (id.isEmpty() || id.length() > 40) return false;
    for (int i = 0; i < id.length(); i++) {
      char c = id.charAt(i);
      if (!((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_' || c == '-')) return false;
    }
    return true;
  }
}
