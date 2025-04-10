import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_management/Custom-Files/custom-dropdown.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/provider/warehouse_provider.dart';
import 'package:inventory_management/Custom-Files/custom-button.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Custom-Files/utils.dart';

class NewLocationForm extends StatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? warehouseData;

  const NewLocationForm({
    super.key,
    this.isEditing = false,
    this.warehouseData,
  });

  @override
  _NewLocationFormState createState() => _NewLocationFormState();
}

class _NewLocationFormState extends State<NewLocationForm> {
  bool? isSuperAdmin;
  final _formKey = GlobalKey<FormState>();
  final _warehouseNameController = TextEditingController();
  final _warehouseIDController = TextEditingController();
  final _userEmailController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _billingAddress1Controller = TextEditingController();
  final _billingAddress2Controller = TextEditingController();
  final _billingCountryCodeController = TextEditingController();
  final _billingCountryController = TextEditingController();
  final _billingStateController = TextEditingController();
  final _billingCityController = TextEditingController();
  final _billingZipCodeController = TextEditingController();
  final _billingPhoneNumberController = TextEditingController();
  final _shippingAddress1Controller = TextEditingController();
  final _shippingAddress2Controller = TextEditingController();
  final _shippingCountryCodeController = TextEditingController();
  final _shippingCountryController = TextEditingController();
  final _shippingStateController = TextEditingController();
  final _shippingCityController = TextEditingController();
  final _shippingZipCodeController = TextEditingController();
  final _shippingPhoneNumberController = TextEditingController();
  final _warehousePincodeController = TextEditingController();
  final _pincodeController = TextEditingController();
  final bool holdStock = true;
  final bool copyStock = true;

  late WarehouseProvider locationProvider;

  void getSuperAdminStatus() async {
    final prefs = await SharedPreferences.getInstance();
    isSuperAdmin = prefs.getBool('_isSuperAdminAssigned');
  }

