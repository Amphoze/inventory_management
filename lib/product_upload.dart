import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/excelFileUpload.dart';
import 'package:inventory_management/provider/product_data_provider.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:intl/intl.dart';

class ProductDataDisplay extends StatefulWidget {
  const ProductDataDisplay({super.key});

  @override
  _ProductDataDisplayState createState() => _ProductDataDisplayState();
}

class _ProductDataDisplayState extends State<ProductDataDisplay> {
  List<Map<String, dynamic>> failedProducts = [];
  bool showFailedProducts = false;

  bool downloadingTemplate = false;

  Future<void> _uploadProducts(BuildContext context) async {
    final authProvider = AuthProvider();
    final productDataProvider = Provider.of<ProductDataProvider>(context, listen: false);

    if (productDataProvider.dataGroups.isEmpty) {
      _showMessage(context, 'No data available to upload.', isError: true);
      return;
    }

    productDataProvider.setUploading(true);

    int successCount = 0;
    List<String> errorMessages = [];
    List<Map<String, dynamic>> invalidProducts = [];

    List<Map<String, dynamic>> productApiData = [];
    for (var productData in productDataProvider.dataGroups) {
      if ((productData['sku']?.isEmpty ?? true) && (productData['displayName']?.isEmpty ?? true)) {
        invalidProducts.add(productData);
        failedProducts.add({
          'sku': 'N/A',
          'reason': 'Product is missing both SKU and display name.',
          'timestamp': DateFormat('yyyy-MM-dd - kk:mm').format(DateTime.now()),
        });
        continue;
      } else if (productData['sku']?.isEmpty ?? true) {
        invalidProducts.add(productData);
        failedProducts.add({
          'sku': 'N/A',
          'reason': 'Product with display name "${productData['displayName']}" is missing a SKU.',
          'timestamp': DateFormat('yyyy-MM-dd - kk:mm').format(DateTime.now()),
        });
        continue;
      } else if (productData['displayName']?.isEmpty ?? true) {
        invalidProducts.add(productData);
        failedProducts.add({
          'sku': productData['sku'] ?? 'N/A',
          'reason': 'Product with SKU "${productData['sku']}" is missing a display name.',
          'timestamp': DateFormat('yyyy-MM-dd - kk:mm').format(DateTime.now()),
        });
        continue;
      }

      Map<String, dynamic> productMap = {
        'displayName': productData['displayName']?.isEmpty ?? true ? null : productData['displayName'],
        'parentSku': productData['parentSku']?.isEmpty ?? true ? null : productData['parentSku'],
        'sku': productData['sku']?.isEmpty ?? true ? null : productData['sku'],
        'netWeight': productData['netWeight']?.isEmpty ?? true ? null : productData['netWeight'],
        'grossWeight': productData['grossWeight']?.isEmpty ?? true ? null : productData['grossWeight'],
        'cost': productData['cost']?.isEmpty ?? true ? null : productData['cost'],
        'mrp': productData['mrp']?.isEmpty ?? true ? null : productData['mrp'],
        'ean': productData['ean']?.isEmpty ?? true ? null : productData['ean'],
        'brand_id': productData['brand_id']?.isEmpty ?? true ? null : productData['brand_id'],
        'tax_rule': productData['tax_rule']?.isEmpty ?? true ? null : productData['tax_rule'],
        'description': productData['description']?.isEmpty ?? true ? null : productData['description'],
        'technicalName': productData['technicalName']?.isEmpty ?? true ? null : productData['technicalName'],
        'labelSku': productData['labelSku']?.isEmpty ?? true ? null : productData['labelSku'],
        'box_name': productData['box_name']?.isEmpty ?? true ? null : productData['box_name'],
        'categoryName': productData['categoryName']?.isEmpty ?? true ? null : productData['categoryName'],
        'length': productData['length']?.isEmpty ?? true ? null : productData['length'],
        'width': productData['width']?.isEmpty ?? true ? null : productData['width'],
        'height': productData['height']?.isEmpty ?? true ? null : productData['height'],
        'shopifyImage': productData['shopifyImage']?.isEmpty ?? true ? null : productData['shopifyImage'],
        'grade': productData['grade']?.isEmpty ?? true ? null : productData['grade'],
      };

      productApiData.add(productMap);
    }

    // Now upload all products in a single request
    final result = await authProvider.createProduct(productApiData);

    productDataProvider.setUploading(false);

    if (result != null) {
      // Handle successful products
      if (result['successfulProducts'] != null) {
        successCount = result['successfulProducts'].length;
      }

      // Handle failed products
      if (result['failedProducts'] != null) {
        for (var failedProduct in result['failedProducts']) {
          String sku = failedProduct['sku'];
          String reason = failedProduct['reason'] ?? 'Unknown error';

          failedProducts.add({
            'sku': sku,
            'reason': reason,
            'timestamp': DateFormat('yyyy-MM-dd - kk:mm').format(DateTime.now()),
          });

          errorMessages.add('Failed to upload SKU: $sku - Reason: $reason');
        }
      }
    }

    // Notify the user of the upload results
    if (successCount > 0) {
      productDataProvider.reset();
      _showMessage(context, '$successCount products uploaded successfully!');
    }

    // Print all error messages for debugging purposes
    if (errorMessages.isNotEmpty || invalidProducts.isNotEmpty) {
      for (var error in errorMessages) {
        print('Error: $error');
      }

      setState(() {
        showFailedProducts = true;
      });
    }

    // Notify user of invalid products
    if (invalidProducts.isNotEmpty) {
      _showMessage(context, '${invalidProducts.length} products are invalid and were not uploaded.', isError: true);
    }
  }

