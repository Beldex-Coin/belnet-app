import 'package:flutter/material.dart';
 
List dataList = [
  {
    "name": "Sales",
    "icon": Icons.payment,
    "subMenu": [
      {"name": "Orders"},
      {"name": "Invoices"}
    ]
  },
  {
    "name": "Marketing",
    "icon": Icons.volume_up,
    "subMenu": [
      {
        "name": "Promotions",
        "subMenu": [
          {"name": "Catalog Price Rule"},
          {"name": "Cart Price Rules"}
        ]
      },
      {
        "name": "Communications",
        "subMenu": [
          {"name": "Newsletter Subscribers"}
        ]
      },
      {
        "name": "SEO & Search",
        "subMenu": [
          {"name": "Search Terms"},
          {"name": "Search Synonyms"}
        ]
      },
      {
        "name": "User Content",
        "subMenu": [
          {"name": "All Reviews"},
          {"name": "Pending Reviews"}
        ]
      }
    ]
  }
];
 
class Menu {
  String? name;
  IconData? icon;
  List<Menu> subMenu = [];
 
  Menu({required this.name, required this.subMenu, required this.icon});
 
  Menu.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    icon = json['icon'];
    if (json['subMenu'] != null) {
      subMenu.clear();
      json['subMenu'].forEach((v) {
        subMenu.add(new Menu.fromJson(v));
      });
    }
  }
}


