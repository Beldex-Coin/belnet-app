## BelNet

[BelNet](https://belnet.beldex.io/) is a decentralized VPN service built on top of the [Beldex](https://beldex.io/) Network. The BelNet dVPN utilizes Beldex masternodes to route your connection. A unique onion routing protocol is used to encrypt and route your data. 
An app to interact with Belnet as a vpn tunnel for android.

[<img src="https://play.google.com/intl/en_us/badges/images/generic/en-play-badge.png" alt="Get it on Google Play" height="80"/>](https://play.google.com/store/apps/details?id=io.beldex.belnet)



## building

build requirements:

* flutter
* gnu make
* cmake
* pkg-config
* git
* autotools

install flutter with snap:

    $ sudo snap install flutter --classic

or with [asdf](https://github.com/asdf-vm/asdf):

    $ asdf install

a one liner to install everything else:

    $ sudo apt install make automake libtool pkg-config cmake git

### build with flutter

before building make sure to update the submodules:

    $ git submodule update --init --recursive

to build the project with flutter:

    $ flutter build apk --debug
    
if succesful it will produce an apk at `build/app/outputs/flutter-apk/app-debug.apk` which you can run

## interactive VPN world map

The home screen shows an interactive world map (`lib/src/map/`):

* **Original location**: the approximate location of your real public IP.
  It is detected while the tunnel is down and saved, so connecting never
  overwrites it. GPS is never used.
* **Exit server**: the selected exit node, placed using the `lat`/`long`
  from the published exit-node list. `exit.bdx` falls back to its built-in
  location (France, 48.5848, 7.7419). A custom exit node is placed using its
  exit IP's geolocation once connected (retried quickly until it succeeds),
  and its last known location is remembered for the next connection.
* **Country zoom (Proton-style, no route line)**: disconnected, the map
  zooms to your own country; connecting/connected, it zooms to the exit
  server's country and highlights it. Disconnecting fades the highlight and
  returns to your country; failed shows the exit in red, then restores
  the disconnected view. Every state follows the real tunnel state.
* **Connection panel**: original and exit IPs and locations, duration,
  measured download and upload speed, and the exit node. Tap the panel to
  expand it.
* **Interaction**: pinch-to-zoom, drag-to-pan, zoom and recenter buttons,
  and tap a marker for details.

The map is drawn with `CustomPainter` from the bundled Natural Earth
110m GeoJSON (`assets/map/world_map.json`), so no map SDK or API key is
needed. IP geolocation uses the keyless HTTPS endpoints the app already
relied on: `https://ipwho.is/`, with `https://ipapi.co/` as a fallback.

## cleaning

to make the workspace pristine use:

    $ ./contrib/clean.sh


## Credits

 * Copyright © 2018-2023 The Beldex Project
 * Portions Copyright © 2018-2021 Lokinet
