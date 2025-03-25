import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:inventory_management/constants/constants.dart';
import 'package:provider/provider.dart';
import '../Api/auth_provider.dart';
import '../provider/location_provider.dart';

class UpdateBinButton extends StatefulWidget {
  final String? productSku;

  const UpdateBinButton({super.key, this.productSku});

  @override
  State<UpdateBinButton> createState() => _UpdateBinButtonState();
}

class _UpdateBinButtonState extends State<UpdateBinButton> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _productSkuController;
  late TextEditingController _warehouseIdController;
  late TextEditingController _binNameController;
  late TextEditingController _binQtyController;
  String? warehouse;
  List<String> bins = [];
  bool isLoadingBins = false;

  Future<void> _fetchBins(String warehouseId) async {
    setState(() => isLoadingBins = true);
    String baseUrl = await Constants.getBaseUrl();
    final url = Uri.parse('$baseUrl/bin/$warehouseId');

    try {
      final token = await Provider.of<AuthProvider>(context, listen: false).getToken();
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Bins API Response: ${response.body}');
      final res = json.decode(response.body);
      if (response.statusCode == 200 && res.containsKey('bins')) {
        setState(() {
          bins = List<String>.from(res['bins'].map((bin) => bin['binName'].toString()));
          _binNameController.clear();
          print('Fetched bins: $bins');
        });
      } else {
        print('No bins key in response');
        setState(() => bins = []);
      }
    } catch (error) {
      print('Error fetching bins: $error');
      // Show SnackBar after dialog is closed
      if (mounted) {
        Navigator.of(context).pop(); // Close any open dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch bins: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => isLoadingBins = false);
    }
  }

  Future<void> _submitBinData(BuildContext dialogContext) async {
    if (_formKey.currentState!.validate()) {
      // Show loading dialog
      showDialog(
        context: dialogContext,
        barrierDismissible: false,
        builder: (context) => const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Adding Bin...'),
              ],
            ),
          ),
        ),
      );

      final body = json.encode({
        'productSku': _productSkuController.text,
        'warehouseId': _warehouseIdController.text,
        'binName': _binNameController.text,
        'binQty': int.parse(_binQtyController.text),
      });

      log('update bin body: $body');

      try {
        final response = await http.post(
          Uri.parse('${await Constants.getBaseUrl()}/bin/update'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${await Provider.of<AuthProvider>(context, listen: false).getToken()}'
          },
          body: body,
        );

        final responseData = json.decode(response.body);

        log('update bin response: $responseData');

        // Close loading dialog
        Navigator.of(dialogContext).pop();
        // Close add bin dialog
        Navigator.of(dialogContext).pop(true);

        // Show SnackBar after all dialogs are closed
        if (mounted) {
          if (response.statusCode == 201 || response.statusCode == 200) {
            await _fetchBins(_warehouseIdController.text);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bin added successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update bin: ${responseData['error'] ?? 'Unknown error'}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // Close loading dialog
        Navigator.of(dialogContext).pop();
        // Close add bin dialog
        Navigator.of(dialogContext).pop(false);

        // Show error SnackBar after all dialogs are closed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding bin: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showAddBinDialog() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, dialogSetState) {
            return AlertDialog(
              title: const Text('Update Bin'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _productSkuController,
                        decoration: const InputDecoration(labelText: 'Product SKU'),
                        validator: (value) => value?.isEmpty ?? true ? 'Please enter Product SKU' : null,
                      ),
                      const SizedBox(height: 8),
                      Consumer<LocationProvider>(
                        builder: (context, pro, child) {
                          return _buildDropdown(
                            value: warehouse,
                            label: 'Warehouse',
                            items: pro.warehouses.map((e) => e['name'].toString()).toList(),
                            onChanged: (value) async {
                              if (value != null) {
                                final tempWarehouse = pro.warehouses.firstWhere((e) => e['name'] == value);
                                dialogSetState(() {
                                  warehouse = value;
                                  _warehouseIdController.text = tempWarehouse['_id'].toString();
                                });
                                await _fetchBins(tempWarehouse['_id'].toString()).then((_) {
                                  dialogSetState(() {});
                                });
                              }
                            },
                            validator: (value) => value == null ? 'Please select a warehouse' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      isLoadingBins
                          ? const CircularProgressIndicator()
                          : _buildDropdown(
                        value: bins.isNotEmpty && bins.contains(_binNameController.text)
                            ? _binNameController.text
                            : null,
                        label: 'Bin Name',
                        items: bins.isEmpty ? ['No bins available'] : bins,
                        onChanged: bins.isEmpty
                            ? null
                            : (value) {
                          dialogSetState(() {
                            _binNameController.text = value ?? '';
                          });
                        },
                        validator: (value) =>
                        value == null || value.isEmpty ? 'Please select a bin' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _binQtyController,
                        decoration: const InputDecoration(labelText: 'Bin Quantity'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter Bin Quantity';
                          if (int.tryParse(value) == null) return 'Please enter a valid number';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => _submitBinData(dialogContext),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    ).then((result) {
      if (result == true) {
        print('Dialog closed with success');
      } else {
        print('Dialog closed without submission');
      }
    });
  }

  @override
  void initState() {
    _productSkuController = TextEditingController(text: widget.productSku);
    _warehouseIdController = TextEditingController();
    _binNameController = TextEditingController();
    _binQtyController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _productSkuController.dispose();
    _warehouseIdController.dispose();
    _binNameController.dispose();
    _binQtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _showAddBinDialog,
      child: const Text('Update Bin'),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required List<String> items,
    required void Function(String?)? onChanged,
    String? Function(String?)? validator,
  }) {
    print('Building dropdown with value: $value, items: $items');
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        label: Text(label, style: const TextStyle(color: Colors.black)),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      validator: validator,
      hint: Text('Select $label'),
      isExpanded: true,
    );
  }
}