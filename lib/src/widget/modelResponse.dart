



import 'dart:convert';

Welcome welcomeFromJson(String str) => Welcome.fromJson(json.decode(str));

String welcomeToJson(Welcome data) => json.encode(data.toJson());

class Welcome {
  final dynamic authCodes;
  final String beldexAddress;
  final ExitMap? exitMap;
  final int numPathsBuilt;
  final int numPeersConnected;
  final int numRoutersKnown;
  final double ratio;
  final bool running;
  final int rxRate;
  final int txRate;
  final int uptime;
  final String version;
  final bool isConnected;

  Welcome({
    this.authCodes,
    required this.beldexAddress,
    required this.exitMap,
    required this.numPathsBuilt,
    required this.numPeersConnected,
    required this.numRoutersKnown,
    required this.ratio,
    required this.running,
    required this.rxRate,
    required this.txRate,
    required this.uptime,
    required this.version,
    required this.isConnected,
  });

  factory Welcome.fromJson(Map<String, dynamic> json) => Welcome(
        authCodes: json["authCodes"],
        beldexAddress: json["beldexAddress"] ?? "",
        exitMap: json["exitMap"] == null ? null : ExitMap.fromJson(json["exitMap"]),
        numPathsBuilt: json["numPathsBuilt"] ?? 0,
        numPeersConnected: json["numPeersConnected"] ?? 0,
        numRoutersKnown: json["numRoutersKnown"] ?? 0,
        ratio: (json["ratio"] as num?)?.toDouble() ?? 0.0,
        running: json["running"] ?? false,
        rxRate: json["rxRate"] ?? 0,
        txRate: json["txRate"] ?? 0,
        uptime: json["uptime"] ?? 0,
        version: json["version"] ?? "",
        isConnected: json["isconnected"] ?? false,
      );

  Map<String, dynamic> toJson() => {
        "authCodes": authCodes,
        "beldexAddress": beldexAddress,
        "exitMap": exitMap?.toJson(),
        "numPathsBuilt": numPathsBuilt,
        "numPeersConnected": numPeersConnected,
        "numRoutersKnown": numRoutersKnown,
        "ratio": ratio,
        "running": running,
        "rxRate": rxRate,
        "txRate": txRate,
        "uptime": uptime,
        "version": version,
        "isconnected": isConnected,
      };
}

class ExitMap {
  final String the0;

  ExitMap({
    required this.the0,
  });

  factory ExitMap.fromJson(Map<String, dynamic> json) => ExitMap(
        the0: json["::/0"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "::/0": the0,
      };
}





// // To parse this JSON data, do
// //
// //     final welcome = welcomeFromJson(jsonString);

// import 'dart:convert';

// Welcome welcomeFromJson(String str) => Welcome.fromJson(json.decode(str));

// String welcomeToJson(Welcome data) => json.encode(data.toJson());

// class Welcome {
//     Welcome({
//         this.authCodes,
//         required this.beldexAddress,
//         required this.exitMap,
//         required this.numPathsBuilt,
//         required this.numPeersConnected,
//         required this.numRoutersKnown,
//         required this.ratio,
//         required this.running,
//         required this.rxRate,
//         required this.txRate,
//         required this.uptime,
//         required this.version,
//         required this.isConnected,
//     });

//     dynamic authCodes;
//     String beldexAddress;
//     ExitMap? exitMap;
//     int numPathsBuilt;
//     int numPeersConnected;
//     int numRoutersKnown;
//     dynamic ratio;
//     bool running;
//     dynamic rxRate;
//     dynamic txRate;
//     int uptime;
//     String version;
//     bool isConnected;

//     factory Welcome.fromJson(Map<String, dynamic> json) => Welcome(
//         authCodes: json["authCodes"],
//         beldexAddress: json["beldexAddress"] == null ? null : json["beldexAddress"],
//         exitMap: json["exitMap"] == null ? null : ExitMap.fromJson(json["exitMap"]),
//         numPathsBuilt: json["numPathsBuilt"] == null ? null : json["numPathsBuilt"],
//         numPeersConnected: json["numPeersConnected"] == null ? null : json["numPeersConnected"],
//         numRoutersKnown: json["numRoutersKnown"] == null ? null : json["numRoutersKnown"],
//         ratio: json["ratio"] == null ? null : json["ratio"].toDouble(),
//         running: json["running"] == null ? null : json["running"],
//         rxRate: json["rxRate"] == null ? null : json["rxRate"],
//         txRate: json["txRate"] == null ? null : json["txRate"],
//         uptime: json["uptime"] == null ? null : json["uptime"],
//         version: json["version"] == null ? null : json["version"],
//         isConnected: json["isconnected"],
//     );

//     Map<String, dynamic> toJson() => {
//         "authCodes": authCodes,
//         "beldexAddress": beldexAddress == null ? null : beldexAddress,
//         "exitMap": exitMap == null ? null : exitMap?.toJson(),
//         "numPathsBuilt": numPathsBuilt == null ? null : numPathsBuilt,
//         "numPeersConnected": numPeersConnected == null ? null : numPeersConnected,
//         "numRoutersKnown": numRoutersKnown == null ? null : numRoutersKnown,
//         "ratio": ratio == null ? null : ratio,
//         "running": running == null ? null : running,
//         "rxRate": rxRate == null ? null : rxRate,
//         "txRate": txRate == null ? null : txRate,
//         "uptime": uptime == null ? null : uptime,
//         "version": version == null ? null : version,
//         "isconnected": isConnected == null ? null : isConnected,
//     };
// }

// class ExitMap {
//     ExitMap({
//         required this.the0,
//     });

//     String the0;

//     factory ExitMap.fromJson(Map<String, dynamic> json) => ExitMap(
//         the0: json["::/0"] == null ? null : json["::/0"],
//     );

//     Map<String, dynamic> toJson() => {
//         "::/0": the0 == null ? null : the0,
//     };
// }
