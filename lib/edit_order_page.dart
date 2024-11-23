import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:inventory_management/Api/inventory_api.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/Widgets/product_card.dart';
import 'package:inventory_management/Widgets/searchable_dropdown.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:inventory_management/Widgets/product_details_card.dart';
import 'package:inventory_management/orders_page.dart';
import 'package:inventory_management/provider/orders_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditOrderPage extends StatefulWidget {
  final Order order; // Pass the order to edit
  final bool isBookPage;

  const EditOrderPage({Key? key, required this.order, required this.isBookPage})
      : super(key: key);

  @override
  _EditOrderPageState createState() => _EditOrderPageState();
}

class _EditOrderPageState extends State<EditOrderPage> {
  final List<Map<String, dynamic>> dynamicItemsList = [];
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _quantityControllers = [];
  final List<TextEditingController> _amountControllers = [];
  List<dynamic> selectedProducts = [];
  Map<String, dynamic>? selectedProductDetails;
  String? selectedProduct;
  int currentPage = 1;
  bool isLoading = false;
  List<int> deletedItemsIndices = [];
  bool _isSavingOrder = false;
  late OrdersProvider _ordersProvider;
  late ScrollController _scrollController;
  late TextEditingController _orderIdController;
  late TextEditingController _IdController;
  late TextEditingController _orderStatusController;
  late TextEditingController _dateController;
  late TextEditingController _paymentModeController;
  late TextEditingController _currencyCodeController;
  late TextEditingController _skuTrackingIdController;
  late TextEditingController _totalWeightController;
  late TextEditingController _totalAmtController;
  late TextEditingController _coinController;
  late TextEditingController _codAmountController;
  late TextEditingController _prepaidAmountController;
  late TextEditingController _discountCodeController;
  late TextEditingController _discountSchemeController;
  late TextEditingController _discountPercentController;
  late TextEditingController _discountAmountController;
  late TextEditingController _taxPercentController;
  late TextEditingController _courierNameController;
  late TextEditingController _orderTypeController;
  late TextEditingController _marketplaceController;
  late TextEditingController _filterController;
  late TextEditingController _freightChargeDelhiveryController;
  late TextEditingController _freightChargeShiprocketController;
  late TextEditingController _agentController;
  late TextEditingController _notesController;
  late TextEditingController _expectedDeliveryDateController;
  late TextEditingController _preferredCourierController;
  late TextEditingController _deliveryTermController;
  late TextEditingController _transactionNumberController;
  late TextEditingController _microDealerOrderController;
  late TextEditingController _fulfillmentTypeController;
  late TextEditingController _numberOfBoxesController;
  late TextEditingController _totalQuantityController;
  late TextEditingController _skuQtyController;
  late TextEditingController _calcEntryNumberController;
  late TextEditingController _currencyController;
  late TextEditingController _paymentDateTimeController;
  late TextEditingController _paymentBankController;
  late TextEditingController _lengthController;
  late TextEditingController _breadthController;
  late TextEditingController _heightController;
  late TextEditingController _awbNumberController;
  late TextEditingController _trackingStatusController;

  // Controllers for customer
  late TextEditingController _customerIdController;
  late TextEditingController _customerFirstNameController;
  late TextEditingController _customerLastNameController;
  late TextEditingController _customerEmailController;
  late TextEditingController _customerPhoneController;
  late TextEditingController _customerGstinController;
  // Controllers for billing address
  late TextEditingController _billingFirstNameController;
  late TextEditingController _billingLastNameController;
  late TextEditingController _billingEmailController;
  late TextEditingController _billingAddress1Controller;
  late TextEditingController _billingAddress2Controller;
  late TextEditingController _billingPhoneController;
  late TextEditingController _billingCityController;
  late TextEditingController _billingPincodeController;
  late TextEditingController _billingStateController;
  late TextEditingController _billingCountryController;
  late TextEditingController _billingCountryCodeController;
  // Controllers for shipping address
  late TextEditingController _shippingFirstNameController;
  late TextEditingController _shippingLastNameController;
  late TextEditingController _shippingEmailController;
  late TextEditingController _shippingAddress1Controller;
  late TextEditingController _shippingAddress2Controller;
  late TextEditingController _shippingPhoneController;
  late TextEditingController _shippingCityController;
  late TextEditingController _shippingPincodeController;
  late TextEditingController _shippingStateController;
  late TextEditingController _shippingCountryController;
  late TextEditingController _shippingCountryCodeController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _ordersProvider = OrdersProvider();

    // Initialize controllers with the order data
    _orderIdController = TextEditingController(text: widget.order.orderId);
    _IdController = TextEditingController(text: widget.order.id);
    _orderStatusController =
        TextEditingController(text: widget.order.orderStatus.toString());
    _dateController = TextEditingController(
        text: widget.order.date != null
            ? _ordersProvider.formatDate(widget.order.date!)
            : '');
    _paymentModeController =
        TextEditingController(text: widget.order.paymentMode ?? '');

    // Initialize the provider with the initial payment mode
    _ordersProvider.setInitialPaymentMode(_paymentModeController.text);

