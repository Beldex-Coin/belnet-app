// To parse this JSON data, do
//
//     final exitNodeDataList = exitNodeDataListFromJson(jsonString);

import 'package:meta/meta.dart';
import 'dart:convert';


List<ExitNodeDataList> exitNodeDataListFromJson(String str) => List<ExitNodeDataList>.from(json.decode(str).map((x) => ExitNodeDataList.fromJson(x)));

String exitNodeDataListToJson(List<ExitNodeDataList> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ExitNodeDataList {
    ExitNodeDataList({
        required this.type,
        required this.node,
    });

    String type;
    List<Node> node;

    factory ExitNodeDataList.fromJson(Map<String, dynamic> json) => ExitNodeDataList(
        type: json["type"],
        node: List<Node>.from(json["node"].map((x) => Node.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "type": type,
        "node": List<dynamic>.from(node.map((x) => x.toJson())),
    };
}

class Node {
    Node({
        required this.id,
        required this.name,
        required this.country,
        required this.icon,
        required this.isActive,
        required this.lat,
        required this.long,
        required this.speedScore
    });

    int id;
    String name;
    String country;
    String icon;
    String isActive;
    double lat;
    double long;
    int speedScore;

    factory Node.fromJson(Map<String, dynamic> json) => Node(
        id: json["id"],
        name: json["name"],
        country: json["country"],
        icon: json["icon"],
        isActive: json["isActive"],
        lat: (json['lat'] ?? 0).toDouble(),
        long: (json['long'] ?? 0).toDouble(),
        speedScore: (json['speedScore'] == null)
          ? 0
          : (json['speedScore'] is int
              ? json['speedScore']
              : int.tryParse(json['speedScore'].toString()) ?? 0),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "country": country,
        "icon": icon,
        "isActive": isActive,
        "lat": lat,
        "long": long,
        "speedScore": speedScore
    };
}








// To parse this JSON data, do
//
//     final exitNodeDataList = exitNodeDataListFromJson(jsonString);

//import 'package:meta/meta.dart';
// import 'dart:convert';

// List<ExitNodeDataList> exitNodeDataListFromJson(String str) => List<ExitNodeDataList>.from(json.decode(str).map((x) => ExitNodeDataList.fromJson(x)));

// String exitNodeDataListToJson(List<ExitNodeDataList> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

// class ExitNodeDataList {
//     ExitNodeDataList({
//         required this.type,
//         required this.node,
//     });

//     String type;
//     List<Node> node;

//     factory ExitNodeDataList.fromJson(Map<String, dynamic> json) => ExitNodeDataList(
//         type: json["type"],
//         node: List<Node>.from(json["node"].map((x) => Node.fromJson(x))),
//     );

//     Map<String, dynamic> toJson() => {
//         "type": type,
//         "node": List<dynamic>.from(node.map((x) => x.toJson())),
//     };
// }

// class Node {
//     Node({
//         required this.id,
//         required this.name,
//         required this.country,
//         required this.icon,
//         required this.isActive,
//     });

//     int id;
//     String name;
//     String country;
//     String icon;
//     String isActive;

//     factory Node.fromJson(Map<String, dynamic> json) => Node(
//         id: json["id"],
//         name: json["name"],
//         country: json["country"],
//         icon: json["icon"],
//         isActive: json["isActive"],
//     );

//     Map<String, dynamic> toJson() => {
//         "id": id,
//         "name": name,
//         "country": country,
//         "icon": icon,
//         "isActive": isActive,
//     };
// }
