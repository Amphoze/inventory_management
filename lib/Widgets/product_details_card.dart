import 'package:flutter/material.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:inventory_management/Custom-Files/colors.dart';

class ProductDetailsCard extends StatelessWidget {
  final Item item;
  final int index;
  final Color cardColor;

  const ProductDetailsCard({
    super.key,
    required this.item,
    required this.index,
    this.cardColor = AppColors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cardColor,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: ExpansionTile(
        title: _buildHeader(),
        children: [_buildExpandedDetails()],
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
                item.product?.displayName ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'SKU: ${item.product?.sku ?? ''}',
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
      child: item.product?.shopifyImage != null && (item.product?.shopifyImage?.isNotEmpty ?? false)
          ? Image.network(
              item.product!.shopifyImage!,
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
          'Qty: ${item.qty}',
          Colors.blue[100]!,
        ),
        const SizedBox(width: 8),
        _buildInfoChip(
          'Rate: Rs.${item.amount! / item.qty!}',
          Colors.green[100]!,
        ),
        const SizedBox(width: 8),
        _buildInfoChip(
          'Amount: Rs.${item.amount}',
          Colors.green[100]!,
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
              'Brand': item.product?.brand?.name ?? '',
              'Description': item.product?.description ?? '',
              'Technical Name': item.product?.technicalName ?? '',
              'Parent SKU': item.product?.parentSku ?? '',
            },
          ),
          const Divider(height: 24),
          _buildDetailSection(
            'Specifications',
            {
              'Dimensions':
                  '${item.product?.dimensions?.length ?? ''} x ${item.product?.dimensions?.width ?? ''} x ${item.product?.dimensions?.height ?? ''}',
              'Net Weight': item.product?.netWeight != null ? '${item.product!.netWeight} kg' : '',
              'Gross Weight': item.product?.grossWeight != null ? '${item.product!.grossWeight} kg' : '',
              'Category': item.product?.category?.name.toString() ?? '',
            },
          ),
          const Divider(height: 24),
          _buildDetailSection(
            'Pricing',
            {
              'MRP': 'Rs.${item.product?.mrp ?? ''}',
              'Cost': 'Rs.${item.product?.cost ?? ''}',
              'Tax Rule': item.product?.taxRule ?? '',
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
        ...details.entries.map((entry) => _buildDetailRow(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
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
