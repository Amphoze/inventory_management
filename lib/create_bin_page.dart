import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inventory_management/Api/bin_provider.dart';
import 'package:inventory_management/provider/warehouse_provider.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  String? _selectedWarehouse;
  bool _isLoading = false;

  Future<void> getWarehouse() async{
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedWarehouse = prefs.getString('warehouseName');
    });
    return;
  }

  @override
  void initState() {
    getWarehouse();
    super.initState();
  }

  @override
  void dispose() {
    _binNameController.dispose();
    _subBinNameController.dispose();
    _binDescriptionController.dispose();
    _binCapacityController.dispose();
    super.dispose();
  }

  Future<void> _createBin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

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
          'binName': _binNameController.text.trim(),
          'binDescription': _binDescriptionController.text.trim(),
          'binCapacity': int.parse(_binCapacityController.text.trim()),
          'warehouse': _selectedWarehouse,
          'subBin': _subBinNameController.text.trim(),
        }),
      );

      log("Create bin response status: ${response.statusCode}");
      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _resetForm();
        Navigator.pop(context);
        context.read<BinProvider>().fetchBins(context);
        Utils.showSnackBar(context, 'Bin "${_binNameController.text}" created!', color: Colors.green);
      } else {
        final errorData = json.decode(response.body);
        Utils.showSnackBar(context, 'Failed: ${errorData['message'] ?? 'Unknown error'}', color: Colors.red);
      }
    } catch (e) {
      log('Error creating bin: $e');
      setState(() => _isLoading = false);
      Utils.showSnackBar(context, 'Error: $e', color: Colors.red);
    }
  }

  void _resetForm() {
    _binNameController.clear();
    _subBinNameController.clear();
    _binDescriptionController.clear();
    _binCapacityController.clear();
    setState(() => _selectedWarehouse = 'Gilehri Warehouse');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Bin'),
        elevation: 1,
        shadowColor: Colors.grey.shade300,
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5, // Fixed width for web compactness
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create New Bin',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _binNameController,
                    label: 'Bin Name',
                    icon: Icons.inventory,
                    validator: (value) => value!.isEmpty ? 'Required' : (value.length < 3 ? 'Min 3 chars' : null),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _subBinNameController,
                    label: 'Sub-bin Name',
                    icon: Icons.inventory,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _binCapacityController,
                    label: 'Bin Capacity',
                    icon: Icons.dashboard,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) => value!.isEmpty ? 'Required' : (int.tryParse(value) == null ? 'Invalid' : null),
                  ),
                  const SizedBox(height: 12),
                  _buildWarehouseDropdown(),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _binDescriptionController,
                    label: 'Bin Description',
                    icon: Icons.description,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createBin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 2,
                        shadowColor: Colors.grey.shade300,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Create Bin',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primaryBlue, size: 20),
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
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            isDense: true,
          ),
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildWarehouseDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Warehouse',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Consumer<WarehouseProvider>(
            builder: (context, pro, child) => DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedWarehouse,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue, size: 20),
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                onChanged: (String? newValue) {
                  if (newValue != null) setState(() => _selectedWarehouse = newValue);
                },
                items: pro.warehouses.map<DropdownMenuItem<String>>((dynamic warehouse) {
                  return DropdownMenuItem<String>(
                    value: warehouse['name'],
                    child: Text(warehouse['name']),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
