import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:logger/logger.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;

class BookProvider with ChangeNotifier {
  final TextEditingController searchController = TextEditingController();

  List<bool> selectedB2BItems = List.generate(40, (index) => false);
  List<bool> selectedB2CItems = List.generate(40, (index) => false);
  List<bool> selectedBookedItems = List.generate(40, (index) => false);

  bool selectAllB2B = false;
  bool selectAllB2C = false;
  bool selectAllBooked = false;

  bool isLoadingB2B = false;
  bool isLoadingB2C = false;
  bool isLoadingBooked = false;

  String? _sortOption;
  String? get sortOption => _sortOption;

  List<Order> _ordersB2B = [];
  List<Order> _ordersB2C = [];
  List<Order> _ordersBooked = [];

  List<Order> get ordersB2B => _ordersB2B;
  List<Order> get ordersB2C => _ordersB2C;
  List<Order> get ordersBooked => _ordersBooked;

  int currentPageB2B = 1;
  int currentPageB2C = 1;
  int currentPageBooked = 1;
  int totalPagesB2B = 0;
  int totalPagesB2C = 0;
  int totalPagesBooked = 0;

  bool isRefreshingOrders = false;
  bool isDelhiveryLoading = false;
  bool isShiprocketLoading = false;
  bool isOthersLoading = false;

  bool isCancel = false;
  bool isRebook = false;

  void setCancelStatus(bool status) {
    isCancel = status;
    notifyListeners();
  }

  void setRebookingStatus(bool status) {
    isRebook = status;
    notifyListeners();
  }

  void setLoading(String provider, bool isLoading) {
    switch (provider) {
      case 'Delhivery':
        isDelhiveryLoading = isLoading;
        break;
      case 'Shiprocket':
        isShiprocketLoading = isLoading;
        break;
      case 'Others':
        isOthersLoading = isLoading;
        break;
    }
    notifyListeners();
  }

  void setRefreshingOrders(bool value) {
    isRefreshingOrders = value;
    notifyListeners();
  }

  void setRefreshingBookedOrders(bool value) {
    isRefreshingOrders = value;
    notifyListeners();
  }

  void setSortOption(String? option) {
    _sortOption = option;
    notifyListeners();
  }

  Future<void> fetchPaginatedOrdersB2B(int page) async {
    await fetchOrders('B2B', page);
  }

