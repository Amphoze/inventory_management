// inner_packing_form.dart
import 'dart:developer';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/provider/inner_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Custom-Files/colors.dart';
import 'Custom-Files/product_search_field.dart';
import 'Custom-Files/utils.dart';

class InnerPackingForm extends StatefulWidget {
  const InnerPackingForm({super.key});

  @override
  State<InnerPackingForm> createState() => _InnerPackingFormState();
}

class _InnerPackingFormState extends State<InnerPackingForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final _skuController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _productController = TextEditingController();
  final _quantityController = TextEditingController();

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    final body = {
      'innerPackingSku': _skuController.text,
      'name': _nameController.text,
      'description': _descriptionController.text,
      'product': _productController.text,
      'quantity': int.parse(_quantityController.text),
    };

    log('create inner body: $body');

    try {
      final response = await http.post(
        Uri.parse('${await Constants.getBaseUrl()}/innerPacking/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      log('create inner response: ${response.body}');
      log('create inner response: ${response.statusCode}');

      if (response.statusCode == 201) {
        if (!mounted) return;
        Utils.showSnackBar(context, 'Inner packing created successfully', color: AppColors.cardsgreen);

        _resetForm();
        context.read<InnerPackagingProvider>().toggleFormVisibility();
      } else {
        throw Exception('Failed to create inner packing');
      }
    } catch (e, s) {
      if (!mounted) return;
      log('create inner error: $e \n\n$s');
      Utils.showSnackBar(context, 'Error creating inner packing', details: e.toString(),  isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    _skuController.clear();
    _nameController.clear();
    _descriptionController.clear();
    _productController.clear();
    _quantityController.clear();
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _productController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Inner Packing Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _skuController,
                          decoration: const InputDecoration(
                            labelText: 'Inner Packing SKU',
                            hintText: 'Enter SKU (e.g., I-03)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.inventory),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an SKU';
                            }
                            if (!value.contains('-')) {
                              return 'SKU must contain a hyphen (e.g., I-03)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            hintText: 'Enter inner packing name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.label),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Enter description',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.description),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ProductSearchableTextField(
                          isRequired: true,
                          onSelected: (product) {
                            setState(() {
                              _productController.text = product?.sku ?? '';
                            });
                            log("_productController.text: ${_productController.text}");
                          },
                        ),
                        // TextFormField(
                        //   controller: _productController,
                        //   decoration: const InputDecoration(
                        //     labelText: 'Product SKU',
                        //     hintText: 'Enter product SKU (e.g., K-167)',
                        //     border: OutlineInputBorder(),
                        //     prefixIcon: Icon(Icons.category),
                        //   ),
                        //   validator: (value) {
                        //     if (value == null || value.isEmpty) {
                        //       return 'Please enter a product SKU';
                        //     }
                        //     if (!value.contains('-')) {
                        //       return 'Product SKU must contain a hyphen';
                        //     }
                        //     return null;
                        //   },
                        // ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            hintText: 'Enter quantity',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.numbers),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a quantity';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            if (int.parse(value) <= 0) {
                              return 'Quantity must be greater than 0';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Create Inner Packing',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
