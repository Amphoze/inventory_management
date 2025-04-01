class OuterPackaging {
  final String id;
  final String outerPackageSku;
  final String outerPackageName;
  final String outerPackageType;
  final double occupiedWeight;
  final String weightUnit;
  final Map<String, double> dimension;
  final String lengthUnit;
  final int outerPackageQuantity;
  final DateTime? updatedAt;

  OuterPackaging({
    required this.id,
    required this.outerPackageSku,
    required this.outerPackageName,
    required this.outerPackageType,
    required this.occupiedWeight,
    required this.weightUnit,
    required this.dimension,
    required this.lengthUnit,
    required this.outerPackageQuantity,
    this.updatedAt,
  });

  factory OuterPackaging.fromJson(Map<String, dynamic> json) {
    return OuterPackaging(
      id: json['_id'] ?? '',
      outerPackageSku: json['outerPackage_sku'] ?? '',
      outerPackageName: json['outerPackage_name'] ?? '',
      outerPackageType: json['outerPackage_type'] ?? '',
      occupiedWeight: (json['occupied_weight'] as num?)?.toDouble() ?? 0.0,
      weightUnit: json['weight_unit'] ?? '',
      dimension: {
        'length': (json['dimension']['length'] as num?)?.toDouble() ?? 0.0,
        'height': (json['dimension']['height'] as num?)?.toDouble() ?? 0.0,
        'breadth': (json['dimension']['breadth'] as num?)?.toDouble() ?? 0.0,
      },
      lengthUnit: json['length_unit'] ?? '',
      outerPackageQuantity: json['outerPackage_quantity'] ?? 0,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}
