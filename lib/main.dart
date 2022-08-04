import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:belnet_lib/belnet_lib.dart';
import 'package:belnet_mobile/src/settings.dart';
import 'package:belnet_mobile/src/utils/is_darkmode.dart';
import 'package:belnet_mobile/src/widget/belnet_divider.dart';
import 'package:belnet_mobile/src/widget/belnet_power_button.dart';
import 'package:belnet_mobile/src/widget/themed_belnet_logo.dart';

void main() async {
  //Load settings
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.getInstance().initialize();

  runApp(BelnetApp());
}

class BelnetApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      title: 'Belnet App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: BelnetHomePage(),
    );
  }
}

class BelnetHomePage extends StatefulWidget {
  BelnetHomePage({Key key}) : super(key: key);

  @override
  BelnetHomePageState createState() => BelnetHomePageState();
}

class BelnetHomePageState extends State<BelnetHomePage> {
  Widget build(BuildContext context) {
    final key = new GlobalKey<ScaffoldState>();

    final bool darkModeOn = inDarkMode(context);

    return Scaffold(
        key: key,
        resizeToAvoidBottomInset:
            false, //Prevents overflow when keyboard is shown
        body: Container(
          color: Color(0xfF9F9F9),
            // decoration: BoxDecoration(  
            //   gradient: LinearGradient(colors: [ Color(0xfF9F9F9),Color(0xffEBEBEB)])
            // ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [ThemedBelnetLogo(), MyForm()])));
  }
}

final exitInput = TextEditingController(text: Settings.getInstance().exitNode);
final dnsInput =
    TextEditingController(text: Settings.getInstance().upstreamDNS);

// Create a Form widget.
class MyForm extends StatefulWidget {
  @override
  MyFormState createState() {
    return MyFormState();
  }
}

class MyFormState extends State<MyForm> {
  static final key = new GlobalKey<FormState>();
  StreamSubscription<bool> _isConnectedEventSubscription;
  bool isClick = false;
  @override
  initState() {
    super.initState();
    _isConnectedEventSubscription = BelnetLib.isConnectedEventStream
        .listen((bool isConnected) => setState(() {}));
  }

  @override
  void dispose() {
    super.dispose();
    _isConnectedEventSubscription?.cancel();
  }

  Future toggleBelnet() async {
   //if(BelnetLib.isConnected)
   isClick = isClick ? false : true;
setState(() {
  
});

    // if (!key.currentState.validate()) {
    //   return;
    // }
    if (BelnetLib.isConnected) {
      await BelnetLib.disconnectFromBelnet();
    } else {
      //Save the exit node and upstream dns
      final Settings settings = Settings.getInstance();
      settings.exitNode = exitInput.value.text.trim();
      settings.upstreamDNS = dnsInput.value.text.trim();

      final result = await BelnetLib.prepareConnection();
      if (result)
        BelnetLib.connectToBelnet(
            exitNode: settings.exitNode, upstreamDNS: settings.upstreamDNS);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool darkModeOn = inDarkMode(context);
    Color color = darkModeOn ? Colors.white : Colors.black;

    return Form(
      key: key,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          BelnetPowerButton(onPressed :toggleBelnet, isClick:isClick ,),
        // BelnetDivider(),
          Padding(
            padding: EdgeInsets.only(left: 45, right: 45),
            child: TextFormField(
              validator: (value) {
                final trimmed = value.trim();
                if (trimmed == "") return null;
                if (trimmed == ".beldex" || !trimmed.endsWith(".beldex"))
                  return "Invalid exit node value";
                return null;
              },
              controller: exitInput,
              cursorColor: color,
              style: TextStyle(color: color),
              decoration: InputDecoration(
                  filled: true,
                  fillColor: darkModeOn
                      ? Color.fromARGB(255, 35, 35, 35)
                      : Color.fromARGB(255, 226, 226, 226),
                  border: InputBorder.none,
                  labelStyle: TextStyle(color: color),
                  labelText: 'Exit Node'),
            ),
          ),
        // BelnetDivider(minus: true),
          // Padding(
          //   padding: EdgeInsets.only(left: 45, right: 45),
          //   child: TextFormField(
          //     validator: (value) {
          //       final trimmed = value.trim();
          //       if (trimmed == "") return null;
          //       RegExp re = RegExp(
          //           r'^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$');
          //       if (!re.hasMatch(trimmed))
          //         return "DNS server does not look like an IP";
          //       return null;
          //     },
          //     controller: dnsInput,
          //     cursorColor: color,
          //     style: TextStyle(color: color),
          //     decoration: InputDecoration(
          //         filled: true,
          //         fillColor: darkModeOn
          //             ? Color.fromARGB(255, 35, 35, 35)
          //             : Color.fromARGB(255, 226, 226, 226),
          //         border: InputBorder.none,
          //         labelStyle: TextStyle(color: color),
          //         labelText: 'DNS'),
          //   ),
          // ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              BelnetLib.isConnected ? "Connected" : "Not Connected",
              style: TextStyle(color: color),
            ),
          ),
          // TextButton(
          //     onPressed: () async {
          //       log((await BelnetLib.status).toString());
          //     },
          //     child: Text("Test"))
        ],
      ),
    );
  }
}















