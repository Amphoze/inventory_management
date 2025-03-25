import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

class Order {
  final List<CallStatus>? callStatus;
  final Customer? customer;
  final String source;
  final String id;
  final String orderId;
  final String picklistId;
  final DateTime? date;
  final String paymentMode;
  final String currencyCode;
  final List<Item> items;
  final String skuTrackingId;
  final double totalWeight;
  final double? totalAmount;
  final int coin;
  final double codAmount;
  final double prepaidAmount;
  final String discountCode;
  final String discountScheme;
  final double discountPercent;
  final double discountAmount;
  final int taxPercent;
  final Address? billingAddress;
  final Address? shippingAddress;
  final String courierName;
  final String orderType;
  final List<OuterPackage>? outerPackages;
  // final String outerPackage;
  final bool replacement;
  int orderStatus;
  bool isBooked;
  bool checkInvoice;
  final List<dynamic>? orderStatusMap;
  final Marketplace? marketplace;
  final String agent;
  final String? filter;
  final FreightCharge? freightCharge;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  bool isSelected;
  final bool isPickerFullyScanned;
  final bool isPackerFullyScanned;
  final DateTime? expectedDeliveryDate;
  final String preferredCourier;
  final String deliveryTerm;
  final String transactionNumber;
  final String microDealerOrder;
  final String fulfillmentType;
  final int numberOfBoxes;
  final int totalQuantity;
  final int skuQty;
  final String calcEntryNumber;
  final String currency;
  final DateTime? paymentDateTime;
  final String paymentBank;
  final double length;
  final double breadth;
  final double height;
  final String shipmentId;
  final String shiprocketOrderId;
  final String awbNumber;
  final String? image;
  final Checker? checker;
  final Racker? racker;
  final CheckManifest? checkManifest;
  late String? trackingStatus;
  final List<Map<String, dynamic>>? availableCouriers;
  final Map<String, dynamic>? outBoundBy;
  final Map<String, dynamic>? confirmedBy;
  final Map<String, dynamic>? baApprovedBy;
  final Map<String, dynamic>? checkInvoiceBy;
  final Map<String, dynamic>? bookedBy;
  final Map<String, dynamic>? rebookedBy;
  final Map<String, dynamic>? pickedBy;
  final Map<String, dynamic>? packedBy;
  final Map<String, dynamic>? checkedBy;
  final Map<String, dynamic>? rackedBy;
  final Map<String, dynamic>? manifestedBy;
  final Map<String, dynamic>? messages;
  final Map<String, dynamic>? merged;
  final String? bookingCourier;
  final String? warehouseId;
  final String? warehouseName;
  final bool? isHold;
  String? selectedCourier;

  final List<Mistake> mistakes;

  String? selectedCourierId;

  Order({
    this.callStatus,
    this.merged,
    this.picklistId = '',
    this.rebookedBy,
    required this.mistakes,
    this.isHold,
    this.selectedCourier = '',
    this.selectedCourierId = '',
    this.warehouseId,
    this.warehouseName,
    this.bookingCourier,
    this.messages,
    this.isBooked = false,
    this.outBoundBy,
    this.confirmedBy,
    this.baApprovedBy,
    this.checkInvoiceBy,
    this.bookedBy,
    this.pickedBy,
    this.packedBy,
    this.checkedBy,
    this.rackedBy,
    this.manifestedBy,
    this.availableCouriers,
    this.checkInvoice = false,
    this.customer,
    this.source = '',
    this.id = '',
    this.orderId = '',
    this.date,
    this.paymentMode = '',
    this.currencyCode = '',
    required this.items,
    this.skuTrackingId = '',
    this.totalWeight = 0.0,
    this.totalAmount = 0.0,
    this.coin = 0,
    this.codAmount = 0.0,
    this.prepaidAmount = 0.0,
    this.discountCode = '',
    this.discountScheme = '',
    this.discountPercent = 0,
    this.discountAmount = 0.0,
    this.taxPercent = 0,
    this.billingAddress,
    this.shippingAddress,
    this.courierName = '',
    this.orderType = '',
    this.outerPackages,
    this.replacement = false,
    required this.orderStatus,
    this.orderStatusMap,
    this.marketplace,
    this.agent = '',
    this.filter = '',
    this.freightCharge,
    this.notes = '',
    this.createdAt,
    this.updatedAt,
    this.isSelected = false,
    this.isPickerFullyScanned = false,
    this.isPackerFullyScanned = false,
    this.expectedDeliveryDate,
    this.preferredCourier = '',
    this.deliveryTerm = '',
    this.transactionNumber = '',
    this.microDealerOrder = '',
    this.fulfillmentType = '',
    this.numberOfBoxes = 0,
    this.totalQuantity = 0,
    this.skuQty = 0,
    this.calcEntryNumber = '',
    this.currency = '',
    this.paymentDateTime,
    this.paymentBank = '',
    this.length = 0.0,
    this.breadth = 0.0,
    this.height = 0.0,
    this.shipmentId = '',
    this.shiprocketOrderId = '',
    this.awbNumber = '',
    this.image = '',
    required this.checker,
    required this.racker,
    required this.checkManifest,
    this.trackingStatus,
  });

