import 'package:flutter/material.dart';
import 'package:inventory_management/Widgets/product_details_card.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:inventory_management/Custom-Files/colors.dart';

class BigComboCard extends StatelessWidget {
  final List<Item> items;
  final int index;
  // final String courierName;

  const BigComboCard({
    super.key,
    required this.items,
    required this.index,
    // required this.courierName,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty || index >= items.length) {
      return const SizedBox.shrink(); // Return empty widget if data is invalid
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '${items[0].comboSku}: ${items[0].comboName!}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Text(items[0].comboSku ?? ''),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Amount: ',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: 'Rs.${items[0].comboAmount?.toString() ?? '0'}',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                          // color: AppColors.cardsred,
                          ),
                    ),
                  ),
                ],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, itemIndex) {
                      final item = items[itemIndex];
                      return ProductDetailsCard(
                        item: item,
                        index: itemIndex,
                        // courierName: courierName,
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Card(
              elevation: 1.0,
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 150,
                      child: _buildProductColumn(),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: _buildDetailsColumn(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Combo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.primaryBlue,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8.0),
        const SizedBox(
          width: 80,
          height: 80,
          child: Icon(
            Icons.inventory,
            size: 50,
            color: AppColors.grey,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          items[0].comboName ?? '',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDetailsColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('SKU:', items[0].comboSku ?? ''),
        _buildInfoRow('Quantity:', items[0].qty?.toString() ?? '0'),
        _buildInfoRow('Amount:', 'Rs.${items[0].comboAmount?.toString() ?? '0'}'),
        _buildInfoRow('Combo Weight:', items[0].comboWeight?.toString() ?? '0'),
        if (items.isNotEmpty) ...[
          const Divider(height: 8),
          Flexible(
            child: _buildProductsColumn(),
          ),
        ],
      ],
    );
  }

  Widget _buildProductsColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: _buildInfoRow('SKU ${index + 1}:', item.product?.sku ?? ''),
            ),
            Flexible(
              child: _buildInfoRow('Product ${index + 1}:', item.product?.displayName ?? ''),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
