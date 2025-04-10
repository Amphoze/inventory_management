
class Invoice {
  final String id;
  final String invoiceNumber;
  final String orderId;
  final String invoiceUrl;
  final DateTime? createdAt;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.orderId,
    required this.invoiceUrl,
    required this.createdAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['createdAt'] ?? '');
    return Invoice(
      id: json['_id'] as String,
      invoiceNumber: json['invoice_number'] ?? '',
      orderId: json['order_id'] ?? '',
      invoiceUrl: json['invoice_url'] ?? '',
      createdAt: createdAt,
    );
  }
}