  static String _parseString(dynamic value) {
    return value?.toString() ?? '';
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    return value is num ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    return value is int ? value : int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(dateString).toLocal();
    } catch (e) {
      return null;
    }
  }

  static String? formatDate(DateTime? date) {
    return date == null ? null : DateFormat('dd-MM-yyyy').format(date);
  }

  static String? parseAndFormatDate(String? dateString) {
    DateTime? parsedDate = _parseDate(dateString);
    return parsedDate != null ? formatDate(parsedDate) : null;
  }

  Map<String, int> countCallStatuses() {
    Map<String, int> statusCounts = {"not answered": 0, "answered": 0, "not reach": 0, "busy": 0};

    if (callStatus != null) {
      for (var status in callStatus!) {
        int currentCount = statusCounts[status.status] ?? 0;
        statusCounts[status.status] = currentCount + 1;
      }
    }
    return statusCounts;
  }

  factory Order.fromJson(Map<String, dynamic> json) {

    // Logger().i("Mistakes :- ${List.from(json['isMistake'] ?? [])} for Order ID :- ${json['order_id'] ?? 'null'}");

    return Order(
      callStatus: (json['callStatus'] as List? ?? []).map((e) => CallStatus.fromJson(e)).toList(),
      merged: json['merged'] ?? {},
      availableCouriers: (json['availableCouriers'] as List?)
              ?.map((courier) => {
                    'name': _parseString(courier['name']),
                    'freight_charge': _parseDouble(courier['freight_charge']),
                    'courier_company_id': _parseString(courier['courier_company_id']),
                  })
              .toList() ??
          [],
      picklistId: _parseString(json['picklistId']),
      warehouseId: json['warehouse']?['warehouse_id']?['_id'] ?? '',
      warehouseName: json['warehouse']?['warehouse_id']?['name'] ?? '',
      isHold: json['warehouse']?['isHold'] ?? false,
      messages: json['messages'] ?? {},

      // mistakes: json['isMistake'] == null ? [] : json['isMistake'].map((e) => Mistake.fromJson(e)).toList(),

      mistakes: json['isMistake'] == null
          ? []
          : (json['isMistake'] as List<dynamic>)
          .map((e) => Mistake.fromJson(e as Map<String, dynamic>))
          .toList(),

      outBoundBy: json['isOutBound'] ?? {},
      confirmedBy: json['confirmedBy'] ?? {},
      baApprovedBy: json['baApprovedBy'] ?? {},
      checkInvoiceBy: json['checkInvoice'] ?? {},
      bookedBy: json['isBooked'] ?? {},
      rebookedBy: json['reBooked'] ?? {},
      pickedBy: json['isPicked'] ?? {},
      packedBy: json['ispacked'] ?? {},
      checkedBy: json['checker'] ?? {},
      rackedBy: json['racker'] ?? {},
      manifestedBy: json['checkManifest'] ?? {},
      isBooked: json['isBooked']?['status'] ?? false,
      checkInvoice: json['checkInvoice']?['approved'] ?? false,
      customer: json['customer'] != null ? Customer.fromJson(json['customer'] ?? {}) : null,
      source: _parseString(json['source']),
      id: _parseString(json['_id']),
      orderId: _parseString(json['order_id']),
      date: _parseDate(json['date'] ?? ''),
      paymentMode: _parseString(json['payment_mode']),
      currencyCode: _parseString(json['currency_code']),
      items: (json['items'] as List? ?? []).map((item) => Item.fromJson(item)).toList(),
      skuTrackingId: _parseString(json['sku_tracking_id']),
      totalWeight: _parseDouble(json['total_weight'] ?? 0),
      totalAmount: _parseDouble(json['total_amt']),
      coin: _parseInt(json['coin']),
      codAmount: _parseDouble(json['cod_amount']),
      prepaidAmount: _parseDouble(json['prepaid_amount']),
      discountCode: _parseString(json['discount_code']),
      discountScheme: _parseString(json['discount_scheme']),
      discountPercent: _parseDouble(json['discount_percent']),
      discountAmount: _parseDouble(json['discount_amount']),
      taxPercent: _parseInt(json['tax_percent']),
      billingAddress: json['billing_addr'] is Map<String, dynamic>
          ? Address.fromJson(json['billing_addr'])
          : Address(address1: _parseString(json['billing_addr'])),
      shippingAddress: json['shipping_addr'] is Map<String, dynamic>
          ? Address.fromJson(json['shipping_addr'])
          : Address(address1: _parseString(json['shipping_addr'])),
      courierName: _parseString(json['courier_name']),
      orderType: _parseString(json['order_type']),
      outerPackages: (json['outerPackage'] as List? ?? []).map((outer) => OuterPackage.fromJson(outer)).toList(),
      // outerPackage: _parseString(json['outerPackage']),
      replacement: json['replacement'] is bool ? json['replacement'] : false,
      orderStatus: _parseInt(json['order_status']),
      orderStatusMap: (json['order_status_map'] as List?)?.map((status) => OrderStatusMap.fromJson(status)).toList() ?? [],
      marketplace: json['marketplace'] != null ? Marketplace.fromJson(json['marketplace']) : null,
      agent: _parseString(json['agent']),
      filter: _parseString(json['filter']),
      freightCharge: json['freight_charge'] != null ? FreightCharge.fromJson(json['freight_charge']) : null,
      notes: _parseString(json['notes']),
      createdAt: _parseDate(_parseString(json['createdAt'])),
      updatedAt: _parseDate(_parseString(json['updatedAt'])),
      isPickerFullyScanned: json['isPickerFullyScanned'] ?? false,
      isPackerFullyScanned: json['isPackerFullyScanned'] ?? false,
      expectedDeliveryDate: _parseDate(_parseString(json['expected_delivery_date'])),
      preferredCourier: _parseString(json['preferred_courier']),
      deliveryTerm: _parseString(json['delivery_term']),
      transactionNumber: _parseString(json['transaction_number']),
      microDealerOrder: _parseString(json['micro_dealer_order']),
      fulfillmentType: _parseString(json['fulfillment_type']),
      numberOfBoxes: _parseInt(json['number_of_boxes']),
      totalQuantity: _parseInt(json['total_quantity']),
      skuQty: _parseInt(json['sku_qty']),
      calcEntryNumber: _parseString(json['calc_entry_number']),
      currency: _parseString(json['currency']),
      paymentDateTime: _parseDate(_parseString(json['payment_date_time'])),
      paymentBank: _parseString(json['payment_bank']),
      length: _parseDouble(json['length']),
      breadth: _parseDouble(json['breadth']),
      height: _parseDouble(json['height']),
      shipmentId: _parseString(json['shipment_id']),
      shiprocketOrderId: _parseString(json['shiprocket_order_id']),
      awbNumber: _parseString(json['awb_number']),
      bookingCourier: _parseString(json['bookingCourier']),
      image: json['image'] ?? '',
      checker: json['checker'] != null ? Checker.fromJson(json['checker']) : null,
      racker: json['racker'] != null ? Racker.fromJson(json['racker']) : null,
      checkManifest: json['checkManifest'] != null ? CheckManifest.fromJson(json['checkManifest'] ?? {}) : null,
      trackingStatus: _parseString(json['tracking_status'] ?? ''),
    );
  }
}

