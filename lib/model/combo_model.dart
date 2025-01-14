class Combo {
  String? id; // Nullable ID
  String name;
  String mrp;
  String cost;
  String comboSku;
  double? comboWeight;
  String? comboQty;
  String? comboAmount;
  List<Map<String, String>> products; // List of product IDs
  List<String>? images; // Nullable list of image filenames

  // Constructor
  Combo({
    this.id,
    this.comboWeight,
    required this.name,
    required this.mrp,
    required this.cost,
    required this.comboSku,
    required this.products,
    this.comboQty,
    this.comboAmount,
    this.images, // Nullable images
  });

  // Factory method to create a Combo from JSON
  factory Combo.fromJson(Map<String, dynamic> json) {
    return Combo(
      id: json['_id'] as String?, // Handle nullable ID
      name: json['name'] as String? ?? '', // Default to empty string if null
      mrp: (json['mrp'] as num?)?.toString() ??
          '0', // Convert to string, default to '0' if null
      cost: (json['cost'] as num?)?.toString() ??
          '0', // Convert to string, default to '0' if null
      comboSku:
          json['comboSku'] as String? ?? '', // Default to empty string if null
      comboWeight:
          json['comboWeight'] as double? ?? 0.0, // Default to empty string if null
      products: (json['products'] as List<dynamic>?)
              ?.map((product) => {
                    'id': (product as Map<String, dynamic>)['_id'] as String? ??
                        '',
                    'sku': product['sku'] as String? ?? '',
                    'displayName' : product['displayName'] as String,
                  })
              .toList() ??
          [], // Default to empty list if null
      comboQty: json['comboQty'] as String? ?? '0',
      comboAmount: json['comboAmount'] as String? ?? '0',
      images: (json['images'] as List<dynamic>?)
              ?.map((image) => image as String)
              .toList() ??
          [], // Handle nullable list
    );
  }

  // Method to convert a Combo to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mrp': mrp,
      'cost': cost,
      'comboSku': comboSku,
      'products': products,
      'comboQty': comboQty,
      'comboAmount': comboAmount,
      'images': images ?? [], // Default to empty list if null
    };
  }
}

class Product {
  final String id;
  final String? displayName;
  final String? sku;
  final bool? active;
  final List<String>? images;

  Product({
    required this.id,
    this.displayName,
    this.sku,
    this.active,
    this.images,
  });

  // Factory constructor to create a Product from JSON, with null checks
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '', // Fallback to empty string if null
      displayName:
          json['displayName'] ?? 'Unknown', // Fallback to 'Unknown' if null
      sku: json['sku'] ?? 'N/A', // Fallback to 'N/A' if null
      active: json['active'] ?? false, // Fallback to 'false' if null
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : [], // Fallback to empty list if null
    );
  }
}
