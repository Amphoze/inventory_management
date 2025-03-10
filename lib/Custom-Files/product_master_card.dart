import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/edit_product.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import '../model/product_master_model.dart';
import '../provider/product_master_provider.dart';

class ProductMasterCard extends StatelessWidget {
  final Product product;

  const ProductMasterCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildWideScreenContent(context),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      height: 150,
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[300],
      ),
      // child: product.shopifyImage.isNotEmpty
      //     ? ClipRRect(
      //         borderRadius: BorderRadius.circular(8),
      //         child: Image.network(
      //           product.shopifyImage,
      //           fit: BoxFit.cover,
      //           errorBuilder: (context, error, stackTrace) {
      //             return _buildPlaceholder();
      //           },
      //         ),
      //       )
      //     : _buildPlaceholder(),
      child: (product.images.isNotEmpty)
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.images[0],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder();
                },
              ),
            )
          : (product.shopifyImage.isNotEmpty)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.shopifyImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholder();
                    },
                  ),
                )
              : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.image,
        size: 50,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildWideScreenContent(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImage(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTitle(product.displayName),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      textStyle: const TextStyle(color: Colors.white),
                    ),
                    onPressed: () async {
                      final res = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditProductPage(product: product)),
                      );
                      Logger().e('pop result is: $res');
                      if (res != null && res == true) {
                        context.read<ProductMasterProvider>().refreshPage();
                      }
                    },
                    child: const Text('Edit Product'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildLeftColumnContent(context)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildRightColumnContent()),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeftColumnContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildText('SKU', product.sku),
        _buildText('Parent SKU', product.parentSku),
        _buildText('EAN', product.ean),
        _buildDescription(context, 'Description', product.description),
        _buildText('Category Name', product.categoryName),
        _buildText('Colour', product.colour),
        _buildText('Net Weight', product.netWeight),
        _buildText('Gross Weight', product.grossWeight),
        _buildText('Label SKU', product.labelSku),
        _buildText('Outer Package Name', product.outerPackageName),
        _buildText('Outer Package Quantity', product.outerPackageQuantity),
      ],
    );
  }

  Widget _buildRightColumnContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildText('Brand', product.brand),
        _buildText('Technical Name', product.technicalName),
        _buildText('MRP', product.mrp.isNotEmpty ? '₹${product.mrp}' : ''),
        _buildText('Cost', product.cost.isNotEmpty ? '₹${product.cost}' : ''),
        _buildText('Tax Rule', product.taxRule.isNotEmpty ? '${product.taxRule}%' : ''),
        _buildText('Grade', product.grade),
        _buildText('Created Date', formatDate(product.createdDate)),
        _buildText('Last Updated', formatDate(product.lastUpdated)),
        _buildText('Length', product.length.isNotEmpty ? '${product.length} cm' : ''),
        _buildText('Width', product.width.isNotEmpty ? '${product.width} cm' : ''),
        _buildText('Heigth', product.height.isNotEmpty ? '${product.height} cm' : ''),
      ],
    );
  }

  Widget _buildTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Tooltip(
              message: value,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black54, overflow: TextOverflow.ellipsis),
                // softWrap: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: InkWell(
              onTap: () => _showDescriptionDialog(context),
              child: Tooltip(
                message: 'Click to view full description',
                child: Text(
                  value,
                  maxLines: 1,
                  style:
                      const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black54, overflow: TextOverflow.ellipsis),
                  // softWrap: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDescriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(product.sku),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5, // Adjust width
            child: SingleChildScrollView(
              child: Html(
                data: product.description,
                style: {
                  "body": Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    fontSize: FontSize(14),
                  ),
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

String formatDate(String dateString) {
  DateTime date = DateTime.parse(dateString);
  String year = date.year.toString();
  String month = date.month.toString().padLeft(2, '0');
  String day = date.day.toString().padLeft(2, '0');

  return '$day-$month-$year';
}
