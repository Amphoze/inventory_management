import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Custom-Files/label_search_field.dart';
import 'Widgets/Searchabledropdown/search_able_dropdown.dart';
import 'model/product_master_model.dart';

class EditProductPage extends StatefulWidget {
  final Product product;

  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  late TextEditingController skuController;
  late TextEditingController parentSkuController;
  late TextEditingController descriptionController;
  late TextEditingController categoryNameController;
  late TextEditingController netWeightController;
  late TextEditingController grossWeightController;
  late TextEditingController labelSkuController;
  late TextEditingController outerPackageNameController;
  late TextEditingController outerPackageQuantityController;
  late TextEditingController technicalNameController;
  late TextEditingController displayNameController;
  late TextEditingController taxRuleController;
  late TextEditingController lengthController;
  late TextEditingController widthController;
  late TextEditingController heightController;

  bool _isLoading = false;

  final formKey = GlobalKey<FormState>();

  // Store initial requirement states based on non-empty fields
  late Map<String, bool> _fieldRequirements;

  @override
  void initState() {
    super.initState();
    skuController = TextEditingController(text: widget.product.sku);
    parentSkuController = TextEditingController(text: widget.product.parentSku);
    descriptionController = TextEditingController(text: widget.product.description);
    categoryNameController = TextEditingController(text: widget.product.categoryName);
    netWeightController = TextEditingController(text: widget.product.netWeight);
    grossWeightController = TextEditingController(text: widget.product.grossWeight);
    labelSkuController = TextEditingController(text: widget.product.labelSku);
    outerPackageNameController = TextEditingController(text: widget.product.outerPackageName);
    outerPackageQuantityController = TextEditingController(text: widget.product.outerPackageQuantity);
    technicalNameController = TextEditingController(text: widget.product.technicalName);
    displayNameController = TextEditingController(text: widget.product.displayName);
    taxRuleController = TextEditingController(text: widget.product.taxRule);
    lengthController = TextEditingController(text: widget.product.length);
    widthController = TextEditingController(text: widget.product.width);
    heightController = TextEditingController(text: widget.product.height);

    // Initialize requirement states based on whether the fields are non-empty
    _fieldRequirements = {
      'sku': widget.product.sku?.isNotEmpty ?? false,
      'parentSku': widget.product.parentSku?.isNotEmpty ?? false,
      'description': widget.product.description?.isNotEmpty ?? false,
      'categoryName': widget.product.categoryName?.isNotEmpty ?? false,
      'netWeight': widget.product.netWeight?.isNotEmpty ?? false,
      'grossWeight': widget.product.grossWeight?.isNotEmpty ?? false,
      'labelSku': widget.product.labelSku?.isNotEmpty ?? false,
      'outerPackageName': widget.product.outerPackageName?.isNotEmpty ?? false,
      'outerPackageQuantity': widget.product.outerPackageQuantity?.isNotEmpty ?? false,
      'technicalName': widget.product.technicalName?.isNotEmpty ?? false,
      'displayName': widget.product.displayName?.isNotEmpty ?? false,
      'taxRule': widget.product.taxRule?.isNotEmpty ?? false,
      'length': widget.product.length?.isNotEmpty ?? false,
      'width': widget.product.width?.isNotEmpty ?? false,
      'height': widget.product.height?.isNotEmpty ?? false,
    };
  }

  @override
  void dispose() {
    skuController.dispose();
    parentSkuController.dispose();
    descriptionController.dispose();
    categoryNameController.dispose();
    netWeightController.dispose();
    grossWeightController.dispose();
    labelSkuController.dispose();
    outerPackageNameController.dispose();
    outerPackageQuantityController.dispose();
    technicalNameController.dispose();
    displayNameController.dispose();
    taxRuleController.dispose();
    lengthController.dispose();
    widthController.dispose();
    heightController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    setState(() {
      widget.product.sku = skuController.text;
      widget.product.parentSku = parentSkuController.text;
      widget.product.description = descriptionController.text;
      widget.product.categoryName = categoryNameController.text;
      widget.product.netWeight = netWeightController.text;
      widget.product.grossWeight = grossWeightController.text;
      widget.product.labelSku = labelSkuController.text;
      widget.product.outerPackageName = outerPackageNameController.text;
      widget.product.outerPackageQuantity = outerPackageQuantityController.text;
      widget.product.technicalName = technicalNameController.text;
      widget.product.displayName = displayNameController.text;
      widget.product.taxRule = taxRuleController.text;
      widget.product.length = lengthController.text;
      widget.product.width = widthController.text;
      widget.product.height = heightController.text;
    });
    _updateProduct();
  }

