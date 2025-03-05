// import 'dart:convert';
// import 'dart:developer';
//
// import 'package:flutter/material.dart';
// import 'package:inventory_management/Custom-Files/product_master_card.dart';
// import 'package:http/http.dart' as http;
// import 'package:inventory_management/constants/constants.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class EditProductPage extends StatefulWidget {
//   final Product product;
//
//   const EditProductPage({super.key, required this.product});
//
//   @override
//   State<EditProductPage> createState() => _EditProductPageState();
// }
//
// class _EditProductPageState extends State<EditProductPage> {
//   late TextEditingController skuController;
//   late TextEditingController parentSkuController;
//   late TextEditingController eanController;
//   late TextEditingController descriptionController;
//   late TextEditingController categoryNameController;
//   late TextEditingController colourController;
//   late TextEditingController netWeightController;
//   late TextEditingController grossWeightController;
//   late TextEditingController labelSkuController;
//   late TextEditingController outerPackageNameController;
//   late TextEditingController outerPackageQuantityController;
//   late TextEditingController brandController;
//   late TextEditingController technicalNameController;
//   late TextEditingController displayNameController;
//   late TextEditingController mrpController;
//   late TextEditingController costController;
//   late TextEditingController taxRuleController;
//   late TextEditingController gradeController;
//   late TextEditingController lengthController;
//   late TextEditingController widthController;
//   late TextEditingController heightController;
//
//   bool _isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     // Initialize controllers with product data
//     skuController = TextEditingController(text: widget.product.sku);
//     parentSkuController = TextEditingController(text: widget.product.parentSku);
//     eanController = TextEditingController(text: widget.product.ean);
//     descriptionController = TextEditingController(text: widget.product.description);
//     categoryNameController = TextEditingController(text: widget.product.categoryName);
//     colourController = TextEditingController(text: widget.product.colour);
//     netWeightController = TextEditingController(text: widget.product.netWeight);
//     grossWeightController = TextEditingController(text: widget.product.grossWeight);
//     labelSkuController = TextEditingController(text: widget.product.labelSku);
//     outerPackageNameController = TextEditingController(text: widget.product.outerPackageName);
//     outerPackageQuantityController = TextEditingController(text: widget.product.outerPackageQuantity);
//     brandController = TextEditingController(text: widget.product.brand);
//     technicalNameController = TextEditingController(text: widget.product.technicalName);
//     displayNameController = TextEditingController(text: widget.product.displayName);
//     mrpController = TextEditingController(text: widget.product.mrp);
//     costController = TextEditingController(text: widget.product.cost);
//     taxRuleController = TextEditingController(text: widget.product.taxRule);
//     gradeController = TextEditingController(text: widget.product.grade);
//     lengthController = TextEditingController(text: widget.product.length);
//     widthController = TextEditingController(text: widget.product.width);
//     heightController = TextEditingController(text: widget.product.height);
//   }
//
//   @override
//   void dispose() {
//     // Dispose controllers
//     skuController.dispose();
//     parentSkuController.dispose();
//     eanController.dispose();
//     descriptionController.dispose();
//     categoryNameController.dispose();
//     colourController.dispose();
//     netWeightController.dispose();
//     grossWeightController.dispose();
//     labelSkuController.dispose();
//     outerPackageNameController.dispose();
//     outerPackageQuantityController.dispose();
//     brandController.dispose();
//     technicalNameController.dispose();
//     displayNameController.dispose();
//     mrpController.dispose();
//     costController.dispose();
//     taxRuleController.dispose();
//     gradeController.dispose();
//     lengthController.dispose();
//     widthController.dispose();
//     heightController.dispose();
//     super.dispose();
//   }
//
//   void _saveProduct() {
//     setState(() {
//       widget.product.sku = skuController.text;
//       widget.product.parentSku = parentSkuController.text;
//       widget.product.ean = eanController.text;
//       widget.product.description = descriptionController.text;
//       widget.product.categoryName = categoryNameController.text;
//       widget.product.colour = colourController.text;
//       widget.product.netWeight = netWeightController.text;
//       widget.product.grossWeight = grossWeightController.text;
//       widget.product.labelSku = labelSkuController.text;
//       widget.product.outerPackageName = outerPackageNameController.text;
//       widget.product.outerPackageQuantity = outerPackageQuantityController.text;
//       widget.product.brand = brandController.text;
//       widget.product.technicalName = technicalNameController.text;
//       widget.product.displayName = displayNameController.text;
//       widget.product.mrp = mrpController.text;
//       widget.product.cost = costController.text;
//       widget.product.taxRule = taxRuleController.text;
//       widget.product.grade = gradeController.text;
//       widget.product.length = lengthController.text;
//       widget.product.width = widthController.text;
//       widget.product.height = heightController.text;
//     });
//     _updateProduct();
//   }
//
//   Widget _buildTextField({
//     required String label,
//     required TextEditingController controller,
//     bool readOnly = false,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: TextField(
//         controller: controller,
//         readOnly: readOnly,
//         decoration: InputDecoration(
//           labelText: label,
//           border: const OutlineInputBorder(),
//           fillColor: readOnly ? Colors.grey[200] : null,
//           filled: readOnly,
//         ),
//       ),
//     );
//   }
//
//   Future<void> _updateProduct() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       final url = Uri.parse('${await Constants.getBaseUrl()}/products/sku/${widget.product.sku}');
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('authToken');
//
//       final response = await http.put(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode({
//           'sku': skuController.text,
//           'parentSku': parentSkuController.text,
//           // 'ean': eanController.text,
//           'description': descriptionController.text, //
//           'categoryName': categoryNameController.text, //
//           // 'colour': colourController.text,
//           'netWeight': netWeightController.text, //
//           'grossWeight': grossWeightController.text, //
//           'labelSku': labelSkuController.text, //
//           'outerPackage_name': outerPackageNameController.text, //
//           'outerPackage_quantity': outerPackageQuantityController.text, //
//           // 'brand': brandController.text,
//           'technicalName': technicalNameController.text, //
//           'displayName': displayNameController.text, //
//           // 'mrp': mrpController.text,
//           // 'cost': costController.text,
//           'tax_rule': taxRuleController.text, //
//           // 'grade': gradeController.text,
//           'length': lengthController.text, //
//           'width': widthController.text, //
//           'height': heightController.text, //
//         }),
//       );
//
//       setState(() {
//         _isLoading = false;
//       });
//
//       log('res: ${response.body}');
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Product updated successfully'),
//             backgroundColor: Colors.green,
//           ),
//         );
//         Navigator.pop(context, true);
//
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to update product. Error: ${response.statusCode}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('An error occurred: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Edit Product'),
//         actions: [
//           _isLoading
//               ? const Padding(
//                   padding: EdgeInsets.only(right: 16.0),
//                   child: CircularProgressIndicator(),
//                 )
//               : Padding(
//                   padding: const EdgeInsets.only(right: 16.0),
//                   child: ElevatedButton(
//                     onPressed: _saveProduct,
//                     child: const Text('Submit'),
//                   ),
//                 ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildTextField(
//                 label: 'SKU',
//                 controller: skuController,
//                 readOnly: true,
//               ),
//               _buildTextField(
//                 label: 'Parent SKU',
//                 controller: parentSkuController,
//                 readOnly: true,
//               ),
//               _buildTextField(label: 'Display Name', controller: displayNameController),
//               // _buildTextField(label: 'EAN', controller: eanController),
//               _buildTextField(label: 'Description', controller: descriptionController),
//               _buildTextField(label: 'Category Name', controller: categoryNameController),
//               // _buildTextField(label: 'Colour', controller: colourController),
//               _buildTextField(label: 'Net Weight', controller: netWeightController),
//               _buildTextField(label: 'Gross Weight', controller: grossWeightController),
//               _buildTextField(label: 'Label SKU', controller: labelSkuController),
//               _buildTextField(label: 'Outer Package Name', controller: outerPackageNameController),
//               _buildTextField(label: 'Outer Package Quantity', controller: outerPackageQuantityController),
//               // _buildTextField(label: 'Brand', controller: brandController),
//               _buildTextField(label: 'Technical Name', controller: technicalNameController),
//               // _buildTextField(label: 'MRP', controller: mrpController),
//               // _buildTextField(label: 'Cost', controller: costController),
//               _buildTextField(label: 'Tax Rule', controller: taxRuleController),
//               // _buildTextField(label: 'Grade', controller: gradeController),
//               _buildTextField(label: 'Length', controller: lengthController),
//               _buildTextField(label: 'Width', controller: widthController),
//               _buildTextField(label: 'Height', controller: heightController),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  // late TextEditingController eanController;
  late TextEditingController descriptionController;
  late TextEditingController categoryNameController;
  // late TextEditingController colourController;
  late TextEditingController netWeightController;
  late TextEditingController grossWeightController;
  late TextEditingController labelSkuController;
  late TextEditingController outerPackageNameController;
  late TextEditingController outerPackageQuantityController;
  // late TextEditingController brandController;
  late TextEditingController technicalNameController;
  late TextEditingController displayNameController;
  // late TextEditingController mrpController;
  // late TextEditingController costController;
  late TextEditingController taxRuleController;
  // late TextEditingController gradeController;
  late TextEditingController lengthController;
  late TextEditingController widthController;
  late TextEditingController heightController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    skuController = TextEditingController(text: widget.product.sku);
    parentSkuController = TextEditingController(text: widget.product.parentSku);
    // eanController = TextEditingController(text: widget.product.ean);
    descriptionController = TextEditingController(text: widget.product.description);
    categoryNameController = TextEditingController(text: widget.product.categoryName);
    // colourController = TextEditingController(text: widget.product.colour);
    netWeightController = TextEditingController(text: widget.product.netWeight);
    grossWeightController = TextEditingController(text: widget.product.grossWeight);
    labelSkuController = TextEditingController(text: widget.product.labelSku);
    outerPackageNameController = TextEditingController(text: widget.product.outerPackageName);
    outerPackageQuantityController = TextEditingController(text: widget.product.outerPackageQuantity);
    // brandController = TextEditingController(text: widget.product.brand);
    technicalNameController = TextEditingController(text: widget.product.technicalName);
    displayNameController = TextEditingController(text: widget.product.displayName);
    // mrpController = TextEditingController(text: widget.product.mrp);
    // costController = TextEditingController(text: widget.product.cost);
    taxRuleController = TextEditingController(text: widget.product.taxRule);
    // gradeController = TextEditingController(text: widget.product.grade);
    lengthController = TextEditingController(text: widget.product.length);
    widthController = TextEditingController(text: widget.product.width);
    heightController = TextEditingController(text: widget.product.height);
  }

  @override
  void dispose() {
    skuController.dispose();
    parentSkuController.dispose();
    // eanController.dispose();
    descriptionController.dispose();
    categoryNameController.dispose();
    // colourController.dispose();
    netWeightController.dispose();
    grossWeightController.dispose();
    labelSkuController.dispose();
    outerPackageNameController.dispose();
    outerPackageQuantityController.dispose();
    // brandController.dispose();
    technicalNameController.dispose();
    displayNameController.dispose();
    // mrpController.dispose();
    // costController.dispose();
    taxRuleController.dispose();
    // gradeController.dispose();
    lengthController.dispose();
    widthController.dispose();
    heightController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    setState(() {
      widget.product.sku = skuController.text;
      widget.product.parentSku = parentSkuController.text;
      // widget.product.ean = eanController.text;
      widget.product.description = descriptionController.text;
      widget.product.categoryName = categoryNameController.text;
      // widget.product.colour = colourController.text;
      widget.product.netWeight = netWeightController.text;
      widget.product.grossWeight = grossWeightController.text;
      widget.product.labelSku = labelSkuController.text;
      widget.product.outerPackageName = outerPackageNameController.text;
      widget.product.outerPackageQuantity = outerPackageQuantityController.text;
      // widget.product.brand = brandController.text;
      widget.product.technicalName = technicalNameController.text;
      widget.product.displayName = displayNameController.text;
      // widget.product.mrp = mrpController.text;
      // widget.product.cost = costController.text;
      widget.product.taxRule = taxRuleController.text;
      // widget.product.grade = gradeController.text;
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
          // 'ean': eanController.text,
          'description': descriptionController.text,
          'categoryName': categoryNameController.text,
          // 'colour': colourController.text,
          'netWeight': netWeightController.text,
          'grossWeight': grossWeightController.text,
          'labelSku': labelSkuController.text,
          'outerPackage_name': outerPackageNameController.text,
          'outerPackage_quantity': outerPackageQuantityController.text,
          // 'brand': brandController.text,
          'technicalName': technicalNameController.text,
          'displayName': displayNameController.text,
          // 'mrp': mrpController.text,
          // 'cost': costController.text,
          'tax_rule': taxRuleController.text,
          // 'grade': gradeController.text,
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
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            offset: const Offset(4, 4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            offset: const Offset(-4, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blueGrey[700]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixIcon: readOnly
              ? Icon(Icons.lock, color: Colors.grey[400], size: 20)
              : null,
        ),
      ),
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
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            // Subtle gradient overlay for depth
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
                      // Custom Header
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
                              ? CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                          )
                              : ElevatedButton.icon(
                            onPressed: _saveProduct,
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

                      // Card Container with subtle elevation
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
                            // Basic Info Section
                            _buildSectionTitle('Basic Information'),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildNeumorphicTextField(
                                    label: 'SKU',
                                    controller: skuController,
                                    readOnly: true,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildNeumorphicTextField(
                                    label: 'Parent SKU',
                                    controller: parentSkuController,
                                    readOnly: true,
                                  ),
                                ),
                              ],
                            ),
                            _buildNeumorphicTextField(label: 'Display Name', controller: displayNameController),
                            _buildNeumorphicTextField(label: 'Description', controller: descriptionController),
                            _buildNeumorphicTextField(label: 'Category Name', controller: categoryNameController),

                            // Product Details Section
                            _buildSectionTitle('Product Details'),
                            // Row(
                            //   children: [
                            //     Expanded(
                            //       child: _buildNeumorphicTextField(
                            //         label: 'Brand',
                            //         controller: brandController,
                            //       ),
                            //     ),
                            //     const SizedBox(width: 16),
                            //     Expanded(
                            //       child: _buildNeumorphicTextField(
                            //         label: 'Colour',
                            //         controller: colourController,
                            //       ),
                            //     ),
                            //   ],
                            // ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildNeumorphicTextField(
                                    label: 'Net Weight',
                                    controller: netWeightController,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildNeumorphicTextField(
                                    label: 'Gross Weight',
                                    controller: grossWeightController,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),

                            // Packaging Section
                            _buildSectionTitle('Packaging'),
                            _buildNeumorphicTextField(label: 'Label SKU', controller: labelSkuController),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildNeumorphicTextField(
                                    label: 'Outer Package Name',
                                    controller: outerPackageNameController,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildNeumorphicTextField(
                                    label: 'Outer Package Quantity',
                                    controller: outerPackageQuantityController,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),

                            // Pricing & Tax Section
                            _buildSectionTitle('Pricing & Tax'),
                            // Row(
                            //   children: [
                            //     Expanded(
                            //       child: _buildNeumorphicTextField(
                            //         label: 'MRP',
                            //         controller: mrpController,
                            //         keyboardType: TextInputType.number,
                            //       ),
                            //     ),
                            //     const SizedBox(width: 16),
                            //     Expanded(
                            //       child: _buildNeumorphicTextField(
                            //         label: 'Cost',
                            //         controller: costController,
                            //         keyboardType: TextInputType.number,
                            //       ),
                            //     ),
                            //   ],
                            // ),
                            _buildNeumorphicTextField(label: 'Tax Rule', controller: taxRuleController),

                            // Dimensions Section
                            _buildSectionTitle('Dimensions'),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildNeumorphicTextField(
                                    label: 'Length',
                                    controller: lengthController,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildNeumorphicTextField(
                                    label: 'Width',
                                    controller: widthController,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildNeumorphicTextField(
                                    label: 'Height',
                                    controller: heightController,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),

                            // Additional Info Section
                            _buildSectionTitle('Additional Information'),
                            // _buildNeumorphicTextField(label: 'EAN', controller: eanController),
                            _buildNeumorphicTextField(label: 'Technical Name', controller: technicalNameController),
                            // _buildNeumorphicTextField(label: 'Grade', controller: gradeController),
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
    );
  }
}