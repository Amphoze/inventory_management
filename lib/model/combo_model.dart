class Combo {
  String? id; // Nullable ID
  String name;
  String mrp;
  String cost;
  String comboSku;
  List<Map<String, String>> products; // List of product IDs
  List<String>? images; // Nullable list of image filenames

  // Constructor
  Combo({
    this.id,
    required this.name,
    required this.mrp,
    required this.cost,
    required this.comboSku,
    required this.products,
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
      products: List<Map<String, String>>.from(
          json['products'] ?? []), // Default to empty list if null
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
