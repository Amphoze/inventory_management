import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/model/manifest_model.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ManifestProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _selectAll = false;
  List<bool> _selectedProducts = [];
  List<Order> _orders = [];
  List<Manifest> _manifests = [];
  int _currentPage = 1; // Ensure this starts at 1
  int _totalPages = 1;
  final PageController _pageController = PageController();
  final TextEditingController _textEditingController = TextEditingController();
  Timer? _debounce;

  bool get selectAll => _selectAll;
  List<bool> get selectedProducts => _selectedProducts;
  List<Order> get orders => _orders;
  List<Manifest> get manifests => _manifests;
  bool get isLoading => _isLoading;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  PageController get pageController => _pageController;
  TextEditingController get textEditingController => _textEditingController;

  int get selectedCount => _selectedProducts.where((isSelected) => isSelected).length;

  bool isRefreshingOrders = false;

  void setRefreshingOrders(bool value) {
    isRefreshingOrders = value;
    notifyListeners();
  }

  bool isCreatingManifest = false;

  void setCreatingManifest(bool value) {
    isCreatingManifest = value;
    notifyListeners();
  }

  void toggleSelectAll(bool value) {
    _selectAll = value;
    _selectedProducts = List<bool>.generate(_orders.length, (index) => _selectAll);
    notifyListeners();
  }

  void toggleProductSelection(int index, bool value) {
    _selectedProducts[index] = value;
    _selectAll = selectedCount == _orders.length;
    notifyListeners();
  }

  bool isCancel = false;
  void setCancelStatus(bool status) {
    isCancel = status;
    notifyListeners();
  }

  Future<String> cancelOrders(BuildContext context, List<String> orderIds) async {
    String baseUrl = await Constants.getBaseUrl();
    String cancelOrderUrl = '$baseUrl/orders/cancel';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    setCancelStatus(true);
    notifyListeners();

    // Headers for the API request
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // Request body containing the order IDs
    final body = json.encode({
      'orderIds': orderIds,
    });

    try {
      // Make the POST request to confirm the orders
      final response = await http.post(
        Uri.parse(cancelOrderUrl),
        headers: headers,
        body: body,
      );

      print('Response status: ${response.statusCode}');
      //print('Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // After successful confirmation, fetch updated orders and notify listeners
        await fetchOrdersWithStatus8(); // Assuming fetchOrders is a function that reloads the orders
        // resetSelections(); // Clear selected order IDs
        setCancelStatus(false);
        notifyListeners(); // Notify the UI to rebuild

        return responseData['message'] ?? 'Orders cancelled successfully';
      } else {
        return responseData['message'] ?? 'Failed to cancel orders';
      }
    } catch (error) {
      setCancelStatus(false);
      notifyListeners();
      print('Error during API request: $error');
      return 'An error occurred: $error';
    }
  }

  Future<void> fetchOrdersWithStatus8({DateTime? date}) async {
    _isLoading = true;
    setRefreshingOrders(true);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    String url = '${await Constants.getBaseUrl()}/orders?orderStatus=8&page=$_currentPage';

    if (date != null || date == 'Select Date') {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date!);
      url += '&date=$formattedDate';
    }

    Uri uri = Uri.parse(url);

    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      log("Code: ${response.statusCode}");
      // log("Body: ${response.body}");

      log('Fetching URL for  manifest orders :- $uri');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<Order> orders = (data['orders'] as List).map((order) => Order.fromJson(order)).toList();

        _totalPages = data['totalPages']; // Get total pages from response
        _orders = orders; // Set the orders for the current page

        // Initialize selected products list
        _selectedProducts = List<bool>.filled(_orders.length, false);

        // Print the total number of orders fetched from the current page
        print('Total Orders Fetched from Page $_currentPage: ${orders.length}');
      } else {
        // Handle non-success responses
        _orders = [];
        _totalPages = 1; // Reset total pages if there’s an error
      }
    } catch (e, s) {
      // Handle errors
      log('error aaya hai: $e $s');
      _orders = [];
      _totalPages = 1; // Reset total pages if there’s an error
    } finally {
      _isLoading = false;
      setRefreshingOrders(false);
      notifyListeners();
    }
  }

  Future<void> fetchCreatedManifests(int page) async {
    Logger().e('fetchCreatedManifests');
    _isLoading = true;
    setRefreshingOrders(true);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    var url = '${await Constants.getBaseUrl()}/manifest';

    Logger().e('url: $url');

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      log("Code: ${response.statusCode}");
      // log("Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // debugPrint("data: $data");

        List<Manifest> manifests = (data['data']['manifest'] as List).map((manifest) => Manifest.fromJson(manifest)).toList();

        log('manifests hai" $manifests');

        _totalPages = data['data']['totalPages'];
        _currentPage = data['data']['currentPage']; // Get total pages from response
        _manifests = manifests; // Set the orders for the current page
        // log(_totalPages.toString());

        log('Total Orders Fetched from Page $_currentPage: ${manifests.length}');
      } else {
        // Handle non-success responses
        _manifests = [];
        _totalPages = 1; // Reset total pages if there’s an error
      }
    } catch (e, s) {
      log("catch data $e $s");
      // Handle errors
      _manifests = [];
      _totalPages = 1; // Reset total pages if there’s an error
    } finally {
      _isLoading = false;
      setRefreshingOrders(false);
      notifyListeners();
    }
  }

  Future<void> createManifest(BuildContext context, String deliveryPartner) async {
    setCreatingManifest(true);
    notifyListeners();

    if (deliveryPartner == 'All') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery courier'),
          backgroundColor: Colors.red,
        ),
      );
      setCreatingManifest(false);
      notifyListeners();
      return;
    }

    final selectedOrderIds = _orders.asMap().entries.where((entry) => _selectedProducts[entry.key]).map((entry) => entry.value.orderId).toList();

    if (selectedOrderIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No orders selected to create manifest'),
          backgroundColor: Colors.red,
        ),
      );
      setCreatingManifest(false);
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    String url = '${await Constants.getBaseUrl()}/manifest';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'orderIds': selectedOrderIds,
            'deliveryPartner': deliveryPartner,
          },
        ),
      );

      log("status code: ${response.statusCode}");

      final res = jsonDecode(response.body);

      log('create manifest body: $res');

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']),
            backgroundColor: Colors.green,
          ),
        );

        fetchOrdersWithStatus8();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['error']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      print('Error updating order status: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error while creating manifest, $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setCreatingManifest(false);
      notifyListeners();
    }
  }

  void handleRowCheckboxChange(int index, bool isSelected) {
    _selectedProducts[index] = isSelected;

    // If any individual checkbox is unchecked, deselect "Select All"
    if (!isSelected) {
      _selectAll = false;
    } else {
      // If all boxes are checked, select "Select All"
      _selectAll = _selectedProducts.every((element) => element);
    }

    notifyListeners();
  }

  Future<void> fetchOrdersByBookingCourier(String courier, int page, {DateTime? date}) async {
    _isLoading = true;
    setRefreshingOrders(true);
    notifyListeners();

    log("courier: $courier");

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    String baseUrl = await Constants.getBaseUrl();

    // Build URL with base parameters
    String url = '$baseUrl/orders?orderStatus=8&bookingCourier=$courier&page=$page';

    // Add date parameter if provided
    if (date != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date!);
      url += '&date=$formattedDate';
    }

    log('url :): $url');

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      log("Code: ${response.statusCode}");
      log("Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Order> orders = (data['orders'] as List).map((order) => Order.fromJson(order)).toList();

        log("orders: $orders");

        _totalPages = data['totalPages']; // Get total pages from response
        _orders = orders; // Set the orders for the current page

        // Initialize selected products list
        _selectedProducts = List<bool>.filled(_orders.length, false);

        // Print the total number of orders fetched from the current page
        print('Total Orders Fetched from Page $_currentPage: ${orders.length}');
      } else {
        // Handle non-success responses
        _orders = [];
        _totalPages = 1; // Reset total pages if there’s an error
      }
    } catch (e) {
      // Handle errors
      _orders = [];
      _totalPages = 1; // Reset total pages if there’s an error
    } finally {
      _isLoading = false;
      setRefreshingOrders(false);
      notifyListeners();
    }
  }