    _currencyCodeController =
        TextEditingController(text: widget.order.currencyCode ?? '');
    _skuTrackingIdController =
        TextEditingController(text: widget.order.skuTrackingId ?? '');
    _totalWeightController =
        TextEditingController(text: widget.order.totalWeight?.toString() ?? '');
    _totalAmtController =
        TextEditingController(text: widget.order.totalAmount?.toString() ?? '');
    _coinController =
        TextEditingController(text: widget.order.coin?.toString() ?? '');
    _codAmountController =
        TextEditingController(text: widget.order.codAmount?.toString() ?? '');
    _prepaidAmountController = TextEditingController(
        text: widget.order.prepaidAmount?.toString() ?? '');
    _discountCodeController =
        TextEditingController(text: widget.order.discountCode ?? '');
    _discountSchemeController =
        TextEditingController(text: widget.order.discountScheme ?? '');
    _discountPercentController = TextEditingController(
        text: widget.order.discountPercent?.toString() ?? '');
    _discountAmountController = TextEditingController(
        text: widget.order.discountAmount?.toString() ?? '');
    _taxPercentController =
        TextEditingController(text: widget.order.taxPercent?.toString() ?? '');
    _courierNameController =
        TextEditingController(text: widget.order.courierName ?? '');

    // Initialize the provider with the initial courier name
    _ordersProvider.setInitialCourier(_courierNameController.text);

    _orderTypeController =
        TextEditingController(text: widget.order.orderType ?? '');
    _marketplaceController = TextEditingController(
        text: widget.order.marketplace?.name?.toString() ?? '');

    // Initialize the provider with the initial marketplace
    _ordersProvider.setInitialMarketplace(_marketplaceController.text);

    _filterController = TextEditingController(text: widget.order.filter ?? '');

    // Initialize the provider with the initial filter
    _ordersProvider.setInitialFilter(_filterController.text);

    _freightChargeDelhiveryController = TextEditingController(
        text: widget.order.freightCharge?.delhivery?.toString() ?? '');
    _freightChargeShiprocketController = TextEditingController(
        text: widget.order.freightCharge?.shiprocket?.toString() ?? '');

    _agentController = TextEditingController(text: widget.order.agent ?? '');
    _notesController = TextEditingController(text: widget.order.notes ?? '');
    _expectedDeliveryDateController = TextEditingController(
        text: widget.order.expectedDeliveryDate != null
            ? _ordersProvider.formatDate(widget.order.expectedDeliveryDate!)
            : '');
    _preferredCourierController =
        TextEditingController(text: widget.order.preferredCourier ?? '');
    _deliveryTermController =
        TextEditingController(text: widget.order.deliveryTerm ?? '');
    _transactionNumberController =
        TextEditingController(text: widget.order.transactionNumber ?? '');
    _microDealerOrderController =
        TextEditingController(text: widget.order.microDealerOrder ?? '');
    _fulfillmentTypeController =
        TextEditingController(text: widget.order.fulfillmentType ?? '');
    _numberOfBoxesController = TextEditingController(
        text: widget.order.numberOfBoxes?.toString() ?? '');
    _totalQuantityController = TextEditingController(
        text: widget.order.totalQuantity?.toString() ?? '');
    _skuQtyController =
        TextEditingController(text: widget.order.skuQty?.toString() ?? '');
    _calcEntryNumberController =
        TextEditingController(text: widget.order.calcEntryNumber ?? '');
    _currencyController =
        TextEditingController(text: widget.order.currency ?? '');
    _paymentDateTimeController = TextEditingController(
        text: widget.order.paymentDateTime != null
            ? _ordersProvider.formatDateTime(widget.order.paymentDateTime!)
            : '');
    _paymentBankController =
        TextEditingController(text: widget.order.paymentBank ?? '');
    _lengthController =
        TextEditingController(text: widget.order.length?.toString() ?? '');
    _breadthController =
        TextEditingController(text: widget.order.breadth?.toString() ?? '');
    _heightController =
        TextEditingController(text: widget.order.height?.toString() ?? '');

    _awbNumberController = TextEditingController(text: widget.order.awbNumber);
    _trackingStatusController =
        TextEditingController(text: widget.order.trackingStatus ?? '');

    // Initalize customer details controllers
    _customerIdController =
        TextEditingController(text: widget.order.customer?.customerId ?? '');
    _customerFirstNameController =
        TextEditingController(text: widget.order.customer?.firstName ?? '');
    _customerLastNameController =
        TextEditingController(text: widget.order.customer?.lastName ?? '');
    _customerEmailController =
        TextEditingController(text: widget.order.customer?.email ?? '');
    _customerPhoneController = TextEditingController(
        text: widget.order.customer?.phone?.toString() ?? '');
    _customerGstinController =
        TextEditingController(text: widget.order.customer?.customerGstin ?? '');

    // Initialize billing address controllers
    _billingFirstNameController = TextEditingController(
        text: widget.order.billingAddress?.firstName ?? '');
    _billingLastNameController = TextEditingController(
        text: widget.order.billingAddress?.lastName ?? '');
    _billingEmailController =
        TextEditingController(text: widget.order.billingAddress?.email ?? '');
    _billingAddress1Controller = TextEditingController(
        text: widget.order.billingAddress?.address1 ?? '');
    _billingAddress2Controller = TextEditingController(
        text: widget.order.billingAddress?.address2 ?? '');
    _billingPhoneController = TextEditingController(
        text: widget.order.billingAddress?.phone?.toString() ?? '');
    _billingCityController =
        TextEditingController(text: widget.order.billingAddress?.city ?? '');
    _billingPincodeController = TextEditingController(
        text: widget.order.billingAddress?.pincode?.toString() ?? '');
    _billingStateController =
        TextEditingController(text: widget.order.billingAddress?.state ?? '');
    _billingCountryController =
        TextEditingController(text: widget.order.billingAddress?.country ?? '');
    _billingCountryCodeController = TextEditingController(
        text: widget.order.billingAddress?.countryCode ?? '');

