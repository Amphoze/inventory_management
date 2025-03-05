import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Import intl package
import 'package:inventory_management/constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/dashboard_model.dart';

class DashboardProvider with ChangeNotifier {
  DashboardData? _dashboardData;
  DashboardData? _doneData;
  bool _isLoading = false;
  String? _errorMessage;

  DashboardData? get dashboardData => _dashboardData;
  DashboardData? get doneData => _doneData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchAllData(String dateString) async {
    setLoading(true);
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      notifyListeners();
      print('Token is missing. Please log in again.');
      setLoading(false);
      return;
    }

    try {
      // Convert and format the date
      DateTime date = DateTime.parse(dateString);
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);

      // Create a list of futures
      final futures = [
        fetchDashboardData(formattedDate),
        fetchDoneData(formattedDate),
      ];

      // Wait for all futures to complete
      await Future.wait(futures);
    } catch (error) {
      print("Error fetching all dashboard data: $error");
    } finally {
      setLoading(false);
    }
  }

  Future<void> fetchDashboardData(String dateString) async {
    // setLoading(true);
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      notifyListeners();
      print('Token is missing. Please log in again.');
      // setLoading(false);
      return;
    }
    try {
      DateTime date = DateTime.parse(dateString); // Convert string to DateTime
      String formattedDate = DateFormat('yyyy-MM-dd').format(date); // Format it back to required string

      final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};

      final url = '${await Constants.getBaseUrl()}/dashboard/search?date=$formattedDate';

      log('url: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _dashboardData = DashboardData.fromJson(data);

        log('dashboard: $_dashboardData');
        notifyListeners();
      }
    } catch (error) {
      print("Error fetching dashboard data: $error");
    } finally {
      // setLoading(false);
    }
  }

  Future<void> fetchDoneData(String dateString) async {
    // setLoading(true);
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      notifyListeners();
      print('Token is missing. Please log in again.');
      // setLoading(false);
      return;
    }
    try {
      DateTime date = DateTime.parse(dateString); // Convert string to DateTime
      String formattedDate = DateFormat('yyyy-MM-dd').format(date); // Format it back to required string

      final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};

      final url = '${await Constants.getBaseUrl()}/dashboard/fetch?date=$formattedDate';

      log('done: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _doneData = DashboardData.fromJson(data);

        log('done: ${_doneData!.confirmedOrderToday}');
        notifyListeners();
      }
    } catch (error) {
      print("Error fetching dashboard data: $error");
    } finally {
      // setLoading(false);
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  String _message = "Order Statistics";
  int _totalOrders = 0;
  int _totalDelivered = 0;
  String _deliveredPercentage = "0";
  int _totalRto = 0;
  String _rtoPercentage = "0";
  String _marketplace = "";
  bool _isPercentLoading = false;

  // Getters
  String get message => _message;
  int get totalOrders => _totalOrders;
  int get totalDelivered => _totalDelivered;
  String get deliveredPercentage => _deliveredPercentage;
  int get totalRto => _totalRto;
  String get rtoPercentage => _rtoPercentage;
  String get marketplace => _marketplace;
  bool get isPercentLoading => _isPercentLoading;

    void resetValues() {
    _message = "Order Statistics";
    _totalOrders = 0;
    _totalDelivered = 0;
    _deliveredPercentage = "0";
    _totalRto = 0;
    _rtoPercentage = "0";
    _marketplace = "";
    notifyListeners();
  }


  Future<void> fetchPercentageData(
    String dateRange,
    String marketplace,
    String options,
  ) async {
    setPercentLoading(true);

    // final token = await _getToken();
    //
    // if (token != null) {
    //   log('Token is missing. Please log in again.');
    //   setPercentLoading(false);
    //   notifyListeners();
    //   return;
    // }

    try {
      final headers = {
        'Authorization':
            'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImFudXBrdW1hcnNvbmlAa2F0eWF5YW5pb3JnYW5pY3MuY29tIiwiaWQiOiI2NzU5NGY3NTczM2I1NWViMWE2MTlmMTYiLCJpYXQiOjE3NDExNTM4ODcsImV4cCI6MTc0MTE5NzA4N30.hnxvPyTgkkbAy0Eqq7_5WPxJhA44t3gWD8M7I_tpLAs',
        // 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      String url = '${await Constants.getBaseUrl()}/dashboard/rto-percentage';

      log('percentage url: $url');

      final body = {
        "date_range": dateRange,
        "marketplace": marketplace,
        "options": options,
      };

      log('percentage body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        resetValues();

        final data = json.decode(response.body);
        _message = data['message'] ?? "Order Statistics";
        _totalOrders = data['total_orders'] ?? 0;
        _totalDelivered = data['total_delivered'] ?? 0;
        _deliveredPercentage = data['delivered_percentage'] ?? '0';
        _totalRto = data['total_rto'] ?? 0;
        _rtoPercentage = data['rto_percentage'] ?? '0';
        _marketplace = data['marketplace'] ?? "";

        log('percentage body : ${response.body}');
        log('Message: $_message');
        log('total_orders: $_totalOrders');
        log('total_delivered: $_totalDelivered');
        log('delivered_percentage: $_deliveredPercentage');
        log('total_rto: $_totalRto');
        log('rto_percentage: $_rtoPercentage');
      } else {
        log('Failed to fetch data: ${response.statusCode}');
      }
    } catch (error) {
      log("Error fetching percentage data: $error");
    } finally {
      setPercentLoading(false);
      notifyListeners();
    }
  }

  void setPercentLoading(bool value) {
    _isPercentLoading = value;
    notifyListeners();
  }
}

Future<String?> _getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('authToken');
}
