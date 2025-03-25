class Picklist {
  final String id;
  final String picklistId;
  final String date;
  final bool isConfirmed;
  final int v;
  final String createdAt;
  final List<Item> items;
  final List<String> orderIds;
  final String updatedAt;

  Picklist({
    this.id = '',
    this.picklistId = '',
    this.date = '',
    this.isConfirmed = false,
    this.v = 0,
    this.createdAt = '',
    this.items = const [],
    this.orderIds = const [],
    this.updatedAt = '',
  });

  factory Picklist.fromJson(Map<String, dynamic> json) => Picklist(
    id: json['_id'] as String? ?? '',
    picklistId: json['picklistId'] as String? ?? '',
    date: json['date'] as String? ?? '',
    isConfirmed: json['isConfirmed'] as bool? ?? false,
    v: json['__v'] as int? ?? 0,
    createdAt: json['createdAt'] as String? ?? '',
    items: json['items'] != null
        ? List<Item>.from((json['items'] as List).map((x) => Item.fromJson(x as Map<String, dynamic>)))
        : [],
    orderIds: json['orderIds'] != null
        ? List<String>.from((json['orderIds'] as List).map((x) => x as String))
        : [],
    updatedAt: json['updatedAt'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'picklistId': picklistId,
    'date': date,
    'isConfirmed': isConfirmed,
    '__v': v,
    'createdAt': createdAt,
    'items': items.map((x) => x.toJson()).toList(),
    'orderIds': orderIds,
    'updatedAt': updatedAt,
  };
}

class Item {
  final String id;
  final ProductId productId;
  final String displayName;
  final String sku;
  final int qty;

  Item({
    this.id = '',
    this.productId = const ProductId(),
    this.displayName = '',
    this.sku = '',
    this.qty = 0,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
    id: json['_id'] as String? ?? '',
    productId: json['product_id'] != null
        ? ProductId.fromJson(json['product_id'] as Map<String, dynamic>)
        : const ProductId(),
    displayName: json['displayName'] as String? ?? '',
    sku: json['sku'] as String? ?? '',
    qty: json['qty'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'product_id': productId.toJson(),
    'displayName': displayName,
    'sku': sku,
    'qty': qty,
  };
}

class ProductId {
  final String id;
  final String displayName;
  final String parentSku;
  final String sku;
  final String description;
  final String brand;
  final String category;
  final String technicalName;
  final String color;
  final String taxRule;
  final Dimensions dimensions;
  final double netWeight;
  final double grossWeight;
  final int outerPackageQuantity;
  final double mrp;
  final bool active;
  final List<String> images;
  final String grade;
  final String createdAt;
  final String updatedAt;
  final int v;
  final String variantName;
  final int itemQty;
  final String shopifyImage;
  final int mdPrice;
  final int retailPrice;
  final double mdMrp;
  final bool isActiveWebListing;
  final String descriptionHindi;

  const ProductId({
    this.id = '',
    this.displayName = '',
    this.parentSku = '',
    this.sku = '',
    this.description = '',
    this.brand = '',
    this.category = '',
    this.technicalName = '',
    this.color = '',
    this.taxRule = '',
    this.dimensions = const Dimensions(),
    this.netWeight = 0.0,
    this.grossWeight = 0.0,
    this.outerPackageQuantity = 0,
    this.mrp = 0,
    this.active = false,
    this.images = const [],
    this.grade = '',
    this.createdAt = '',
    this.updatedAt = '',
    this.v = 0,
    this.variantName = '',
    this.itemQty = 0,
    this.shopifyImage = '',
    this.mdPrice = 0,
    this.retailPrice = 0,
    this.mdMrp = 0,
    this.isActiveWebListing = false,
    this.descriptionHindi = '',
  });

  factory ProductId.fromJson(Map<String, dynamic> json) => ProductId(
    id: json['_id'] as String? ?? '',
    displayName: json['displayName'] as String? ?? '',
    parentSku: json['parentSku'] as String? ?? '',
    sku: json['sku'] as String? ?? '',
    description: json['description'] as String? ?? '',
    brand: json['brand'] as String? ?? '',
    category: json['category'] as String? ?? '',
    technicalName: json['technicalName'] as String? ?? '',
    color: json['color'] as String? ?? '',
    taxRule: json['tax_rule'] as String? ?? '',
    dimensions: json['dimensions'] != null
        ? Dimensions.fromJson(json['dimensions'] as Map<String, dynamic>)
        : const Dimensions(),
    netWeight: json['netWeight']?.toDouble() ?? 0.0,
    grossWeight: json['grossWeight']?.toDouble() ?? 0.0,
    outerPackageQuantity: json['outerPackage_quantity'] as int? ?? 0,
    mrp: json['mrp'] as double? ?? 0,
    active: json['active'] as bool? ?? false,
    images: json['images'] != null
        ? List<String>.from((json['images'] as List).map((x) => x as String))
        : [],
    grade: json['grade'] as String? ?? '',
    createdAt: json['createdAt'] as String? ?? '',
    updatedAt: json['updatedAt'] as String? ?? '',
    v: json['__v'] as int? ?? 0,
    variantName: json['variant_name'] as String? ?? '',
    itemQty: json['itemQty'] as int? ?? 0,
    shopifyImage: json['shopifyImage'] as String? ?? '',
    mdPrice: json['MDprice'] as int? ?? 0,
    retailPrice: json['RetailPrice'] as int? ?? 0,
    mdMrp: json['MD_mrp'] as double? ?? 0,
    isActiveWebListing: json['isActiveWebListing'] as bool? ?? false,
    descriptionHindi: json['description_hindi'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'displayName': displayName,
    'parentSku': parentSku,
    'sku': sku,
    'description': description,
    'brand': brand,
    'category': category,
    'technicalName': technicalName,
    'color': color,
    'tax_rule': taxRule,
    'dimensions': dimensions.toJson(),
    'netWeight': netWeight,
    'grossWeight': grossWeight,
    'outerPackage_quantity': outerPackageQuantity,
    'mrp': mrp,
    'active': active,
    'images': images,
    'grade': grade,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    '__v': v,
    'variant_name': variantName,
    'itemQty': itemQty,
    'shopifyImage': shopifyImage,
    'MDprice': mdPrice,
    'RetailPrice': retailPrice,
    'MD_mrp': mdMrp,
    'isActiveWebListing': isActiveWebListing,
    'description_hindi': descriptionHindi,
  };
}

class Dimensions {
  final double length;
  final double width;
  final double height;

  const Dimensions({
    this.length = 0,
    this.width = 0,
    this.height = 0,
  });

  factory Dimensions.fromJson(Map<String, dynamic> json) => Dimensions(
    length: json['length'] as double? ?? 0,
    width: json['width'] as double? ?? 0,
    height: json['height'] as double? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'length': length,
    'width': width,
    'height': height,
  };
}