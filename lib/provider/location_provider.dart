// ignore_for_file: avoid_print

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Custom-Files/colors.dart';
import '../dashboard.dart';

class LocationProvider with ChangeNotifier {
  final AuthProvider authProvider;

  LocationProvider({required this.authProvider});

  List<Map<String, dynamic>> _warehouses = [];
  List<Map<String, dynamic>> _filteredWarehouses = [];
  Map<String, dynamic>? warehouseData; // for get warehouse by ID

  List<Map<String, dynamic>> get warehouses => _filteredWarehouses.isNotEmpty ? _filteredWarehouses : _warehouses;

  bool _isCreatingNewLocation = false;
  int _selectedBillingCountryIndex = 0;
  int _selectedBillingStateIndex = 0;
  int _selectedShippingCountryIndex = 0;
  int _selectedShippingStateIndex = 0;
  int _selectedLocationTypeIndex = 0;
  bool? _holdsStock;
  bool? _copysku;
  bool _copyAddress = false;
  int _currentPage = 1;
  int _totalPages = 1;
  final TextEditingController _textEditingController = TextEditingController();

  bool _isEditingLocation = false; // Add this property to track editing state

  bool get isCreatingNewLocation => _isCreatingNewLocation;
  int get selectedBillingCountryIndex => _selectedBillingCountryIndex;
  int get selectedBillingStateIndex => _selectedBillingStateIndex;
  int get selectedShippingCountryIndex => _selectedShippingCountryIndex;
  int get selectedShippingStateIndex => _selectedShippingStateIndex;
  int get selectedLocationTypeIndex => _selectedLocationTypeIndex;
  bool? get holdsStock => _holdsStock;
  bool? get copysku => _copysku;
  bool get copyAddress => _copyAddress;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  TextEditingController get textEditingController => _textEditingController;


  bool get isEditingLocation => _isEditingLocation;

  final List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> get locations => _locations;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? _successMessage;

  List<Map<String, dynamic>> pincodes = [];
  String? validationMessage;

  bool _isEmailValid = false;

  bool get isEmailValid => _isEmailValid;

