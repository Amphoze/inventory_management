import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inventory_management/Api/bin_api.dart';
import 'package:inventory_management/provider/location_provider.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import 'Api/auth_provider.dart';
import 'Custom-Files/colors.dart';
import 'Custom-Files/utils.dart';
import 'constants/constants.dart';

class CreateBinPage extends StatefulWidget {
  const CreateBinPage({Key? key}) : super(key: key);

  @override
  _CreateBinPageState createState() => _CreateBinPageState();
}

class _CreateBinPageState extends State<CreateBinPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _binNameController = TextEditingController();
  final TextEditingController _subBinNameController = TextEditingController();
  final TextEditingController _binDescriptionController = TextEditingController();
  final TextEditingController _binCapacityController = TextEditingController();

  String _selectedWarehouse = 'Gilehri Warehouse';
  bool _isLoading = false;

  @override
  void dispose() {
    _binNameController.dispose();
    _subBinNameController.dispose();
    _binDescriptionController.dispose();
    _binCapacityController.dispose();
    super.dispose();
  }

  Future<void> _createBin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final baseUrl = await Constants.getBaseUrl();
      final url = '$baseUrl/bin';
      Logger().d('Create bin URL: $url');

      final token = await AuthProvider().getToken();

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'binName': _binNameController.text,
          'binDescription': _binDescriptionController.text,
          'binCapacity': int.parse(_binCapacityController.text),
          'warehouse': _selectedWarehouse,
          'subBin': _subBinNameController.text,
        }),
      );

      log("Create bin response status: ${response.statusCode}");

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        log("Create bin response data: $data");

        _resetForm();

        Navigator.pop(context);

        context.read<BinApi>().fetchBins(context);

        Utils.showSnackBar(context, 'Bin "${_binNameController.text}" created successfully!', color: Colors.green);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Unknown error occurred';

        Utils.showSnackBar(context, 'Failed to create bin: $errorMessage', color: Colors.red);

        log('Failed to create bin: ${response.statusCode}, $errorMessage');
      }
    } catch (e) {
      log('Error creating bin: $e');

      setState(() {
        _isLoading = false;
      });

      Utils.showSnackBar(context, 'Error: ${e.toString()}', color: Colors.red);
    }
  }

  void _resetForm() {
    _binNameController.clear();
    _binDescriptionController.clear();
    _subBinNameController.clear();
    _binCapacityController.clear();
    setState(() {
      _selectedWarehouse = 'Gilehri Warehouse';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Bin'),
        elevation: 0,
      ),
      body: Container(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Create New Storage Bin',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add a new bin to your warehouse inventory system.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Bin Name'),
                  TextFormField(
                    controller: _binNameController,
                    decoration: _buildInputDecoration('Enter bin name', Icons.inventory),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bin name is required';
                      }
                      if (value.length < 3) {
                        return 'Bin name must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Sub-bin Name'),
                  TextFormField(
                    controller: _subBinNameController,
                    decoration: _buildInputDecoration('Enter sub-bin name', Icons.inventory),
                    // validator: (value) {
                    //   if (value == null || value.isEmpty) {
                    //     return 'Sub-Bin name is required';
                    //   }
                    //   if (value.length < 3) {
                    //     return 'Bin name must be at least 3 characters';
                    //   }
                    //   return null;
                    // },
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Bin Capacity'),
                  TextFormField(
                    controller: _binCapacityController,
                    decoration: _buildInputDecoration('Enter capacity (units)', Icons.dashboard),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bin capacity is required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid capacity';
                      }
                      return null;
                    },
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Warehouse'),
                  _buildWarehouseDropdown(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Bin Description'),
                  TextFormField(
                    controller: _binDescriptionController,
                    decoration: _buildInputDecoration('Enter bin description', Icons.description),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createBin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'CREATE BIN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primaryBlue),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  Widget _buildWarehouseDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Consumer<LocationProvider>(builder: (context, pro, child) {
        return DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedWarehouse,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue),
            iconSize: 24,
            elevation: 16,
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedWarehouse = newValue;
                });
              }
            },
            items: pro.warehouses.map<DropdownMenuItem<String>>((dynamic warehouse) {
              return DropdownMenuItem<String>(
                value: warehouse['name'],
                child: Text(warehouse['name']),
              );
            }).toList(),
          ),
        );
      }),
    );
  }
}