// Create a Form widget.
// class MyForm extends StatefulWidget {
//   @override
//   MyFormState createState() {
//     return MyFormState();
//   }
// }

// class MyFormState extends State<MyForm> {
//   static final key = new GlobalKey<FormState>();
//   StreamSubscription<bool> _isConnectedEventSubscription;
//   bool isClick = false;
//   @override
//   initState() {
//     super.initState();
//     _isConnectedEventSubscription = BelnetLib.isConnectedEventStream
//         .listen((bool isConnected) => setState(() {}));
//   }

//   @override
//   void dispose() {
//     super.dispose();
//     _isConnectedEventSubscription?.cancel();
//   }

//   Future toggleBelnet() async {
//    //if(BelnetLib.isConnected)
//    isClick = isClick ? false : true;
// setState(() {
  
// });

//     if (!key.currentState.validate()) {
//       return;
//     }
//     if (BelnetLib.isConnected) {
//       await BelnetLib.disconnectFromBelnet();
//     } else {
//       //Save the exit node and upstream dns
//       final Settings settings = Settings.getInstance();
//       settings.exitNode = exitInput.value.text.trim();
//       settings.upstreamDNS = dnsInput.value.text.trim();

//       final result = await BelnetLib.prepareConnection();
//       if (result)
//         BelnetLib.connectToBelnet(
//             exitNode: settings.exitNode, upstreamDNS: settings.upstreamDNS);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     bool darkModeOn = inDarkMode(context);
//     Color color = darkModeOn ? Colors.white : Colors.black;

//     return Form(
//       key: key,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: <Widget>[
//           BelnetPowerButton(onPressed :toggleBelnet, isClick:isClick ,),
//         // BelnetDivider(),
//           Padding(
//             padding: EdgeInsets.only(left: 45, right: 45),
//             child: TextFormField(
//               validator: (value) {
//                 final trimmed = value.trim();
//                 if (trimmed == "") return null;
//                 if (trimmed == ".beldex" || !trimmed.endsWith(".beldex"))
//                   return "Invalid exit node value";
//                 return null;
//               },
//               controller: exitInput,
//               cursorColor: color,
//               style: TextStyle(color: color),
//               decoration: InputDecoration(
//                   filled: true,
//                   fillColor: darkModeOn
//                       ? Color.fromARGB(255, 35, 35, 35)
//                       : Color.fromARGB(255, 226, 226, 226),
//                   border: InputBorder.none,
//                   labelStyle: TextStyle(color: color),
//                   labelText: 'Exit Node'),
//             ),
//           ),
//         // BelnetDivider(minus: true),
//           // Padding(
//           //   padding: EdgeInsets.only(left: 45, right: 45),
//           //   child: TextFormField(
//           //     validator: (value) {
//           //       final trimmed = value.trim();
//           //       if (trimmed == "") return null;
//           //       RegExp re = RegExp(
//           //           r'^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$');
//           //       if (!re.hasMatch(trimmed))
//           //         return "DNS server does not look like an IP";
//           //       return null;
//           //     },
//           //     controller: dnsInput,
//           //     cursorColor: color,
//           //     style: TextStyle(color: color),
//           //     decoration: InputDecoration(
//           //         filled: true,
//           //         fillColor: darkModeOn
//           //             ? Color.fromARGB(255, 35, 35, 35)
//           //             : Color.fromARGB(255, 226, 226, 226),
//           //         border: InputBorder.none,
//           //         labelStyle: TextStyle(color: color),
//           //         labelText: 'DNS'),
//           //   ),
//           // ),
//           Padding(
//             padding: EdgeInsets.all(8.0),
//             child: Text(
//               BelnetLib.isConnected ? "Connected" : "Not Connected",
//               style: TextStyle(color: color),
//             ),
//           ),
//           // TextButton(
//           //     onPressed: () async {
//           //       log((await BelnetLib.status).toString());
//           //     },
//           //     child: Text("Test"))
//         ],
//       ),
//     );
//   }
// }