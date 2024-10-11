class Invoice {
  final String id;
  final String? invoiceNumber;
  final String? invoiceUrl;

  Invoice({
    required this.id,
    this.invoiceNumber,
    this.invoiceUrl,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['_id'] as String,
      invoiceNumber: json['invoice_number'] as String?,
      invoiceUrl: json['invoice_url'] as String?,
    );
  }
}
