class Product {
  String sku;
  String categoryName;
  String brand;
  String mrp;
  String createdDate;
  String lastUpdated;
  String colour;
  String displayName;
  String parentSku;
  String netWeight;
  String grossWeight;
  String ean;
  String description;
  String technicalName;
  String labelSku;
  String outerPackageName;
  String outerPackageQuantity;
  String length;
  String width;
  String height;
  String cost;
  String taxRule;
  String grade;
  final String shopifyImage;
  final String variantName;

  Product({
    required this.sku,
    required this.categoryName,
    required this.brand,
    required this.mrp,
    required this.createdDate,
    required this.lastUpdated,
    required this.colour,
    required this.displayName,
    required this.parentSku,
    required this.ean,
    required this.description,
    required this.technicalName,
    required this.cost,
    required this.taxRule,
    required this.grade,
    required this.shopifyImage,
    required this.netWeight,
    required this.grossWeight,
    required this.labelSku,
    required this.outerPackageName,
    required this.outerPackageQuantity,
    required this.length,
    required this.width,
    required this.height,
    required this.variantName,
  });

  factory Product.fromJson(Map<String, dynamic> data) {
    return Product(
      sku: data['sku'] ?? '',
      parentSku: data['parentSku'] ?? '',
      ean: data['ean'] ?? '',
      description: data['description'] ?? '',
      categoryName: data['categoryName'] ?? '',
      brand: data['brand'] ?? '',
      colour: data['colour'] ?? '',
      netWeight: data['netWeight']?.toString() ?? '',
      grossWeight: data['grossWeight']?.toString() ?? '',
      labelSku: data['labelSku'] ?? '',
      outerPackageQuantity: data['outerPackage_quantity']?.toString() ?? '',
      outerPackageName: data['outerPackage_name'] ?? '',
      grade: data['grade'] ?? '',
      technicalName: data['technicalName'] ?? '',
      length: data['length']?.toString() ?? '',
      width: data['width']?.toString() ?? '',
      height: data['height']?.toString() ?? '',
      mrp: data['mrp']?.toString() ?? '',
      cost: data['cost']?.toString() ?? '',
      taxRule: data['tax_rule']?.toString() ?? '',
      shopifyImage: data['shopifyImage'] ?? '',
      createdDate: data['createdAt'] ?? '',
      lastUpdated: data['updatedAt'] ?? '',
      displayName: data['displayName'] ?? '',
      variantName: data['variant_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sku': sku,
      'categoryName': categoryName,
      'brand': brand,
      'mrp': mrp,
      'createdDate': createdDate,
      'lastUpdated': lastUpdated,
      'colour': colour,
      'displayName': displayName,
      'parentSku': parentSku,
      'netWeight': netWeight,
      'grossWeight': grossWeight,
      'ean': ean,
      'shopifyImage': shopifyImage,
      'variantName' : variantName,
    };
  }
}