    // Initialize shipping address controllers
    _shippingFirstNameController = TextEditingController(
        text: widget.order.shippingAddress?.firstName ?? '');
    _shippingLastNameController = TextEditingController(
        text: widget.order.shippingAddress?.lastName ?? '');
    _shippingEmailController =
        TextEditingController(text: widget.order.shippingAddress?.email ?? '');
    _shippingAddress1Controller = TextEditingController(
        text: widget.order.shippingAddress?.address1 ?? '');
    _shippingAddress2Controller = TextEditingController(
        text: widget.order.shippingAddress?.address2 ?? '');
    _shippingPhoneController = TextEditingController(
        text: widget.order.shippingAddress?.phone?.toString() ?? '');
    _shippingCityController =
        TextEditingController(text: widget.order.shippingAddress?.city ?? '');
    _shippingPincodeController = TextEditingController(
        text: widget.order.shippingAddress?.pincode?.toString() ?? '');
    _shippingStateController =
        TextEditingController(text: widget.order.shippingAddress?.state ?? '');
    _shippingCountryController = TextEditingController(
        text: widget.order.shippingAddress?.country ?? '');
    _shippingCountryCodeController = TextEditingController(
        text: widget.order.shippingAddress?.countryCode ?? '');

    // Initialize dynamicItemsList with existing items
    for (var item in widget.order.items) {
      dynamicItemsList.add({
        'product_id': item.product!.id,
        'qty': item.qty,
        'sku': item.sku,
        'amount': item.amount,
      });
      // Initialize controllers for each item
      _quantityControllers
          .add(TextEditingController(text: item.qty.toString()));
      _amountControllers.add(TextEditingController(
          text: item.amount?.toStringAsFixed(2) ?? '0.00'));
    }
    _initializeControllers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _orderIdController.dispose();
    _IdController.dispose();
    _orderStatusController.dispose();
    _dateController.dispose();
    _paymentModeController.dispose();
    _currencyCodeController.dispose();
    _skuTrackingIdController.dispose();
    _totalWeightController.dispose();
    _totalAmtController.dispose();
    _coinController.dispose();
    _codAmountController.dispose();
    _prepaidAmountController.dispose();
    _discountCodeController.dispose();
    _discountSchemeController.dispose();
    _discountPercentController.dispose();
    _discountAmountController.dispose();
    _taxPercentController.dispose();
    _courierNameController.dispose();
    _orderTypeController.dispose();
    _marketplaceController.dispose();
    _filterController.dispose();
    _freightChargeDelhiveryController.dispose();
    _freightChargeShiprocketController.dispose();
    _expectedDeliveryDateController.dispose();
    _preferredCourierController.dispose();
    _deliveryTermController.dispose();
    _transactionNumberController.dispose();
    _microDealerOrderController.dispose();
    _fulfillmentTypeController.dispose();
    _numberOfBoxesController.dispose();
    _totalQuantityController.dispose();
    _skuQtyController.dispose();
    _calcEntryNumberController.dispose();
    _currencyController.dispose();
    _paymentDateTimeController.dispose();
    _paymentBankController.dispose();
    _lengthController.dispose();
    _breadthController.dispose();
    _heightController.dispose();
    _agentController.dispose();
    _notesController.dispose();
    _trackingStatusController.dispose();
    _awbNumberController.dispose();

    // Dispose customer details controllers
    _customerIdController.dispose();
    _customerFirstNameController.dispose();
    _customerLastNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _customerGstinController.dispose();

    // Dispose billing address controllers
    _billingFirstNameController.dispose();
    _billingLastNameController.dispose();
    _billingEmailController.dispose();
    _billingAddress1Controller.dispose();
    _billingAddress2Controller.dispose();
    _billingPhoneController.dispose();
    _billingCityController.dispose();
    _billingPincodeController.dispose();
    _billingStateController.dispose();
    _billingCountryController.dispose();
    _billingCountryCodeController.dispose();

    // Dispose shipping address controllers
    _shippingFirstNameController.dispose();
    _shippingLastNameController.dispose();
    _shippingEmailController.dispose();
    _shippingAddress1Controller.dispose();
    _shippingAddress2Controller.dispose();
    _shippingPhoneController.dispose();
    _shippingCityController.dispose();
    _shippingPincodeController.dispose();
    _shippingStateController.dispose();
    _shippingCountryController.dispose();
    _shippingCountryCodeController.dispose();

