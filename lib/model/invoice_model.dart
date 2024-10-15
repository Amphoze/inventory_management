
class Invoice {
  final String id;
  final String? invoiceNumber;
  final String? invoiceUrl;
  final DateTime createdAt;

  Invoice({
    required this.id,
    this.invoiceNumber,
    this.invoiceUrl,
    required this.createdAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['_id'] as String,
      invoiceNumber: json['invoice_number'] as String?,
      invoiceUrl: json['invoice_url'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String), // Parse the date string
    );
  }
}