class Customer {
  final String? customerId;
  final String? firstName;
  final String? lastName;
  final int? phone;
  final String? email;
  final String? billingAddress;
  final String? customerGstin;
  final String? customerType;

  Customer({
    required this.customerId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.billingAddress,
    required this.customerGstin,
    this.customerType,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      customerId: json['customer_id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      phone: json['phone'] is int ? json['phone'] : null,
      billingAddress: json['billing_addr']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      customerGstin: json['customer_gstin']?.toString() ?? '',
      customerType: json['customer_type']?.toString() ?? '',
    );
  }
}

class Item {
  final int? qty;

  final Product? product;
  final double? amount;
  final double? comboWeight;
  final String? sku;
  final String? id;
  final bool? isCombo;
  final String? comboSku;
  final String? comboName;
  int? comboAmount = 0;

  Item({
    this.comboWeight,
    required this.qty,
    this.isCombo,
    this.comboAmount,
    this.comboSku,
    this.comboName,
    this.product,
    required this.amount,
    required this.sku,
    required this.id,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      qty: json['qty']?.toInt() ?? 0,
      isCombo: json['isCombo'] ?? false,
      comboAmount: json['comboAmount'] ?? 0,
      comboSku: json['comboSku'] ?? '',
      comboName: json['combo_id']?['name'] ?? '',
      comboWeight: json['combo_id']?['comboWeight'] ?? 0,
      product: json['product_id'] != null ? Product.fromJson(json['product_id'] ?? {}) : null,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      sku: json['sku']?.toString() ?? '',
      id: json['_id']?.toString() ?? '',
    );
  }
}

class Product {
  final Dimensions? dimensions;
  final String? id;
  final String displayName;
  final String? parentSku;
  final String? sku;
  final String? ean;
  final String? description;
  final Brand? brand;
  final Category? category;
  final String? technicalName;
  final Label? label;
  final String? taxRule;
  final BoxSize? boxSize;
  final OuterPackage? outerPackage;
  final double? netWeight;
  final double? grossWeight;
  final double? mrp;
  final double? cost;
  final bool? active;
  final List<String>? images;
  final String? grade;
  final String? shopifyImage;
  final String? variantName;

