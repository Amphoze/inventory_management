import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Import intl package
import 'package:shared_preferences/shared_preferences.dart';
import '../model/dashboard_model.dart';

class DashboardProvider with ChangeNotifier {
  DashboardData? _dashboardData;
  bool _isLoading = false;
  String? _errorMessage;

  DashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboardData(String dateString) async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      notifyListeners();
      print('Token is missing. Please log in again.');
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

      final response = await http.get(
        Uri.parse(
            'https://inventory-management-backend-s37u.onrender.com/dashboard/search?date=$formattedDate'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _dashboardData = DashboardData.fromJson(data);
        notifyListeners();
      }
    } catch (error) {
      print("Error fetching dashboard data: $error");
    }
  }
}

Future<String?> _getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('authToken');
}
