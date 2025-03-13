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
  String selectedItemType = 'Product';
  String? selectedOrderType;
  String? selectedMarketplace;
  String? selectedFilter;
  String? selectedPayment;
  String? selectedCourier;
  bool isBillingSameAsShipping = true;

  // Futures for fetching all products and combos
  Future<List<Product?>>? _productsFuture;
  Future<List<Combo?>>? _combosFuture;

  // Controllers for all fields
  late TextEditingController orderIdController;
  late TextEditingController paymentModeController;
  late TextEditingController currencyCodeController;
  late TextEditingController coinController; // Not required
  late TextEditingController codAmountController;
  late TextEditingController prepaidAmountController;
  late TextEditingController discountCodeController; // Not required
  late TextEditingController discountPercentController;
  late TextEditingController discountAmountController;
  late TextEditingController taxPercentController; // Not required
  late TextEditingController marketplaceController;
  late TextEditingController totalQuantityController;
  late TextEditingController agentController; // Not required
  late TextEditingController notesController; // Not required
  late TextEditingController totalAmtController; // Not required

  late TextEditingController customerFirstNameController;
  late TextEditingController customerLastNameController;
  late TextEditingController customerEmailController; // Not required
  late TextEditingController customerPhoneController;

  late TextEditingController billingFirstNameController;
  late TextEditingController billingLastNameController;
  late TextEditingController billingEmailController; // Not required
  late TextEditingController billingAddress1Controller; // Not required
  late TextEditingController billingAddress2Controller; // Not required
  late TextEditingController billingPhoneController;
  late TextEditingController billingCityController;
  late TextEditingController billingPincodeController;
  late TextEditingController billingStateController;
  late TextEditingController billingCountryController;
  late TextEditingController billingCountryCodeController;

  late TextEditingController shippingFirstNameController;
  late TextEditingController shippingLastNameController;
  late TextEditingController shippingEmailController;
  late TextEditingController shippingAddress1Controller; // Not required
  late TextEditingController shippingAddress2Controller; // Not required
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

  CreateOrderProvider() {
    initializeControllers();
    _fetchInitialData(); // Fetch initial product/combo data
  }

  void initializeControllers() {
    orderIdController = TextEditingController();
    paymentModeController = TextEditingController();
    currencyCodeController = TextEditingController(text: 'INR');
    coinController = TextEditingController(); // Not required
    codAmountController = TextEditingController(text: '0.00');
    prepaidAmountController = TextEditingController();
    discountCodeController = TextEditingController(); // Not required
    discountPercentController = TextEditingController(text: '0');
    discountAmountController = TextEditingController(text: '0.00');
    taxPercentController = TextEditingController();
    marketplaceController = TextEditingController();
    totalQuantityController = TextEditingController();
    agentController = TextEditingController(); // Not required
    notesController = TextEditingController(); // Not required
    totalAmtController = TextEditingController(text: '0.00');

    customerFirstNameController = TextEditingController();
    customerLastNameController = TextEditingController();
    customerEmailController = TextEditingController(); // Not required
    customerPhoneController = TextEditingController();

    billingFirstNameController = TextEditingController();
    billingLastNameController = TextEditingController();
    billingEmailController = TextEditingController(); // Not required
    billingAddress1Controller = TextEditingController(); // Not required
    billingAddress2Controller = TextEditingController(); // Not required
    billingPhoneController = TextEditingController();
    billingCityController = TextEditingController();
    billingPincodeController = TextEditingController();
    billingStateController = TextEditingController();
    billingCountryController = TextEditingController();
    billingCountryCodeController = TextEditingController(text: 'IN');

    shippingFirstNameController = TextEditingController();
    shippingLastNameController = TextEditingController();
    shippingEmailController = TextEditingController();
    shippingAddress1Controller = TextEditingController(); // Not required
    shippingAddress2Controller = TextEditingController(); // Not required
    shippingPhoneController = TextEditingController();
    shippingCityController = TextEditingController();
    shippingPincodeController = TextEditingController();
    shippingStateController = TextEditingController();
    shippingCountryController = TextEditingController();
    shippingCountryCodeController = TextEditingController(text: 'IN');

    _updateItemControllers();
  }

  void _fetchInitialData() {
    _productsFuture = fetchAllProducts(addedProductList);
    _combosFuture = fetchAllCombos(addedComboList);
    notifyListeners();
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
  }

  // Formatting utilities
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
    // dateController.text = date;
    notifyListeners();
  }

  void selectMarketplace(String? value) {
    selectedMarketplace = value;
    marketplaceController.text = value ?? '';
    notifyListeners();
  }

  void selectPayment(String? value) {
    selectedPayment = value;
    paymentModeController.text = value ?? '';
    notifyListeners();
  }

  Future<void> addProduct(Map<String, String> selected) async {
    if (selected['id'] == null || addedProductList.any((item) => item['id'] == selected['id'])) return;

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
    _productsFuture = fetchAllProducts(addedProductList);
    setTotalQuantity();
    notifyListeners();
  }

  Future<void> deleteProduct(int index, String id) async {
    final fetchedProduct = await fetchProduct(id);
    if (fetchedProduct != null && index < addedProductList.length) {
      final qty = int.parse(addedProductQuantityControllers[index].text);
      final rate = double.parse(addedProductRateControllers[index].text);
      addedProductList.removeAt(index);
      totalAmtController.text = (double.parse(totalAmtController.text) - (rate * qty)).toStringAsFixed(2);
      codAmountController.text = totalAmtController.text;
      addedProductQuantityControllers.removeAt(index);
      addedProductRateControllers.removeAt(index);
      _productsFuture = fetchAllProducts(addedProductList);
      setTotalQuantity();
      notifyListeners();
    }
  }

  Future<void> addCombo(Map<String, String> selected) async {
    if (selected['id'] == null || addedComboList.any((item) => item['id'] == selected['id'])) return;

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
    _combosFuture = fetchAllCombos(addedComboList);
    setTotalQuantity();
    notifyListeners();
  }

  Future<void> deleteCombo(int index, String sku) async {
    final fetchedCombo = await fetchCombo(sku);
    if (fetchedCombo != null && index < addedComboList.length) {
      final qty = int.parse(addedComboQuantityControllers[index].text);
      final rate = double.parse(addedComboRateControllers[index].text);
      addedComboList.removeAt(index);
      totalAmtController.text = (double.parse(totalAmtController.text) - (rate * qty)).toStringAsFixed(2);
      codAmountController.text = totalAmtController.text;
      addedComboQuantityControllers.removeAt(index);
      addedComboRateControllers.removeAt(index);
      _combosFuture = fetchAllCombos(addedComboList);
      setTotalQuantity();
      notifyListeners();
    }
  }

  void updateTotalAmount() {
    double total = 0;

    // Calculate total for individual products
    for (int i = 0; i < addedProductList.length; i++) {
      final qty = int.tryParse(addedProductQuantityControllers[i].text) ?? 0;
      final rate = double.tryParse(addedProductRateControllers[i].text) ?? 0;
      total += qty * rate;
    }

    // Calculate total for combo products
    for (int i = 0; i < addedComboList.length; i++) {
      final qty = int.tryParse(addedComboQuantityControllers[i].text) ?? 0;
      final rate = double.tryParse(addedComboRateControllers[i].text) ?? 0;
      total += qty * rate;
    }

    // Apply discount if any (before calculating prepaid & COD)
    final discountPercent = double.tryParse(discountPercentController.text) ?? 0;
    double discountAmount = 0;

    if (discountPercent > 0) {
      discountAmount = total * (discountPercent / 100);
      total -= discountAmount;
    }

    // Assign discount amount to the controller
    discountAmountController.text = discountAmount.toStringAsFixed(2);

    // Assign the discounted total amount
    totalAmtController.text = total.toStringAsFixed(2);

    // Handle Prepaid, Partial, and COD Payments
    final prepaidAmount = double.tryParse(prepaidAmountController.text) ?? 0.0;
    final codAmount = (total - prepaidAmount).clamp(0, total); // Ensure no negative COD

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

  Future<String?> saveOrder() async {
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
        'email': customerEmailController.text, // Uncomment
        'phone': customerPhoneController.text, // Keep as string
      },
      'billing_addr': {
        'first_name': billingFirstNameController.text,
        'last_name': billingLastNameController.text,
        'email': billingEmailController.text, // Uncomment
        'address1': billingAddress1Controller.text, // Uncomment
        'address2': billingAddress2Controller.text, // Uncomment
        'phone': billingPhoneController.text, // Keep as string
        'city': billingCityController.text,
        'pincode': billingPincodeController.text, // Keep as string
        'state': billingStateController.text,
        'country': billingCountryController.text,
        'country_code': billingCountryCodeController.text,
      },
      'shipping_addr': {
        'first_name': shippingFirstNameController.text,
        'last_name': shippingLastNameController.text,
        'email': shippingEmailController.text,
        'address1': shippingAddress1Controller.text, // Uncomment
        'address2': shippingAddress2Controller.text, // Uncomment
        'phone': shippingPhoneController.text, // Keep as string
        'city': shippingCityController.text,
        'pincode': shippingPincodeController.text, // Keep as string
        'state': shippingStateController.text,
        'country': shippingCountryController.text,
        'country_code': shippingCountryCodeController.text,
      },
      'payment_mode': paymentModeController.text,
      'currency_code': currencyCodeController.text,
      'items': itemsList,
      'total_amt': double.tryParse(totalAmtController.text) ?? 0,
      'coin': int.tryParse(coinController.text) ?? 0, // Not required
      'cod_amount': double.tryParse(codAmountController.text) ?? 0,
      'prepaid_amount': double.tryParse(prepaidAmountController.text) ?? 0,
      'discount_code': discountCodeController.text, // Not required
      'discount_percent': double.tryParse(discountPercentController.text) ?? 0,
      'discount_amount': double.tryParse(discountAmountController.text) ?? 0,
      'tax_percent': double.tryParse(taxPercentController.text) ?? 0, // Not required
      'total_quantity': int.tryParse(totalQuantityController.text) ?? 0,
      'marketplace': marketplaceController.text.trim(),
      'source': source,
      'agent': agentController.text, // Not required
      'notes': notesController.text, // Not required
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        Logger().i('Order saved successfully: $res}');
        return res['message'];
      } else {
        Logger().e('Failed to save order: ${response.statusCode} - ${response.body}');
        // throw Exception('Failed to save order');
        return res['message'] ?? res['error'];
      }
    } catch (e) {
      Logger().e('Error saving order: $e');
      return 'Error saving order: $e';
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
          return;
        }
      } else {
        log('Failed to load location details :- ${response.body}');
        Utils.showSnackBar(context, 'Failed to load location details. Please check your internet connection.');
        return;
      }
    } catch (e, stace) {
      log('Error to fetch location details :- $e\n$stace');
      Utils.showSnackBar(context, 'Failed to load location details. Please check your internet connection.');
      return;
    } finally {
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

  Future<List<Product?>>? get productsFuture => _productsFuture;
  Future<List<Combo?>>? get combosFuture => _combosFuture;
}
