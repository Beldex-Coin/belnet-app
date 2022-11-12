// To parse this JSON data, do
//
//     final exitNodeList = exitNodeListFromJson(jsonString);

import 'dart:convert';

List<ExitNodeList> exitNodeListFromJson(String str) => List<ExitNodeList>.from(json.decode(str).map((x) => ExitNodeList.fromJson(x)));

String exitNodeListToJson(List<ExitNodeList> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ExitNodeList {
    ExitNodeList({
        required this.id,
        required this.exit,
        required this.country,
        required this.icon,
    });

    int id;
    String exit;
    String country;
    String icon;

    factory ExitNodeList.fromJson(Map<String, dynamic> json) => ExitNodeList(
        id: json["id"] == null ? null : json["id"],
        exit: json["exit"] == null ? null : json["exit"],
        country: json["country"] == null ? null : json["country"],
        icon: json["icon"] == null ? null : json["icon"],
    );

    Map<String, dynamic> toJson() => {
        "id": id == null ? null : id,
        "exit": exit == null ? null : exit,
        "country": country == null ? null : country,
        "icon": icon == null ? null : icon,
    };
}
