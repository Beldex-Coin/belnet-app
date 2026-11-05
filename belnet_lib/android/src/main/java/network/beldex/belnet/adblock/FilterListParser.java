package network.beldex.belnet.adblock;

import java.io.BufferedReader;
import java.io.IOException;

/**
 * Streaming parser for the common DNS blocklist formats. One pass, constant
 * memory apart from the output hash arrays.
 *
 * <p>Supported line formats (detected per line, so mixed files work):
 * <ul>
 *   <li>hosts: {@code 0.0.0.0 ads.example.com [more names]} (only "sink"
 *       addresses: 0.0.0.0, 127.0.0.1, ::, ::1 - hosts entries that point a
 *       name at a real address are overrides, not blocks, and are skipped)
 *   <li>plain domains: {@code ads.example.com}
 *   <li>wildcards: {@code *.ads.example.com} / {@code .ads.example.com}
 *   <li>AdGuard / Adblock Plus DNS rules: {@code ||ads.example.com^},
 *       {@code ||ads.example.com^$important}, exceptions
 *       {@code @@||example.com^}
 * </ul>
 *
 * <p>Everything a DNS filter cannot honour safely is skipped rather than
 * approximated: regex rules, URL/path rules, rules with modifiers other than
 * {@code $important} (client-, dnstype- or denyallow-scoped rules), cosmetic
 * rules, and wildcards in the middle of a name.
 */
final class FilterListParser {
  private FilterListParser() {}

  /** Lines longer than this are never valid rules (protects against binary junk). */
  private static final int MAX_LINE_LENGTH = 1024;

  static final class Result {
    int lines;
    int blockRules;
    int allowRules;
    int skipped;

    int rules() {
      return blockRules + allowRules;
    }
  }

  /** Names that appear in hosts files but must never be treated as rules. */
  private static boolean isLocalName(String name) {
    switch (name) {
      case "localhost.localdomain":
      case "local.localdomain":
      case "ip6-localhost.localdomain":
        return true;
      default:
        return name.endsWith(".local") || name.endsWith(".localhost") || name.endsWith(".lan")
            || name.endsWith(".home.arpa") || name.endsWith(".in-addr.arpa")
            || name.endsWith(".ip6.arpa");
    }
  }

  private static boolean isSinkAddress(String ip) {
    switch (ip) {
      case "0.0.0.0":
      case "127.0.0.1":
      case "::":
      case "::0":
      case "::1":
      case "0:0:0:0:0:0:0:0":
      case "0:0:0:0:0:0:0:1":
        return true;
      default:
        return false;
    }
  }

  private static boolean looksLikeIp(String token) {
    if (token.indexOf(':') >= 0) return true; // IPv6
    int dots = 0;
    for (int i = 0; i < token.length(); i++) {
      char c = token.charAt(i);
      if (c == '.') dots++;
      else if (c < '0' || c > '9') return false;
    }
    return dots == 3;
  }

  static Result parse(BufferedReader reader, LongArrayBuilder block, LongArrayBuilder allow)
      throws IOException {
    Result r = new Result();
    String line;
    while ((line = reader.readLine()) != null) {
      r.lines++;
      if (line.length() > MAX_LINE_LENGTH) {
        r.skipped++;
        continue;
      }
      parseLine(line, block, allow, r);
    }
    return r;
  }

  /** Parses one line, adding any rules it contains. Package-visible for tests. */
  static void parseLine(String raw, LongArrayBuilder block, LongArrayBuilder allow, Result r) {
    String line = raw.trim();
    if (line.isEmpty()) return;
    char first = line.charAt(0);
    if (first == '#' || first == '!' || first == '[') return; // comments / ABP header

    // Cosmetic (element-hiding) rules are irrelevant to DNS.
    if (line.contains("##") || line.contains("#@#") || line.contains("#?#")
        || line.contains("#$#") || line.contains("#%#")) {
      r.skipped++;
      return;
    }

    // Adblock-style rules.
    boolean exception = false;
    if (line.startsWith("@@")) {
      exception = true;
      line = line.substring(2);
    }
    if (line.startsWith("||")) {
      String name = parseAbpDomainRule(line.substring(2));
      add(name, exception, block, allow, r);
      return;
    }
    if (exception || first == '|' || first == '/' || line.indexOf('$') >= 0
        || line.indexOf('^') >= 0) {
      // URL rules, regex rules, or anything with modifiers we did not parse.
      r.skipped++;
      return;
    }

    // Strip inline comments ("0.0.0.0 ads.com # tracker").
    int hash = line.indexOf('#');
    if (hash >= 0) line = line.substring(0, hash).trim();
    if (line.isEmpty()) return;

    String[] tokens = line.split("\\s+");
    if (tokens.length >= 2 && looksLikeIp(tokens[0])) {
      if (!isSinkAddress(tokens[0])) {
        r.skipped++;
        return;
      }
      for (int i = 1; i < tokens.length; i++) add(stripWildcard(tokens[i]), false, block, allow, r);
      return;
    }
    if (tokens.length == 1) {
      add(stripWildcard(tokens[0]), false, block, allow, r);
      return;
    }
    r.skipped++;
  }

  /** "*.ads.com" / ".ads.com" -> "ads.com" (subdomains are matched anyway). */
  private static String stripWildcard(String token) {
    if (token.startsWith("*.")) return token.substring(2);
    if (token.startsWith(".")) return token.substring(1);
    return token;
  }

  /**
   * Body of a {@code ||} rule (after the bars). Returns the domain, or null
   * when the rule is not a plain domain rule.
   */
  private static String parseAbpDomainRule(String body) {
    int end = body.length();
    int caret = body.indexOf('^');
    int dollar = body.indexOf('$');
    int nameEnd = caret >= 0 ? caret : (dollar >= 0 ? dollar : end);
    if (dollar >= 0 && dollar < nameEnd) nameEnd = dollar;
    String name = body.substring(0, nameEnd);

    // What follows the name may only be "^", "^|", and "$important".
    String tail = body.substring(nameEnd);
    if (tail.startsWith("^")) tail = tail.substring(1);
    if (tail.startsWith("|")) tail = tail.substring(1);
    if (!tail.isEmpty()) {
      if (!tail.startsWith("$")) return null; // path / URL rule
      String mods = tail.substring(1);
      for (String mod : mods.split(",")) {
        if (!mod.trim().equals("important")) return null; // scoped rule
      }
    }
    if (name.startsWith("*.")) name = name.substring(2);
    return name;
  }

  private static void add(
      String candidate, boolean exception, LongArrayBuilder block, LongArrayBuilder allow, Result r) {
    String name = DomainHash.normalize(candidate);
    if (name == null || isLocalName(name)) {
      r.skipped++;
      return;
    }
    long h = DomainHash.hash(name);
    if (exception) {
      allow.add(h);
      r.allowRules++;
    } else {
      block.add(h);
      r.blockRules++;
    }
  }
}
