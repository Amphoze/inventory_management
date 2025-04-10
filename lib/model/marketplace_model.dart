import 'package:inventory_management/model/combo_model.dart'; // Assuming your Product model is in combo_model.dart

// Model for SKU Map
class SkuMap {
  final String mktpSku;
  final String productId;
  Product? product;

  SkuMap({
    required this.mktpSku,
    required this.productId,
    this.product,
  });

  factory SkuMap.fromJson(Map<String, dynamic> json) {
    return SkuMap(
      mktpSku: json['mktp_sku'] ?? '',
      productId: json['product_id'] ?? '',
      product: json['product'] != null ? Product.fromJson(json['product']) : null, // Assuming you need product details
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mktp_sku': mktpSku,
      'product_id': productId,
      // You can exclude 'product' from the JSON if it's not needed in the API request
    };
  }
}

// Model for Marketplace
class Marketplace {
  final String? id;
  final String name;
  final List<SkuMap> skuMap;

  Marketplace({
    this.id,
    required this.name,
    required this.skuMap,
  });

  factory Marketplace.fromJson(Map<String, dynamic> json) {
    return Marketplace(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      skuMap: (json['sku_map'] as List)
          .map((skuMapJson) => SkuMap.fromJson(skuMapJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku_map': skuMap.map((sku) => sku.toJson()).toList(),
    };
  }
}