  Future<void> _updateProduct() async {
    setState(() => _isLoading = true);

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
          'description': descriptionController.text,
          'categoryName': categoryNameController.text,
          'netWeight': netWeightController.text,
          'grossWeight': grossWeightController.text,
          'labelSku': labelSkuController.text,
          'outerPackage_name': outerPackageNameController.text,
          'outerPackage_quantity': outerPackageQuantityController.text,
          'technicalName': technicalNameController.text,
          'displayName': displayNameController.text,
          'tax_rule': taxRuleController.text,
          'length': lengthController.text,
          'width': widthController.text,
          'height': heightController.text,
        }),
      );

      setState(() => _isLoading = false);

      log('res: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully'), backgroundColor: Colors.green),
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
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildNeumorphicTextField({
    required String label,
    required TextEditingController controller,
    required String fieldKey, // Add fieldKey to map to _fieldRequirements
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    bool isRequired = _fieldRequirements[fieldKey] ?? false; // Check if field was initially non-empty

    return FormField<String>(
      validator: isRequired
          ? (value) {
              if (controller.text.trim().isEmpty) {
                return 'This field is required';
              }
              return null;
            }
          : null,
      builder: (FormFieldState<String> formFieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: formFieldState.hasError ? Colors.red : Colors.transparent,
                  width: formFieldState.hasError ? 2 : 0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    offset: const Offset(4, 4),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    offset: const Offset(-4, -4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                readOnly: readOnly,
                inputFormatters: [
                  if (keyboardType == TextInputType.number) FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
                keyboardType: keyboardType,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                decoration: InputDecoration(
                  labelText: "$label ${isRequired ? ' *' : ''}",
                  labelStyle: TextStyle(color: Colors.blueGrey[700]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: readOnly ? Icon(Icons.lock, color: Colors.grey[400], size: 20) : null,
                ),
                onChanged: (value) {
                  formFieldState.didChange(value);
                },
              ),
            ),
            if (formFieldState.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text(
                  formFieldState.errorText ?? '',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey[800],
          shadows: [
            Shadow(
              color: Colors.blueAccent.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: formKey,
        child: Container(
          color: Colors.white,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.withValues(alpha: 0.05),
                        Colors.white.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.arrow_back_ios, color: Colors.blueGrey[700]),
                                  onPressed: () => Navigator.pop(context, false),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Edit Product',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey[900],
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            _isLoading
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                                  )
                                : ElevatedButton.icon(
                                    onPressed: () {
                                      if (formKey.currentState!.validate()) {
                                        _saveProduct();
                                      }
                                    },
                                    icon: const Icon(Icons.save, color: Colors.white),
                                    label: const Text(
                                      'Save Changes',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      backgroundColor: Colors.blueAccent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 6,
                                      shadowColor: Colors.blueAccent.withValues(alpha: 0.4),
                                    ),
                                  ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Basic Information'),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildNeumorphicTextField(
                                      label: 'SKU',
                                      controller: skuController,
                                      fieldKey: 'sku',
                                      readOnly: true,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildNeumorphicTextField(
                                      label: 'Parent SKU',
                                      controller: parentSkuController,
                                      fieldKey: 'parentSku',
                                      readOnly: true,
                                    ),
                                  ),
                                ],
                              ),
                              _buildNeumorphicTextField(
                                label: 'Display Name',
                                controller: displayNameController,
                                fieldKey: 'displayName',
                              ),
                              _buildNeumorphicTextField(
                                label: 'Description',
                                controller: descriptionController,
                                fieldKey: 'description',
                              ),
                              _buildNeumorphicTextField(
                                label: 'Category Name',
                                controller: categoryNameController,
                                fieldKey: 'categoryName',
                              ),
                              _buildSectionTitle('Product Details'),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildNeumorphicTextField(
                                      label: 'Net Weight',
                                      controller: netWeightController,
                                      fieldKey: 'netWeight',
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildNeumorphicTextField(
                                      label: 'Gross Weight',
                                      controller: grossWeightController,
                                      fieldKey: 'grossWeight',
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              _buildSectionTitle('Packaging'),
                              LabelSearchableTextField(
                                isRequired: _fieldRequirements['labelSku'] ?? false, // Dynamic requirement
                                controller: labelSkuController,
                                isEditProduct: true,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: searchabletestfeild(
                                      isRequired: _fieldRequirements['outerPackageName'] ?? false, // Dynamic requirement
                                      controller: outerPackageNameController,
                                      isEditProduct: true,
                                      lable: 'search Outer Packaging',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildNeumorphicTextField(
                                      label: 'Outer Package Quantity',
                                      controller: outerPackageQuantityController,
                                      fieldKey: 'outerPackageQuantity',
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              _buildSectionTitle('Pricing & Tax'),
                              _buildNeumorphicTextField(
                                label: 'Tax Rule',
                                controller: taxRuleController,
                                fieldKey: 'taxRule',
                              ),
                              _buildSectionTitle('Dimensions'),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildNeumorphicTextField(
                                      label: 'Length',
                                      controller: lengthController,
                                      fieldKey: 'length',
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildNeumorphicTextField(
                                      label: 'Width',
                                      controller: widthController,
                                      fieldKey: 'width',
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildNeumorphicTextField(
                                      label: 'Height',
                                      controller: heightController,
                                      fieldKey: 'height',
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              _buildSectionTitle('Additional Information'),
                              _buildNeumorphicTextField(
                                label: 'Technical Name',
                                controller: technicalNameController,
                                fieldKey: 'technicalName',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
