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

class CreateOrderProvider with ChangeNotifier {
  List<Map<String, dynamic>> addedProductList = [];
  List<Map<String, dynamic>> addedComboList = [];
  bool isLoading = false;
  bool isSavingOrder = false;
  String selectedItemType = 'Product'; //
  String? selectedOrderType; //
  String? selectedMarketplace; //
  String? selectedFilter; //
  String selectedPayment = 'COD'; //
  String? selectedCourier; //
  bool isBillingSameAsShipping = true;

  final List<Product?> _productsFuture = [];
  final List<Combo?> _combosFuture = [];

  late TextEditingController orderIdController;
  late TextEditingController paymentModeController;
  late TextEditingController currencyCodeController;
  late TextEditingController coinController;
  late TextEditingController codAmountController;
  late TextEditingController prepaidAmountController;
  late TextEditingController discountCodeController;
  late TextEditingController discountPercentController;
  late TextEditingController discountAmountController;
  late TextEditingController taxPercentController;
  late TextEditingController marketplaceController;
  late TextEditingController totalQuantityController;
  late TextEditingController agentController;
  late TextEditingController notesController;
  late TextEditingController totalAmtController;
  late TextEditingController originalAmtController;

  late TextEditingController customerFirstNameController;
  late TextEditingController customerLastNameController;
  late TextEditingController customerEmailController;
  late TextEditingController customerPhoneController;

  late TextEditingController billingFirstNameController;
  late TextEditingController billingLastNameController;
  late TextEditingController billingEmailController;
  late TextEditingController billingAddress1Controller;
  late TextEditingController billingAddress2Controller;
  late TextEditingController billingPhoneController;
  late TextEditingController billingCityController;
  late TextEditingController billingPincodeController;
  late TextEditingController billingStateController;
  late TextEditingController billingCountryController;
  late TextEditingController billingCountryCodeController;

  late TextEditingController shippingFirstNameController;
  late TextEditingController shippingLastNameController;
  late TextEditingController shippingEmailController;
  late TextEditingController shippingAddress1Controller;
  late TextEditingController shippingAddress2Controller;
  late TextEditingController shippingPhoneController;
  late TextEditingController shippingCityController;
  late TextEditingController shippingPincodeController;
  late TextEditingController shippingStateController;
  late TextEditingController shippingCountryController;
  late TextEditingController shippingCountryCodeController;

  final List<TextEditingController> addedProductQuantityControllers = [];
  final List<TextEditingController> addedProductRateControllers = [];
  final List<TextEditingController> addedComboQuantityControllers = [];
  final List<TextEditingController> addedComboRateControllers = [];

  // CreateOrderProvider() {
  //   initializeControllers();
  //   // _fetchInitialData();
  // }