  Product({
    required this.dimensions,
    required this.id,
    required this.displayName,
    required this.parentSku,
    required this.sku,
    required this.ean,
    required this.description,
    required this.brand,
    required this.category,
    required this.technicalName,
    this.label,
    required this.taxRule,
    this.boxSize,
    this.outerPackage,
    required this.netWeight,
    required this.grossWeight,
    required this.mrp,
    required this.cost,
    required this.active,
    required this.images,
    required this.grade,
    required this.shopifyImage,
    required this.variantName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      dimensions: json['dimensions'] != null ? Dimensions.fromJson(json['dimensions'] ?? {}) : null,
      id: json['_id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      parentSku: json['parentSku']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      ean: json['ean']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      brand: json['brand'] is Map<String, dynamic>
          ? Brand.fromJson(json['brand'])
          : (json['brand'] is String ? Brand(id: json['brand']) : null),
      category: json['category'] is Map<String, dynamic>
          ? Category.fromJson(json['category'])
          : (json['category'] is String ? Category(id: json['category']) : null),
      technicalName: json['technicalName']?.toString() ?? '',
      label: json['label'] is Map<String, dynamic>
          ? Label.fromJson(json['label'])
          : (json['label'] is String ? Label(id: json['label']) : null),
      taxRule: json['tax_rule']?.toString() ?? '',
      boxSize: json['boxSize'] is Map<String, dynamic>
          ? BoxSize.fromJson(json['boxSize'])
          : (json['boxSize'] is String ? BoxSize(id: json['boxSize']) : null),
      outerPackage: json['outerPackage'] is Map<String, dynamic>
          ? OuterPackage.fromJson(json['outerPackage'])
          : (json['outerPackage'] is String ? OuterPackage(id: json['outerPackage']) : null),
      netWeight: (json['netWeight'] as num?)?.toDouble() ?? 0.0,
      grossWeight: (json['grossWeight'] as num?)?.toDouble() ?? 0.0,
      mrp: (json['mrp'] as num?)?.toDouble() ?? 0.0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      active: json['active'] ?? true,
      images: (json['images'] as List?)?.map((img) => img.toString()).toList() ?? [],
      grade: json['grade']?.toString() ?? '',
      shopifyImage: json['shopifyImage']?.toString() ?? '',
      variantName: json['variant_name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dimensions': dimensions?.toJson(),
      'id': id,
      'displayName': displayName,
      'parentSku': parentSku,
      'sku': sku,
      'ean': ean,
      'description': description,
      'brand': brand?.toJson(),
      'category': category?.toJson(),
      'technicalName': technicalName,
      'label': label?.toJson(),
      'tax_rule': taxRule,
      'boxSize': boxSize?.toJson(),
      'outerPackage': outerPackage?.toJson(),
      'netWeight': netWeight,
      'grossWeight': grossWeight,
      'mrp': mrp,
      'cost': cost,
      'active': active,
      'images': images,
      'grade': grade,
      'shopifyImage': shopifyImage,
      'variant_name': variantName,
    };
  }
}

class Brand {
  final String? id;
  final String? name;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  Brand({
    this.id,
    this.name,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      v: json['__v'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'createdAt': createdAt?.toIso8601String() ?? null,
      'updatedAt': updatedAt?.toIso8601String() ?? null,
      '__v': v,
    };
  }
}

class Category {
  final String? id;
  final String? name;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  Category({
    this.id,
    this.name,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] as String?,
      name: json['name'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      v: json['__v'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'createdAt': createdAt?.toIso8601String() ?? null,
      'updatedAt': updatedAt?.toIso8601String() ?? null,
      '__v': v,
    };
  }
}

class Label {
  final String? id;
  final String? name;
  final String? labelSku;
  final String? productSku;
  final int? quantity;
  final String? description;

  Label({this.id, this.name, this.labelSku, this.productSku, this.quantity, this.description});

  factory Label.fromJson(Map<String, dynamic> json) {
    return Label(
      id: json['_id'] as String?,
      name: json['name'] as String?,
      labelSku: json['labelSku'] as String?,
      productSku: json['product SKU '] as String?,
      quantity: json['quantity'] as int?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'labelSku': labelSku,
      'product SKU ': productSku,
      'quantity': quantity,
      'description': description,
    };
  }
}

class OuterPackage {
  final String? id;
  final String? outerPackageSku;
  final String? outerPackageName;
  final String? outerPackageType;
  final num? occupiedWeight;
  final String? weightUnit;
  final String? lengthUnit;

  OuterPackage(
      {this.id, this.outerPackageSku, this.outerPackageName, this.outerPackageType, this.occupiedWeight, this.weightUnit, this.lengthUnit});

  factory OuterPackage.fromJson(Map<String, dynamic> json) {
    return OuterPackage(
      id: json['_id'] as String?,
      outerPackageSku: json['outerPackage_sku'] as String? ?? '',
      outerPackageName: json['outerPackage_name'] as String? ?? '',
      outerPackageType: json['outerPackage_type'] as String? ?? '',
      occupiedWeight: json['occupied_weight'] as num? ?? 0,
      weightUnit: json['weight_unit'] as String? ?? '',
      lengthUnit: json['length_unit'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'outerPackage_sku': outerPackageSku,
      'outerPackage_name': outerPackageName,
      'outerPackage_type': outerPackageType,
      'occupied_weight': occupiedWeight,
      'weight_unit': weightUnit,
      'length_unit': lengthUnit
    };
  }
}

class BoxSize {
  final String? id;
  final String? boxName;
  final String? unit;

  BoxSize({
    this.id,
    this.boxName,
    this.unit,
  });

  factory BoxSize.fromJson(Map<String, dynamic> json) {
    return BoxSize(
      id: json['_id'] as String? ?? '',
      boxName: json['box_name'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'box_name': boxName,
      'unit': unit,
    };
  }
}

class BoxDimensions {
  final double? length;
  final double? width;
  final double? height;

  BoxDimensions({
    this.length,
    this.width,
    this.height,
  });

  factory BoxDimensions.fromJson(Map<String, dynamic> json) {
    return BoxDimensions(
      length: (json['length'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'length': length,
      'width': width,
      'height': height,
    };
  }
}

class Dimensions {
  final double? length;
  final double? width;
  final double? height;

  Dimensions({
    required this.length,
    required this.width,
    required this.height,
  });

  factory Dimensions.fromJson(Map<String, dynamic> json) {
    return Dimensions(
      length: (json['length'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'length': length,
      'width': width,
      'height': height,
    };
  }
}

class Address {
  final String? firstName;
  final String? lastName;
  final String? address1;
  final String? address2;
  final int? phone;
  final String? city;
  final String? pincode;
  final String? zipcode;
  final String? state;
  final String? country;
  final String? countryCode;
  final String? email;

  Address({
    this.firstName,
    this.lastName,
    this.address1,
    this.address2,
    this.phone,
    this.city,
    this.pincode,
    this.zipcode,
    this.state,
    this.country,
    this.countryCode,
    this.email,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      address1: json['address1']?.toString() ?? '',
      address2: json['address2']?.toString() ?? '',
      phone: (json['phone'] as num?)?.toInt(),
      city: json['city']?.toString() ?? '',
      pincode: json['pincode'] is int ? json['pincode'].toString() : json['pincode'] ?? '0',
      zipcode: json['zip_code'] is int ? json['zip_code'].toString() : json['zip_code'] ?? '',
      state: json['state']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      countryCode: json['country_code']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}

class OrderStatusMap {
  final String? status;
  final int? statusId;
  final DateTime? date;

  OrderStatusMap({
    required this.status,
    required this.statusId,
    required this.date,
  });

  factory OrderStatusMap.fromJson(Map<String, dynamic> json) {
    return OrderStatusMap(
      status: json['status']?.toString() ?? '',
      statusId: (json['status_id'] as num?)?.toInt() ?? 0,
      date: Order._parseDate(json['createdAt']),
    );
  }
}

class FreightCharge {
  final double? delhivery;
  final double? shiprocket;
  final double? standardShipping;

  FreightCharge({
    required this.delhivery,
    required this.shiprocket,
    required this.standardShipping,
  });

  factory FreightCharge.fromJson(Map<String, dynamic> json) {
    return FreightCharge(
      delhivery: (json['Delhivery'] as num?)?.toDouble() ?? 0.0,
      shiprocket: (json['Shiprocket'] as num?)?.toDouble() ?? 0.0,
      standardShipping: (json['standard_shipping'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Marketplace {
  final String id;
  final String name;
  final List<Map<String, dynamic>> skuMap;
  final int version;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Marketplace({
    required this.id,
    required this.name,
    required this.skuMap,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Marketplace.fromJson(Map<String, dynamic> json) {
    return Marketplace(
      id: json['_id'],
      name: json['name'],
      skuMap: List<Map<String, dynamic>>.from(json['sku_map']) ?? [],
      version: json['__v'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'sku_map': skuMap,
      '__v': version,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class Checker {
  final bool approved;
  final DateTime? timestamp;

  Checker({required this.approved, this.timestamp});

  factory Checker.fromJson(Map<String, dynamic> json) {
    return Checker(
      approved: json['approved'] ?? false,
      timestamp: DateTime.tryParse(json['timestamp'] ?? ''),
    );
  }
}

class Racker {
  final bool approved;
  final DateTime? timestamp;

  Racker({required this.approved, this.timestamp});

  factory Racker.fromJson(Map<String, dynamic> json) {
    return Racker(
      approved: json['approved'] ?? false,
      timestamp: DateTime.tryParse(json['timestamp'] ?? ''),
    );
  }
}

class CheckManifest {
  final bool approved;
  final DateTime? timestamp;

  CheckManifest({required this.approved, this.timestamp});

  factory CheckManifest.fromJson(Map<String, dynamic> json) {
    return CheckManifest(
      approved: json['approved'] ?? false,
      timestamp: DateTime.tryParse(json['timestamp'] ?? ''),
    );
  }
}

class CallStatus {
  final String status;
  final DateTime timestamp;
  final String id;

  CallStatus({
    required this.status,
    required this.timestamp,
    required this.id,
  });

  factory CallStatus.fromJson(Map<String, dynamic> json) {
    return CallStatus(
      status: json['status'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      id: json['_id'] ?? '',
    );
  }
}

class Mistake {
  final String id;
  final bool status;
  final String user;
  final String timestamp;

  Mistake({required this.id, required this.status, required this.user, required this.timestamp});

  factory Mistake.fromJson(Map<String, dynamic> json) {
    return Mistake(
      id: json['_id'] ?? '',
      status: json['status'] ?? false,
      user: json['user'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'status': status,
      'user': user,
      'timestamp': timestamp,
    };
  }
}