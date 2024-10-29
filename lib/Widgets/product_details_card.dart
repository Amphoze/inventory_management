import 'package:flutter/material.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:inventory_management/Custom-Files/colors.dart';

class OrderItemCard extends StatelessWidget {
  final Item item;
  final int index; // To display product number
  final String courierName;
  final String orderStatus;
  final Color cardColor;

  const OrderItemCard({
    Key? key,
    required this.item,
    required this.index,
    required this.courierName,
    required this.orderStatus,
    this.cardColor = AppColors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cardColor,
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductColumn(),
            const SizedBox(width: 8.0),
            Expanded(
              child: _buildDetailsColumn(),
            ),
          ],
        ),
      ),
    );
  }

  Column _buildProductColumn() {
    return Column(
      children: [
        Text(
          'Product ${index + 1}',
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2.0),
        if (item.product?.shopifyImage != null &&
            item.product!.shopifyImage!.isNotEmpty)
          Image.network(
            item.product!.shopifyImage!,
            key: ValueKey(item.product!.shopifyImage),
            width: 140,
            height: 140,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(
                width: 100,
                height: 100,
                child: Icon(
                  Icons.image,
                  size: 70,
                  color: AppColors.grey,
                ),
              );
            },
          )
        else
          const SizedBox(
            width: 100,
            height: 100,
            child: Icon(
              Icons.image,
              size: 70,
              color: AppColors.grey,
            ),
          ),
        const SizedBox(height: 5.0),
        SizedBox(
          width: 370,
          child: Text(
            item.product?.displayName ?? '',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Column _buildDetailsColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('SKU:', item.product?.sku ?? ''),
        _buildInfoRow('Quantity:', item.qty?.toString() ?? ''),
        _buildInfoRow('Amount:', 'Rs.${item.amount ?? ''}'),
        _buildInfoRow('Description:', item.product?.description ?? ''),
        _buildInfoRow('Technical Name:', item.product?.technicalName ?? ''),
        _buildInfoRow('Parent SKU:', item.product?.parentSku ?? ''),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildFirstDetailsColumn(),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: _buildSecondDetailsColumn(),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: _buildThirdDetailsColumn(),
            ),
          ],
        ),
      ],
    );
  }

  Column _buildFirstDetailsColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Brand:', item.product?.brand!.name ?? ''),
        _buildInfoRow(
          'Dimensions:',
          '${item.product?.dimensions?.length ?? ''} x ${item.product?.dimensions?.width ?? ''} x ${item.product?.dimensions?.height ?? ''}',
        ),
        _buildInfoRow('Tax Rule:', item.product?.taxRule ?? ''),
        // _buildInfoRow('Brand:', (item.product?.brand ?? '') as String?),
        _buildInfoRow('MRP:', 'Rs.${item.product?.mrp ?? ''}'),
        _buildInfoRow('Cost:', 'Rs.${item.product?.cost ?? ''}'),
      ],
    );
  }

  Column _buildSecondDetailsColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('EAN:', item.product?.ean ?? ''),
        _buildInfoRow('Product Grade:', item.product?.grade ?? ''),
        _buildInfoRow('Active:', item.product?.active?.toString() ?? ''),
        _buildInfoRow('Label:', item.product?.label?.name.toString() ?? ''),
        _buildInfoRow(
            'Category:', item.product?.category?.name.toString() ?? ''),
      ],
    );
  }

  Column _buildThirdDetailsColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Color:', item.product?.color ?? ''),
        _buildInfoRow(
            'Net Weight:',
            item.product?.netWeight != null
                ? '${item.product!.netWeight} kg'
                : ''),
        _buildInfoRow(
            'Gross Weight:',
            item.product?.grossWeight != null
                ? '${item.product!.grossWeight} kg'
                : ''),
        _buildInfoRow('Box Size:', item.product?.boxSize?.boxName ?? ''),
        _buildInfoRow(
          'Variant Name:',
          item.product?.variantName ?? '',
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Row(
      children: [
        Text(
          '$label ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Flexible(
          child: Text(
            value ?? '',
            style: const TextStyle(fontSize: 12),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
