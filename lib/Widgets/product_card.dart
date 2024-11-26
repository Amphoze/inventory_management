import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/model/orders_model.dart';

class ProductDetailsCard extends StatelessWidget {
  final Product product;
  final int index;

  const ProductDetailsCard({
    super.key,
    required this.product,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.lightGrey,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
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
        if (product.shopifyImage != null && product.shopifyImage!.isNotEmpty)
          Image.network(
            product.shopifyImage!,
            key: ValueKey(product.shopifyImage),
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
            product.displayName,
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
        _buildInfoRow('SKU:', product.sku ?? ''),
        _buildInfoRow('Description:', product.description ?? ''),
        _buildInfoRow('Technical Name:', product.technicalName ?? ''),
        _buildInfoRow('Parent SKU:', product.parentSku ?? ''),
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
        _buildInfoRow(
          'Dimensions:',
          product.dimensions != null
              ? '${product.dimensions!.length ?? ''} x ${product.dimensions!.width ?? ''} x ${product.dimensions!.height ?? ''}'
              : '',
        ),
        _buildInfoRow('Tax Rule:', product.taxRule ?? ''),
        _buildInfoRow('Brand:', product.brand?.name ?? ''),
        _buildInfoRow('MRP:', product.mrp != null ? 'Rs.${product.mrp}' : ''),
        _buildInfoRow(
            'Cost:', product.cost != null ? 'Rs.${product.cost}' : ''),
      ],
    );
  }

  Column _buildSecondDetailsColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('EAN:', product.ean?.toString() ?? ''),
        _buildInfoRow('Product Grade:', product.grade ?? ''),
        _buildInfoRow(
            'Active:', product.active != null ? product.active.toString() : ''),
        _buildInfoRow('Label:', product.label?.name ?? ''),
        _buildInfoRow('Category:', product.category?.name ?? ''),
      ],
    );
  }

  Column _buildThirdDetailsColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Color:', product.color!.name ?? ''),
        _buildInfoRow('Net Weight:',
            product.netWeight != null ? '${product.netWeight} kg' : ''),
        _buildInfoRow('Gross Weight:',
            product.grossWeight != null ? '${product.grossWeight} kg' : ''),
        // _buildInfoRow('Box Size:', product.boxSize?.boxName ?? ''),
        _buildInfoRow('Outer Package Name:',
            product.outerPackage?.outerPackageName ?? ''),
        _buildInfoRow('Variant Name:', product.variantName ?? ''),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
