import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/model/combo_model.dart' hide Product;
import 'package:inventory_management/model/orders_model.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Custom-Files/utils.dart';

class TransferOrderProvider with ChangeNotifier {
  List<Map<String, dynamic>> addedProductList = [];
  List<Map<String, dynamic>> addedComboList = [];
  bool isLoading = false;
  bool isSavingOrder = false;
  String selectedItemType = 'Product';
  String? selectedOrderType;
  String selectedMarketplace = 'TransferOrder';
  String? selectedFromWarehouse;
  String? selectedToWarehouse;
  String? selectedFilter;
  String? selectedPayment;
  String? selectedCourier;
  bool isBillingSameAsShipping = true;

  final List<Product?> _productsFuture = [];
  final List<Combo?> _combosFuture = [];

  late TextEditingController marketplaceController;
  late TextEditingController totalQuantityController;

  late TextEditingController notesController;
  late TextEditingController totalAmtController;

  late TextEditingController customerPhoneController;

  late TextEditingController billingAddress1Controller;
  late TextEditingController billingAddress2Controller;
  late TextEditingController billingPhoneController;
  late TextEditingController billingCityController;
  late TextEditingController billingPincodeController;
  late TextEditingController billingStateController;
  late TextEditingController billingCountryController;

  late TextEditingController shippingAddress1Controller;
  late TextEditingController shippingAddress2Controller;
  late TextEditingController shippingPhoneController;
  late TextEditingController shippingCityController;
  late TextEditingController shippingPincodeController;
  late TextEditingController shippingStateController;
  late TextEditingController shippingCountryController;

  final List<TextEditingController> addedProductQuantityControllers = [];
  final List<TextEditingController> addedProductRateControllers = [];
  final List<TextEditingController> addedComboQuantityControllers = [];
  final List<TextEditingController> addedComboRateControllers = [];

  void initializeControllers() {
    marketplaceController = TextEditingController();
    totalQuantityController = TextEditingController();

    notesController = TextEditingController();
    totalAmtController = TextEditingController(text: '0.00');

    customerPhoneController = TextEditingController();

    billingAddress1Controller = TextEditingController();
    billingAddress2Controller = TextEditingController();
    billingPhoneController = TextEditingController();
    billingCityController = TextEditingController();
    billingPincodeController = TextEditingController();
    billingStateController = TextEditingController();
    billingCountryController = TextEditingController();

    shippingAddress1Controller = TextEditingController();
    shippingAddress2Controller = TextEditingController();
    shippingPhoneController = TextEditingController();
    shippingCityController = TextEditingController();
    shippingPincodeController = TextEditingController();
    shippingStateController = TextEditingController();
    shippingCountryController = TextEditingController();

    _updateItemControllers();
  }

  void _updateItemControllers() {
    addedProductQuantityControllers.clear();
    addedProductRateControllers.clear();
    addedComboQuantityControllers.clear();
    addedComboRateControllers.clear();

    for (var item in addedProductList) {
      final rate = item['amount'] / item['qty'];
      addedProductQuantityControllers.add(TextEditingController(text: item['qty'].toString()));
      addedProductRateControllers.add(TextEditingController(text: rate.toStringAsFixed(2)));
    }

    for (var item in addedComboList) {
      final rate = double.parse(item['amount'].toString()) / item['qty'];
      addedComboQuantityControllers.add(TextEditingController(text: item['qty'].toString()));
      addedComboRateControllers.add(TextEditingController(text: rate.toStringAsFixed(2)));
    }
  }

  void disposeControllers() {
    marketplaceController.dispose();
    totalQuantityController.dispose();

    notesController.dispose();

    customerPhoneController.dispose();

    billingAddress1Controller.dispose();
    billingAddress2Controller.dispose();
    billingPhoneController.dispose();
    billingCityController.dispose();
    billingPincodeController.dispose();
    billingStateController.dispose();
    billingCountryController.dispose();

    shippingAddress1Controller.dispose();
    shippingAddress2Controller.dispose();
    shippingPhoneController.dispose();
    shippingCityController.dispose();
    shippingPincodeController.dispose();
    shippingStateController.dispose();
    shippingCountryController.dispose();

    for (var controller in addedProductQuantityControllers) controller.dispose();
    for (var controller in addedProductRateControllers) controller.dispose();
    for (var controller in addedComboQuantityControllers) controller.dispose();
    for (var controller in addedComboRateControllers) controller.dispose();
  }