  void copyAddress(bool value) {
    setState(() {
      if (value == true) {
        _shippingAddress1Controller.text = _billingAddress1Controller.text;
        _shippingAddress2Controller.text = _billingAddress2Controller.text;
        _shippingCountryController.text = _billingCountryController.text;
        _shippingCountryCodeController.text = _billingCountryCodeController.text;
        _shippingStateController.text = _billingStateController.text;
        _shippingCityController.text = _billingCityController.text;
        _shippingZipCodeController.text = _billingZipCodeController.text;
        _shippingPhoneNumberController.text = _billingPhoneNumberController.text;
      } else {
        _shippingAddress1Controller.clear();
        _shippingAddress2Controller.clear();
        _shippingCountryController.clear();
        _shippingCountryCodeController.clear();
        _shippingStateController.clear();
        _shippingCityController.clear();
        _shippingZipCodeController.clear();
        _shippingPhoneNumberController.clear();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    locationProvider = context.read<WarehouseProvider>();
    getSuperAdminStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider = Provider.of<WarehouseProvider>(context, listen: false);

      if (widget.isEditing && widget.warehouseData != null) {
        _warehouseIDController.text = widget.warehouseData!['_id'] ?? '';
        _warehouseNameController.text = widget.warehouseData!['name'] ?? '';
        _userEmailController.text = widget.warehouseData!['userEmail'] ?? '';
        _taxIdController.text =
            widget.warehouseData!['location']['otherDetails']?['taxIdentificationNumber']?.toString() ?? '';

        _billingAddress1Controller.text = widget.warehouseData!['location']['billingAddress']['addressLine1'] ?? '';
        _billingAddress2Controller.text = widget.warehouseData!['location']['billingAddress']['addressLine2'] ?? '';

        final billingAddress = widget.warehouseData!['location']['billingAddress'];

        final selectedBillingCountryIndex = locationProvider.countries.indexWhere(
          (country) => country['name'] == billingAddress['country'],
        );
        if (selectedBillingCountryIndex != -1) {
          locationProvider.selectBillingCountry(selectedBillingCountryIndex);
        }

        final selectedBillingStateIndex = locationProvider.states.indexWhere(
          (state) => state['name'] == billingAddress['state'],
        );
        if (selectedBillingStateIndex != -1) {
          locationProvider.selectBillingState(selectedBillingStateIndex);
        }

        final shippingAddress = widget.warehouseData!['location']['shippingAddress'];

        final selectedShippingCountryIndex = locationProvider.countries.indexWhere(
          (country) => country['name'] == shippingAddress['country'],
        );
        if (selectedShippingCountryIndex != -1) {
          locationProvider.selectShippingCountry(selectedShippingCountryIndex);
        }

        final selectedShippingStateIndex = locationProvider.states.indexWhere(
          (state) => state['name'] == shippingAddress['state'],
        );
        if (selectedShippingStateIndex != -1) {
          locationProvider.selectShippingState(selectedShippingStateIndex);

          final selectedLocationTypeIndex = locationProvider.locationTypes.indexWhere(
            (type) => type['name'] == widget.warehouseData!['location']['locationType'],
          );
          if (selectedLocationTypeIndex != -1) {
            locationProvider.selectLocationType(selectedLocationTypeIndex);
          }

          _billingCityController.text = widget.warehouseData!['location']['billingAddress']['city'] ?? '';
          _billingZipCodeController.text =
              widget.warehouseData!['location']['billingAddress']['zipCode']?.toString() ?? '';
          _billingPhoneNumberController.text =
              widget.warehouseData!['location']['billingAddress']['phoneNumber']?.toString() ?? '';
          _shippingAddress1Controller.text = widget.warehouseData!['location']['shippingAddress']['addressLine1'] ?? '';
          _shippingAddress2Controller.text = widget.warehouseData!['location']['shippingAddress']['addressLine2'] ?? '';
          _shippingCityController.text = widget.warehouseData!['location']['shippingAddress']['city'] ?? '';
          _shippingZipCodeController.text =
              widget.warehouseData!['location']['shippingAddress']['zipCode']?.toString() ?? '';
          _shippingPhoneNumberController.text =
              widget.warehouseData!['location']['shippingAddress']['phoneNumber']?.toString() ?? '';
          _warehousePincodeController.text = widget.warehouseData!['warehousePincode']?.toString() ?? '';
          _pincodeController.text = (widget.warehouseData!['pincode']?.isNotEmpty == true)
              ? widget.warehouseData!['pincode'][0].toString()
              : '';

          locationProvider.updateHoldsStock(widget.warehouseData!['holdStocks'] ?? false);

          locationProvider.updateCopysku(widget.warehouseData!['copyMasterSkuFromPrimary'] ?? false);
        }
      }
    });
  }

  @override
  void dispose() {
    _warehouseNameController.dispose();
    _userEmailController.dispose();
    _taxIdController.dispose();
    _billingAddress1Controller.dispose();
    _billingAddress2Controller.dispose();
    _billingCityController.dispose();
    _billingZipCodeController.dispose();
    _billingPhoneNumberController.dispose();
    _shippingAddress1Controller.dispose();
    _shippingAddress2Controller.dispose();
    _shippingCityController.dispose();
    _shippingZipCodeController.dispose();
    _shippingPhoneNumberController.dispose();
    _warehousePincodeController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  final List<PincodeData> _pincodeList = [PincodeData()];

  bool _isPrimary = false;

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<WarehouseProvider>(context);

    final isEmailValid = Provider.of<WarehouseProvider>(context).isEmailValid;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 8,
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryBlue),
                    onPressed: () {
                      locationProvider.resetForm();
                      _pincodeController.clear();

                      if (locationProvider.isEditingLocation) {
                        locationProvider.toggleEditingLocation();
                      } else if (locationProvider.isCreatingNewLocation) {
                        locationProvider.toggleCreatingNewLocation();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    locationProvider.isEditingLocation ? 'Edit Warehouse' : 'Create New Warehouse',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        labelWithRequiredSymbol('Warehouse Name'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _warehouseNameController,
                          decoration: InputDecoration(
                            labelText: 'Warehouse Name',
                            hintText: 'Warehouse Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter warehouse name';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        labelWithRequiredSymbol('Email'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _userEmailController,
                          onChanged: (text) {
                            Provider.of<WarehouseProvider>(context, listen: false).validateEmail(text);
                          },
                          validator: (string) {
                            if (string == null || string.isEmpty) {
                              return "Email is Required..!";
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            suffixIcon: isEmailValid
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : const Icon(Icons.error, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Enter Other Details',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _taxIdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Tax Identification No.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
              const SizedBox(height: 24),
              Consumer<WarehouseProvider>(
                builder: (context, locationProvider, child) {
                  return Row(
                    children: [
                      Checkbox(
                        value: locationProvider.copyAddress,
                        onChanged: (bool? value) {
                          locationProvider.updateCopyAddress(value ?? false);
                          copyAddress(value ?? false);
                        },
                      ),
                      const Text(
                        'Shipping Address same as Billing Address?',
                        style: TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildBillingAddress(),
              if (locationProvider.copyAddress) ...[const SizedBox(height: 16), _buildShippingAddress()],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Warehouse Type',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                          const SizedBox(height: 8),
                        CustomDropdown(
                          option: locationProvider.locationTypes,
                          selectedIndex: locationProvider.selectedLocationTypeIndex,
                          onSelectedChanged: (locationType) {
                            locationProvider.selectLocationType(locationType);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        labelWithRequiredSymbol('Warehouse Pincode'),
                        const SizedBox(height: 8),
                        TextFormField(
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          controller: _warehousePincodeController,
                          decoration: InputDecoration(
                            labelText: 'Warehouse Pincode',
                            hintText: 'Warehouse Pincode',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Warehouse Pincode';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8),
              if (isSuperAdmin == true) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _isPrimary,
                      onChanged: (bool? value) {
                        setState(() {
                          _isPrimary = value ?? false;
                        });
                      },
                    ),
                    labelWithRequiredSymbol('Is Primary Location'),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              labelWithRequiredSymbol('Pincodes'),
              const SizedBox(height: 8),
              Column(
                children: [
                  ..._pincodeList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: SizedBox(
                        width: 400,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                controller: data.controller,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Pincode',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty ? 'Please enter start pincode' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed:
                                  _pincodeList.length > 1 ? () => setState(() => _pincodeList.removeAt(index)) : null,
                            )
                          ],
                        ),
                      ),
                    );
                  }),
                  ElevatedButton(
                    onPressed: () => setState(() => _pincodeList.add(PincodeData())),
                    child: const Text('Add Pincode'),
                  ),
                ],
              ),
              if (locationProvider.validationMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    locationProvider.validationMessage!,
                    style: const TextStyle(
                      color: AppColors.cardsred,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomButton(
                    width: 120,
                    height: 40,
                    onTap: () {
                      locationProvider.resetForm();
                      _pincodeController.clear();

                      if (locationProvider.isEditingLocation) {
                        locationProvider.toggleEditingLocation();
                      } else if (locationProvider.isCreatingNewLocation) {
                        locationProvider.toggleCreatingNewLocation();
                      }
                    },
                    color: AppColors.grey,
                    textColor: AppColors.white,
                    fontSize: 14,
                    text: 'Cancel',
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(width: 16),
                  CustomButton(
                    width: 140,
                    height: 40,
                    onTap: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        Utils.showLoadingDialog(context, 'Create Warehouse');

                        copyAddress(locationProvider.copyAddress);

                        final body = {
                          'name': _warehouseNameController.text.trim(),
                          'email': _userEmailController.text.trim(),
                          'location': {
                            'otherDetails': {
                              'taxIdentificationNumber': int.tryParse(_taxIdController.text.trim()) ?? 0,
                            },
                            'billingAddress': {
                              'addressLine1': _billingAddress1Controller.text.trim(),
                              'addressLine2': _billingAddress2Controller.text.trim(),
                              'country': _billingCountryController.text.trim(),
                              'country_code': _billingCountryCodeController.text.trim(),
                              'state': _billingStateController.text.trim(),
                              'city': _billingCityController.text.trim(),
                              'zipCode': int.tryParse(_billingZipCodeController.text.trim()) ?? 0,
                              'phoneNumber': int.tryParse(_billingPhoneNumberController.text.trim()) ?? 0,
                            },
                            'shippingAddress': {
                              'addressLine1': _shippingAddress1Controller.text.trim(),
                              'addressLine2': _shippingAddress2Controller.text.trim(),
                              'country': _shippingCountryController.text.trim(),
                              'country_code': _shippingCountryCodeController.text.trim(),
                              'state': _shippingStateController.text.trim(),
                              'city': _shippingCityController.text.trim(),
                              'zipCode': int.tryParse(_shippingZipCodeController.text.trim()) ?? 0,
                              'phoneNumber': int.tryParse(_shippingPhoneNumberController.text.trim()) ?? 0,
                            },
                            'locationType': locationProvider.selectedLocationTypeIndex.toString(),
                          },
                          "pinCodes": _pincodeList.map((pincode) => pincode.controller.text.trim()).toList(),
                          "isPrimary": _isPrimary,
                          'warehouse_id': ''
                        };

                        log('Create Warehouse Payload: $body');

                        final success = await locationProvider.createWarehouse(body);

                        Navigator.pop(context);

                        Utils.showSnackBar(
                            context, success ? 'Warehouse created successfully' : 'Failed to create warehouse',
                            color: success ? AppColors.cardsgreen : AppColors.cardsred);

                        if (success) {
                          locationProvider.fetchWarehouses();
                          // _formKey.currentState?.reset();
                          locationProvider.toggleCreatingNewLocation();
                        }
                      }
                    },
                    color: AppColors.primaryBlue,
                    textColor: AppColors.white,
                    fontSize: 14,
                    text: locationProvider.isEditingLocation ? 'Update Location' : 'Save Location',
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillingAddress() {
    return Column(
      children: [
        Row(
          children: [
            labelWithRequiredSymbol('Billing Address'),
            const SizedBox(width: 8),
            const Text("(Enter the pincode only. We'll fetch the address for you.)",
                style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _billingAddress1Controller,
          validator: (string) {
            if (string == null || string.isEmpty) {
              return "Address is Required..!";
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: 'Address Line 1',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _billingAddress2Controller,
          decoration: InputDecoration(
            labelText: 'Address Line 2',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: TextFormField(
                controller: _billingZipCodeController,
                validator: (string) {
                  if (string == null || string.isEmpty) {
                    return "ZIP/Postal Code is Required..!";
                  }
                  return null;
                },
                onChanged: (string) {
                  if (string.length == 6) {
                    getLocationDetails(context: context, pincode: string, isBilling: true);
                  }
                },
                onFieldSubmitted: (string) {
                  getLocationDetails(context: context, pincode: string, isBilling: true);
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: 'ZIP Code/Postal Code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: TextFormField(
                controller: _billingCountryCodeController,
                validator: (string) {
                  if (string == null || string.isEmpty) {
                    return "Country Code is Required..!";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Country Code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 2,
              child: TextFormField(
                controller: _billingCountryController,
                validator: (string) {
                  if (string == null || string.isEmpty) {
                    return "Country is Required..!";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Country',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: TextFormField(
                controller: _billingStateController,
                validator: (string) {
                  if (string == null || string.isEmpty) {
                    return "State is Required..!";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: TextFormField(
                controller: _billingCityController,
                validator: (string) {
                  if (string == null || string.isEmpty) {
                    return "City is Required..!";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: TextFormField(
                controller: _billingPhoneNumberController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                maxLength: 13,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShippingAddress() {
    return Column(
      children: [
        Row(
          children: [
            labelWithRequiredSymbol('Shipping Address'),
            const SizedBox(width: 8),
            const Text("(Enter the pincode only. We'll fetch the address for you.)",
                style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _shippingAddress1Controller,
          validator: (string) {
            if (string == null || string.isEmpty) {
              return "Address is Required..!";
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: 'Address Line 1',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _shippingAddress2Controller,
          decoration: InputDecoration(
            labelText: 'Address Line 2',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: TextFormField(
                controller: _shippingZipCodeController,
                validator: (string) {
                  if (string == null || string.isEmpty) {
                    return "ZIP/Postal Code is Required..!";
                  }
                  return null;
                },
                onChanged: (string) {
                  if (string.length == 6) {
                    getLocationDetails(context: context, pincode: string, isBilling: false);
                  }
                },
                onFieldSubmitted: (string) {
                  getLocationDetails(context: context, pincode: string, isBilling: false);
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: 'ZIP Code/Postal Code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: TextFormField(
                controller: _shippingCountryCodeController,
                validator: (string) {
                  if (string == null || string.isEmpty) {
                    return "Country Code is Required..!";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Country Code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 2,
              child: TextFormField(
                controller: _shippingCountryController,
                validator: (string) {
                  if (string == null || string.isEmpty) {
                    return "Country is Required..!";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Country',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: TextFormField(
                controller: _shippingStateController,
                validator: (string) {
                  if (string == null || string.isEmpty) {
                    return "State is Required..!";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: TextFormField(
                controller: _shippingCityController,
                validator: (string) {
                  if (string == null || string.isEmpty) {
                    return "City is Required..!";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: TextFormField(
                controller: _shippingPhoneNumberController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                maxLength: 13,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget labelWithRequiredSymbol(String text) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          ' *',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void clearLocationDetails({bool isBilling = true}) {
    if (isBilling) {
      _billingCountryController.clear();
      _billingStateController.clear();
      _billingCityController.clear();
      _billingCountryCodeController.clear();
    } else {
      _shippingCountryController.clear();
      _shippingStateController.clear();
      _shippingCityController.clear();
      _shippingCountryCodeController.clear();
    }
  }

  Future<void> getLocationDetails(
      {required BuildContext context, required String pincode, bool isBilling = true}) async {
    Utils.showLoadingDialog(context, 'Fetching Address');

    try {
      Uri url =
          Uri.parse('https://api.opencagedata.com/geocode/v1/json?q=$pincode&key=55710109e7c24fbc98c86377005c0612');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = await jsonDecode(response.body);

        if (data['results'] != null && data['results'].isNotEmpty) {
          final components = data['results'][0]['components'];

          log('Components - $components');

          String country = components['country'] ?? '';
          String state = components['state'] ?? '';
          String city =
              components['city_district'] ?? components['state_district'] ?? components['_normalized_city'] ?? '';
          String countryCode = components['country_code'].toString().toUpperCase() ?? '';

          if (isBilling) {
            _billingCountryController.text = country;
            _billingStateController.text = state;
            _billingCityController.text = city;
            _billingCountryCodeController.text = countryCode;
          } else {
            _shippingCountryController.text = country;
            _shippingStateController.text = state;
            _shippingCityController.text = city;
            _shippingCountryCodeController.text = countryCode;
          }

          setState(() {});
        } else {
          log('No location details found for the provided pincode :- ${response.body}');
          Utils.showSnackBar(context, 'No location details found for the provided pincode.', isError: true);
          clearLocationDetails(isBilling: isBilling);
        }
      } else {
        log('Failed to load location details :- ${response.body}');
        Utils.showSnackBar(context, 'Failed to load location details', isError: true);
        clearLocationDetails(isBilling: isBilling);
      }
    } catch (e, stace) {
      log('Error to fetch location details :- $e\n$stace');
      Utils.showSnackBar(context, 'Failed to load location details', details: e.toString(), isError: true);
      clearLocationDetails(isBilling: isBilling);
    } finally {
      Navigator.pop(context);
    }
  }
}

class PincodeData {
  final TextEditingController controller = TextEditingController();
  // final TextEditingController endController = TextEditingController();
  // final TextEditingController cityController = TextEditingController();

  Map<String, dynamic> toJson() => {'pincode': controller.text.trim()};
}
