import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/provider/outerbox_provider.dart';

import 'Custom-Files/utils.dart';

class OuterPackageForm extends StatefulWidget {
  const OuterPackageForm({super.key});

  @override
  State<OuterPackageForm> createState() => _OuterPackageFormState();
}

class _OuterPackageFormState extends State<OuterPackageForm> {
  final List<String> _typeOptions = ['Bag ', 'Barrel ', 'Bucket ', 'CARBA', 'Cane ', 'Carba ', 'Corogated Box', 'WHITE BAG'];
  String? _selectedType;
  final _formKey = GlobalKey<FormState>();
  final _skuController = TextEditingController();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _qtyController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _selectedUnit = 'cm';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _typeController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  String? _requiredFieldValidator(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  String? _numberValidator(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _skuController.clear();
    _nameController.clear();
    _typeController.clear();
    _lengthController.clear();
    _widthController.clear();
    _heightController.clear();
    _weightController.clear();
    setState(() {
      _selectedUnit = 'cm';
    });
  }

  Widget _buildFormSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Icon prefixIcon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          border: const OutlineInputBorder(),
          prefixIcon: prefixIcon,
          filled: true,
          fillColor: Colors.white,
        ),
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<String> items,
    String? selectedValue,
    required void Function(String?) onChanged,
    required String? Function(String?)? validator,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        value: selectedValue,
        onChanged: onChanged,
        validator: validator,
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pro = context.read<OuterboxProvider>();

    return Form(
      key: _formKey,
      child: Column(
        children: [
          // if (pro.errorMessage != null)
          //   Padding(
          //     padding: const EdgeInsets.all(8.0),
          //     child: Card(
          //       color: Colors.red.shade50,
          //       child: Padding(
          //         padding: const EdgeInsets.all(16.0),
          //         child: Row(
          //           children: [
          //             Icon(Icons.error_outline, color: Colors.red.shade700),
          //             const SizedBox(width: 8),
          //             Expanded(
          //               child: Text(
          //                 pro.errorMessage!,
          //                 style: TextStyle(color: Colors.red.shade700),
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),
          _buildFormSection(
            'Package Information',
            [
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _skuController,
                      label: 'Outer Package SKU',
                      prefixIcon: const Icon(Icons.qr_code),
                      validator: (value) => _requiredFieldValidator(value, 'SKU'),
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _nameController,
                      label: 'Package Name',
                      prefixIcon: const Icon(Icons.inventory_2),
                      validator: (value) => _requiredFieldValidator(value, 'name'),
                      required: true,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                      child: _buildDropdown(
                    label: 'Outer Package Type',
                    items: _typeOptions,
                    selectedValue: _selectedType,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedType = newValue;
                      });
                    },
                    validator: (value) => _requiredFieldValidator(value, 'type'),
                    required: true,
                  )),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _qtyController,
                      label: 'Outerpackage Quantity',
                      prefixIcon: const Icon(Icons.inventory),
                      validator: (value) => _numberValidator(value, 'quantity'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      required: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _buildFormSection(
            'Dimensions',
            [
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _lengthController,
                      label: 'Length (cm)',
                      prefixIcon: const Icon(Icons.straighten),
                      validator: (value) => _numberValidator(value, 'length'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _widthController,
                      label: 'Width (cm)',
                      prefixIcon: const Icon(Icons.straighten),
                      validator: (value) => _numberValidator(value, 'width'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _heightController,
                      label: 'Height (cm)',
                      prefixIcon: const Icon(Icons.height),
                      validator: (value) => _numberValidator(value, 'height'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      required: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _buildFormSection(
            'Weight',
            [
              _buildTextField(
                controller: _weightController,
                label: 'Occupied Weight (kg)',
                prefixIcon: const Icon(Icons.scale),
                validator: (value) => _numberValidator(value, 'weight'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                required: true,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: pro.isLoading || _isSubmitting
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isSubmitting = true;
                            });

                            final packageData = {
                              'outerPackage_sku': _skuController.text,
                              'outerPackage_name': _nameController.text,
                              'outerPackage_type': _selectedType,
                              'dimension': {
                                'length': int.parse(_lengthController.text),
                                'breadth': int.parse(_widthController.text),
                                'height': int.parse(_heightController.text),
                              },
                              'length_unit': _selectedUnit,
                              "weight_unit": "kg",
                              'occupied_weight': double.parse(_weightController.text),
                              "outerPackage_quantity": int.parse(_qtyController.text)
                            };

                            log('data: $packageData');

                            await pro.createBoxsize(packageData);

                            if (mounted) {
                              setState(() {
                                _isSubmitting = false;
                              });

                              if (pro.errorMessage == null) {
                                // _resetForm();
                                pro.toggleFormVisibility();
                                Utils.showSnackBar(context, 'Box size created successfully', color: AppColors.cardsgreen);
                              } else {
                                Utils.showSnackBar(context, pro.errorMessage ?? 'Some error occurred', isError: true);
                              }
                            }
                          }
                        },
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Submit'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: pro.isLoading || _isSubmitting ? null : pro.toggleFormVisibility,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
