import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
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

  // Method to get the image or a default icon if the image is not available
  // Widget getManifestImage() {
  //   if (image != null && image!.isNotEmpty) {
  //     return Image.network(
  //       image!,
  //       width: 200, // You can adjust the size as needed
  //       height: 200,
  //       errorBuilder: (context, error, stackTrace) {
  //         return const Icon(
  //           Icons.broken_image,
  //           size: 200,
  //           color: AppColors.grey,
  //         ); // Fallback to an icon if the image fails to load
  //       },
  //     );
  //   } else {
  //     return const Icon(Icons.image,
  //         size: 200,
  //         color:
  //             AppColors.grey); // Dispatched an icon if the image is not present
  //   }
  // }

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
