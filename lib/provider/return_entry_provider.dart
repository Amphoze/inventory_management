import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/model/orders_model.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReturnEntryProvider with ChangeNotifier {
  bool _isLoading = false;
  int selectedItemsCount = 0;
  List<Order> _orders = [];
  Timer? _debounce;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;

  bool isRefreshingOrders = false;

  void setRefreshingOrders(bool value) {
    isRefreshingOrders = value;
    notifyListeners();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  String formatDate(DateTime date) {
    String year = date.year.toString();
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');
    return '$day-$month-$year';
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
      } else {
        searchOrders(query);
      }
    });
  }

  void showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
      ),
    );
  }

  void showMessageDialog(BuildContext context, String message, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message, style: TextStyle(color: color)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ok')),
        ],
      ),
    );
  }

  Future<void> searchOrders(String orderId) async {
    String encodedOrderId = Uri.encodeComponent(orderId);

    final url = '${await Constants.getBaseUrl()}/orders?order_id=$encodedOrderId';
    log('search all orders url: $url');
    final mainUrl = Uri.parse(url);
    log('parsed url: $mainUrl');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';

    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.get(
        mainUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _orders = [Order.fromJson(data)];
        Logger().e('return orders: $_orders');
        notifyListeners();
      } else {
        _orders = [];
      }
    } catch (e, s) {
      log('catched error: $e $s');
      _orders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> qualityCheck(String orderId, List<Map<String, dynamic>> qualityCheckResults) async {
    final url = '${await Constants.getBaseUrl()}/orders/qualityCheck/$orderId';
    log('quality check post api: $url');
    final mainUrl = Uri.parse(url);
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      return {'success': false};
    }

    Logger().e('body: $qualityCheckResults');

    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.post(
        mainUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"qualityCheckResults": qualityCheckResults}),
      );
      final data = jsonDecode(response.body);

      Logger().e('return orders body: $data');
      if (response.statusCode == 200) {
        Logger().e('return orders: $data');
        notifyListeners();
        return {'success': true, 'message': data['message']};
      } else {
        Logger().e('return orders error: ${response.statusCode}');
        return {'success': false, 'message': data['message']};
      }
    } catch (e, s) {
      log('catched error: $e $s');
      return {'success': false};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
