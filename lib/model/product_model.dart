class Product {
  final String displayName;
  final String? id;
  final String sku;
  final String category;
  final String imageUrl;
  final String brand;
  final String mrp;
  final String boxsize;
  final String amazonLink;
  final String flipkartLink;
  final String snapdealLink;

  // Add new fields
  final String modelNo;
  final String companyName;

  Product({
     this.id,
    required this.displayName,
    required this.sku,
    required this.category,
    required this.imageUrl,
    required this.brand,
    required this.mrp,
    required this.boxsize,
    required this.amazonLink,
    required this.flipkartLink,
    required this.snapdealLink,
    // Initialize new fields
    required this.modelNo,
    required this.companyName,

  });

  // Factory constructor to create a Product object from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? "",
      displayName: json['displayName'] ?? 'Unknown Product',
      sku: json['sku'] ?? 'Unknown SKU',
      category: json['category'] ?? 'Uncategorized',
      imageUrl: json['shopifyImage'] ?? '',
      brand: json['brand'] ?? 'No Brand',
      mrp: json['mrp'] != null ? json['mrp'].toString() : '0',
      boxsize: json['boxSize']??'',
      amazonLink: json['amazonLink'] ?? '',
      flipkartLink: json['flipkartLink'] ?? '',
      snapdealLink: json['snapdealLink'] ?? '',
      // Parse new fields
      modelNo: json['modelNo'] ?? 'Unknown Model No',
      companyName: json['companyName'] ?? 'Unknown Company',

    );
  }

  // Method to convert Product object back to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id':id,
      'displayName': displayName,
      'sku': sku,
      'category': category,
      'imageUrl': imageUrl,
      'brand': brand,
      'mrp': mrp,
      'boxSize':boxsize,
      'amazonLink': amazonLink,
      'flipkartLink': flipkartLink,
      'snapdealLink': snapdealLink,
      // Include new fields
      'modelNo': modelNo,
      'companyName': companyName,
    };
  }
}
