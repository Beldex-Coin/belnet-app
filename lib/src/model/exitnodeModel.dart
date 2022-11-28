// To parse this JSON data, do
//
//     final exitnodeList = exitnodeListFromJson(jsonString);

import 'dart:convert';

List<ExitnodeList> exitnodeListFromJson(String str) => List<ExitnodeList>.from(json.decode(str).map((x) => ExitnodeList.fromJson(x)));

String exitnodeListToJson(List<ExitnodeList> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ExitnodeList {
    ExitnodeList({
        required this.id,
        required this.name,
        required this.country,
        required this.icon,
    });

    int id;
    String name;
    String country;
    String icon;

    factory ExitnodeList.fromJson(Map<String, dynamic> json) => ExitnodeList(
        id: json["id"] == null ? null : json["id"],
        name: json["name"] == null ? null : json["name"],
        country: json["country"] == null ? null : json["country"],
        icon: json["icon"] == null ? null : json["icon"],
    );

    Map<String, dynamic> toJson() => {
        "id": id == null ? null : id,
        "name": name == null ? null : name,
        "country": country == null ? null : country,
        "icon": icon == null ? null : icon,
    };
}
