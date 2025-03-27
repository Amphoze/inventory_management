
import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/model/combo_model.dart';
import 'package:logger/logger.dart';

class ComboCard extends StatelessWidget {
  final Combo combo;
  final int index;

  const ComboCard({
    super.key,
    required this.combo,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
                      '${combo.comboSku}: ${combo.name}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 10),
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
                          text: 'Rs.${combo.comboAmount}',
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
                  child: const Text('Close'),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.8,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: combo.products.length,
                  itemBuilder: (context, index) {
                    final product = combo.products[index];
                    Logger().e('ppp: $product');
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.inventory),
                        title: Text('SKU: ${product['sku']}'),
                        subtitle: Text('Product: ${product['displayName']}'),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
      child: Card(
        elevation: 1.0,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: IntrinsicHeight(
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
          combo.name,
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
        _buildInfoRow('SKU:', combo.comboSku),
        _buildInfoRow('Quantity:', combo.comboAmount.toString()),
        _buildInfoRow('Amount:', 'Rs.${combo.mrp}'),
        if (combo.products.isNotEmpty) ...[
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
      children: combo.products.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final product = entry.value;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: _buildInfoRow(
                'SKU $index:',
                product['sku'] ?? '',
              ),
            ),
            Flexible(
              child: _buildInfoRow(
                'Product $index:',
                product['displayName'] ?? '',
              ),
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
