import 'dart:convert';

import 'package:flutter/services.dart';

class CargoCatalog {
  const CargoCatalog(this.categories);
  final List<CargoCategory> categories;

  factory CargoCatalog.fromJson(Map<String, dynamic> json) => CargoCatalog(
        (json['categories'] as List)
            .map((value) => CargoCategory.fromJson(value))
            .toList(),
      );

  static Future<CargoCatalog> load() async => CargoCatalog.fromJson(
        jsonDecode(await rootBundle.loadString('assets/cargo_catalog.json')),
      );
}

class CargoCategory {
  CargoCategory.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        description = json['description'],
        suppliers = (json['suppliers'] as List)
            .map((value) => CargoSupplier.fromJson(value))
            .toList();
  final String id;
  final String name;
  final String description;
  final List<CargoSupplier> suppliers;
}

class CargoSupplier {
  CargoSupplier.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        description = json['description'],
        isRecipient = json['role'] == 'recipient',
        locations = List<String>.from(json['locations']),
        groups = (json['groups'] as List)
            .map((value) => CargoGroup.fromJson(value))
            .toList();
  final String id;
  final String name;
  final String description;
  final List<String> locations;
  final bool isRecipient;
  final List<CargoGroup> groups;
}

class CargoGroup {
  CargoGroup.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        note = json['note'],
        products = (json['products'] as List)
            .map((value) => CargoProduct.fromJson(value))
            .toList();
  final String id;
  final String name;
  final String? note;
  final List<CargoProduct> products;
}

class CargoProduct {
  CargoProduct.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        note = json['note'],
        requiresDetails = json['requiresDetails'] == true;
  final String name;
  final String? note;
  final bool requiresDetails;
}

class TransportRequest {
  const TransportRequest({
    required this.category,
    required this.supplier,
    required this.group,
    required this.product,
    required this.origin,
    required this.destination,
  });
  final String category;
  final String supplier;
  final String group;
  final String product;
  final String origin;
  final String destination;
}
