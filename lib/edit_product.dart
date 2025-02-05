import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/product-card.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProductPage extends StatefulWidget {
  final Product product;

  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  late TextEditingController skuController;
  late TextEditingController parentSkuController;
  late TextEditingController eanController;
  late TextEditingController descriptionController;
  late TextEditingController categoryNameController;
  late TextEditingController colourController;
  late TextEditingController netWeightController;
  late TextEditingController grossWeightController;
  late TextEditingController labelSkuController;
  late TextEditingController outerPackageNameController;
  late TextEditingController outerPackageQuantityController;
  late TextEditingController brandController;
  late TextEditingController technicalNameController;
  late TextEditingController displayNameController;
  late TextEditingController mrpController;
  late TextEditingController costController;
  late TextEditingController taxRuleController;
  late TextEditingController gradeController;
  late TextEditingController lengthController;
  late TextEditingController widthController;
  late TextEditingController heightController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with product data
    skuController = TextEditingController(text: widget.product.sku);
    parentSkuController = TextEditingController(text: widget.product.parentSku);
    eanController = TextEditingController(text: widget.product.ean);
    descriptionController = TextEditingController(text: widget.product.description);
    categoryNameController = TextEditingController(text: widget.product.categoryName);
    colourController = TextEditingController(text: widget.product.colour);
    netWeightController = TextEditingController(text: widget.product.netWeight);
    grossWeightController = TextEditingController(text: widget.product.grossWeight);
    labelSkuController = TextEditingController(text: widget.product.labelSku);
    outerPackageNameController = TextEditingController(text: widget.product.outerPackage_name);
    outerPackageQuantityController = TextEditingController(text: widget.product.outerPackage_quantity);
    brandController = TextEditingController(text: widget.product.brand);
    technicalNameController = TextEditingController(text: widget.product.technicalName);
    displayNameController = TextEditingController(text: widget.product.displayName);
    mrpController = TextEditingController(text: widget.product.mrp);
    costController = TextEditingController(text: widget.product.cost);
    taxRuleController = TextEditingController(text: widget.product.tax_rule);
    gradeController = TextEditingController(text: widget.product.grade);
    lengthController = TextEditingController(text: widget.product.length);
    widthController = TextEditingController(text: widget.product.width);
    heightController = TextEditingController(text: widget.product.height);
  }

  @override
  void dispose() {
    // Dispose controllers
    skuController.dispose();
    parentSkuController.dispose();
    eanController.dispose();
    descriptionController.dispose();
    categoryNameController.dispose();
    colourController.dispose();
    netWeightController.dispose();
    grossWeightController.dispose();
    labelSkuController.dispose();
    outerPackageNameController.dispose();
    outerPackageQuantityController.dispose();
    brandController.dispose();
    technicalNameController.dispose();
    displayNameController.dispose();
    mrpController.dispose();
    costController.dispose();
    taxRuleController.dispose();
    gradeController.dispose();
    lengthController.dispose();
    widthController.dispose();
    heightController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    setState(() {
      widget.product.sku = skuController.text;
      widget.product.parentSku = parentSkuController.text;
      widget.product.ean = eanController.text;
      widget.product.description = descriptionController.text;
      widget.product.categoryName = categoryNameController.text;
      widget.product.colour = colourController.text;
      widget.product.netWeight = netWeightController.text;
      widget.product.grossWeight = grossWeightController.text;
      widget.product.labelSku = labelSkuController.text;
      widget.product.outerPackage_name = outerPackageNameController.text;
      widget.product.outerPackage_quantity = outerPackageQuantityController.text;
      widget.product.brand = brandController.text;
      widget.product.technicalName = technicalNameController.text;
      widget.product.displayName = displayNameController.text;
      widget.product.mrp = mrpController.text;
      widget.product.cost = costController.text;
      widget.product.tax_rule = taxRuleController.text;
      widget.product.grade = gradeController.text;
      widget.product.length = lengthController.text;
      widget.product.width = widthController.text;
      widget.product.height = heightController.text;
    });
    _updateProduct();
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          fillColor: readOnly ? Colors.grey[200] : null,
          filled: readOnly,
        ),
      ),
    );
  }

  Future<void> _updateProduct() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('${await Constants.getBaseUrl()}/products/sku/${widget.product.sku}');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'sku': skuController.text,
          'parentSku': parentSkuController.text,
          // 'ean': eanController.text,
          'description': descriptionController.text, //
          'categoryName': categoryNameController.text, //
          // 'colour': colourController.text,
          'netWeight': netWeightController.text, //
          'grossWeight': grossWeightController.text, //
          'labelSku': labelSkuController.text, //
          'outerPackage_name': outerPackageNameController.text, //
          'outerPackage_quantity': outerPackageQuantityController.text, //
          // 'brand': brandController.text,
          'technicalName': technicalNameController.text, //
          'displayName': displayNameController.text, //
          // 'mrp': mrpController.text,
          // 'cost': costController.text,
          'tax_rule': taxRuleController.text, //
          // 'grade': gradeController.text,
          'length': lengthController.text, //
          'width': widthController.text, //
          'height': heightController.text, //
        }),
      );

      setState(() {
        _isLoading = false;
      });

      log('res: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update product. Error: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: CircularProgressIndicator(),
                )
              : Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: ElevatedButton(
                    onPressed: _saveProduct,
                    child: const Text('Submit'),
                  ),
                ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                label: 'SKU',
                controller: skuController,
                readOnly: true,
              ),
              _buildTextField(
                label: 'Parent SKU',
                controller: parentSkuController,
                readOnly: true,
              ),
              _buildTextField(label: 'Display Name', controller: displayNameController),
              // _buildTextField(label: 'EAN', controller: eanController),
              _buildTextField(label: 'Description', controller: descriptionController),
              _buildTextField(label: 'Category Name', controller: categoryNameController),
              // _buildTextField(label: 'Colour', controller: colourController),
              _buildTextField(label: 'Net Weight', controller: netWeightController),
              _buildTextField(label: 'Gross Weight', controller: grossWeightController),
              _buildTextField(label: 'Label SKU', controller: labelSkuController),
              _buildTextField(label: 'Outer Package Name', controller: outerPackageNameController),
              _buildTextField(label: 'Outer Package Quantity', controller: outerPackageQuantityController),
              // _buildTextField(label: 'Brand', controller: brandController),
              _buildTextField(label: 'Technical Name', controller: technicalNameController),
              // _buildTextField(label: 'MRP', controller: mrpController),
              // _buildTextField(label: 'Cost', controller: costController),
              _buildTextField(label: 'Tax Rule', controller: taxRuleController),
              // _buildTextField(label: 'Grade', controller: gradeController),
              _buildTextField(label: 'Length', controller: lengthController),
              _buildTextField(label: 'Width', controller: widthController),
              _buildTextField(label: 'Height', controller: heightController),
            ],
          ),
        ),
      ),
    );
  }
}
