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

## cleaning

to make the workspace pristine use:

    $ ./contrib/clean.sh


## Credits

 * Copyright © 2018-2023 The Beldex Project
 * Portions Copyright © 2018-2021 Lokinet
