// To parse this JSON data, do
//
//     final exitnodeListModel = exitnodeListModelFromJson(jsonString);

import 'package:meta/meta.dart';
import 'dart:convert';

List<ExitnodeListModel> exitnodeListModelFromJson(String str) => List<ExitnodeListModel>.from(json.decode(str).map((x) => ExitnodeListModel.fromJson(x)));

String exitnodeListModelToJson(List<ExitnodeListModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ExitnodeListModel {
    ExitnodeListModel({
        required this.id,
        required this.name,
        required this.country,
        required this.icon,
        required this.type,
    });

    int id;
    String name;
    String country;
    String icon;
    Type? type;

    factory ExitnodeListModel.fromJson(Map<String, dynamic> json) => ExitnodeListModel(
        id: json["id"],
        name: json["name"],
        country: json["country"],
        icon: json["icon"],
        type: typeValues.map[json["type"]],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "country": country,
        "icon": icon,
        "type": typeValues.reverse![type],
    };
}

enum Type { BELDEX, CONTRIBUTOR }

final typeValues = EnumValues({
    "beldex": Type.BELDEX,
    "contributor": Type.CONTRIBUTOR
});

class EnumValues<T> {
    Map<String, T> map;
    Map<T, String>? reverseMap;

    EnumValues(this.map);

    Map<T, String>? get reverse {
        if (reverseMap == null) {
            reverseMap = map.map((k, v) => new MapEntry(v, k));
        }
        return reverseMap;
    }
}
