// Updated CheckOrderModel class to match the response structure
class CheckOrderModel {
  final String orderId;
  final String packListId;
  final List<Item> items;
  final List<OrderPic> orderPics;

  CheckOrderModel({
    required this.orderId,
    required this.packListId,
    required this.items,
    required this.orderPics,
  });

  factory CheckOrderModel.fromJson(Map<String, dynamic> json) {
    return CheckOrderModel(
      orderId: json['order_id'] ?? '',
      packListId: json['packListId'] ?? '',
      items: (json['items'] as List<dynamic>)
          .map((item) => Item.fromJson(item))
          .toList(),
      orderPics: (json['orderPics'] as List<dynamic>)
          .map((pic) => OrderPic.fromJson(pic))
          .toList(),
    );
  }
}

class Item {
  final String productId;
  final String sku;
  final String parentSku;
  final String shopifyImage;
  final String displayName;

  Item({
    required this.productId,
    required this.sku,
    required this.parentSku,
    required this.shopifyImage,
    required this.displayName,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      productId: json['product_id'] ?? '',
      sku: json['sku'] ?? '',
      parentSku: json['parentSku'] ?? '',
      shopifyImage: json['shopifyImage'] ?? '',
      displayName: json['displayName'] ?? '',
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