    for (var controller in _quantityControllers) {
      controller.dispose();
    }
    for (var controller in _amountControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _clearFields() {
    _orderIdController.clear();
    _dateController.clear();
    _paymentModeController.clear();
    _currencyCodeController.clear();
    _skuTrackingIdController.clear();
    _totalWeightController.clear();
    _totalAmtController.clear();
    _coinController.clear();
    _codAmountController.clear();
    _prepaidAmountController.clear();
    _discountCodeController.clear();
    _discountSchemeController.clear();
    _discountPercentController.clear();
    _discountAmountController.clear();
    _taxPercentController.clear();
    _courierNameController.clear();
    _orderTypeController.clear();
    _marketplaceController.clear();
    _filterController.clear();
    _freightChargeDelhiveryController.clear();
    _freightChargeShiprocketController.clear();
    _expectedDeliveryDateController.clear();
    _preferredCourierController.clear();
    _deliveryTermController.clear();
    _transactionNumberController.clear();
    _microDealerOrderController.clear();
    _fulfillmentTypeController.clear();
    _numberOfBoxesController.clear();
    _totalQuantityController.clear();
    _skuQtyController.clear();
    _calcEntryNumberController.clear();
    _currencyController.clear();
    _paymentDateTimeController.clear();
    _paymentBankController.clear();
    _lengthController.clear();
    _breadthController.clear();
    _heightController.clear();
    _agentController.clear();
    _notesController.clear();
    _trackingStatusController.clear();
    _awbNumberController.clear();

    // Clear customer details
    _customerIdController.clear();
    _customerFirstNameController.clear();
    _customerLastNameController.clear();
    _customerEmailController.clear();
    _customerPhoneController.clear();
    _customerGstinController.clear();

    // Clear billing address
    _billingFirstNameController.clear();
    _billingLastNameController.clear();
    _billingEmailController.clear();
    _billingAddress1Controller.clear();
    _billingAddress2Controller.clear();
    _billingPhoneController.clear();
    _billingCityController.clear();
    _billingPincodeController.clear();
    _billingStateController.clear();
    _billingCountryController.clear();
    _billingCountryCodeController.clear();

    // Clear shipping address
    _shippingFirstNameController.clear();
    _shippingLastNameController.clear();
    _shippingEmailController.clear();
    _shippingAddress1Controller.clear();
    _shippingAddress2Controller.clear();
    _shippingPhoneController.clear();
    _shippingCityController.clear();
    _shippingPincodeController.clear();
    _shippingStateController.clear();
    _shippingCountryController.clear();
    _shippingCountryCodeController.clear();
  }

  // String formatDate(DateTime? date) {
  //   if (date == null) return '';
  //   String year = date.year.toString();
  //   String month = date.month.toString().padLeft(2, '0');
  //   String day = date.day.toString().padLeft(2, '0');
  //   return '$day-$month-$year';
  // }

  Future<void> _selectDate(
      BuildContext context, bool isExpectedDelivery) async {
    DateTime initialDate = DateTime.now();

    if (isExpectedDelivery && _expectedDeliveryDateController.text.isNotEmpty) {
      try {
        initialDate =
            parseDate(_expectedDeliveryDateController.text) ?? DateTime.now();
      } catch (e) {
        print('Error parsing expected delivery date: $e');
      }
    } else if (!isExpectedDelivery && _dateController.text.isNotEmpty) {
      try {
        initialDate = parseDate(_dateController.text) ?? DateTime.now();
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      final formattedDate = _ordersProvider.formatDate(picked);

      if (isExpectedDelivery) {
        Provider.of<OrdersProvider>(context, listen: false)
            .updateExpectedDeliveryDate(formattedDate);
        _expectedDeliveryDateController.text = formattedDate;
      } else {
        Provider.of<OrdersProvider>(context, listen: false)
            .updateDate(formattedDate);
        _dateController.text = formattedDate;
      }
    }
  }

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
      print('Error parsing date string: $e');
    }
    return null;
  }

  void _deleteItem(int index) {
    setState(() {
      deletedItemsIndices.add(index);
      _quantityControllers[index].dispose();
      _amountControllers[index].dispose();
    });
  }

  void _initializeControllers() {
    for (var item in widget.order.items) {
      _quantityControllers
          .add(TextEditingController(text: item.qty.toString()));
      _amountControllers.add(TextEditingController(
          text: item.amount?.toStringAsFixed(2) ?? '0.00'));
    }
  }