  String formatDate(DateTime date) => "${date.day}-${date.month}-${date.year}";
  String formatDateTime(DateTime date) => "${date.day}-${date.month}-${date.year} ${date.hour}:${date.minute}:${date.second}";

  DateTime? parseDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      Logger().e('Error parsing date: $e');
    }
    return null;
  }

  DateTime? parsePaymentDate(String dateStr) {
    try {
      final parts = dateStr.split(' ');
      if (parts.length == 2) {
        final dateParts = parts[0].split('-');
        final timeParts = parts[1].split(':');
        if (dateParts.length == 3 && timeParts.length >= 2) {
          final day = int.parse(dateParts[0]);
          final month = int.parse(dateParts[1]);
          final year = int.parse(dateParts[2]);
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final second = timeParts.length == 3 ? int.parse(timeParts[2]) : 0;
          return DateTime(year, month, day, hour, minute, second);
        }
      }
    } catch (e) {
      Logger().e('Error parsing payment date: $e');
    }
    return null;
  }

  void updateDate(String date) {
    notifyListeners();
  }

  void selectFromWarehouse(String? value) {
    selectedFromWarehouse = value;
    notifyListeners();
  }

  void selectToWarehouse(String? value, String? id) async {
    selectedToWarehouse = value;

    log('selectedToWarehouse: $selectedToWarehouse');
    log('selectedToWarehouse id: $id');

    if (id != null) {
      final warehouseDetails = await fetchWarehouseDetails(id);
      log('warehouseDetails: $warehouseDetails');

      if (warehouseDetails != null) {
        final shippingAddress = warehouseDetails['location']?['shippingAddress'];
        log('shippingAddress: $shippingAddress');

        if (shippingAddress != null) {
          final phoneNumber = shippingAddress['phoneNumber'];
          final zipCode = shippingAddress['zipCode'];
          shippingAddress1Controller.text = shippingAddress['addressLine1'] as String? ?? '';
          shippingAddress2Controller.text = shippingAddress['addressLine2'] as String? ?? '';
          shippingCountryController.text = shippingAddress['country'] as String? ?? '';
          shippingStateController.text = shippingAddress['state'] as String? ?? '';
          shippingCityController.text = shippingAddress['city'] as String? ?? '';
          shippingPincodeController.text = zipCode?.toString() ?? '';
          shippingPhoneController.text = phoneNumber?.toString() ?? '';
        }
      }
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>?> fetchWarehouseDetails(String warehouseId) async {
    final url = Uri.parse('${await Constants.getBaseUrl()}/warehouse/$warehouseId');
    final token = await _getToken();

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }
    } catch (e) {
      Logger().e('Error fetching warehouse details: $e');
    }
    return null;
  }

  Future<void> addProduct(BuildContext context, Map<String, String> selected) async {
    if (selected['id'] == null) return;

    bool productExists = addedProductList.any((item) => item['id'] == selected['id']);

    if (productExists) {
      Utils.showSnackBar(context, 'Product already added', color: Colors.red);
      return;
    }

    Utils.showLoadingDialog(context, 'Adding product');

    try {
      final fetchedProduct = await fetchProduct(selected['id']!);
      if (fetchedProduct == null) return;

      final newItem = {
        'id': fetchedProduct.id,
        'qty': 1,
        'amount': 0.0,
        'sku': fetchedProduct.sku ?? '',
      };

      addedProductList.add(newItem);
      addedProductQuantityControllers.add(TextEditingController(text: '1'));
      addedProductRateControllers.add(TextEditingController(text: '0.00'));
      _productsFuture.add(fetchedProduct);
      setTotalQuantity();
    } catch (e, s) {
      log('addProduct error: $e $s');
    } finally {
      Navigator.of(context).pop();
      notifyListeners();
    }
  }

  Future<void> deleteProduct(BuildContext context, int index, String id) async {
    // Note: Your example didn't include deleteProduct, so I'm adapting it to match
    log('Deleting product at index: $index');

    Utils.showLoadingDialog(context, 'Deleting product');

    try {
      final fetchedProduct = await fetchProduct(id);
      if (fetchedProduct == null) return;

      Logger().e('fetched p: $fetchedProduct');

      if (index < addedProductList.length) {
        addedProductList.removeAt(index);

        // totalAmtController.text = (double.parse(totalAmtController.text) -
        //         double.parse(addedProductRateControllers[index].text) * int.parse(addedProductQuantityControllers[index].text))
        //     .toStringAsFixed(2);

        addedProductQuantityControllers.removeAt(index);
        addedProductRateControllers.removeAt(index);

        final productIndex = _productsFuture.indexWhere((product) => product?.id == id);
        if (productIndex != -1) {
          _productsFuture.removeAt(productIndex);
        }

        log('p: $addedProductList');
        setTotalQuantity();
      }
    } catch (e, s) {
      log('deleteProduct error: $e $s');
    } finally {
      Navigator.of(context).pop();
      notifyListeners();
    }
  }

  Future<void> addCombo(BuildContext context, Map<String, String> selected) async {
    if (selected['id'] == null) return;

    bool comboExists = addedComboList.any((item) => item['id'] == selected['id']) ||
        addedComboList.any((item) => item['id'] == selected['id']);

    if (comboExists) {
      Utils.showSnackBar(context, 'Combo already added', color: Colors.red);
      return;
    }

    Utils.showLoadingDialog(context, 'Adding Combo');

    try {
      final fetchedCombo = await fetchCombo(selected['sku']!);
      if (fetchedCombo == null) return;

      final newItem = {
        'id': fetchedCombo.id,
        'qty': 1,
        'amount': fetchedCombo.comboAmount ?? '0',
        'sku': fetchedCombo.comboSku ?? '',
      };

      addedComboList.add(newItem);
      addedComboQuantityControllers.add(TextEditingController(text: '1'));
      addedComboRateControllers.add(TextEditingController(text: fetchedCombo.comboAmount ?? '0'));

      // if (fetchedCombo.comboAmount != null && fetchedCombo.comboAmount != '0') {
      //   totalAmtController.text = '0';
      //   // codAmountController.text = totalAmtController.text;
      // }

      _combosFuture.add(fetchedCombo);

      log('addedComboList in add: $addedComboList');
      log('_combosFuture in add: $_combosFuture');

      setTotalQuantity();
    } catch (e, s) {
      log('addCombo error: $e $s');
    } finally {
      Navigator.of(context).pop();
      notifyListeners();
    }
  }

  Future<void> deleteCombo(BuildContext context, int index, String sku) async {
    log('Deleting combo at index: $index');

    Utils.showLoadingDialog(context, 'Deleting combo');

    try {
      final fetchedCombo = await fetchCombo(sku);
      if (fetchedCombo == null) return;

      Logger().e('fetched c: $fetchedCombo');

      if (index < addedComboList.length) {
        // final qty = int.parse(addedComboQuantityControllers[index].text);
        // final rate = double.parse(addedComboRateControllers[index].text);

        addedComboList.removeAt(index);

        // totalAmtController.text =
        //     (double.parse(totalAmtController.text) - (rate * qty))
        //         .toStringAsFixed(2);
        // codAmountController.text = totalAmtController.text;

        addedComboQuantityControllers.removeAt(index);
        addedComboRateControllers.removeAt(index);

        final comboIndex = _combosFuture.indexWhere((combo) => combo?.id == fetchedCombo.id);
        if (comboIndex != -1) {
          _combosFuture.removeAt(comboIndex);
        }

        log('c: $addedComboList');
        setTotalQuantity();
      }
    } catch (e, s) {
      log('deleteCombo error: $e $s');
    } finally {
      Navigator.of(context).pop();
      notifyListeners();
    }
  }

  void setTotalQuantity() {
    int totalQuantity = 0;

    try {
      totalQuantity = addedProductQuantityControllers.fold(0, (sum, controller) {
        final quantity = int.tryParse(controller.text) ?? 0;
        return sum + quantity;
      });

      totalQuantity = addedComboQuantityControllers.fold(totalQuantity, (sum, controller) {
        final quantity = int.tryParse(controller.text) ?? 0;
        return sum + quantity;
      });
      totalQuantityController.text = totalQuantity.toString();
    } catch (e, s) {
      log('caught error: $e $s');
    }

    log('totalQuantityController: ${totalQuantityController.text}');
    log('totalQuantity: $totalQuantity');
    notifyListeners();
  }

  Future<Product?> fetchProduct(String query) async {
    final url = Uri.parse('${await Constants.getBaseUrl()}/products/search/$query');
    final token = await _getToken();

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data != null ? Product.fromJson(data) : null;
      }
    } catch (e) {
      Logger().e('Error fetching product: $e');
    }
    return null;
  }

  Future<Combo?> fetchCombo(String query) async {
    final url = Uri.parse('${await Constants.getBaseUrl()}/combo?comboSku=$query');
    final token = await _getToken();

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['combos']?.isNotEmpty ?? false) {
          return Combo.fromJson(data['combos'].firstWhere((c) => c['comboSku'] == query || c['id'] == query));
        }
      }
    } catch (e) {
      Logger().e('Error fetching combo: $e');
    }
    return null;
  }

  Future<List<Product?>> fetchAllProducts(List<dynamic> dynamicItemsList) async {
    isLoading = true;
    notifyListeners();

    List<Product?> products = [];
    for (var item in dynamicItemsList) {
      Product? product = await fetchProduct(item['id']);
      products.add(product);
    }

    isLoading = false;
    notifyListeners();
    return products;
  }

  Future<List<Combo?>> fetchAllCombos(List<dynamic> addedComboList) async {
    isLoading = true;
    notifyListeners();

    List<Combo?> combos = [];
    for (var item in addedComboList) {
      Combo? combo = await fetchCombo(item['sku'] ?? item['id']);
      if (combo != null) combos.add(combo);
    }

    isLoading = false;
    notifyListeners();
    return combos;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<Map<String, dynamic>> saveOrder() async {
    isSavingOrder = true;
    notifyListeners();

    setBillingSameAsShipping(isBillingSameAsShipping);

    List<Map<String, dynamic>> itemsList = [
      ...addedProductList.asMap().entries.map((entry) {
        int index = entry.key;
        var item = entry.value;
        double rate = double.tryParse(addedProductRateControllers[index].text) ?? 0.0;
        int qty = int.tryParse(addedProductQuantityControllers[index].text) ?? 1;
        double amount = rate * qty;
        return {
          'id': item['id'],
          'qty': qty,
          'sku': item['sku'],
          'amount': amount,
        };
      }),
      ...addedComboList.asMap().entries.map((entry) {
        int index = entry.key;
        var item = entry.value;
        double rate = double.tryParse(addedComboRateControllers[index].text) ?? 0.0;
        int qty = int.tryParse(addedComboQuantityControllers[index].text) ?? 1;
        double amount = rate * qty;
        return {
          'id': item['id'],
          'qty': qty,
          'sku': item['sku'],
          'amount': amount,
        };
      }),
    ];

    Map<String, dynamic> orderData = {
      'customer': {
        'phone': shippingPhoneController.text,
      },
      'billing_addr': {
        'address1': billingAddress1Controller.text,
        'address2': billingAddress2Controller.text,
        'phone': billingPhoneController.text,
        'city': billingCityController.text,
        'pincode': billingPincodeController.text,
        'state': billingStateController.text,
        'country': billingCountryController.text,
      },
      'shipping_addr': {
        'address1': shippingAddress1Controller.text,
        'address2': shippingAddress2Controller.text,
        'city': shippingCityController.text,
        'pincode': shippingPincodeController.text,
        'state': shippingStateController.text,
        'country': shippingCountryController.text,
      },
      'payment_mode': "Prepaid",
      'items': itemsList,
      'total_amt': 0,
      'cod_amount': 0,
      'prepaid_amount': 0,
      'total_quantity': int.tryParse(totalQuantityController.text) ?? 0,
      'marketplace': selectedMarketplace,
      'source': selectedMarketplace,
      'notes': notesController.text,
      'warehouseFrom': selectedFromWarehouse,
      'warehouseTo': selectedToWarehouse,
    };

    log('transfer order: $orderData');

    try {
      final url = Uri.parse('${await Constants.getBaseUrl()}/orders');
      final token = await _getToken();
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(orderData),
      );

      final res = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Logger().i('Order saved successfully: ${response.body}');
        return {"success": true, "message": res['order_id']};
      } else {
        Logger().e('Failed to save order: ${response.statusCode} - ${response.body}');
        return {"success": false, "error": res['error'], "details": res['details']};
      }
    } catch (e) {
      Logger().e('Error saving order: $e');
      return {"success": false, "message": e.toString()};
    } finally {
      isSavingOrder = false;
      notifyListeners();
    }
  }

  void clearLocationDetails({required bool isBilling}) {
    if (isBilling) {
      billingCountryController.clear();
      billingStateController.clear();
      billingCityController.clear();
    } else {
      shippingCountryController.clear();
      shippingStateController.clear();
      shippingCityController.clear();
    }
  }

  Future<void> getLocationDetails({required BuildContext context, required String pincode, required bool isBilling}) async {
    try {
      Uri url = Uri.parse('https://api.opencagedata.com/geocode/v1/json?q=$pincode&key=55710109e7c24fbc98c86377005c0612');

      Utils.showLoadingDialog(context, "Fetching Address");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = await jsonDecode(response.body);

        if (data['results'] != null && data['results'].isNotEmpty) {
          final components = data['results'][0]['components'];

          log('Components - $components');

          String country = components['country'] ?? '';
          String state = components['state'] ?? '';
          String city = components['city_district'] ?? components['state_district'] ?? components['_normalized_city'] ?? '';
          String countryCode = components['country_code'].toString().toUpperCase() ?? '';

          if (isBilling) {
            billingCountryController.text = country;
            billingStateController.text = state;
            billingCityController.text = city;
          } else {
            shippingCountryController.text = country;
            shippingStateController.text = state;
            shippingCityController.text = city;
          }
        } else {
          log('No location details found for the provided pincode :- ${response.body}');
          Utils.showSnackBar(context, 'No location details found for the provided pincode.');
          // return;
        }
      } else {
        log('Failed to load location details :- ${response.body}');
        Utils.showSnackBar(context, 'Failed to load location details. Please check your internet connection.');
        // return;
      }
    } catch (e, stace) {
      log('Error to fetch location details :- $e\n$stace');
      Utils.showSnackBar(context, 'Failed to load location details. Please check your internet connection.');
      // return;
    } finally {
      Navigator.pop(context);
      notifyListeners();
    }
  }

  void setBillingSameAsShipping(bool? value) {
    isBillingSameAsShipping = value ?? true;
    if (isBillingSameAsShipping) {
      billingAddress1Controller.text = shippingAddress1Controller.text;
      billingAddress2Controller.text = shippingAddress2Controller.text;
      billingPhoneController.text = shippingPhoneController.text;
      billingCityController.text = shippingCityController.text;
      billingPincodeController.text = shippingPincodeController.text;
      billingStateController.text = shippingStateController.text;
      billingCountryController.text = shippingCountryController.text;
    }
    notifyListeners();
  }

  List<Product?> get productsFuture => _productsFuture;
  List<Combo?> get combosFuture => _combosFuture;
}
