import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;

class PickerProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _selectAll = false;
  List<bool> _selectedProducts = [];
  List<Order> _orders = [];
  List<dynamic> _extractedOrders = [];
  int _currentPage = 1;
  int _totalPages = 1;
  final PageController _pageController = PageController();
  final TextEditingController _textEditingController = TextEditingController();
  Timer? _debounce;

  List<dynamic> get extractedOrders => _extractedOrders;

  bool get selectAll => _selectAll;

  List<bool> get selectedProducts => _selectedProducts;

  List<Order> get orders => _orders;

  bool get isLoading => _isLoading;

  int get currentPage => _currentPage;

  int get totalPages => _totalPages;

  PageController get pageController => _pageController;

  TextEditingController get textEditingController => _textEditingController;

  int get selectedCount => _selectedProducts.where((isSelected) => isSelected).length;

  bool isRefreshingOrders = false;

  bool isCancel = false;

  void setCancelStatus(bool status) {
    isCancel = status;
    notifyListeners();
  }

  void setRefreshingOrders(bool value) {
    isRefreshingOrders = value;
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
        await fetchOrdersWithStatus4(); // Assuming fetchOrders is a function that reloads the orders
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

  Future<void> fetchOrdersWithStatus4() async {
    _isLoading = true;
    setRefreshingOrders(true);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    String url = '${await Constants.getBaseUrl()}/order-picker?page=$_currentPage&limit=5';

    log('fetchOrdersWithStatus4 url: $url');

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        log(data['data'].runtimeType.toString());

        _extractedOrders = data['data'];
        _totalPages = data['totalPages'] ?? 1;
        _currentPage = data['currentPage'] ?? 1;
        // log("_extractedOrders: $_extractedOrders");
        log("${_extractedOrders.length}");
      } else {
        // Handle non-success responses
        _extractedOrders = [];
        _totalPages = 1; // Reset total pages if there’s an error
      }
    } catch (e) {
      // Handle errors
      log(e.toString());
      _extractedOrders = [];
      _totalPages = 1; // Reset total pages if there’s an error
    } finally {
      _isLoading = false;
      setRefreshingOrders(false);
      notifyListeners();
    }
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
        // If query is empty, reload all orders
        fetchOrdersWithStatus4();
      } else {
        searchOrders(query); // Trigger the search after the debounce period
      }
    });
  }

  Future<List<Order>> searchOrders(String query) async {
    if (query.isEmpty) {
      await fetchOrdersWithStatus4();
      return _orders;
    }

    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    final warehouseId = prefs.getString('warehouseId') ?? '';

    String encodedOrderId = Uri.encodeComponent(query);

    final url = '${await Constants.getBaseUrl()}/orders?warehouse=$warehouseId&orderStatus=4&order_id=$encodedOrderId';

    log('search pick: $url');

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

        List<Order> orders = [];
        // print('Response data: $jsonData');
        if (jsonData != null) {
          orders.add(Order.fromJson(jsonData));
          print('Response data: $jsonData');
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
    log('Current page set to: $_currentPage');
    fetchOrdersWithStatus4();
    notifyListeners();
  }

  // Format date
  String formatDate(DateTime date) {
    String year = date.year.toString();
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');
    return '$day-$month-$year';
  }

  Future<void> fetchPicklist(BuildContext context, String date, String picklistId) async {
    // _isLoading = true;
    // notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    String url = '${await Constants.getBaseUrl()}/order-picker/picklistCsv?date=$date&picklistId=$picklistId';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final downloadUrl = data['downloadUrl'];

        if (downloadUrl != null) {
          final canLaunch = await canLaunchUrl(Uri.parse(downloadUrl));
          if (canLaunch) {
            await launchUrl(Uri.parse(downloadUrl));
          } else {
            log('Could not launch $downloadUrl');
          }
        } else {
          log('No download URL found');
          // throw Exception('No download URL found');
        }
      } else {
        // Handle non-success responses
      }
    } catch (e) {
      log('error aaya hai: $e');
    }
  }

  Future<Map<String, dynamic>> generatePicklist(BuildContext context, String date, String selectedPicklist) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    String url = '${await Constants.getBaseUrl()}/order-picker/picklistCsv?date=$date&picklistId=$selectedPicklist';

    log('picklist url: $url'); // Use developer.log instead of Logger()

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
        await generateAndDownloadPdf(data, selectedPicklist, date); // Call the PDF generation function
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

    // Define table headers based on the provided PDF structure
    final headers = ['Item Name', 'Quantity'];

    // Parse JSON data
    Map<String, dynamic> data = jsonData is String ? jsonDecode(jsonData) : jsonData;
    List<dynamic> items = data['items'] ?? [];

    // Prepare table rows and calculate total quantity
    int grandTotal = 0;
    List<List<String>> rows = items.map((item) {
      int qty = item['qty'] ?? 0;
      grandTotal += qty;
      return [
        item['displayName']?.toString() ?? '',
        qty.toString(),
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Picklist-${jsonData['picklistId']}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.Text(
                  'Date: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(date))}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.normal,
                    color: PdfColors.blueGrey800,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows,
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey800),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
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
                1: pw.Alignment.centerRight, // Quantity column right aligned
              },
              columnWidths: const {
                0: pw.FlexColumnWidth(2.0), // Item Name wider
                1: pw.FlexColumnWidth(0.2), // Quantity narrower
              },
              cellPadding: const pw.EdgeInsets.all(3),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Grand Total: $grandTotal',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ];
        },
      ),
    );

    // Generate PDF as bytes
    final Uint8List pdfBytes = await pdf.save();

    // Download the PDF in the browser
    final blob = html.Blob([pdfBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'picklist_$selectedPicklist.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