  Future<String> cancelOrders(BuildContext context, List<String> orderIds) async {
    String baseUrl = await Constants.getBaseUrl();
    String cancelOrderUrl = '$baseUrl/orders/cancel';

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    setCancelStatus(true);
    notifyListeners();

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final body = json.encode({
      'orderIds': orderIds,
    });

    try {
      final response = await http.post(
        Uri.parse(cancelOrderUrl),
        headers: headers,
        body: body,
      );

      print('Response status: ${response.statusCode}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        setRefreshingOrders(false);
        setCancelStatus(false);
        notifyListeners();

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

  Future<bool> writeRemark(BuildContext context, String id, String msg) async {
    final token = await _getToken();
    notifyListeners();
    if (token!.isEmpty) {
      print('Token is missing. Please log in again.');
      return false;
    }

    final url = '${await Constants.getBaseUrl()}/orders/$id';
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          "messages": {"bookerMessage": msg}
        }),
      );

      log("response: ${response.statusCode}");

      if (response.statusCode == 200) {
        return true;
      } else {
        log('Failed to update order: ${response.body}');
        return false;
      }
    } catch (error) {
      log('Error updating order: $error');
      return false;
    }
  }

  Future<String> rebookOrders(List<String> orderIds) async {
    String baseUrl = await Constants.getBaseUrl();
    String url = '$baseUrl/orders/reBooking';

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    setRebookingStatus(true);
    notifyListeners();

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final body = json.encode({
      'orderIds': orderIds,
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print('Response status: ${response.statusCode}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        setRefreshingOrders(false);
        setRebookingStatus(false);
        notifyListeners();

        return responseData['message'] ?? 'Orders cancelled successfully';
      } else {
        return responseData['message'] ?? 'Failed to cancel orders';
      }
    } catch (error) {
      setRebookingStatus(false);
      notifyListeners();
      print('Error during API request: $error');
      return 'An error occurred: $error';
    }
  }

  Future<void> fetchPaginatedOrdersB2C(int page) async {
    Logger().e('ye le call ho gaya');
    await fetchOrders('B2C', page);
  }

  Future<void> fetchOrders(String type, int page, {DateTime? date, String? market}) async {
    String? token = await _getToken();
    final prefs = await SharedPreferences.getInstance();
    final warehouseId = prefs.getString('warehouseId') ?? '';

    if (token == null) {
      print('Token is null, unable to fetch orders.');
      return;
    }

    String url = '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&filter=$type&orderStatus=3&page=$page';

    if (date != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      url += '&date=$formattedDate';
    }

    if (market != 'All' && market != null) {
      url += '&marketplace=$market';
    }

    Logger().e('fetchOrders url: $url');

    try {
      if (type == 'B2B') {
        isLoadingB2B = true;
        setRefreshingOrders(true);
      } else {
        isLoadingB2C = true;
        setRefreshingOrders(true);
      }
      notifyListeners();

      clearAllSelections();

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        List<Order> orders = (jsonResponse['orders'] as List).map((orderJson) => Order.fromJson(orderJson)).toList();

        log('fetch book orders: ${orders.length}');
        if (type == 'B2B') {
          _ordersB2B = orders;
          currentPageB2B = page;
          totalPagesB2B = jsonResponse['totalPages'];
        } else {
          _ordersB2C = orders;
          currentPageB2C = page;
          totalPagesB2C = jsonResponse['totalPages'];
        }
      } else {
        if (type == 'B2B') {
          _ordersB2B = [];
          currentPageB2B = 1;
          totalPagesB2B = 0;
        } else {
          _ordersB2C = [];
          currentPageB2C = 1;
          totalPagesB2C = 0;
        }
      }
    } catch (e) {
      if (type == 'B2B') {
        _ordersB2B = [];
        currentPageB2B = 1;
        totalPagesB2B = 0;
      } else {
        _ordersB2C = [];
        currentPageB2C = 1;
        totalPagesB2C = 0;
      }
      log('Error fetching book page - $type orders: $e');
    } finally {
      if (type == 'B2B') {
        isLoadingB2B = false;
        setRefreshingOrders(false);
      } else {
        isLoadingB2C = false;
        setRefreshingOrders(false);
      }
      notifyListeners();
    }
  }

  Future<void> fetchBookedOrders(int page, {DateTime? date, String? market}) async {
    String? token = await _getToken();
    final prefs = await SharedPreferences.getInstance();
    final warehouseId = prefs.getString('warehouseId') ?? '';

    if (token == null) {
      print('Token is null, unable to fetch orders.');
      return;
    }

    String url = '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&isBooked=true&page=$page';

    if (date != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      url += '&date=$formattedDate';
    }

    if (market != 'All' && market != null) {
      url += '&marketplace=$market';
    }

    try {
      isLoadingBooked = true;
      setRefreshingBookedOrders(true);
      notifyListeners();

      clearAllSelections();

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        List<Order> orders = (jsonResponse['orders'] as List).map((orderJson) => Order.fromJson(orderJson)).toList();

        Logger().e(jsonResponse['orders'][0]['isBooked']['status']);

        _ordersBooked = orders;
        currentPageBooked = page;
        totalPagesBooked = jsonResponse['totalPages'];
      } else {
        _ordersBooked = [];
        currentPageBooked = 1;
        totalPagesBooked = 0;
      }
    } catch (e) {
      _ordersBooked = [];
      currentPageBooked = 1;
      totalPagesBooked = 0;
      log('Error fetching orders: $e');
    } finally {
      isLoadingBooked = false;
      setRefreshingBookedOrders(false);
      notifyListeners();
    }
  }

  Future<String> bookOrders(BuildContext context, List<Map<String, String>> orderIds, String courier) async {
    log('courier: $courier');
    setLoading(courier, true);
    String baseUrl = await Constants.getBaseUrl();
    String bookOrderUrl = '$baseUrl/orders/book';
    final String? token = await _getToken();

    if (token == null) {
      setLoading(courier, false);
      return 'No auth token found';
    }

    log('list: $orderIds');
    String? res;
    if (courier == 'Shiprocket') {
      for (int i = 0; i < orderIds.length; i++) {
        String orderId = orderIds[i]['orderId']!;
        String courierId = orderIds[i]['courierId']!;

        res = await bookShiprocketOrder(context, orderId, courierId, courier);
      }
      return res ?? '';
    }

    List<String?> orderIdsList = orderIds.map((orderId) => orderId['orderId']).toList();

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final body = json.encode({
      'orderIds': orderIdsList,
      'service': courier.toLowerCase(),
    });
    log(body);

    try {
      final response = await http.post(
        Uri.parse(bookOrderUrl),
        headers: headers,
        body: body,
      );

      final responseData = json.decode(response.body);

      log('book responseData: $responseData');

      if (response.statusCode == 200) {
        clearAllSelections();
        setLoading(courier, false);

        notifyListeners();
        return "${responseData['message'] ?? ''} - (${responseData["serviceResponse"][0]["orderCreationResponse"]["pickup_location"]["name"] ?? ''})";
      } else {
        setLoading(courier, false);
        return responseData['message'] ?? 'Failed to book orders';
      }
    } catch (error) {
      log('Error during API request: $error');
      return 'An error occurred: $error';
    } finally {
      setLoading(courier, false);
      notifyListeners();
    }
  }

  Future<String> bookShiprocketOrder(BuildContext context, String orderId, String courierId, String courier) async {
    String baseUrl = await Constants.getBaseUrl();
    String bookOrderUrl = '$baseUrl/orders/book';
    final String? token = await _getToken();

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final body = json.encode({
      'orderIds': [orderId],
      'service': courier.toLowerCase(),
      'courierId': courierId,
    });

    log('body: $body');

    try {
      final response = await http.post(
        Uri.parse(bookOrderUrl),
        headers: headers,
        body: body,
      );

      final responseData = json.decode(response.body);

      log('Shiprocket response: $responseData');

      if (response.statusCode == 200) {
        clearAllSelections();
        setLoading(courier, false);

        notifyListeners();
        return "${responseData['message'] ?? 'Orders booked successfully'}";
      } else {
        setLoading(courier, false);
        return responseData['message'] ?? 'Failed to book orders';
      }
    } catch (error) {
      log('Error during API request: $error');
      setLoading(courier, false);
    } finally {
      setLoading(courier, false);
      notifyListeners();
    }
    return '';
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  void onSearchChanged() {
    print('Search query: ${searchController.text}');
    notifyListeners();
  }

  void handleRowCheckboxChange(String? orderId, bool isSelected, bool isB2B) {
    int index;
    if (isB2B) {
      index = _ordersB2B.indexWhere((order) => order.orderId == orderId);
      if (index != -1) {
        selectedB2BItems[index] = isSelected;
        _ordersB2B[index].isSelected = isSelected;
      }
    } else {
      index = _ordersB2C.indexWhere((order) => order.orderId == orderId);
      if (index != -1) {
        selectedB2CItems[index] = isSelected;
        _ordersB2C[index].isSelected = isSelected;
      }
    }
    _updateSelectAllState(isB2B);
    notifyListeners();
  }

  void handleRowCheckboxChangeBooked(String? orderId, bool isSelected) {
    int index;
    index = _ordersBooked.indexWhere((order) => order.orderId == orderId);
    if (index != -1) {
      selectedBookedItems[index] = isSelected;
      _ordersBooked[index].isSelected = isSelected;
    }

    selectAllBooked = selectedBookedItems.every((item) => item);

    notifyListeners();
  }

  void _updateSelectAllState(bool isB2B) {
    if (isB2B) {
      selectAllB2B = selectedB2BItems.every((item) => item);
    } else {
      selectAllB2C = selectedB2CItems.every((item) => item);
    }
    notifyListeners();
  }

  void toggleSelectAll(bool isB2B, bool? value) {
    if (isB2B) {
      selectAllB2B = value!;
      selectedB2BItems.fillRange(0, selectedB2BItems.length, selectAllB2B);

      for (int i = 0; i < _ordersB2B.length; i++) {
        _ordersB2B[i].isSelected = selectAllB2B;
      }
    } else {
      selectAllB2C = value!;
      selectedB2CItems.fillRange(0, selectedB2CItems.length, selectAllB2C);

      for (int i = 0; i < _ordersB2C.length; i++) {
        _ordersB2C[i].isSelected = selectAllB2C;
      }
    }
    notifyListeners();
  }

  void toggleBookedSelectAll(bool? value) {
    selectAllBooked = value!;
    selectedBookedItems.fillRange(0, selectedBookedItems.length, selectAllBooked);

    for (int i = 0; i < _ordersBooked.length; i++) {
      _ordersBooked[i].isSelected = selectAllBooked;
    }

    notifyListeners();
  }

  void clearAllSelections() {
    selectedB2BItems.fillRange(0, selectedB2BItems.length, false);
    selectedB2CItems.fillRange(0, selectedB2CItems.length, false);
    selectAllB2B = false;
    selectAllB2C = false;
    notifyListeners();
  }

  void clearSearchResults() {
    _ordersB2B = [];
    _ordersB2C = [];
    _ordersBooked = [];
    notifyListeners();
  }

  bool _isCloning = false;
  bool get isCloning => _isCloning;

  void setCloning(bool value) {
    _isCloning = value;
    notifyListeners();
  }

  Future<String> cloneOrders(BuildContext context, String type, int page, List<String> orderIds) async {
    String baseUrl = await Constants.getBaseUrl();
    String cloneOrderUrl = '$baseUrl/orders/clone';
    final String? token = await _getToken();
    setCloning(true);

    if (token == null) {
      setCloning(false);
      return 'No auth token found';
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final body = json.encode({
      'orderIds': orderIds,
    });

    try {
      final response = await http.post(
        Uri.parse(cloneOrderUrl),
        headers: headers,
        body: body,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchOrders(type, page);
        clearAllSelections();
        return responseData['message'] + ": ${responseData['newOrders'][0]['order_id']}" ?? 'Orders clone successfully';
      } else {
        return responseData['message'] ?? 'Failed to clone orders';
      }
    } catch (error) {
      log('catched error: $error');
      return 'An error occurred: $error';
    } finally {
      setCloning(false);
      notifyListeners();
    }
  }

  Future<void> searchB2BOrders(String query, String searchType) async {
    String encodedOrderId = Uri.encodeComponent(query);

    final prefs = await SharedPreferences.getInstance();
    final warehouseId = prefs.getString('warehouseId') ?? '';

    String url = '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&orderStatus=3&filter=B2B';
    final token = await _getToken();
    if (token == null) return;

    if (searchType == 'Order ID') {
      url += '&order_id=$encodedOrderId';
    } else {
      url += '&awb_number=$query';
    }
    log('searchB2BOrders url: $url');

    try {
      isLoadingB2B = true;
      notifyListeners();

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(response.body);

        _ordersB2B = [Order.fromJson(data)];
        print(response.body);
      } else {
        _ordersB2B = [];
      }
    } catch (e) {
      _ordersB2B = [];
    } finally {
      isLoadingB2B = false;
      notifyListeners();
    }
  }

  Future<void> searchB2COrders(String query, String searchType) async {
    String encodedOrderId = Uri.encodeComponent(query);

    final prefs = await SharedPreferences.getInstance();
    final warehouseId = prefs.getString('warehouseId') ?? '';

    String url = '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&orderStatus=3&filter=B2C';
    final token = await _getToken();
    if (token == null) return;

    if (searchType == 'Order ID') {
      url += '&order_id=$encodedOrderId';
    } else {
      url += '&awb_number=$query';
    }

    log('searchB2COrders url: $url');

    try {
      isLoadingB2C = true;
      notifyListeners();

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      log('res: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _ordersB2C = [Order.fromJson(data)];
        log('_ordersB2C: $ordersB2C');
      } else {
        _ordersB2C = [];
      }
    } catch (e) {
      _ordersB2C = [];
    } finally {
      isLoadingB2C = false;
      notifyListeners();
    }
  }

  Future<void> searchBookedOrders(String query, String searchType) async {
    final prefs = await SharedPreferences.getInstance();
    final warehouseId = prefs.getString('warehouseId') ?? '';

    var url = '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&isBooked=true';
    final token = await _getToken();
    if (token == null) return;

    if (searchType == 'Order ID') {
      String encodedOrderId = Uri.encodeComponent(query);
      url += '&order_id=$encodedOrderId';
    } else {
      url += '&awb_number=$query';
    }

    log('searchBookedOrders url: $url');

    try {
      isLoadingBooked = true;
      notifyListeners();

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (searchType == 'Order ID') {
          _ordersBooked = [Order.fromJson(data)];
        } else {
          _ordersBooked = [Order.fromJson(data['orders'][0])];
        }

        log('_ordersBooked: $ordersBooked');
      } else {
        _ordersBooked = [];
      }
    } catch (e) {
      log('error: $e');
      _ordersBooked = [];
    } finally {
      isLoadingBooked = false;
      notifyListeners();
    }
  }

  Future<void> generatePicklist(BuildContext context, String marketplace) async {
    String currentTime = DateTime.now().toIso8601String();

    log("currentTime: $currentTime");
    log("marketplace: $marketplace");

    String baseUrl = await Constants.getBaseUrl();
    String url = '$baseUrl/order-picker?currentTime=$currentTime&marketplace=$marketplace';

    log('generatePicklist url: $url');

    String? token = await _getToken();
    if (token == null) {
      print('Token is null, unable to fetch order picker data.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      log('Picklist Status: ${response.statusCode}');
      log('Picklist Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error']['message']),
            backgroundColor: AppColors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error']['message']),
            backgroundColor: AppColors.cardsred,
          ),
        );
        print('Failed to post order picker data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error posting order picker data: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<Uint8List> generatePdf(List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();

    int totalAmount = data.fold(0, (sum, item) => sum + int.parse(item["amount"]));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(16.0),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Picklist",
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(width: 1),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text("Item Name", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(" SUM of Single Qty", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...data.map(
                      (item) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(item["displayName"]),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(item["qty"].toString()),
                          ),
                        ],
                      ),
                    ),
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text("Grand Total", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text("₹$totalAmount", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  void downloadPdf(List<Map<String, dynamic>> data) async {
    final pdfBytes = await generatePdf(data);
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "picklist.pdf")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<bool> editWarehouse(String orderId, String warehouse) async {
    log('editWarehouse called');
    String baseUrl = await Constants.getBaseUrl();
    String url = '$baseUrl/orders/editwarehouse';
    final String? token = await _getToken();

    if (token == null) {
      print('Token is null, unable to fetch orders.');
      return false;
    }

    log('editWarehouse url: $url');

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final body = json.encode({
      'order_id': orderId,
      'warehouse': warehouse,
    });

    log('edit warehouse body: $body');

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      final responseData = json.decode(response.body);
      Logger().e(responseData);

      if (response.statusCode == 200) {
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (error) {
      log('Error during API request: $error');
      return false;
    }
  }

  Future<Map<String, dynamic>> generatePacklist(BuildContext context, String date, String selectedPicklist) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    String url = '${await Constants.getBaseUrl()}/order-picker/packerCsv?date=$date&picklistId=$selectedPicklist';

    log('picklist url: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        await generateAndDownloadPdf(data, selectedPicklist, date);
        return {'status': 'success', 'message': 'PDF downloaded successfully'};
      } else {
        log('Error: Status code ${response.statusCode}');
        return {'status': 'error', 'message': 'Failed to fetch data: ${response.statusCode}'};
      }
    } catch (e, s) {
      log('Error occurred: $e, Stacktrace: $s');
      return {'status': 'error', 'message': 'Error: $e'};
    }
  }

  Future<void> generateAndDownloadPdf(dynamic jsonData, String selectedPicklist, String date) async {
    final pdf = pw.Document();

    final headers = [
      'Order ID',
      'SKU',
      'Name',
      'Qty',
      'Total Wt.',
      'AWB',
      'Courier',
      'Conformer Remark',
      'Packed By',
      'Checked By',
    ];

    Map<String, dynamic> data;
    if (jsonData is String) {
      data = jsonDecode(jsonData);
    } else if (jsonData is Map<String, dynamic>) {
      data = jsonData;
    } else {
      throw Exception('Invalid JSON data format');
    }

    List<dynamic> orders = data['orders'] ?? [];

    List<List<String>> rows = [];
    for (var order in orders) {
      String orderId = order['OrderId']?.toString() ?? '';
      String totalWeight = order['Total_Weight']?.toString() ?? '';
      String awbNumber = order['AWB_number']?.toString() ?? '';
      String courierName = order['Courier_Name']?.toString() ?? '';
      String confirmerRemark = order['Confirmer_Remark']?.toString() ?? '';

      List<dynamic> items = order['items'] ?? [];
      for (var item in items) {
        rows.add([
          orderId,
          item['ProductSku']?.toString() ?? '',
          item['ProductName']?.toString() ?? '',
          item['Quantity']?.toString() ?? '',
          totalWeight,
          awbNumber,
          courierName,
          confirmerRemark,
          '',
          '',
        ]);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Packlist - (${DateFormat('dd-MM-yyyy').format(DateTime.parse(date))})',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Text(
                    'Picklist ID: $selectedPicklist',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.normal,
                      color: PdfColors.blueGrey800,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows,
              border: pw.TableBorder.all(
                width: 0.5,
                color: PdfColors.grey800,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey100,
              ),
              headerStyle: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
              cellStyle: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.black,
              ),
              cellAlignments: {
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                for (int i = 0; i < headers.length; i++)
                  if (i != 3 && i != 4) i: pw.Alignment.centerLeft,
              },
              columnWidths: const {
                0: pw.FlexColumnWidth(0.8),
                1: pw.FlexColumnWidth(0.8),
                2: pw.FlexColumnWidth(2.0),
                3: pw.FlexColumnWidth(0.3),
                4: pw.FlexColumnWidth(0.8),
                5: pw.FlexColumnWidth(1.0),
                6: pw.FlexColumnWidth(1.2),
                7: pw.FlexColumnWidth(1.2),
                8: pw.FlexColumnWidth(0.8),
                9: pw.FlexColumnWidth(0.8),
              },
              cellPadding: const pw.EdgeInsets.all(2),
            ),
          ];
        },
      ),
    );

    final Uint8List pdfBytes = await pdf.save();

    final blob = html.Blob([pdfBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'packlist_$selectedPicklist.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
