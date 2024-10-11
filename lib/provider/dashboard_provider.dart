import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Import intl package
import '../model/dashboard_model.dart';

class DashboardProvider with ChangeNotifier {
  DashboardData? _dashboardData;
  bool _isLoading = false;
  String? _errorMessage;

  DashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;



  Future<void> fetchDashboardData(String dateString) async {
    try {
      DateTime date = DateTime.parse(dateString); // Convert string to DateTime
      String formattedDate = DateFormat('yyyy-MM-dd').format(date); // Format it back to required string

      final response = await http.get(Uri.parse('https://inventory-management-backend-s37u.onrender.com/dashboard/search?date=$formattedDate'));

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
