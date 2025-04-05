import 'package:flutter/material.dart';
import '../../Api/auth_provider.dart';
import '../../constants/constants.dart';
import '../models/check_order_model.dart';
import '../models/recheck_order_model.dart'; // Import the new model
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

class CheckOrdersProvider with ChangeNotifier {
  final authProvider = AuthProvider();

  bool _isCheckOrdersLoading = false;
  bool _isCheckingOrders = false;
  bool _isRecheckOrdersLoading = false; // Add loading state for recheck orders
  List<CheckOrderModel> _checkOrders = [];
  List<RecheckOrderModel> _recheckOrders = []; // Add list for recheck orders

  bool get isCheckOrdersLoading => _isCheckOrdersLoading;
  bool get isCheckingOrders => _isCheckingOrders;
  bool get isRecheckOrdersLoading => _isRecheckOrdersLoading;
  List<CheckOrderModel> get checkOrders => _checkOrders;
  List<RecheckOrderModel> get recheckOrders => _recheckOrders;

  void setCheckOrdersLoading(bool value) {
    _isCheckOrdersLoading = value;
    notifyListeners();
  }

  void setCheckingOrders(bool value) {
    _isCheckingOrders = value;
    notifyListeners();
  }

  void setRecheckOrdersLoading(bool value) {
    _isRecheckOrdersLoading = value;
    notifyListeners();
  }

  Future<void> getCheckOrders() async {
    setCheckOrdersLoading(true);

    final token = await authProvider.getToken();
    Uri uri = Uri.parse("${await Constants.getBaseUrl()}/KO-captain/supervisor");

    try {
      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          final Map<String, dynamic> ordersData = jsonResponse['order'];
          _checkOrders = [CheckOrderModel.fromJson(ordersData)];
          // _checkOrders = ordersData.map((order) => CheckOrderModel.fromJson(order)).toList();
          notifyListeners();
        } else {
          throw Exception('Failed to fetch orders: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e, s) {
      log('Error fetching orders: $e $s');
      _checkOrders = [];
      notifyListeners();
    } finally {
      setCheckOrdersLoading(false);
    }
  }

  Future<void> searchCheckOrders(String query) async {
    setCheckOrdersLoading(true);

    final token = await authProvider.getToken();
    Uri uri = Uri.parse("${await Constants.getBaseUrl()}/KO-captain/supervisor?search=$query");

    try {
      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          final Map<String, dynamic> ordersData = jsonResponse['order'];
          _checkOrders = [CheckOrderModel.fromJson(ordersData)];
          notifyListeners();
        } else {
          throw Exception('Failed to fetch orders: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e, s) {
      log('Error fetching orders: $e $s');
      _checkOrders = [];
      notifyListeners();
    } finally {
      setCheckOrdersLoading(false);
    }
  }

  Future<bool> updateCheckStatus({
    required String orderId,
    required String pickListId,
    required bool check,
  }) async {
    setCheckingOrders(true);
    final token = await authProvider.getToken();
    final Uri uri = Uri.parse("${await Constants.getBaseUrl()}/KO-captain/check");

    try {
      final Map<String, dynamic> body = {
        "orderId": orderId,
        // "packListId": '',
        "check": check,
      };

      log("check order body: $body");
      final http.Response response = await http.put(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      log("check order response: ${response.body}");

      if (response.statusCode == 200) {
        log("Check status updated successfully");
        // await getCheckOrders();
        return true;
      } else {
        return false;
        // throw Exception('Failed to update check status: ${response.statusCode}');
      }
    } catch (e) {
      log('Error updating check status: $e');
      return false;
      // throw e;
    } finally {
      setCheckingOrders(false);
    }
  }

  Future<void> getRecheckOrders() async {
    setRecheckOrdersLoading(true);

    final token = await authProvider.getToken();
    Uri uri = Uri.parse("${await Constants.getBaseUrl()}/KO-captain/recheckOrders");

    try {
      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          final List<dynamic> ordersData = jsonResponse['data'];
          _recheckOrders = ordersData.map((order) => RecheckOrderModel.fromJson(order)).toList();
          notifyListeners();
        } else {
          throw Exception('Failed to fetch recheck orders: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('Failed to load recheck orders: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching recheck orders: $e');
      _recheckOrders = [];
      notifyListeners();
    } finally {
      setRecheckOrdersLoading(false);
    }
  }
}