  void initializeControllers() {
    orderIdController = TextEditingController();
    paymentModeController = TextEditingController();
    currencyCodeController = TextEditingController(text: 'INR');
    coinController = TextEditingController();
    codAmountController = TextEditingController(text: '0.00');
    prepaidAmountController = TextEditingController();
    discountCodeController = TextEditingController();
    discountPercentController = TextEditingController(text: '0');
    discountAmountController = TextEditingController(text: '0.00');
    taxPercentController = TextEditingController();
    marketplaceController = TextEditingController();
    totalQuantityController = TextEditingController();
    agentController = TextEditingController();
    notesController = TextEditingController();
    totalAmtController = TextEditingController(text: '0.00');
    originalAmtController = TextEditingController(text: '0.00');

    customerFirstNameController = TextEditingController();
    customerLastNameController = TextEditingController();
    customerEmailController = TextEditingController();
    customerPhoneController = TextEditingController();

    billingFirstNameController = TextEditingController();
    billingLastNameController = TextEditingController();
    billingEmailController = TextEditingController();
    billingAddress1Controller = TextEditingController();
    billingAddress2Controller = TextEditingController();
    billingPhoneController = TextEditingController();
    billingCityController = TextEditingController();
    billingPincodeController = TextEditingController();
    billingStateController = TextEditingController();
    billingCountryController = TextEditingController();
    billingCountryCodeController = TextEditingController(text: 'IN');

    shippingFirstNameController = TextEditingController();
    shippingLastNameController = TextEditingController();
    shippingEmailController = TextEditingController();
    shippingAddress1Controller = TextEditingController();
    shippingAddress2Controller = TextEditingController();
    shippingPhoneController = TextEditingController();
    shippingCityController = TextEditingController();
    shippingPincodeController = TextEditingController();
    shippingStateController = TextEditingController();
    shippingCountryController = TextEditingController();
    shippingCountryCodeController = TextEditingController(text: 'IN');

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
    orderIdController.dispose();
    paymentModeController.dispose();
    currencyCodeController.dispose();
    coinController.dispose();
    codAmountController.dispose();
    prepaidAmountController.dispose();
    discountCodeController.dispose();
    discountPercentController.dispose();
    discountAmountController.dispose();
    taxPercentController.dispose();
    marketplaceController.dispose();
    totalQuantityController.dispose();

    agentController.dispose();
    notesController.dispose();

    customerFirstNameController.dispose();
    customerLastNameController.dispose();
    customerEmailController.dispose();
    customerPhoneController.dispose();

    billingFirstNameController.dispose();
    billingLastNameController.dispose();
    billingEmailController.dispose();
    billingAddress1Controller.dispose();
    billingAddress2Controller.dispose();
    billingPhoneController.dispose();
    billingCityController.dispose();
    billingPincodeController.dispose();
    billingStateController.dispose();
    billingCountryController.dispose();
    billingCountryCodeController.dispose();

    shippingFirstNameController.dispose();
    shippingLastNameController.dispose();
    shippingEmailController.dispose();
    shippingAddress1Controller.dispose();
    shippingAddress2Controller.dispose();
    shippingPhoneController.dispose();
    shippingCityController.dispose();
    shippingPincodeController.dispose();
    shippingStateController.dispose();
    shippingCountryController.dispose();
    shippingCountryCodeController.dispose();

    for (var controller in addedProductQuantityControllers) controller.dispose();
    for (var controller in addedProductRateControllers) controller.dispose();
    for (var controller in addedComboQuantityControllers) controller.dispose();
    for (var controller in addedComboRateControllers) controller.dispose();

    addedProductList.clear();
    addedComboList.clear();
    _productsFuture.clear();
    _combosFuture.clear();

    selectedOrderType = null; //
    selectedMarketplace = null; //
    selectedFilter = null; //
    selectedCourier = null; //

    notifyListeners();
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

  void selectMarketplace(String? value) {
    selectedMarketplace = value;
    marketplaceController.text = value ?? '';
    notifyListeners();
  }

  void selectPayment(String value) {
    selectedPayment = value;
    paymentModeController.text = value;
    log('selectedPayment: $selectedPayment');
    log('paymentModeController: ${paymentModeController.text}');
    notifyListeners();
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

        totalAmtController.text =
            (double.parse(totalAmtController.text) -
                double.parse(addedProductRateControllers[index].text) *
                    int.parse(addedProductQuantityControllers[index].text))
                .toStringAsFixed(2);

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

      if (fetchedCombo.comboAmount != null && fetchedCombo.comboAmount != '0') {
        totalAmtController.text = (double.parse(totalAmtController.text) +
            (100 - double.parse(discountPercentController.text)) * (double.parse(fetchedCombo.comboAmount!) ?? 0))
            .toStringAsFixed(2);
        codAmountController.text = totalAmtController.text;
      }

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
        final qty = int.parse(addedComboQuantityControllers[index].text);
        final rate = double.parse(addedComboRateControllers[index].text);

        addedComboList.removeAt(index);

        totalAmtController.text =
            (double.parse(totalAmtController.text) - (rate * qty))
                .toStringAsFixed(2);
        codAmountController.text = totalAmtController.text;

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

  void updateTotalAmount() {
    double total = 0;

    for (int i = 0; i < addedProductList.length; i++) {
      final qty = int.tryParse(addedProductQuantityControllers[i].text) ?? 0;
      final rate = double.tryParse(addedProductRateControllers[i].text) ?? 0;
      total += qty * rate;
    }

    for (int i = 0; i < addedComboList.length; i++) {
      final qty = int.tryParse(addedComboQuantityControllers[i].text) ?? 0;
      final rate = double.tryParse(addedComboRateControllers[i].text) ?? 0;
      total += qty * rate;
    }

    final discountPercent = double.tryParse(discountPercentController.text) ?? 0;
    double discountAmount = 0;

    if (discountPercent > 0) {
      discountAmount = total * (discountPercent / 100);
      total -= discountAmount;
    }

    discountAmountController.text = discountAmount.toStringAsFixed(2);

    totalAmtController.text = total.toStringAsFixed(2);

    final prepaidAmount = double.tryParse(prepaidAmountController.text) ?? 0.0;
    final codAmount = (total - prepaidAmount).clamp(0, total);

    codAmountController.text = codAmount.toStringAsFixed(2);

    setTotalQuantity();

    notifyListeners();
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
    log('fetchProduct called');
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

    String source;

    switch (selectedMarketplace) {
      case 'Shopify':
        source = 'shopify';
        break;
      case 'Woocommerce':
        source = 'woocommerce';
        break;
      case 'Offline':
        source = 'other';
        break;
      case 'GGV-USA':
        source = 'ggvusa';
        break;
      case 'GGV-CA':
        source = 'ggvca';
        break;
      case 'GGV-UAE':
        source = 'ggvuae';
        break;
      case 'MicroDealer':
        source = 'md';
        break;
      default:
        source = marketplaceController.text;
        break;
    }

    Map<String, dynamic> orderData = {
      'order_id': orderIdController.text,
      'customer': {
        'first_name': customerFirstNameController.text,
        'last_name': customerLastNameController.text,
        'email': customerEmailController.text,
        'phone': customerPhoneController.text,
      },
      'billing_addr': {
        'first_name': billingFirstNameController.text,
        'last_name': billingLastNameController.text,
        'email': billingEmailController.text,
        'address1': billingAddress1Controller.text,
        'address2': billingAddress2Controller.text,
        'phone': billingPhoneController.text,
        'city': billingCityController.text,
        'pincode': billingPincodeController.text,
        'state': billingStateController.text,
        'country': billingCountryController.text,
        'country_code': billingCountryCodeController.text,
      },
      'shipping_addr': {
        'first_name': shippingFirstNameController.text,
        'last_name': shippingLastNameController.text,
        'email': shippingEmailController.text,
        'address1': shippingAddress1Controller.text,
        'address2': shippingAddress2Controller.text,
        'phone': shippingPhoneController.text,
        'city': shippingCityController.text,
        'pincode': shippingPincodeController.text,
        'state': shippingStateController.text,
        'country': shippingCountryController.text,
        'country_code': shippingCountryCodeController.text,
      },
      'payment_mode': paymentModeController.text,
      'currency_code': currencyCodeController.text,
      'items': itemsList,
      'total_amt': double.tryParse(totalAmtController.text) ?? 0,
      'coin': int.tryParse(coinController.text) ?? 0,
      'cod_amount': double.tryParse(codAmountController.text) ?? 0,
      'prepaid_amount': double.tryParse(prepaidAmountController.text) ?? 0,
      'discount_code': discountCodeController.text,
      'discount_percent': double.tryParse(discountPercentController.text) ?? 0,
      'discount_amount': double.tryParse(discountAmountController.text) ?? 0,
      'tax_percent': double.tryParse(taxPercentController.text) ?? 0,
      'total_quantity': int.tryParse(totalQuantityController.text) ?? 0,
      'marketplace': marketplaceController.text.trim(),
      'source': source,
      'agent': agentController.text,
      'notes': notesController.text,
    };

    log('create order data: $orderData');

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

      final res = json.decode(response.body);

      log('order create response: $res');

      if (response.statusCode == 200 || response.statusCode == 201) {
        Logger().i('Order saved successfully: $res}');
        return {"success": true, "message": res['message']};
      } else {
        Logger().e('Failed to save order: ${response.statusCode} - ${response.body}');
        return {"success": false, "message": res['error'], "details": res['details']};
      }
    } catch (e) {
      Logger().e('Error saving order: $e');
      return {"success": false, "message": 'Error saving order: $e'};
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
      billingCountryCodeController.clear();
    } else {
      shippingCountryController.clear();
      shippingStateController.clear();
      shippingCityController.clear();
      shippingCountryCodeController.clear();
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
            billingCountryCodeController.text = countryCode;
          } else {
            shippingCountryController.text = country;
            shippingStateController.text = state;
            shippingCityController.text = city;
            shippingCountryCodeController.text = countryCode;
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
      Navigator.of(context).pop();
      notifyListeners();
    }
  }

  void setBillingSameAsShipping(bool? value) {
    isBillingSameAsShipping = value ?? true;
    if (isBillingSameAsShipping) {
      billingFirstNameController.text = shippingFirstNameController.text;
      billingLastNameController.text = shippingLastNameController.text;
      billingEmailController.text = shippingEmailController.text;
      billingAddress1Controller.text = shippingAddress1Controller.text;
      billingAddress2Controller.text = shippingAddress2Controller.text;
      billingPhoneController.text = shippingPhoneController.text;
      billingCityController.text = shippingCityController.text;
      billingPincodeController.text = shippingPincodeController.text;
      billingStateController.text = shippingStateController.text;
      billingCountryController.text = shippingCountryController.text;
      billingCountryCodeController.text = shippingCountryCodeController.text;
    }
    notifyListeners();
  }

  double _calculateTotal() {
    double total = 0;
    int totalQty = 0; // Store total quantity separately

    final controllerPairs = [
      [addedProductQuantityControllers, addedProductRateControllers],
      [addedComboQuantityControllers, addedComboRateControllers],
    ];

    for (final pair in controllerPairs) {
      for (var i = 0; i < pair[0].length; i++) {
        final qty = int.tryParse(pair[0][i].text) ?? 0;
        final rate = double.tryParse(pair[1][i].text) ?? 0;
        total += qty * rate;
        totalQty += qty; // Accumulate total quantity
      }
    }

    totalQuantityController.text = totalQty.toString(); // Use totalQty instead of qty

    notifyListeners();
    return total;
  }

  void applyDiscount() {
    final discount = double.parse(discountPercentController.text);
    final total = _calculateTotal();
    final discountAmt = total * (discount / 100);

    double discountedTotal = discount != 0 ? total - discountAmt : total;
    totalAmtController.text = discountedTotal.toStringAsFixed(2);
    discountAmountController.text = discountAmt.toStringAsFixed(2);
    codAmountController.clear();
    prepaidAmountController.clear();
    notifyListeners();
  }

  void updateOriginal() {
    final discount = double.parse(discountPercentController.text);
    final total = _calculateTotal();

    double discountedTotal = discount != 0 ? total - (total * (discount / 100)) : total;

    totalAmtController.text = discountedTotal.toStringAsFixed(2);
    originalAmtController.text = total.toString(); // Use totalQty instead of qty
    codAmountController.clear();
    prepaidAmountController.clear();
    notifyListeners();
  }

  void updateCod(BuildContext context) {
    try {
      final discount = double.parse(discountPercentController.text);
      final cod = double.parse(codAmountController.text);
      final total = _calculateTotal();

      originalAmtController.text = total.toStringAsFixed(2);
      double discountedTotal = discount != 0 ? total - (total * (discount / 100)) : total;
      totalAmtController.text = discountedTotal.toStringAsFixed(2);

      if (cod > discountedTotal || cod < 0) {
        Utils.showSnackBar(context, 'COD amount cannot be negative or greater than total amount');
        return;
      }

      prepaidAmountController.text = (discountedTotal - cod).toStringAsFixed(2);

      if (cod == 0) {
        selectPayment('PrePaid');
      } else {
        selectPayment('COD');
      }
    } catch (e, s) {
      log('Error in updateCod: $e \n\n$s');
    }
    notifyListeners();
  }

  void updatePrepaid(BuildContext context) {
    final discount = double.parse(discountPercentController.text);
    final prepaid = double.parse(prepaidAmountController.text);
    final total = _calculateTotal();

    log('updatePrepaid: $prepaid');
    log('updatePrepaid total: $total');
    log('updatePrepaid discount: $discount');
    // log('updatePrepaid cod: $cod');

    originalAmtController.text = total.toStringAsFixed(2);

    double discountedTotal = discount != 0 ? total - (total * (discount / 100)) : total;
    totalAmtController.text = discountedTotal.toStringAsFixed(2);

    if (prepaid > discountedTotal || prepaid < 0) {
      Utils.showSnackBar(context, 'Prepaid amount cannot be negative or greater than total amount');
      return;
    }

    codAmountController.text = (discountedTotal - prepaid).toStringAsFixed(2);

    final cod = double.parse(codAmountController.text);
    if (cod == 0) {
      selectPayment('PrePaid');
    } else {
      selectPayment('COD');
    }
    notifyListeners();
  }

  List<Product?> get productsFuture => _productsFuture;
  List<Combo?> get combosFuture => _combosFuture;
}
