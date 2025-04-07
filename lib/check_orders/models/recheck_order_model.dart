class RecheckOrderModel {
  final PackedBy packedBy;
  final String id;
  final String picklistId;
  final String orderId;
  final List<OrderPic> orderPics;
  final bool isChecked;
  final bool reChecked;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecheckOrderModel({
    required this.packedBy,
    required this.id,
    required this.picklistId,
    required this.orderId,
    required this.orderPics,
    required this.isChecked,
    required this.reChecked,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecheckOrderModel.fromJson(Map<String, dynamic> json) {
    return RecheckOrderModel(
      packedBy: PackedBy.fromJson(json['packedBy']),
      id: json['_id'] ?? '',
      picklistId: json['pickListId'] ?? '',
      orderId: json['orderId'] ?? '',
      orderPics: (json['orderPics'] as List<dynamic>)
          .map((pic) => OrderPic.fromJson(pic))
          .toList(),
      isChecked: json['isChecked'] ?? false,
      reChecked: json['ReChecked'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toString()),
    );
  }
}

class PackedBy {
  final String name;
  final String email;
  final int contact;

  PackedBy({
    required this.name,
    required this.email,
    required this.contact,
  });

  factory PackedBy.fromJson(Map<String, dynamic> json) {
    return PackedBy(
      name: json['Name'] ?? '',
      email: json['email'] ?? '',
      contact: json['contact'] ?? 0,
    );
  }
}

class OrderPic {
  final String itemSku;
  final String image1;
  final String image2;

  OrderPic({
    required this.itemSku,
    required this.image1,
    required this.image2,
  });

  factory OrderPic.fromJson(Map<String, dynamic> json) {
    return OrderPic(
      itemSku: json['item_sku'] ?? '',
      image1: json['image1'] ?? '',
      image2: json['image2'] ?? '',
    );
  }
}