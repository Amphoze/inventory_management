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

import '../model/picker_model.dart';

class PickerProvider with ChangeNotifier {
  bool _isPicklistLoading = false;
  bool _isOrderLoading = false;
  bool _selectAll = false;
  List<bool> _selectedProducts = [];
  List<Order> _orders = [];
  List<Picklist> _picklists = [];
  int _currentPage = 1;
  int _totalPages = 1;
  final PageController _pageController = PageController();
  final TextEditingController _textEditingController = TextEditingController();

  List<Picklist> get picklists => _picklists;
  bool get selectAll => _selectAll;
  List<bool> get selectedProducts => _selectedProducts;
  List<Order> get orders => _orders;
  bool get isPicklistLoading => _isPicklistLoading;
  bool get isOrderLoading => _isOrderLoading;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  PageController get pageController => _pageController;
  TextEditingController get textEditingController => _textEditingController;
  int get selectedCount => _selectedProducts.where((isSelected) => isSelected).length;

  bool isCancel = false;

  void setCancelStatus(bool status) {
    isCancel = status;
    notifyListeners();
  }

  void setPicklistLoading(bool value) {
    _isPicklistLoading  = value;
    notifyListeners();
  }

  void setOrderLoading(bool value) {
    _isOrderLoading = value;
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

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        await fetchOrdersWithStatus4();

        setCancelStatus(false);
        notifyListeners();

        return responseData['message'] ?? 'Orders cancelled successfully';
      } else {
        return responseData['message'] ?? 'Failed to cancel orders';
      }
    } catch (error) {
      setCancelStatus(false);
      notifyListeners();

      return 'An error occurred: $error';
    }
  }

  Future<void> fetchOrdersWithStatus4() async {
    setPicklistLoading(true);

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
        final res = json.decode(response.body);

        _picklists = (res['data'] as List).map((picklist) => Picklist.fromJson(picklist)).toList();
        _totalPages = res['totalPages'] ?? 1;
        _currentPage = res['currentPage'] ?? 1;

        log("${_picklists.length}");
      } else {
        _picklists = [];
        _currentPage = 1;
        _totalPages = 1;
      }
    } catch (e, s) {
      log('picker error: $e $s');
      _picklists = [];
      _currentPage = 1;
      _totalPages = 1;
    } finally {
      setPicklistLoading(false);
      notifyListeners();
    }
  }

  Future<List<Order>> searchOrders(String query) async {
    if (query.isEmpty) {
      await fetchOrdersWithStatus4();
      return _orders;
    }

    setOrderLoading(true);

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

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        List<dynamic> orders = jsonData['orders'] ?? [];

        _orders = orders.map((e) => Order.fromJson(e)).toList();


      } else {
        _orders = [];
        _currentPage = 1;
        _totalPages = 1;
      }
    } catch (error, s) {
      log('Error occurred: $error $s');
      _orders = [];
      _currentPage = 1;
      _totalPages = 1;
    } finally {
      setOrderLoading(false);
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

  String formatDate(DateTime date) {
    String year = date.year.toString();
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');
    return '$day-$month-$year';
  }

  Future<Map<String, dynamic>> downloadPicklist(BuildContext context, String date, String selectedPicklist) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    String url = '${await Constants.getBaseUrl()}/order-picker/picklistCsv?date=$date&picklistId=$selectedPicklist';

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

    final headers = ['Item Name', 'Quantity'];

    Map<String, dynamic> data = jsonData is String ? jsonDecode(jsonData) : jsonData;
    List<dynamic> items = data['items'] ?? [];

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
                1: pw.Alignment.centerRight,
              },
              columnWidths: const {
                0: pw.FlexColumnWidth(2.0),
                1: pw.FlexColumnWidth(0.2),
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

    final Uint8List pdfBytes = await pdf.save();

    final blob = html.Blob([pdfBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'picklist_$selectedPicklist.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
