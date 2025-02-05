import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class WarehousesProvider with ChangeNotifier {
  bool _isLoading = false;
  List<Map<String, dynamic>> _warehouses = [];
  final int _currentPage = 1;
  int _totalPages = 1;

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get warehouses => _warehouses;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  Future<void> fetchWarehouses() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';

    String url = '${await Constants.getBaseUrl()}/warehouse';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final warehousesData = jsonResponse['data']['warehouses'] as List;
        _warehouses = warehousesData
            .map((warehouse) => {
                  'id': warehouse['_id'],
                  'name': warehouse['name'],
                  'warehousePincode': warehouse['warehousePincode'] ??
                      (warehouse['pinCodes']?.isNotEmpty
                          ? warehouse['pinCodes'][0]['startPincode'].toString()
                          : 'N/A'),
                  'isPrimary': warehouse['isPrimary'],
                })
            .toList()
            .toList();

        _totalPages = jsonResponse['data']['totalPages'];
      } else {
        _warehouses = [];
        _totalPages = 1;
      }
    } catch (e) {
      log('Error fetching warehouses: $e');
      _warehouses = [];
      _totalPages = 1;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