  Future<void> _selectPaymentDateTime(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    TimeOfDay initialTime = TimeOfDay.now();
    int initialSeconds = 0;

    if (_paymentDateTimeController.text.isNotEmpty) {
      try {
        DateTime? parsedDate =
            parsePaymentDate(_paymentDateTimeController.text);
        if (parsedDate != null) {
          initialDate = parsedDate;
          initialTime = TimeOfDay.fromDateTime(parsedDate);
          initialSeconds = parsedDate.second; // Capture seconds
        }
      } catch (e) {
        print('Error parsing payment date: $e');
      }
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );

      if (pickedTime != null) {
        final DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
          initialSeconds,
        );

        final formattedDateTime = _ordersProvider.formatDateTime(finalDateTime);
        Provider.of<OrdersProvider>(context, listen: false)
            .updatePaymentDateTime(formattedDateTime);
        _paymentDateTimeController.text = formattedDateTime;
      }
    }
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
      print('Error parsing date string: $e');
    }
    return null;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<Product?> fetchProductbySku(String sku) async {
    final url =
        'https://inventory-management-backend-s37u.onrender.com/products?sku=$sku';

    try {
      final token = await getToken();
      if (token == null) {
        print('No token found');
        return null;
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Log the response body for debugging
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if data contains 'products' key and is not empty
        if (data['products'] != null && data['products'].isNotEmpty) {
          return Product.fromJson(
              data['products'][0]); // Access the first product
        } else {
          print('No products found');
          return null; // Handle case where no products are found
        }
      } else {
        print('Failed to load product, status code: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      print('An error occurred: $error');
      return null;
    }
  }

  Future<Product?> fetchProductById(String productId) async {
    final url =
        'https://inventory-management-backend-s37u.onrender.com/products/search/$productId';

    try {
      final token = await getToken(); // Your method to get token
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Product.fromJson(
            data); // Assuming your Product model has a fromJson method
      } else {
        print('Failed to load product, status code: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      print('An error occurred: $error');
      return null;
    }
  }

  Future<void> _addProduct(Map<String, String>? selected) async {
    if (selected != null) {
      final fetchedProduct = await fetchProductById(selected['id']!);

      if (fetchedProduct != null) {
        final newItem = {
          'product_id': fetchedProduct.id,
          'qty': 1,
          'amount': 0.0,
        };

        setState(() {
          dynamicItemsList.add(newItem);
          _quantityControllers.add(TextEditingController(text: '1'));
          _amountControllers.add(TextEditingController(text: '0.00'));
        });
      } else {
        print('Product could not be added');
      }
    }
  }

  Future<void> _deleteProduct(int index) async {
    if (index < dynamicItemsList.length) {
      setState(() {
        dynamicItemsList.removeAt(index);
        _quantityControllers.removeAt(index);
        _amountControllers.removeAt(index);
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSavingOrder = true; // Set loading state
    });
    // Prepare the items list for the update
    List<Map<String, dynamic>> itemsList = dynamicItemsList.map((item) {
      int index = dynamicItemsList.indexOf(item);
      double amount = double.tryParse(_amountControllers[index].text) ?? 0.0;
      int qty = int.tryParse(_quantityControllers[index].text) ?? 1;
      log("Itemmmmmmmmmmmmmmm $item");
      return {
        'product_id': item['product_id'],
        'qty': qty,
        'sku': item['sku'],
        'amount': amount,
      };
    }).toList();
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> updatedData = {
        'order_id': _orderIdController.text, // required
        'order_status': int.tryParse(_orderStatusController.text), // required
        'date': _dateController.text,
        'payment_mode': _paymentModeController.text,
        'currency_code': _currencyCodeController.text,
        'sku_tracking_id': _skuTrackingIdController.text,
        'coin': _coinController.text,
        'total_weight': _totalWeightController.text,
        'tax_percent': _taxPercentController.text,
        'cod_amount': _codAmountController.text,
        'prepaid_amount': _prepaidAmountController.text,
        'total_amt': _totalAmtController.text,
        'discount_code': _discountCodeController.text,
        'discount_scheme': _discountSchemeController.text,
        'discount_percent': _discountPercentController.text,
        'discount_amount': _discountAmountController.text,
        'courier_name': _courierNameController.text,
        'order_type': _orderTypeController.text,
        'name': _marketplaceController.text,
        'filter':
            _filterController.text.isNotEmpty ? _filterController.text : null,
        'expected_delivery_date':
            parseDate(_expectedDeliveryDateController.text)?.toIso8601String(),
        'preferred_courier': _preferredCourierController.text,
        'delivery_term': _deliveryTermController.text,
        'transaction_number': _transactionNumberController.text,
        'micro_dealer_order': _microDealerOrderController.text,
        'fulfillment_type': _fulfillmentTypeController.text,
        'number_of_boxes': _numberOfBoxesController.text,
        'total_quantity': _totalQuantityController.text,
        'sku_qty': _skuQtyController.text,
        'calc_entry_number': _calcEntryNumberController.text,
        'currency': _currencyController.text,
        'payment_date_time': parsePaymentDate(_paymentDateTimeController.text)
            ?.toIso8601String(),
        'payment_bank': _paymentBankController.text,
        'length': _lengthController.text,
        'breadth': _breadthController.text,
        'height': _heightController.text,
        'tracking_status': _trackingStatusController.text,
        'agent': _agentController.text,
        'notes': _notesController.text,
        'awb_number': _awbNumberController.text,
        //customer
        "customer": {
          'customer_id': _customerIdController.text,
          'first_name': _customerFirstNameController.text,
          'last_name': _customerLastNameController.text,
          'phone': _customerPhoneController.text,
          'email': _customerEmailController.text,
          'customer_gstin': _customerGstinController.text
        },
        //billing address
        "billing_addr": {
          "first_name": _billingFirstNameController.text,
          "last_name": _billingLastNameController.text,
          "email": _billingEmailController.text,
          "address1": _billingAddress1Controller.text,
          "address2": _billingAddress2Controller.text,
          "phone": _billingPhoneController.text,
          "city": _billingCityController.text,
          "pincode": _billingPincodeController.text,
          "state": _billingStateController.text,
          "country": _billingCountryController.text,
          "country_code": _billingCountryCodeController.text,
        },
        //shipping address
        "shipping_addr": {
          "first_name": _shippingFirstNameController.text,
          "last_name": _shippingLastNameController.text,
          "email": _shippingEmailController.text,
          "address1": _shippingAddress1Controller.text,
          "address2": _shippingAddress2Controller.text,
          "phone": _shippingPhoneController.text,
          "city": _shippingCityController.text,
          "pincode": _shippingPincodeController.text,
          "state": _shippingStateController.text,
          "country": _shippingCountryController.text,
          "country_code": _shippingCountryCodeController.text,
        },
        'items': itemsList,
      };

      if (updatedData['order_id'] == null ||
          updatedData['order_id'].isEmpty ||
          updatedData['order_status'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order ID and status are required.')),
        );
        return;
      }

      try {
        await Provider.of<OrdersProvider>(context, listen: false)
            .updateOrder(widget.order.id, updatedData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order updated successfully!')),
        );
        final ordersProvider =
            Provider.of<OrdersProvider>(context, listen: false);
        ordersProvider.fetchReadyOrders();
        ordersProvider.fetchFailedOrders();
        Navigator.of(context).pop();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update order.')),
        );
      } finally {
        // Reset loading state
        setState(() {
          _isSavingOrder = false;
        });
      }
    } else {
      setState(() {
        _isSavingOrder = false; // Reset loading state if validation fails
      });
    }
  }

  Future<List<Product?>> fetchAllProducts(
      List<dynamic> dynamicItemsList) async {
    List<Product?> products = [];
    for (var item in dynamicItemsList) {
      Product? product = await fetchProductById(item['product_id']);
      products.add(product);
    }
    return products;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          title: const Text('Edit Order'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(AppColors.orange),
                  padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 12.0)),
                ),
                onPressed: _saveChanges,
                child: _isSavingOrder
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Field
                const Text(
                  "Order Details",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: AppColors.green,
                  ),
                ),
                const Divider(thickness: 1, color: AppColors.grey),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                          controller: _orderIdController,
                          label: 'Order ID',
                          icon: Icons.confirmation_number,
                          enabled: false),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, false),
                        child: AbsorbPointer(
                          child: _buildTextField(
                            controller: _dateController,
                            label: "Date",
                            icon: Icons.date_range,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _orderTypeController,
                        label: 'Order Type',
                        icon: Icons.shopping_cart,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ChangeNotifierProvider.value(
                        value: _ordersProvider,
                        child: Consumer<OrdersProvider>(
                          builder: (context, ordersProvider, child) {
                            final String? selectedMarketplace =
                                ordersProvider.selectedMarketplace;
                            final bool isCustomMarketplace =
                                selectedMarketplace != null &&
                                    selectedMarketplace.isNotEmpty &&
                                    selectedMarketplace != 'Shopify' &&
                                    selectedMarketplace != 'Woocommerce' &&
                                    selectedMarketplace != 'Offline';

                            final List<DropdownMenuItem<String>> item = [
                              const DropdownMenuItem<String>(
                                value: 'Shopify',
                                child: Text('Shopify'),
                              ),
                              const DropdownMenuItem<String>(
                                value: 'Woocommerce',
                                child: Text('Woocommerce'),
                              ),
                              const DropdownMenuItem<String>(
                                value: 'Offline',
                                child: Text('Offline'),
                              ),
                            ];

                            if (isCustomMarketplace) {
                              item.add(DropdownMenuItem<String>(
                                value: selectedMarketplace,
                                child: Text(selectedMarketplace),
                              ));
                            }

                            return DropdownButtonFormField<String>(
                              value: selectedMarketplace,
                              decoration: const InputDecoration(
                                labelText: 'Marketplace',
                                prefixIcon: Icon(Icons.store),
                                border: OutlineInputBorder(),
                              ),
                              dropdownColor: Colors.white,
                              hint: const Text('Select Marketplace'),
                              items: item,
                              onChanged: (value) {
                                if (value != null) {
                                  ordersProvider.selectMarketplace(value);
                                  _marketplaceController.text = value;
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _microDealerOrderController,
                        label: 'Micro Dealer Order',
                        icon: Icons.shopping_cart,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _fulfillmentTypeController,
                        label: 'Fulfillment Type',
                        icon: Icons.assignment,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _transactionNumberController,
                        label: 'Transaction Number',
                        icon: Icons.confirmation_number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _calcEntryNumberController,
                        label: 'Calculation Entry Number',
                        icon: Icons.calculate,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: ChangeNotifierProvider.value(
                        value: _ordersProvider,
                        child: Consumer<OrdersProvider>(
                            builder: (context, ordersProvider, child) {
                          final String? selectedFilter =
                              ordersProvider.selectedFilter;

                          // Create the list of DropdownMenuItems
                          final List<DropdownMenuItem<String>> items = [
                            const DropdownMenuItem<String>(
                              value: 'B2B',
                              child: Text('B2B'),
                            ),
                            const DropdownMenuItem<String>(
                              value: 'B2C',
                              child: Text('B2C'),
                            ),
                          ];

                          // Add custom filter if it exists and is not already listed
                          if (selectedFilter != null &&
                              selectedFilter.isNotEmpty &&
                              selectedFilter != 'B2B' &&
                              selectedFilter != 'B2C') {
                            items.add(DropdownMenuItem<String>(
                              value: selectedFilter,
                              child: Text(selectedFilter),
                            ));
                          }

                          return DropdownButtonFormField<String>(
                            value:
                                selectedFilter, // Show the current selected value or null
                            decoration: const InputDecoration(
                              labelText: 'Filter',
                              prefixIcon: Icon(Icons.filter_1),
                              border: OutlineInputBorder(),
                            ),
                            dropdownColor: Colors.white,
                            hint: const Text(
                                'Select Filter'), // Hint text when no value is selected
                            items: items,
                            onChanged: (value) {
                              ordersProvider.selectFilter(
                                  value); // Update the selected filter
                              _filterController.text =
                                  value ?? ''; // Clear the controller if null
                            },
                          );
                        }),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                // Customer Details
                _buildHeading("Payment Details"),
                const Divider(thickness: 1, color: AppColors.grey),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ChangeNotifierProvider.value(
                        value: _ordersProvider,
                        child: Consumer<OrdersProvider>(
                          builder: (context, ordersProvider, child) {
                            final String? selectedPayment =
                                ordersProvider.selectedPayment;
                            final bool isCustomPayment =
                                selectedPayment != null &&
                                    selectedPayment.isNotEmpty &&
                                    selectedPayment != 'PrePaid' &&
                                    selectedPayment != 'COD';

                            final List<DropdownMenuItem<String>> item = [
                              const DropdownMenuItem<String>(
                                value: 'PrePaid',
                                child: Text('PrePaid'),
                              ),
                              const DropdownMenuItem<String>(
                                value: 'COD',
                                child: Text('COD'),
                              ),
                            ];

                            if (isCustomPayment) {
                              item.add(DropdownMenuItem<String>(
                                value: selectedPayment,
                                child: Text(selectedPayment),
                              ));
                            }

                            return DropdownButtonFormField<String>(
                              value: selectedPayment,
                              decoration: const InputDecoration(
                                labelText: 'Payment Mode',
                                prefixIcon: Icon(Icons.payment),
                                border: OutlineInputBorder(),
                              ),
                              dropdownColor: Colors.white,
                              hint: const Text('Select Payment Mode'),
                              items: item,
                              onChanged: (value) {
                                if (value != null) {
                                  ordersProvider.selectPayment(value);
                                  _paymentModeController.text = value;
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _currencyCodeController,
                        label: "Currency Code",
                        icon: Icons.currency_bitcoin,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _currencyController,
                        label: 'Currency',
                        icon: Icons.monetization_on,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _paymentBankController,
                        label: 'Payment Bank',
                        icon: Icons.account_balance,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectPaymentDateTime(context),
                        child: AbsorbPointer(
                          child: _buildTextField(
                            controller: _paymentDateTimeController,
                            label: "Payment Date and Time",
                            icon: Icons.access_time,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _codAmountController,
                        label: 'COD Amount',
                        icon: Icons.money,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _prepaidAmountController,
                        label: 'Prepaid Amount',
                        icon: Icons.credit_card,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _totalAmtController,
                        label: 'Total Amount',
                        icon: Icons.currency_rupee,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Customer Details

                _buildHeading("Shipping and Delivery Details"),
                const Divider(thickness: 1, color: AppColors.grey),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ChangeNotifierProvider.value(
                        value: _ordersProvider,
                        child: Consumer<OrdersProvider>(
                          builder: (context, ordersProvider, child) {
                            final String? selectedCourier =
                                ordersProvider.selectedCourier;
                            final bool isCustomCourier =
                                selectedCourier != null &&
                                    selectedCourier.isNotEmpty &&
                                    selectedCourier != 'Delhivery' &&
                                    selectedCourier != 'Shiprocket';

                            final List<DropdownMenuItem<String>> items = [
                              const DropdownMenuItem<String>(
                                value: 'Delhivery',
                                child: Text('Delhivery'),
                              ),
                              const DropdownMenuItem<String>(
                                value: 'Shiprocket',
                                child: Text('Shiprocket'),
                              ),
                            ];

                            if (isCustomCourier) {
                              items.add(DropdownMenuItem<String>(
                                value: selectedCourier,
                                child: Text(selectedCourier),
                              ));
                            }

                            return DropdownButtonFormField<String>(
                              value: selectedCourier,
                              decoration: const InputDecoration(
                                labelText: 'Courier Name',
                                prefixIcon: Icon(Icons.local_shipping),
                                border: OutlineInputBorder(),
                              ),
                              dropdownColor: Colors.white,
                              hint: const Text('Select Courier'),
                              items: items,
                              onChanged: (value) {
                                if (value != null) {
                                  ordersProvider.selectCourier(value);
                                  _courierNameController.text = value;
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _preferredCourierController,
                        label: 'Preferred Courier',
                        icon: Icons.local_shipping,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _deliveryTermController,
                        label: 'Delivery Term',
                        icon: Icons.description,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _skuTrackingIdController,
                        label: 'SKU Tracking ID',
                        icon: Icons.local_shipping,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, true),
                        child: AbsorbPointer(
                          child: _buildTextField(
                            controller: _expectedDeliveryDateController,
                            label: "Expected Delivery Date",
                            icon: Icons.date_range,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _trackingStatusController,
                        label: 'Tracking Status',
                        icon: Icons.local_shipping,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Customer Details
                _buildHeading("Order Specifications"),
                const Divider(thickness: 1, color: AppColors.grey),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _numberOfBoxesController,
                        label: 'Number of Boxes',
                        icon: Icons.inbox,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _totalQuantityController,
                        label: 'Total Quantity',
                        icon: Icons.format_list_numbered,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _skuQtyController,
                        label: 'SKU Quantity',
                        icon: Icons.list_alt,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _totalWeightController,
                        label: 'Total Weight',
                        icon: Icons.line_weight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Customer Details

                _buildHeading("Order Dimension"),
                const Divider(thickness: 1, color: AppColors.grey),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _lengthController,
                        label: 'Length',
                        icon: Icons.straighten,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _breadthController,
                        label: 'Breadth',
                        icon: Icons.straighten,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _heightController,
                        label: 'Height',
                        icon: Icons.height,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                // Customer Details
                _buildHeading("Discount Information"),
                const Divider(thickness: 1, color: AppColors.grey),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _discountCodeController,
                        label: 'Discount Code',
                        icon: Icons.discount,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _discountSchemeController,
                        label: 'Discount Scheme',
                        icon: Icons.card_giftcard,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _discountPercentController,
                        label: 'Discount Percent',
                        icon: Icons.percent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _discountAmountController,
                        label: 'Discount Amount',
                        icon: Icons.money_off,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Customer Details
                _buildHeading("Additional Information"),
                const Divider(thickness: 1, color: AppColors.grey),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _coinController,
                        label: 'Coin',
                        icon: Icons.monetization_on,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _taxPercentController,
                        label: 'Tax Percent',
                        icon: Icons.account_balance_wallet,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _agentController,
                        label: 'Agent',
                        icon: Icons.person,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _notesController,
                        label: 'Notes',
                        icon: Icons.note,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    if (widget.isBookPage)
                      Expanded(
                        child: _buildTextField(
                          controller: _awbNumberController,
                          label: 'AWB Number',
                          icon: Icons.confirmation_number,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 30),
                // Customer Details
                _buildHeading("Customer Details"),
                const Divider(thickness: 1, color: AppColors.grey),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _customerIdController,
                        label: 'Customer ID',
                        icon: Icons.perm_identity,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _customerEmailController,
                        label: 'Email',
                        icon: Icons.email,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _customerFirstNameController,
                        label: 'First Name',
                        icon: Icons.person,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _customerLastNameController,
                        label: 'Last Name',
                        icon: Icons.person,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _customerPhoneController,
                        label: 'Phone',
                        icon: Icons.phone,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _customerGstinController,
                        label: 'Customer GSTin',
                        icon: Icons.business,
                      ),
                    ),
                  ],
                ),

                // Billing Address
                const SizedBox(height: 30),
                _buildHeading("Billing Address"),
                const Divider(thickness: 1, color: AppColors.grey),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _billingFirstNameController,
                        label: 'First Name',
                        icon: Icons.person,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _billingLastNameController,
                        label: 'Last Name',
                        icon: Icons.person,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _billingEmailController,
                        label: 'Email',
                        icon: Icons.email,
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _billingAddress1Controller,
                        label: 'Address 1',
                        icon: Icons.location_on,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _billingAddress2Controller,
                        label: 'Address 2',
                        icon: Icons.location_on,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _billingCityController,
                        label: 'City',
                        icon: Icons.location_city,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _billingStateController,
                        label: 'State',
                        icon: Icons.map,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _billingCountryController,
                        label: 'Country',
                        icon: Icons.public,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _billingPhoneController,
                        label: 'Phone',
                        icon: Icons.phone,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _billingPincodeController,
                        label: 'Pincode',
                        icon: Icons.code,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _billingCountryCodeController,
                        label: 'Country Code',
                        icon: Icons.travel_explore,
                      ),
                    ),
                  ],
                ),

                // Shipping Address
                const SizedBox(height: 30),

                _buildHeading("Shipping Address"),
                const Divider(thickness: 1, color: AppColors.grey),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _shippingFirstNameController,
                        label: 'First Name',
                        icon: Icons.person,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _shippingLastNameController,
                        label: 'Last Name',
                        icon: Icons.person,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _shippingEmailController,
                        label: 'Email',
                        icon: Icons.email,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _shippingAddress1Controller,
                        label: 'Address 1',
                        icon: Icons.location_on,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _shippingAddress2Controller,
                        label: 'Address 2',
                        icon: Icons.location_on,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _shippingCityController,
                        label: 'City',
                        icon: Icons.location_city,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _shippingStateController,
                        label: 'State',
                        icon: Icons.map,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _shippingCountryController,
                        label: 'Country',
                        icon: Icons.public,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _shippingPhoneController,
                        label: 'Phone',
                        icon: Icons.phone,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _shippingPincodeController,
                        label: 'Pincode',
                        icon: Icons.code,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: _shippingCountryCodeController,
                        label: 'Country Code',
                        icon: Icons.travel_explore,
                      ),
                    ),
                  ],
                ),

                //Product Details
                const SizedBox(height: 30),
                _buildHeading('Items (Product Details)'),
                const Divider(
                    thickness: 1, color: Color.fromARGB(164, 158, 158, 158)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: SearchableDropdown(
                        label: 'Add Product',
                        onChanged: (selected) {
                          _addProduct(selected);
                          print('Selected Product: $selected');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (widget.order.items.isEmpty)
                  const Center(
                    child: Text(
                      'No Products',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey,
                      ),
                    ),
                  )
                else
                  FutureBuilder<List<Product?>>(
                    future: fetchAllProducts(dynamicItemsList),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData ||
                          snapshot.data == null ||
                          snapshot.data!.isEmpty) {
                        return const Center(child: Text('No products found'));
                      } else {
                        final products = snapshot.data!;
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: dynamicItemsList.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            if (product == null) {
                              return const Text('No product found');
                            }
                            return Row(
                              children: [
                                Expanded(
                                  flex: 9,
                                  child: ProductDetailsCard(
                                    product: product,
                                    index: index,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        width: 140,
                                        child: _buildTextField(
                                          controller:
                                              _quantityControllers[index],
                                          label: 'Qty',
                                          icon:
                                              Icons.production_quantity_limits,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: 140,
                                        child: _buildTextField(
                                          controller: _amountControllers[index],
                                          label: 'Amount',
                                          icon: Icons.currency_rupee,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          _deleteProduct(index);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.delete),
                                            SizedBox(width: 8),
                                            Text('Delete Item'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Function to build headings
  Widget _buildHeading(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: AppColors.primaryBlue,
      ),
    );
  }

  // Function to build text fields
  // Function to build text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
  }) {
    return Focus(
      child: Builder(
        builder: (BuildContext context) {
          final bool isFocused = Focus.of(context).hasFocus;
          final bool isEmpty = controller.text.isEmpty;

          return TextFormField(
            controller: controller,
            enabled: enabled,
            style: TextStyle(
              color: enabled ? AppColors.green : Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: isFocused || !isEmpty
                    ? Colors.black
                    : Colors.grey.withOpacity(0.7),
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.grey[400]!,
                ),
              ),
              prefixIcon: Icon(icon, color: Colors.black),
              filled: true,
              fillColor: enabled ? Colors.white : Colors.grey[300],
            ),
          );
        },
      ),
    );
  }
}
