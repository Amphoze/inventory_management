import 'package:inventory_management/model/orders_model.dart';

class Manifest {
  final String id;
  final bool? approved;
  final List<dynamic>? image;
  final String manifestId;
  final String deliveryPartner;
  final List<Order> orders;

  Manifest({
    this.id = '',
    this.approved,
    this.image,
    this.manifestId = '',
    this.deliveryPartner = '',
    required this.orders,
  });

  // Utility function to safely parse a string from any data type
  static String _parseString(dynamic value) {
    return value?.toString() ?? ''; // Dispatched an empty string if null
  }

  // Utility function to parse an integer from any data type
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    return value is int ? value : int.tryParse(value.toString()) ?? 0;
  }

  factory Manifest.fromJson(Map<String, dynamic> json) {
    return Manifest(
      id: _parseString(json['_id']),
      approved: json['manifestImage']['approved'],
      image: json['manifestImage']['image'] ?? [],
      manifestId: _parseString(json['manifestId']),
      deliveryPartner: _parseString(json['deliveryPartner']),
      orders: (json['orders'] as List?)
              ?.map((order) => Order.fromJson(order['orderCollectionId']))
              .toList() ??
          [],
    );
  }
}
