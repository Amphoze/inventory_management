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
      String formattedDate = DateFormat('yyyy-MM-dd')
          .format(date); // Format it back to required string

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };

      final url =
          '${await Constants.getBaseUrl()}/dashboard/search?date=$formattedDate';

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
      String formattedDate = DateFormat('yyyy-MM-dd')
          .format(date); // Format it back to required string

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };

      final url =
          '${await Constants.getBaseUrl()}/dashboard/fetch?date=$formattedDate';

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
}

Future<String?> _getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('authToken');
}
