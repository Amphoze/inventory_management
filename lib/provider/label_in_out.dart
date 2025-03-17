import 'dart:developer';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:inventory_management/constants/constants.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Custom-Files/colors.dart';
import '../Custom-Files/label_search_field.dart';
import '../Custom-Files/vendor_search_field.dart';
import 'location_provider.dart';

class LabelFormPage extends StatefulWidget {
  const LabelFormPage({super.key});

  @override
  LabelFormPageState createState() => LabelFormPageState();
}

class LabelFormPageState extends State<LabelFormPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _labelInFormKey = GlobalKey<FormState>();
  final _labelOutFormKey = GlobalKey<FormState>();

  TextEditingController labelSkuController = TextEditingController();
  TextEditingController qtyController = TextEditingController();
  TextEditingController packagingSizeController = TextEditingController();
  TextEditingController costController = TextEditingController();
  TextEditingController vendorNameController = TextEditingController();
  TextEditingController vendorAddressController = TextEditingController();
  TextEditingController vendorPhoneController = TextEditingController();
  TextEditingController vendorEmailController = TextEditingController();
  TextEditingController shopNameController = TextEditingController();
  TextEditingController remarkController = TextEditingController();
  TextEditingController packagingTypeController = TextEditingController();

  String? receivingPlace;
  String? deliveredTo;
  bool _isLoading = false;
  bool _autoValidate = false;

  final FocusNode _labelSkuFocus = FocusNode();
  final FocusNode _qtyFocus = FocusNode();
  final FocusNode _costFocus = FocusNode();
  final FocusNode _vendorNameFocus = FocusNode();
  final FocusNode _vendorAddressFocus = FocusNode();
  final FocusNode _vendorPhoneFocus = FocusNode();
  final FocusNode _vendorEmailFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_resetForm);
  }

  void _resetForm() {
    if (_tabController.indexIsChanging) {
      labelSkuController.clear();
      qtyController.clear();
      packagingSizeController.clear();
      costController.clear();
      vendorNameController.clear();
      vendorAddressController.clear();
      vendorPhoneController.clear();
      vendorEmailController.clear();
      shopNameController.clear();
      remarkController.clear();
      packagingTypeController.clear();
      setState(() {
        _autoValidate = false;
        receivingPlace = null;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_resetForm);
    _tabController.dispose();

    labelSkuController.dispose();
    qtyController.dispose();
    packagingSizeController.dispose();
    costController.dispose();
    vendorNameController.dispose();
    vendorAddressController.dispose();
    vendorPhoneController.dispose();
    vendorEmailController.dispose();
    shopNameController.dispose();
    remarkController.dispose();
    packagingTypeController.dispose();

    _labelSkuFocus.dispose();
    _qtyFocus.dispose();
    _costFocus.dispose();
    _vendorNameFocus.dispose();
    _vendorAddressFocus.dispose();
    _vendorPhoneFocus.dispose();
    _vendorEmailFocus.dispose();

    super.dispose();
  }

  Future<void> submitForm(String endpoint, GlobalKey<FormState> formKey) async {
    setState(() {
      _autoValidate = true;
    });

    if (!formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields correctly'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_tabController.index == 1) {
      if (receivingPlace == deliveredTo) {
        showErrorSnackbar('Receiving Place and Delivered To cannot be the same.');
        setState(() => _isLoading = false);
        return;
      }
    }

    setState(() => _isLoading = true);

    int? qty = int.tryParse(qtyController.text);
    int? cost = int.tryParse(costController.text);
    String phone = vendorPhoneController.text.trim();

    final payload = _tabController.index == 0
        ? {
            "labelSku": labelSkuController.text.trim(),
            "qty": qty,
            "packagingSize": packagingSizeController.text.trim(),
            "cost": cost,
            "Vendor": {
              "Name": vendorNameController.text.trim(),
              "Address": vendorAddressController.text.trim(),
              "Phone": phone,
              "Email": vendorEmailController.text.trim(),
              "shopName": shopNameController.text.trim(),
            },
            "Receiving_place": receivingPlace,
            "remark": remarkController.text.trim(),
            "packagingType": packagingTypeController.text.trim(),
          }
        : {
            "labelSku": labelSkuController.text.trim(),
            "qty": qty,
            "Receiving_place": receivingPlace,
            "remark": remarkController.text.trim(),
            "warehouseTo": deliveredTo,
          };

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${await Constants.getBaseUrl()}/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      log('Response Body: ${response.body}');
      log('Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        formKey.currentState!.reset();
        setState(() {
          _autoValidate = false;
        });

        showSuccessDialog(responseData['data']['orderNumber']);
      } else {
        Map<String, dynamic> errorData = {};
        try {
          errorData = json.decode(response.body);
        } catch (e) {
          errorData['message'] = 'Failed to submit form: ${response.statusCode}';
        }

        showErrorSnackbar(errorData['message'] ?? 'Failed to submit form: ${response.statusCode}');
      }
    } catch (e) {
      showErrorSnackbar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void showSuccessDialog(String orderNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Success', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your form has been submitted successfully.'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Text('Order Number: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      orderNumber,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('OK', style: TextStyle(color: AppColors.primaryBlue)),
          ),
        ],
      ),
    );
  }

  void showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    bool isRequired = false,
    int maxLines = 1,
    IconData? prefixIcon,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        maxLength: label == 'Vendor Phone' ? 10 : null,
        inputFormatters: [
          if (label == 'Vendor Phone' || label == 'Cost' || label == 'Quantity') FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          suffixIcon: suffix,
          errorStyle: TextStyle(color: Colors.red[700]),
        ),
        keyboardType: keyboardType,
        validator: _autoValidate ? validator : null,
        maxLines: maxLines,
        onFieldSubmitted: (_) {
          if (nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          }
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Divider(
        color: Colors.grey[300],
        thickness: 1,
      ),
    );
  }

  Widget buildForm(GlobalKey<FormState> formKey) {
    final String formType = _tabController.index == 0 ? 'Label In' : 'Label Out';

    return Form(
      key: formKey,
      autovalidateMode: _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      formType,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Label Details'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: LabelSearchableTextField(
                      isRequired: true,
                      controller: labelSkuController,
                    )),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(
                        controller: qtyController,
                        label: 'Quantity',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.numbers,
                        isRequired: true,
                        focusNode: _qtyFocus,
                        validator: (value) {
                          if (value!.isEmpty) return 'Quantity is required';
                          if (int.tryParse(value) == null) return 'Enter a valid number';
                          if (int.parse(value) <= 0) return 'Quantity must be greater than 0';
                          return null;
                        },
                      ),
                    ),
                    if (_tabController.index == 0) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          controller: costController,
                          label: 'Cost',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.currency_rupee,
                          isRequired: true,
                          focusNode: _costFocus,
                          nextFocus: _vendorNameFocus,
                          validator: (value) {
                            if (value!.isEmpty) return 'Cost is required';
                            if (int.tryParse(value) == null) return 'Enter a valid number';
                            if (int.parse(value) < 0) return 'Cost cannot be negative';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                if (_tabController.index == 0) ...[
                  _buildDivider(),
                  _buildSectionTitle('Vendor Details'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Expanded(
                      //   child: _buildTextField(
                      //     controller: vendorNameController,
                      //     label: 'Vendor Name',
                      //     prefixIcon: Icons.business,
                      //     isRequired: true,
                      //     focusNode: _vendorNameFocus,
                      //     nextFocus: _vendorAddressFocus,
                      //     validator: (value) => value!.isEmpty ? 'Vendor Name is required' : null,
                      //   ),
                      // ),
                      Expanded(
                        child: VendorSearchableTextField(
                          isRequired: true,
                          onSelected: (vendor) {
                            if (vendor != null) {
                              setState(() {
                                vendorNameController.text = vendor.name;
                                vendorPhoneController.text = vendor.phone.toString();
                                vendorAddressController.text = vendor.address;
                                vendorEmailController.text = vendor.email;
                              });
                              debugPrint('Vendor Details - Phone: ${vendor.phone}, '
                                  'Address: ${vendor.address}, Email: ${vendor.email}');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          controller: vendorPhoneController,
                          label: 'Vendor Phone',
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone,
                          isRequired: true,
                          focusNode: _vendorPhoneFocus,
                          nextFocus: _vendorEmailFocus,
                          validator: (value) {
                            if (value!.isEmpty) return 'Phone number is required';
                            if (!RegExp(r'^\d{10,15}$').hasMatch(value) && value.length != 10) {
                              return 'Enter a valid phone number (10-15 digits)';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  _buildTextField(
                    controller: vendorAddressController,
                    label: 'Vendor Address',
                    prefixIcon: Icons.location_on,
                    maxLines: 2,
                    focusNode: _vendorAddressFocus,
                    nextFocus: _vendorPhoneFocus,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: vendorEmailController,
                          label: 'Vendor Email',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email,
                          focusNode: _vendorEmailFocus,
                          validator: (value) {
                            if (value!.isNotEmpty && !EmailValidator.validate(value)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          controller: shopNameController,
                          label: 'Shop Name',
                          prefixIcon: Icons.store,
                        ),
                      ),
                    ],
                  ),
                  _buildDivider(),
                  _buildSectionTitle('Additional Information'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: packagingSizeController,
                          label: 'Packaging Size',
                          prefixIcon: Icons.straighten,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: packagingTypeController,
                          label: 'Packaging Type',
                          prefixIcon: Icons.inventory_2,
                        ),
                      ),
                    ],
                  ),
                ],
                if (_tabController.index == 1) ...[
                  _buildTextField(
                    controller: remarkController,
                    label: 'Remark',
                    prefixIcon: Icons.comment,
                    maxLines: 3,
                  ),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Consumer<LocationProvider>(
                        builder: (context, pro, child) {
                          return _buildDropdown(
                            value: receivingPlace,
                            icon: Icons.store,
                            label: 'Receiving Place*',
                            items: pro.warehouses.map((e) => e['name'].toString()).toList(),
                            onChanged: (value) => setState(() => receivingPlace = value ?? ''),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                    ),
                    if (_tabController.index == 1) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Consumer<LocationProvider>(
                          builder: (context, pro, child) {
                            return _buildDropdown(
                              value: deliveredTo,
                              icon: Icons.store,
                              label: 'Delivered To Warehouse*',
                              items: pro.warehouses.map((e) => e['name'].toString()).toList(),
                              onChanged: (value) => setState(() => deliveredTo = value ?? ''),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 300,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => submitForm(
                                  _tabController.index == 0 ? 'label/labelIn' : 'label/labelOut',
                                  formKey,
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Submitting...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.send),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Submit $formType',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.grey[50],
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primaryBlue,
              indicatorWeight: 3,
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: Colors.grey[600],
              tabs: const [
                Tab(
                  icon: Icon(Icons.input),
                  text: 'Label In',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
                Tab(
                  icon: Icon(Icons.output),
                  text: 'Label Out',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.grey[50],
            child: TabBarView(
              controller: _tabController,
              children: [
                buildForm(_labelInFormKey),
                buildForm(_labelOutFormKey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
    IconData icon = Icons.list,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[400]!, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[400]!, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        fillColor: Colors.white,
        filled: true,
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      validator: validator,
      hint: Text('Select $label'),
    );
  }
}
