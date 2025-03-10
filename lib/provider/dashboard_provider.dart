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
  String _marketplace = "";
  bool _isPercentLoading = false;
  Map<String, int> _statusTotals = {};
  Map<String, String> _statusPercentages = {};

  // Getters
  String get message => _message;
  int get totalOrders => _totalOrders;
  String get marketplace => _marketplace;
  bool get isPercentLoading => _isPercentLoading;
  Map<String, int> get statusTotals => _statusTotals;
  Map<String, String> get statusPercentages => _statusPercentages;

  // Legacy getters for backward compatibility (optional)
  int get totalDelivered => _statusTotals['delivered'] ?? 0;
  String get deliveredPercentage => _statusPercentages['delivered'] ?? "0";
  int get totalRto => _statusTotals['rto'] ?? 0;
  String get rtoPercentage => _statusPercentages['rto'] ?? "0";

  void resetValues() {
    _message = "Order Statistics";
    _totalOrders = 0;
    _marketplace = "";
    _statusTotals = {};
    _statusPercentages = {};
    notifyListeners();
  }

  Future<void> fetchPercentageData(
    String dateRange,
    String marketplace,
    List<String> options
  ) async {
    setPercentLoading(true);

    final token = await _getToken();
    log('token is: $token');
    if (token == null || token.isEmpty) {
      notifyListeners();
      log('Token is missing. Please log in again.');
      setPercentLoading(false);
      return;
    }

    try {
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      String url = '${await Constants.getBaseUrl()}/dashboard/rto-percentage';
      log('percentage url: $url');

      final body = {
        "date_range": dateRange,
        "marketplace": marketplace,
        "options": options, // Send as array
      };

      log('percentage body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      log('Percentage response body: ${response.body}');

      if (response.statusCode == 200) {
        resetValues();

        final data = json.decode(response.body);

        _message = data['message'] ?? "Order Statistics";
        _totalOrders = data['total_orders'] ?? 0;
        _marketplace = data['marketplace'] ?? "";

        data.forEach((key, value) {
          if (key.startsWith('total_')) {
            String status = key.replaceFirst('total_', '');
            _statusTotals[status] = value ?? 0;
          } else if (key.endsWith('_percentage')) {
            String status = key.replaceFirst('_percentage', '');
            _statusPercentages[status] = value?.toString() ?? "0";
          }
        });

        log('percentage response: ${response.body}');
        log('Message: $_message');
        log('total_orders: $_totalOrders');
        log('status_totals: $_statusTotals');
        log('status_percentages: $_statusPercentages');
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