  void _showMessage(BuildContext context, String message, {bool isError = false}) {
    print(message);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.cardsred : AppColors.primaryGreen,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _clearFailedProducts() {
    setState(() {
      failedProducts.clear();
      showFailedProducts = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final productDataProvider = Provider.of<ProductDataProvider>(context);

    final double screenWidth = MediaQuery.of(context).size.width;
    final double baseTextSize = screenWidth > 1200 ? 16.0 : (screenWidth > 800 ? 15.0 : 14.0);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Upload Products',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ExcelFileUploader(
                  sheetName: 'Sheet1',
                  onUploadSuccess: (List<Map<String, String>> uploadedData) {
                    productDataProvider.setDataGroups(uploadedData);
                  },
                  onError: (String errorMessage) {
                    _showMessage(context, errorMessage, isError: true);
                  },
                ),
                if (productDataProvider.isUploadSuccessful) ...[
                  const SizedBox(width: 16.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    ),
                    onPressed: productDataProvider.isUploading ? null : () => _uploadProducts(context),
                    child: const Text('Upload Products'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () {
                      // Clear the uploaded data
                      productDataProvider.reset();
                      _showMessage(context, 'Upload cancelled.');
                    },
                  ),
                ],
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      downloadingTemplate = true;
                    });

                    await AuthProvider().downloadTemplate(context, 'product');

                    setState(() {
                      downloadingTemplate = false;
                    });
                  },
                  child: downloadingTemplate ? const CircularProgressIndicator(color: Colors.white) : const Text('Download Template'),
                ),
                const SizedBox(width: 16.0),
                ElevatedButton(
                  onPressed: failedProducts.isEmpty
                      ? null
                      : () {
                          setState(() {
                            showFailedProducts = !showFailedProducts;
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  ),
                  child: const Text('Failed Products'),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: productDataProvider.dataGroups.isEmpty
                  ? const Center(child: Text('No data available.'))
                  : ListView.builder(
                      itemCount: productDataProvider.dataGroups.length,
                      itemBuilder: (context, index) {
                        Map<String, String> dataMap = productDataProvider.dataGroups[index];

                        Logger().e('sheet data: $dataMap');

                        return GestureDetector(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.blueAccent, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.grey.withValues(alpha: 0.5),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (dataMap['shopifyImage'] != null && dataMap['shopifyImage']!.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      dataMap['shopifyImage']!,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                const SizedBox(height: 4.0),
                                _buildRowContent(dataMap, baseTextSize),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (showFailedProducts && failedProducts.isNotEmpty) ...[
              const Divider(),
              ExpansionTile(
                title: const Text(
                  'Failed Products',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                initiallyExpanded: showFailedProducts,
                children: [
                  SizedBox(
                    height: 200, // Set a height for the scrolling area
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: failedProducts.length,
                      itemBuilder: (context, index) {
                        final failedProduct = failedProducts[index];
                        return ListTile(
                          title: Text('SKU: ${failedProduct['sku']}'),
                          subtitle: Text(
                            'Reason: ${failedProduct['reason']}\nFailed at: ${failedProduct['timestamp']}',
                            style: const TextStyle(color: Colors.red), // Optional styling
                          ),
                        );
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: _clearFailedProducts,
                    child: const Text('Clear Failed Products'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRowContent(Map<String, dynamic> dataMap, double baseTextSize) {
    final List<String> fieldsToShow = dataMap.keys.toList();

    List<Widget> rowWidgets = [];

    for (int i = 0; i < fieldsToShow.length; i += 2) {
      String leftField = fieldsToShow[i];
      String rightField = fieldsToShow.length > i + 1 ? fieldsToShow[i + 1] : '';

      rowWidgets.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTwoColumnRow(leftField, dataMap[leftField], baseTextSize),
            if (rightField.isNotEmpty) _buildTwoColumnRow(rightField, dataMap[rightField], baseTextSize),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rowWidgets,
    );
  }

  Widget _buildTwoColumnRow(String fieldName, dynamic value, double baseTextSize) {
    String displayValue = value != null && value.isNotEmpty ? value.toString() : '';
    // String displayValue = value != null ? value.toString() : '';

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Text(
                '$fieldName:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: baseTextSize,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              flex: 5,
              child: Text(
                displayValue,
                style: TextStyle(fontSize: baseTextSize),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