// Debounce function to avoid searching on every keystroke
  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
        // If query is empty, reload all orders
        fetchOrdersWithStatus8();
      } else {
        searchOrders(query); // Trigger the search after the debounce period
      }
    });
  }

// Method to search orders by order ID
  Future<List<Order>> searchOrders(String query) async {
    if (query.isEmpty) {
      await fetchOrdersWithStatus8();
      return _orders;
    }

    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';

    final url = '${await Constants.getBaseUrl()}/orders?orderStatus=8&order_id=$query';

    print('Searching failed orders with term: $query');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('Response data: $jsonData');

        List<Order> orders = [];
        if (jsonData != null) {
          orders.add(Order.fromJson(jsonData));
        } else {
          print('No data found in response.');
        }

        _orders = orders;
        print('Orders fetched: ${orders.length}');
      } else {
        print('Failed to load orders: ${response.statusCode}');
        _orders = [];
      }
    } catch (error) {
      print('Error searching failed orders: $error');
      _orders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _orders;
  }

  void goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    _currentPage = page;
    print('Current page set to: $_currentPage'); // Debugging line
    fetchOrdersWithStatus8();
    notifyListeners();
  }

  // Format date
  String formatDate(DateTime date) {
    String year = date.year.toString();
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');
    return '$day-$month-$year';
  }
}
