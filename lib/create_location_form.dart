import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_management/Custom-Files/custom-dropdown.dart';
import 'package:provider/provider.dart';
import 'package:inventory_management/provider/location_provider.dart';
import 'package:inventory_management/Custom-Files/custom-button.dart';
import 'package:inventory_management/Custom-Files/colors.dart';

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
  final _formKey = GlobalKey<FormState>();

  final _warehouseNameController = TextEditingController();
  final _warehouseIDController = TextEditingController();
  final _userEmailController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _billingAddress1Controller = TextEditingController();
  final _billingAddress2Controller = TextEditingController();
  final _billingCountryController = TextEditingController();
  final _billingStateController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _shippingAddress1Controller = TextEditingController();
  final _shippingAddress2Controller = TextEditingController();
  final _shippingCountryController = TextEditingController();
  final _shippingStateController = TextEditingController();
  final _shippingCityController = TextEditingController();
  final _shippingZipCodeController = TextEditingController();
  final _shippingPhoneNumberController = TextEditingController();
  final _warehousePincodeController = TextEditingController();
  final _pincodeController = TextEditingController();

  final bool holdStock = true;
  final bool copyStock = true;

  @override
  void initState() {
    super.initState();

    // _userEmailController.addListener(_onEmailChanged);

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final locationProvider =
    //       Provider.of<LocationProvider>(context, listen: false);

    //   if (widget.isEditing && widget.warehouseData != null) {
    //     //print("1");
    //     //print("Data loaded in form - ${widget.warehouseData}");
    //     _warehouseNameController.text = widget.warehouseData!['name'] ?? '';
    //     _userEmailController.text = widget.warehouseData!['userEmail'] ??
    //         ''; // Adjust based on your data
    //     _taxIdController.text = widget.warehouseData!['location']
    //                 ['otherDetails']?['taxIdentificationNumber']
    //             ?.toString() ??
    //         '';

    //     _billingAddress1Controller.text = widget.warehouseData!['location']
    //             ['billingAddress']['addressLine1'] ??
    //         '';
    //     _billingAddress2Controller.text = widget.warehouseData!['location']
    //             ['billingAddress']['addressLine2'] ??
    //         '';

    //     final billingAddress =
    //         widget.warehouseData!['location']['billingAddress'];

    //     // Get country index based on warehouseData
    //     final selectedBillingCountryIndex =
    //         locationProvider.countries.indexWhere(
    //       (country) => country['name'] == billingAddress['country'],
    //     );
    //     if (selectedBillingCountryIndex != -1) {
    //       locationProvider.selectBillingCountry(selectedBillingCountryIndex);
    //     }

    //     // Get state index based on warehouseData
    //     final selectedBillingStateIndex = locationProvider.states.indexWhere(
    //       (state) => state['name'] == billingAddress['state'],
    //     );
    //     if (selectedBillingStateIndex != -1) {
    //       locationProvider.selectBillingState(selectedBillingStateIndex);
    //     }

    //     final shippingAddress =
    //         widget.warehouseData!['location']['shippingAddress'];

    //     // Get country index based on warehouseData
    //     final selectedShippingCountryIndex =
    //         locationProvider.countries.indexWhere(
    //       (country) => country['name'] == shippingAddress['country'],
    //     );
    //     if (selectedShippingCountryIndex != -1) {
    //       locationProvider.selectShippingCountry(selectedShippingCountryIndex);
    //     }

    //     // Get state index based on warehouseData
    //     final selectedShippingStateIndex = locationProvider.states.indexWhere(
    //       (state) => state['name'] == shippingAddress['state'],
    //     );
    //     if (selectedShippingStateIndex != -1) {
    //       locationProvider.selectShippingState(selectedShippingStateIndex);
    //       // }

    //       // Get location type index based on warehouseData
    //       final selectedLocationTypeIndex =
    //           locationProvider.locationTypes.indexWhere(
    //         (type) =>
    //             type['name'] ==
    //             widget.warehouseData!['location']['locationType'],
    //       );
    //       if (selectedLocationTypeIndex != -1) {
    //         locationProvider.selectLocationType(selectedLocationTypeIndex);
    //       }

    //       _cityController.text =
    //           widget.warehouseData!['location']['billingAddress']['city'] ?? '';
    //       _zipCodeController.text = widget.warehouseData!['location']
    //                   ['billingAddress']['zipCode']
    //               ?.toString() ??
    //           '';
    //       _phoneNumberController.text = widget.warehouseData!['location']
    //                   ['billingAddress']['phoneNumber']
    //               ?.toString() ??
    //           '';
    //       _shippingAddress1Controller.text = widget.warehouseData!['location']
    //               ['shippingAddress']['addressLine1'] ??
    //           '';
    //       _shippingAddress2Controller.text = widget.warehouseData!['location']
    //               ['shippingAddress']['addressLine2'] ??
    //           '';
    //       _shippingCityController.text = widget.warehouseData!['location']
    //               ['shippingAddress']['city'] ??
    //           '';
    //       _shippingZipCodeController.text = widget.warehouseData!['location']
    //                   ['shippingAddress']['zipCode']
    //               ?.toString() ??
    //           '';
    //       _shippingPhoneNumberController.text = widget
    //               .warehouseData!['location']['shippingAddress']['phoneNumber']
    //               ?.toString() ??
    //           '';
    //       _warehousePincodeController.text =
    //           widget.warehouseData!['warehousePincode']?.toString() ?? '';
    //       _pincodeController.text = (widget
    //                   .warehouseData!['pincode']?.isNotEmpty ==
    //               true)
    //           ? widget.warehouseData!['pincode'][0]
    //               .toString() // Just an example, modify according to your needs
    //           : '';

    //       // // Prefill holdsStock
    //       // locationProvider
    //       //     .updateHoldsStock(widget.warehouseData!['holdStocks'] ?? false);

    //       // // Prefill copyStock
    //       // locationProvider.updateCopysku(
    //       //     widget.warehouseData!['copyMasterSkuFromPrimary'] ?? false);
    //     }
    //   }
    // });
  }

  @override
  void dispose() {
    _warehouseNameController.dispose();
    _userEmailController.dispose();
    _taxIdController.dispose();
    _billingAddress1Controller.dispose();
    _billingAddress2Controller.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    _phoneNumberController.dispose();
    _shippingAddress1Controller.dispose();
    _shippingAddress2Controller.dispose();
    _shippingCityController.dispose();
    _shippingZipCodeController.dispose();
    _shippingPhoneNumberController.dispose();
    _warehousePincodeController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  // void _onEmailChanged() {
  //   // Notify the provider whenever the email changes
  //   Provider.of<LocationProvider>(context, listen: false)
  //       .validateEmail(_userEmailController.text);
  // }

  // Add to state class
  final List<PincodeData> _pincodeList = [PincodeData()];
  bool _isPrimary = false;

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final isWideScreen = MediaQuery.of(context).size.width > 800;
    // String? errorMessage;
    final isEmailValid = Provider.of<LocationProvider>(context).isEmailValid;

    // print(
    //     "Selected Billing Country Index in UI: ${locationProvider.selectedBillingCountryIndex}");

    return Expanded(
      child: SingleChildScrollView(
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
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.primaryBlue), // Back icon
                      onPressed: () {
                        locationProvider.resetForm();
                        _pincodeController.clear();
                        // Check current mode and toggle accordingly
                        if (locationProvider.isEditingLocation) {
                          locationProvider
                              .toggleEditingLocation(); // Turn off editing mode
                        } else if (locationProvider.isCreatingNewLocation) {
                          locationProvider
                              .toggleCreatingNewLocation(); // Turn off creating mode
                        }
                      },
                    ),
                    const SizedBox(width: 8), // Space between icon and text
                    Text(
                      locationProvider.isEditingLocation
                          ? 'Edit Location'
                          : 'New Location',
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isWideScreen)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Warehouse ID',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // labelWithRequiredSymbol('Warehouse ID'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _warehouseIDController,
                              decoration: InputDecoration(
                                labelText: 'Warehouse ID',
                                hintText: 'Warehouse ID',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                              ),
                              // validator: (value) {
                              //   if (value == null || value.isEmpty) {
                              //     return 'Please enter warehouse ID';
                              //   }
                              //   return null;
                              // },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
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
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // labelWithRequiredSymbol('User Email'),
                            const Text(
                              'User Email',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextFormField(
                              controller: _userEmailController,
                              onChanged: (text) {
                                Provider.of<LocationProvider>(context,
                                        listen: false)
                                    .validateEmail(text);
                              },
                              decoration: InputDecoration(
                                labelText: 'User Email',
                                hintText: 'User Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                                suffixIcon: isEmailValid
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.green)
                                    : const Icon(Icons.error,
                                        color: Colors.red),
                              ),
                              // validator: (value) {
                              //   if (value == null || value.isEmpty) {
                              //     return 'Please enter user email';
                              //   }
                              //   // Basic email validation is handled by the provider
                              //   return isEmailValid
                              //       ? null
                              //       : 'Please enter a valid email address';
                              // },
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  Column(
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
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // labelWithRequiredSymbol('User Email'),
                      const Text(
                        'User Email',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _userEmailController,
                        decoration: InputDecoration(
                          labelText: 'User Email',
                          hintText: 'User Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          suffixIcon: isEmailValid
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : const Icon(Icons.error, color: Colors.red),
                        ),
                        // validator: (value) {
                        //   if (value == null || value.isEmpty) {
                        //     return 'Please enter user email';
                        //   }
                        //   // Basic email validation is handled by the provider
                        //   return isEmailValid
                        //       ? null
                        //       : 'Please enter a valid email address';
                        // },
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                // labelWithRequiredSymbol('Enter Other Details'),
                const Text(
                  'Enter Other Details',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Divider(
                  color: Colors.grey.shade400,
                  thickness: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _taxIdController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Tax Identification No.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'Please enter tax identification number';
                  //   }
                  //   if (value.length != 11) {
                  //     return 'Tax identification number must be 11 digits';
                  //   }
                  //   return null;
                  // },
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                const SizedBox(height: 24),
                // labelWithRequiredSymbol('Billing Address'),
                const Text(
                  'Billing Address',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Divider(
                  color: Colors.grey.shade400,
                  thickness: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _billingAddress1Controller,
                  decoration: InputDecoration(
                    labelText: 'Address Line 1',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'Please enter billing address line 1';
                  //   }
                  //   return null;
                  // },
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
                TextFormField(
                  controller: _billingCountryController,
                  decoration: InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // CustomDropdown(
                //   option: locationProvider.countries,
                //   selectedIndex: locationProvider.selectedBillingCountryIndex,
                //   onSelectedChanged: (country) {
                //     locationProvider.selectBillingCountry(country);
                //   },
                // ),
                // const Text(
                //   'State',
                //   style: TextStyle(
                //     fontSize: 13,
                //     color: AppColors.black,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                // const SizedBox(height: 8),
                // CustomDropdown(
                //   option: locationProvider.states,
                //   selectedIndex: locationProvider.selectedBillingStateIndex,
                //   onSelectedChanged: (state) {
                //     locationProvider.selectBillingState(state);
                //   },
                // ),
                TextFormField(
                  controller: _billingStateController,
                  decoration: InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'Please enter city';
                  //   }
                  //   return null;
                  // },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _zipCodeController,
                  decoration: InputDecoration(
                    labelText: 'ZIP Code/Postal Code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'Please enter ZIP/Postal code';
                  //   }
                  //   return null;
                  // },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'Please enter phone number';
                  //   }
                  //   return null;
                  // },
                ),
                const SizedBox(height: 24),
                Consumer<LocationProvider>(
                  builder: (context, locationProvider, child) {
                    return Row(
                      children: [
                        Checkbox(
                          value: locationProvider.copyAddress,
                          onChanged: (bool? value) {
                            locationProvider.updateCopyAddress(value ?? false);

                            if (value == true) {
                              // Copy billing address to shipping address and update controllers
                              _shippingAddress1Controller.text =
                                  _billingAddress1Controller.text;
                              _shippingAddress2Controller.text =
                                  _billingAddress2Controller.text;
                              _shippingCityController.text =
                                  _cityController.text;
                              _shippingZipCodeController.text =
                                  _zipCodeController.text;
                              _shippingPhoneNumberController.text =
                                  _phoneNumberController.text;

                              // Notify provider to update any additional state
                              locationProvider.updateShippingAddress(
                                address1: _billingAddress1Controller.text,
                                address2: _billingAddress2Controller.text,
                                city: _cityController.text,
                                zipCode: _zipCodeController.text,
                                phoneNumber: _phoneNumberController.text,
                              );
                            } else {
                              // Clear shipping address fields and controllers if unchecked
                              _shippingAddress1Controller.clear();
                              _shippingAddress2Controller.clear();
                              _shippingCityController.clear();
                              _shippingZipCodeController.clear();
                              _shippingPhoneNumberController.clear();

                              locationProvider.updateShippingAddress(
                                address1: '',
                                address2: '',
                                city: '',
                                zipCode: '',
                                phoneNumber: '',
                              );
                            }
                          },
                        ),
                        const Text(
                          'Copy Billing Address to Shipping Address',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                // labelWithRequiredSymbol('Shipping Address'),
                const Text(
                  'Shipping Address',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Divider(
                  color: Colors.grey.shade400,
                  thickness: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _shippingAddress1Controller,
                  decoration: InputDecoration(
                    labelText: 'Address Line 1',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'Please enter shipping address line 1';
                  //   }
                  //   return null;
                  // },
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
                TextFormField(
                  controller: _shippingCountryController,
                  decoration: InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                // const Text(
                //   'Country',
                //   style: TextStyle(
                //     fontSize: 13,
                //     color: AppColors.black,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                // const SizedBox(height: 8),
                // CustomDropdown(
                //   option: locationProvider.countries,
                //   selectedIndex: locationProvider.selectedShippingCountryIndex,
                //   onSelectedChanged: (country) {
                //     locationProvider.selectShippingCountry(country);
                //   },
                // ),
                const SizedBox(height: 16),
                // const Text(
                //   'State',
                //   style: TextStyle(
                //     fontSize: 13,
                //     color: AppColors.black,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                // const SizedBox(height: 8),
                // CustomDropdown(
                //     option: locationProvider.states,
                //     selectedIndex: locationProvider.selectedShippingStateIndex,
                //     onSelectedChanged: (state) {
                //       locationProvider.selectShippingState(state);
                //     }),
                TextFormField(
                  controller: _shippingStateController,
                  decoration: InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _shippingCityController,
                  decoration: InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'Please enter shipping city';
                  //   }
                  //   return null;
                  // },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _shippingZipCodeController,
                  decoration: InputDecoration(
                    labelText: 'ZIP Code/Postal Code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'Please enter shipping ZIP/Postal code';
                  //   }
                  //   return null;
                  // },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _shippingPhoneNumberController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'Please enter shipping phone number';
                  //   }
                  //   return null;
                  // },
                ),
                const SizedBox(height: 16),
                Divider(
                  color: Colors.grey.shade400,
                  thickness: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Warehouse Type',
                  style: TextStyle(
                    fontSize: 13,
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
                // const SizedBox(height: 16),
                // labelWithRequiredSymbol('Holds Stock'),
                // const Text(
                //   'Holds Stock',
                //   style: TextStyle(
                //     fontSize: 14,
                //     color: AppColors.black,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                // Row(
                //   children: [
                //     const Text("Yes"),
                //     Radio<String>(
                //       value: "Yes",
                //       groupValue: locationProvider.holdsStock == null
                //           ? null
                //           : locationProvider.holdsStock!
                //               ? "Yes"
                //               : "No",
                //       onChanged: (String? value) {
                //         locationProvider.updateHoldsStock(value);
                //       },
                //     ),
                //     const Text("No"),
                //     Radio<String>(
                //       value: "No",
                //       groupValue: locationProvider.holdsStock == null
                //           ? null
                //           : locationProvider.holdsStock!
                //               ? "Yes"
                //               : "No",
                //       onChanged: (String? value) {
                //         locationProvider.updateHoldsStock(value);
                //       },
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 16),
                // // labelWithRequiredSymbol('Copy Master SKU from Primary'),
                // const Text(
                //   'Copy Master SKU from Primary',
                //   style: TextStyle(
                //     fontSize: 14,
                //     color: AppColors.black,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                // Row(
                //   children: [
                //     const Text("Yes"),
                //     Radio<String>(
                //       value: "Yes",
                //       groupValue: locationProvider.copysku == null
                //           ? null
                //           : locationProvider.copysku!
                //               ? "Yes"
                //               : "No",
                //       onChanged: (String? value) {
                //         locationProvider.updateCopysku(value);
                //       },
                //     ),
                //     const Text("No"),
                //     Radio<String>(
                //       value: "No",
                //       groupValue: locationProvider.copysku == null
                //           ? null
                //           : locationProvider.copysku!
                //               ? "Yes"
                //               : "No",
                //       onChanged: (String? value) {
                //         locationProvider.updateCopysku(value);
                //       },
                //     ),
                //   ],
                // ),
                const SizedBox(height: 16),
                // const Text(
                //   'Warehouse Pincode',
                //   style: TextStyle(
                //     fontSize: 14,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                labelWithRequiredSymbol('Warehouse Pincode'),
                const SizedBox(height: 8),
                TextFormField(
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
                    // const Text('Is Primary Location'),
                    labelWithRequiredSymbol('Is Primary Location'),
                  ],
                ),

                const SizedBox(height: 16),
                labelWithRequiredSymbol('Pincodes'),
                // const Text(
                //   'Pincodes',
                //   style: TextStyle(
                //     fontSize: 14,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    ..._pincodeList.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: data.startController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Start Pincode',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? 'Please enter start pincode'
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: data.endController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'End Pincode',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? 'Please enter end pincode'
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: data.cityController,
                                decoration: const InputDecoration(
                                  labelText: 'City',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? 'Please enter city'
                                        : null,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: _pincodeList.length > 1
                                  ? () => setState(
                                      () => _pincodeList.removeAt(index))
                                  : null,
                            )
                          ],
                        ),
                      );
                    }),
                    ElevatedButton(
                      onPressed: () =>
                          setState(() => _pincodeList.add(PincodeData())),
                      child: const Text('Add Pincode Range'),
                    ),
                  ],
                ),
                // SizedBox(
                //   width: 250,
                //   child: Row(
                //     children: [
                //       Expanded(
                //         child: TextField(
                //           controller: _pincodeController,
                //           decoration: InputDecoration(
                //             hintText: 'Enter Pincode',
                //             border: OutlineInputBorder(
                //               borderRadius: BorderRadius.circular(8),
                //             ),
                //             suffixIcon: IconButton(
                //               icon:
                //                   const Icon(Icons.add, color: AppColors.green),
                //               onPressed: () {
                //                 locationProvider
                //                     .addPincode(_pincodeController.text);
                //                 _pincodeController.clear();
                //               },
                //             ),
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
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
                // Wrap(
                //   spacing: 8,
                //   children: locationProvider.pincodes.map((pincode) {
                //     final index = locationProvider.pincodes.indexOf(pincode);
                //     return GestureDetector(
                //       child: Chip(
                //         elevation: 4,
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(12),
                //           side: const BorderSide(
                //             color: Colors.green,
                //             width: 2,
                //           ),
                //         ),
                //         backgroundColor: AppColors.white,
                //         label: Text(
                //           pincode,
                //           style: const TextStyle(
                //               color: Colors.black, fontWeight: FontWeight.bold),
                //         ),
                //         deleteIcon: const Icon(Icons.delete_outline,
                //             color: AppColors.cardsred),
                //         onDeleted: () {
                //           locationProvider.removePincode(index);
                //           ScaffoldMessenger.of(context).showSnackBar(
                //             SnackBar(content: Text('Pincode $pincode removed')),
                //           );
                //         },
                //         avatar: const CircleAvatar(
                //           backgroundColor: AppColors.green,
                //           child: Icon(Icons.pin_drop, color: AppColors.white),
                //         ),
                //       ),
                //     );
                //   }).toList(),
                // ),
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
                        // Check current mode and toggle accordingly
                        if (locationProvider.isEditingLocation) {
                          locationProvider
                              .toggleEditingLocation(); // Turn off editing mode
                        } else if (locationProvider.isCreatingNewLocation) {
                          locationProvider
                              .toggleCreatingNewLocation(); // Turn off creating mode
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
                      // Within the onTap method of the Save Location button:
                      onTap: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          final body = {
                            'name': _warehouseNameController.text,
                            'email': _userEmailController.text,
                            'location': {
                              'otherDetails': {
                                'taxIdentificationNumber':
                                    int.tryParse(_taxIdController.text) ?? 0,
                              },
                              // Billing address
                              'billingAddress': {
                                'addressLine1': _billingAddress1Controller.text,
                                'addressLine2': _billingAddress2Controller.text,
                                'country':
                                    _billingCountryController.text.toString() ??
                                        '',
                                'state':
                                    _billingStateController.text.toString() ??
                                        '',
                                'city': _cityController.text,
                                'zipCode':
                                    int.tryParse(_zipCodeController.text) ?? 0,
                                'phoneNumber':
                                    int.tryParse(_phoneNumberController.text) ??
                                        0,
                              },
                              // Shipping address
                              'shippingAddress': {
                                'addressLine1':
                                    _shippingAddress1Controller.text,
                                'addressLine2':
                                    _shippingAddress2Controller.text,
                                'country': _shippingCountryController.text
                                        .toString() ??
                                    '',
                                'state':
                                    _shippingStateController.text.toString() ??
                                        '',
                                'city': _shippingCityController.text,
                                'zipCode': int.tryParse(
                                        _shippingZipCodeController.text) ??
                                    0,
                                'phoneNumber': int.tryParse(
                                        _shippingPhoneNumberController.text) ??
                                    0,
                              },
                              // Other fields
                              'locationType': locationProvider
                                      .selectedLocationTypeIndex
                                      .toString() ??
                                  '',
                              // 'holdStocks':
                              //     locationProvider.holdsStock ?? false,
                              // 'copyMasterSkuFromPrimary':
                              //     locationProvider.copysku ?? false,
                            },
                            "pinCodes": _pincodeList
                                .map((pincode) => pincode.toJson())
                                .toList(),
                            "isPrimary": _isPrimary,
                            'warehouse_id': ''
                          };

                          log('Body: $body');

                          final success =
                              await locationProvider.createWarehouse(body);

                          final snackBar = success
                              ? const SnackBar(
                                  content:
                                      Text('Warehouse created successfully!'),
                                  backgroundColor: Colors.green,
                                )
                              : SnackBar(
                                  content: Text(
                                      'Failed to create warehouse: ${locationProvider.errorMessage}'),
                                  backgroundColor: Colors.red,
                                );

                          ScaffoldMessenger.of(context).showSnackBar(snackBar);

                          if (success) {
                            locationProvider.refreshContent();
                            _formKey.currentState?.reset();
                            locationProvider.toggleCreatingNewLocation();
                          }
                        }
                        // else {
                        //   ScaffoldMessenger.of(context).showSnackBar(
                        //     const SnackBar(
                        //       content:
                        //           Text('Please fill in all required fields.'),
                        //       backgroundColor: Colors.orange,
                        //     ),
                        //   );
                        // }
                      },

                      color: AppColors.primaryGreen,
                      textColor: AppColors.white,
                      fontSize: 14,
                      text: locationProvider.isEditingLocation
                          ? 'Update Location'
                          : 'Save Location',
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 25,
                ),
              ],
            ),
          ),
        ),
      ),
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
}

class PincodeData {
  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  Map<String, dynamic> toJson() => {
        'startPincode': int.parse(startController.text),
        'endPincode': int.parse(endController.text),
        'city': cityController.text
      };
}
