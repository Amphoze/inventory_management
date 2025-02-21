import 'package:flutter/material.dart';
import 'package:inventory_management/Widgets/product_details_card.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:inventory_management/Custom-Files/colors.dart';

class BigComboCard extends StatelessWidget {
  final List<Item> items;
  final int index;

  const BigComboCard({
    super.key,
    required this.items,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty || index >= items.length) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => _showDetailsDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              _buildComboIcon(),
              const SizedBox(width: 8),
              Expanded(child: _buildComboDetails()),
              _buildAmountChip(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComboIcon() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.inventory,
            size: 24,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Combo ${index + 1}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildComboDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          items[0].comboName ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          'SKU: ${items[0].comboSku ?? ''}',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildDetailChip(
              'Qty: ${items[0].qty ?? 0}',
              Icons.shopping_basket_outlined,
            ),
            const SizedBox(width: 8),
            _buildDetailChip(
              '${items[0].comboWeight ?? 0} kg',
              Icons.scale_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '₹${items[0].comboAmount ?? 0}',
        style: TextStyle(
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[0].comboName ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          items[0].comboSku ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildAmountChip(),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) => ProductDetailsCard(
                  item: items[index],
                  index: index,
                ),
              ),
            ),
            const Divider(height: 1),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}