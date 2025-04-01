import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/Custom-Files/utils.dart';
import 'dart:convert';
import '../Api/auth_provider.dart';
import '../constants/constants.dart';
import '../model/outerpacking_model.dart';
import 'colors.dart';
import 'outer_packaging_search_field.dart';

class OuterPackageSelectorButton extends StatefulWidget {
  final String orderId;
  final VoidCallback? onSuccess;
  final VoidCallback? onRefresh; // New callback for refreshing

  const OuterPackageSelectorButton({
    super.key,
    required this.orderId,
    this.onSuccess,
    this.onRefresh, // Add this parameter
  });

  @override
  _OuterPackageSelectorButtonState createState() => _OuterPackageSelectorButtonState();
}

class _OuterPackageSelectorButtonState extends State<OuterPackageSelectorButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isLoading
          ? const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : const Icon(Icons.outbox),
      onPressed: _isLoading ? null : () => _showOuterPackageDialog(context),
      tooltip: 'Select Outer Packages',
    );
  }

  Future<void> _showOuterPackageDialog(BuildContext context) async {
    Map<String, int> selectedPackages = {};
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Outer Packages'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            height: MediaQuery.of(context).size.height * 0.3,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OuterPackageQuantitySelector(
                    onPackageSelected: (sku, quantity) {
                      setDialogState(() {
                        if (quantity > 0) {
                          selectedPackages[sku] = quantity;
                        } else {
                          selectedPackages.remove(sku);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (selectedPackages.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        itemCount: selectedPackages.length,
                        itemBuilder: (context, index) {
                          final sku = selectedPackages.keys.elementAt(index);
                          final quantity = selectedPackages[sku];
                          return ListTile(
                            title: Text('$sku x $quantity'),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () {
                                setDialogState(() {
                                  selectedPackages.remove(sku);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                if (formKey.currentState!.validate() && selectedPackages.isNotEmpty) {
                  // Show loading dialog
                  Utils.showLoadingDialog(context, 'Submitting Outer Packages...');

                  setState(() => _isLoading = true);
                  setDialogState(() => _isLoading = true);
                  final success = await _submitOuterPackages(selectedPackages);
                  setState(() => _isLoading = false);
                  setDialogState(() => _isLoading = false);

                  // Dismiss loading dialog
                  if (mounted) Navigator.pop(context); // Close loading dialog

                  if (success && mounted) {
                    Navigator.pop(dialogContext); // Close main dialog
                    widget.onSuccess?.call();
                    widget.onRefresh?.call(); // Call refresh function
                  }
                } else if (selectedPackages.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select at least one outer package'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: _isLoading
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _submitOuterPackages(Map<String, int> selectedPackages) async {
    String baseUrl = await Constants.getBaseUrl();
    final url = '$baseUrl/boxsize/outerPackage/edit';
    final token = await AuthProvider().getToken();

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication token not found'), backgroundColor: Colors.red),
      );
      return false;
    }

    List<String> outerPackageList = [];
    selectedPackages.forEach((sku, quantity) {
      outerPackageList.addAll(List.filled(quantity, sku));
    });

    final payload = {
      'order_id': widget.orderId,
      'outerPackage': outerPackageList,
    };

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Outer packages updated successfully'), backgroundColor: Colors.green),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: ${response.body}'), backgroundColor: Colors.red),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      return false;
    }
  }
}

class OuterPackageQuantitySelector extends StatefulWidget {
  final Function(String sku, int quantity) onPackageSelected;

  const OuterPackageQuantitySelector({
    super.key,
    required this.onPackageSelected,
  });

  @override
  _OuterPackageQuantitySelectorState createState() => _OuterPackageQuantitySelectorState();
}

class _OuterPackageQuantitySelectorState extends State<OuterPackageQuantitySelector> {
  OuterPackaging? _selectedPackage;
  int _quantity = 1;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: OuterPackagingSearchableTextField(
              isRequired: true,
              onSelected: (packaging) {
                setState(() {
                  _selectedPackage = packaging;
                  if (packaging != null && _quantity > 0) {
                    widget.onPackageSelected(packaging.outerPackageSku, _quantity);
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: TextFormField(
              initialValue: '1',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a quantity';
                }
                final qty = int.tryParse(value);
                if (qty == null) {
                  return 'Please enter a valid number';
                }
                if (qty <= 0) {
                  return 'Quantity must be greater than 0';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _quantity = int.tryParse(value) ?? 1;
                  if (_quantity < 1) _quantity = 1;
                  if (_selectedPackage != null) {
                    widget.onPackageSelected(_selectedPackage!.outerPackageSku, _quantity);
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}