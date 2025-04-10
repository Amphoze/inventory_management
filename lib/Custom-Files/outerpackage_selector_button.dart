import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final VoidCallback? onRefresh;

  const OuterPackageSelectorButton({
    super.key,
    required this.orderId,
    this.onSuccess,
    this.onRefresh,
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
          : const Icon(Icons.inventory_2),
      onPressed: _isLoading ? null : () => _showOuterPackageDialog(context),
      tooltip: 'Select Outer Packages',
    );
  }

  Future<void> _showOuterPackageDialog(BuildContext context) async {
    Map<String, Map<String, dynamic>> selectedPackages = {};
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Outer Packages'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            height: MediaQuery.of(context).size.height * 0.4,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OuterPackageQuantitySelector(
                    onPackageSelected: (sku, name) {
                      setDialogState(() {
                        // Add package with default quantity of 1 if not already present
                        if (!selectedPackages.containsKey(sku)) {
                          selectedPackages[sku] = {
                            'name': name,
                            'quantity': 1,
                          };
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (selectedPackages.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: selectedPackages.length,
                        itemBuilder: (context, index) {
                          final sku = selectedPackages.keys.elementAt(index);
                          final packageData = selectedPackages[sku]!;
                          final name = packageData['name'] as String;
                          final quantity = packageData['quantity'] as int;
                          return ListTile(
                            title: Text('$name ($sku)'),
                            trailing: SizedBox(
                              width: 150,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: quantity.toString(),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: const InputDecoration(
                                          // border: OutlineInputBorder(),
                                          // contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        final qty = int.tryParse(value);
                                        if (qty == null || qty <= 0) {
                                          return 'Must be > 0';
                                        }
                                        return null;
                                      },
                                      onChanged: (value) {
                                        setDialogState(() {
                                          final qty = int.tryParse(value) ?? 1;
                                          if (qty > 0) {
                                            selectedPackages[sku]!['quantity'] = qty;
                                          } else {
                                            selectedPackages[sku]!['quantity'] = 1;
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                                    onPressed: () {
                                      setDialogState(() {
                                        selectedPackages.remove(sku);
                                      });
                                    },
                                  ),
                                ],
                              ),
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
                        Utils.showLoadingDialog(context, 'Submitting Outer Packages...');
                        setState(() => _isLoading = true);
                        setDialogState(() => _isLoading = true);
                        final success = await _submitOuterPackages(selectedPackages);
                        setState(() => _isLoading = false);
                        setDialogState(() => _isLoading = false);

                        if (mounted) Navigator.pop(context); // Close loading dialog

                        if (success && mounted) {
                          Navigator.pop(dialogContext);
                          widget.onSuccess?.call();
                          widget.onRefresh?.call();
                        }
                      } else if (selectedPackages.isEmpty) {
                        Utils.showSnackBar(context, 'Please select at least one outer package',  isError: true);
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

  Future<bool> _submitOuterPackages(Map<String, Map<String, dynamic>> selectedPackages) async {
    String baseUrl = await Constants.getBaseUrl();
    final url = '$baseUrl/boxsize/outerPackage/edit';
    final token = await AuthProvider().getToken();

    if (token == null) {
      Utils.showSnackBar(context, 'Authentication token not found',  isError: true);
      return false;
    }

    // Modified to send both SKU and name
    List<String> outerPackageList = [];
    selectedPackages.forEach((sku, data) {
      for (int i = 0; i < (data['quantity'] as int); i++) {
        outerPackageList.add(sku);
      }
    });

    final payload = {
      'order_id': widget.orderId,
      'outerPackage': outerPackageList,
    };

    log("package payload is: $payload");

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
        Utils.showSnackBar(context, 'Outer packages updated successfully', color: AppColors.cardsgreen);
        return true;
      } else {
        Utils.showSnackBar(context, 'Failed to update the outer package', details: response.body, isError: true);
        return false;
      }
    } catch (e) {
      Utils.showSnackBar(context, 'Failed to update the outer package', details: e.toString(),  isError: true);

      return false;
    }
  }
}

class OuterPackageQuantitySelector extends StatefulWidget {
  final Function(String sku, String name) onPackageSelected;

  const OuterPackageQuantitySelector({
    super.key,
    required this.onPackageSelected,
  });

  @override
  _OuterPackageQuantitySelectorState createState() => _OuterPackageQuantitySelectorState();
}

class _OuterPackageQuantitySelectorState extends State<OuterPackageQuantitySelector> {
  OuterPackaging? _selectedPackage;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: OuterPackagingSearchableTextField(
        isRequired: true,
        onSelected: (packaging) {
          setState(() {
            _selectedPackage = packaging;
            if (packaging != null) {
              widget.onPackageSelected(
                packaging.outerPackageSku,
                packaging.outerPackageName, // Assuming OuterPackaging has a name field
              );
            }
          });
        },
      ),
    );
  }
}
