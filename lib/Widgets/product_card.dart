import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/model/orders_model.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final int index;

  const ProductCard({
    super.key,
    required this.product,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        color: AppColors.lightGrey,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: ExpansionTile(
          title: _buildHeader(),
          children: [_buildExpandedDetails()],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _buildProductImage(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'SKU: ${product.sku ?? ''}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              _buildPriceRow(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: product.shopifyImage != null && product.shopifyImage!.isNotEmpty
          ? Image.network(
        product.shopifyImage!,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
      )
          : _buildPlaceholderIcon(),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[200],
      child: const Icon(
        Icons.image,
        size: 40,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildPriceRow() {
    return Row(
      children: [
        _buildInfoChip(
          'MRP: Rs.${product.mrp ?? ''}',
          Colors.green[100]!,
        ),
        const SizedBox(width: 8),
        _buildInfoChip(
          'Cost: Rs.${product.cost ?? ''}',
          Colors.blue[100]!,
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildExpandedDetails() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          _buildDetailSection(
            'Product Details',
            {
              'Brand': product.brand?.name ?? '',
              'Description': product.description ?? '',
              'Technical Name': product.technicalName ?? '',
              'Parent SKU': product.parentSku ?? '',
            },
          ),
          const Divider(height: 24),
          _buildDetailSection(
            'Specifications',
            {
              'Dimensions': product.dimensions != null
                  ? '${product.dimensions!.length ?? ''} x ${product.dimensions!.width ?? ''} x ${product.dimensions!.height ?? ''}'
                  : '',
              'Net Weight': product.netWeight != null ? '${product.netWeight} kg' : '',
              'Gross Weight': product.grossWeight != null ? '${product.grossWeight} kg' : '',
              'Category': product.category?.name ?? '',
              'Variant Name': product.variantName ?? '',
            },
          ),
          const Divider(height: 24),
          _buildDetailSection(
            'Additional Information',
            {
              'EAN': product.ean?.toString() ?? '',
              'Product Grade': product.grade ?? '',
              'Active': product.active?.toString() ?? '',
              'Label': product.label?.name ?? '',
              'Tax Rule': product.taxRule ?? '',
              'Outer Package': product.outerPackage?.outerPackageName ?? '',
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, Map<String, String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        ...details.entries
            .where((entry) => entry.value.isNotEmpty)
            .map((entry) => _buildDetailRow(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}