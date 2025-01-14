class LabelModel {
  String name;
  String labelSku;
  // String image;
  String description;
  // List<Map<String, String>> products; 
  int quantity;

  LabelModel({
    required this.name,
    required this.labelSku,
    // required this.image,
    required this.description,
    // required this.products,
    required this.quantity,
  });

  // Factory method to create a LabelModel instance from JSON
  factory LabelModel.fromJson(Map<String, dynamic> json) {
    return LabelModel(
      name: json['name'] as String,
      labelSku: json['labelSku'] as String,
      // image: json['image'] as String,
      description: json['description'] as String,
      // products: List<Map<String, String>>.from(json['products'] ?? []), 
      quantity: json['quantity'] as int,
    );
  }

  // Method to convert a LabelModel instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'labelSku': labelSku,
      // 'image': image,
      'description': description,
      // 'products':products, 
      'quantity': quantity,
    };
  }
}
