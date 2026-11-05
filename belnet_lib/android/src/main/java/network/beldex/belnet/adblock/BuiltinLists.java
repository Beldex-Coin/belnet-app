package network.beldex.belnet.adblock;

/**
 * Lists compiled into the app.
 *
 * <p>{@link #SEED_BLOCK}: a small set of the largest ad/tracking networks,
 * used only until the first filter-list download succeeds (for example when
 * the Ad Blocker is first enabled while offline). Every entry is a pure
 * advertising/measurement domain whose blocking does not break app
 * functionality.
 *
 * <p>{@link #ESSENTIAL_ALLOW}: names that must keep resolving whatever a
 * downloaded list says. BelNet's own infrastructure (bootstrap, exit-node
 * list, IP/location checks used by the app), the filter-list hosts
 * themselves (so a bad list can always be replaced) and Android's
 * connectivity, time and push endpoints. Entries allow the exact host and
 * its subdomains only, never sibling domains.
 */
final class BuiltinLists {
  private BuiltinLists() {}

  static final String[] SEED_BLOCK = {
    // Google ad serving
    "doubleclick.net",
    "googlesyndication.com",
    "googleadservices.com",
    "adservice.google.com",
    "pagead2.googlesyndication.com",
    "googletagservices.com",
    // Programmatic exchanges / SSPs / DSPs
    "adnxs.com",
    "adsrvr.org",
    "criteo.com",
    "criteo.net",
    "pubmatic.com",
    "rubiconproject.com",
    "openx.net",
    "casalemedia.com",
    "smartadserver.com",
    "33across.com",
    "sharethrough.com",
    "yieldmo.com",
    "teads.tv",
    "amazon-adsystem.com",
    "media.net",
    "adform.net",
    "bidswitch.net",
    "contextweb.com",
    "lijit.com",
    // Content-recommendation ads
    "taboola.com",
    "outbrain.com",
    // In-app ad SDK networks
    "applovin.com",
    "applvn.com",
    "unityads.unity3d.com",
    "adcolony.com",
    "vungle.com",
    "chartboost.com",
    "inmobi.com",
    "startappservice.com",
    "mopub.com",
    "supersonicads.com",
    "ads.mopub.com",
    "an.facebook.com",
    "ads.linkedin.com",
    // Measurement / tracking
    "scorecardresearch.com",
    "moatads.com",
    "quantserve.com",
    "app-measurement.com",
    "google-analytics.com",
    "analytics.tiktok.com",
    "hotjar.com",
    "adsafeprotected.com",
    "doubleverify.com",
  };

  static final String[] ESSENTIAL_ALLOW = {
    // BelNet / Beldex infrastructure used by the app
    "beldex.io",
    "beldex.dev",
    "belnet-exitnode.s3.ap-south-1.amazonaws.com",
    // IP and location checks used by the app's UI
    "api.ipify.org",
    "ipwho.is",
    "ipapi.co",
    // Filter-list hosts: an update must always be able to fix a bad list
    "adguardteam.github.io",
    "raw.githubusercontent.com",
    "oisd.nl",
    "cdn.jsdelivr.net",
    // Android connectivity checks, time, push and Play services
    "connectivitycheck.gstatic.com",
    "connectivitycheck.android.com",
    "clients1.google.com",
    "clients3.google.com",
    "android.clients.google.com",
    "time.android.com",
    "mtalk.google.com",
    "fcm.googleapis.com",
    "firebaseinstallations.googleapis.com",
    "android.googleapis.com",
    "play.googleapis.com",
    "play.google.com",
  };

  static long[] hashes(String[] names) {
    LongArrayBuilder b = new LongArrayBuilder(names.length);
    for (String n : names) {
      String norm = DomainHash.normalize(n);
      if (norm != null) b.add(DomainHash.hash(norm));
    }
    return b.toSortedUnique();
  }
}