  void goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    _currentPage = page;
    print('Current page set to: $_currentPage'); // Debugging line
    fetchWarehouses(page: _currentPage);
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners(); // Notify listeners when the state changes
  }

  // Helper methods for handling success and error
  void _setError(String message) {
    _errorMessage = message;
    _successMessage = null;
    notifyListeners();
  }

  void _setSuccess(String message) {
    _successMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  void validateEmail(String email) {
    String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regex = RegExp(pattern);
    _isEmailValid = regex.hasMatch(email);
    notifyListeners();
  }

  void addPincode(List<Map<String, dynamic>> pincode) {
    if (pincode.isEmpty) {
      validationMessage = 'Please enter a pincode';
      notifyListeners();
    } else {
      pincodes = pincode;
      // pincodes.add(pincode);
      validationMessage = null; // Clear validation message
      notifyListeners();
    }
  }

  void removePincode(int index) {
    pincodes.removeAt(index);
    notifyListeners();
  }

  List<Map<String, dynamic>> countries = [
    {'name': 'India'},
    {'name': 'USA'},
    {'name': 'UK'},
    {'name': 'Canada'},
  ];

  List<Map<String, dynamic>> states = [
    {'name': 'Madhya Pradesh'},
    {'name': 'Maharashtra'},
    {'name': 'California'},
    {'name': 'Ontario'},
  ];

  List<Map<String, dynamic>> locationTypes = [
    {'name': 'Warehouse'},
    {'name': 'Retail Store'},
    {'name': 'Distribution Center'},
  ];

  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void toggleCreatingNewLocation() {
    _isCreatingNewLocation = !_isCreatingNewLocation;
    notifyListeners();
  }

  void toggleEditingLocation() {
    _isEditingLocation = !_isEditingLocation;
    notifyListeners();
  }

  void selectBillingCountry(int index) {
    _selectedBillingCountryIndex = index;
    // print(
    //     "selected billing contry index in provider : $_selectedBillingCountryIndex");
    // print("called notifylisteners() after this line");
    notifyListeners();
  }

  void selectBillingState(int index) {
    _selectedBillingStateIndex = index;
    notifyListeners();
  }

  void selectShippingCountry(int index) {
    _selectedShippingCountryIndex = index;
    notifyListeners();
  }

  void selectShippingState(int index) {
    _selectedShippingStateIndex = index;
    notifyListeners();
  }

  void selectLocationType(int index) {
    _selectedLocationTypeIndex = index;
    notifyListeners();
  }

  void updateHoldsStock(String? value) {
    print("Hold Stock Value: $value");
    if (value == "Yes") {
      _holdsStock = true;
    } else if (value == "No") {
      _holdsStock = false;
    } else {
      _holdsStock = null;
    }
    notifyListeners();
  }

  void updateCopysku(String? value) {
    print("Copy SKU Value: $value");
    if (value == "Yes") {
      _copysku = true;
    } else if (value == "No") {
      _copysku = false;
    } else {
      _copysku = null;
    }
    notifyListeners();
  }

  void updateCopyAddress(bool value) {
    _copyAddress = value;
    notifyListeners();
  }

  void addLocation(Map<String, dynamic> newLocation) {
    _locations.add(newLocation);
    notifyListeners();
  }

  Future<void> saveWarehouseData(BuildContext context, String warehouseId, String warehouseName, bool isPrimary) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('warehouseId', warehouseId);
    await prefs.setString('warehouseName', warehouseName);
    await prefs.setBool('isPrimary', isPrimary);

    log('warehouseId: $warehouseId');
    log('warehouseName: $warehouseName');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully signed in to $warehouseName'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
    }
  }

  Future<void> fetchWarehouses({int page = 1}) async {
    _isLoading = true;
    notifyListeners();

    final result = await getAllWarehouses(page: page);

    if (result['success']) {
      final warehousesData = result['data']?['warehouses'] ?? [];
      _totalPages = result['totalPages'];

      if (warehousesData is List && warehousesData.isNotEmpty) {
        _warehouses = List<Map<String, dynamic>>.from(warehousesData);
      } else {
        _setError('Unexpected data format');
      }
    } else {
      _setError('Error fetching warehouses');
    }

    _isLoading = false;
    notifyListeners();
  }

  void refreshContent() async {
    await fetchWarehouses();
    notifyListeners();
  }

  // Shipping address fields
  String? _shippingAddress1;
  String? _shippingAddress2;
  String? _shippingCity;
  String? _shippingZipCode;
  String? _shippingPhoneNumber;

  String? get shippingAddress1 => _shippingAddress1;
  String? get shippingAddress2 => _shippingAddress2;
  String? get shippingCity => _shippingCity;
  String? get shippingZipCode => _shippingZipCode;
  String? get shippingPhoneNumber => _shippingPhoneNumber;

  void updateShippingAddress({
    String? address1,
    String? address2,
    String? city,
    String? zipCode,
    String? phoneNumber,
  }) {
    _shippingAddress1 = address1;
    _shippingAddress2 = address2;
    _shippingCity = city;
    _shippingZipCode = zipCode;
    _shippingPhoneNumber = phoneNumber;
    print("Shipping Address Updated: $_shippingAddress1, $_shippingCity, $_shippingZipCode, $_shippingPhoneNumber");
    notifyListeners();
  }

  Future<Map<String, dynamic>> getAllWarehouses({int page = 1}) async {
    return await authProvider.getAllWarehouses(page: page);
  }

  Future<bool> createWarehouse(Map<String, dynamic> body) async {
    try {
      final taxIdentificationNumber = body['taxIdentificationNumber'] is int
          ? body['taxIdentificationNumber'] as int
          : int.tryParse(body['taxIdentificationNumber'].toString()) ?? 0;

      final holdStocks = body['holdStocks'] is bool ? body['holdStocks'] as bool : body['holdStocks'] == 'true';

      final copyMasterSkuFromPrimary =
          body['copyMasterSkuFromPrimary'] is bool ? body['copyMasterSkuFromPrimary'] as bool : body['copyMasterSkuFromPrimary'] == 'true';

      // Extract pincodes from location if available
      final List<String> pincodes = body['pincode'] is List<String> ? List<String>.from(body['pincode']) : [];

      final response = await authProvider.createWarehouse(warehouseData: body);
      // final response = await authProvider.createWarehouse(
      //   name: location['name'] as String,
      //   email: location['email'] as String,
      //   taxIdentificationNumber: taxIdentificationNumber,
      //   billingAddressLine1:
      //       location['billingAddress']['addressLine1'] as String,
      //   billingAddressLine2:
      //       location['billingAddress']['addressLine2'] as String,
      //   billingCountry: countries[_selectedBillingCountryIndex]['name'],
      //   billingState: states[_selectedBillingStateIndex]['name'],
      //   billingCity: location['billingAddress']['city'] as String,
      //   billingZipCode: location['billingAddress']['zipCode'] as int,
      //   billingPhoneNumber: location['billingAddress']['phoneNumber'] as int,
      //   shippingAddressLine1:
      //       location['shippingAddress']['addressLine1'] as String,
      //   shippingAddressLine2:
      //       location['shippingAddress']['addressLine2'] as String,
      //   shippingCountry: countries[_selectedShippingCountryIndex]['name'],
      //   shippingState: states[_selectedShippingStateIndex]['name'],
      //   shippingCity: location['shippingAddress']['city'] as String,
      //   shippingZipCode: location['shippingAddress']['zipCode'] as int,
      //   shippingPhoneNumber: location['shippingAddress']['phoneNumber'] as int,
      //   locationType: locationTypes[_selectedLocationTypeIndex]['name'],
      //   holdStocks: holdStocks,
      //   copyMasterSkuFromPrimary: copyMasterSkuFromPrimary,
      //   pincodes: pincodes,
      //   warehousePincode: location['warehousePincode'] as int,
      // );

      if (response['success']) {
        _setSuccess('Warehouse created successfully!');
        return true;
      } else {
        _setError(response['message'] ?? 'Failed to create warehouse.');
        print('Error while creating warehouse: $_errorMessage');
        return false;
      }
    } catch (e) {
      _setError('An error occurred: $e');
      print('Error while creating warehouse: $e');
      return false;
    }
  }

  // Filtered warehouses
  void filterWarehouses(String query) {
    if (query.isEmpty) {
      _filteredWarehouses.clear();
    } else {
      _filteredWarehouses = _warehouses.where((warehouse) {
        final name = warehouse['name']?.toLowerCase() ?? '';
        final email = warehouse['email']?.toLowerCase() ?? '';
        return name.contains(query.toLowerCase()) || email.contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  Future<bool> deleteWarehouse(BuildContext context, String warehouseId) async {
    bool isDeleted = await authProvider.deleteWarehouse(warehouseId);

    if (isDeleted) {
      warehouses.removeWhere((warehouse) => warehouse['_id'] == warehouseId);
      notifyListeners();
    }

    return isDeleted;
  }

  void resetForm() {
    pincodes.clear();
    _selectedBillingCountryIndex = _selectedBillingStateIndex = _selectedLocationTypeIndex = 0;
    _selectedShippingCountryIndex = _selectedShippingStateIndex = _selectedLocationTypeIndex = 0;
    _holdsStock = _copysku = null;
    _copyAddress = false;
    validationMessage = _errorMessage = _successMessage = null;

    notifyListeners();
  }

// Method to fetch warehouse data by ID
  Future<void> fetchWarehouseById(String warehouseId) async {
    _isLoading = true; // Set loading to true
    notifyListeners(); // Notify listeners about the change

    try {
      // Call your API method
      warehouseData = await authProvider.fetchWarehouseById(warehouseId);
      // print("Open $warehouseData in editing mode");
    } catch (error) {
      // Handle error here if needed or let it propagate
      rethrow; // Rethrow the error to be handled in the UI
    } finally {
      _isLoading = false; // Set loading to false
      notifyListeners(); // Notify listeners about the change
    }
  }
}
