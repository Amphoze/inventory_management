import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/constants/constants.dart';
import '../Api/auth_provider.dart';

class InnerPackagingProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _innerPackings = [];
  int _currentPage = 1;
  int _totalPages = 1;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get innerPackings => _innerPackings;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      _currentPage = page;
      fetchAllInnerPackings(page: page);
    }
    notifyListeners();
  }

  bool showInnerPackForm = false;
  void toggleFormVisibility() {
    showInnerPackForm = !showInnerPackForm;
    notifyListeners();
  }

  // POST /innerPacking
  Future<void> createInnerPacking(Map<String, dynamic> packingData) async {
    String baseUrl = await Constants.getBaseUrl();
    _setLoading(true);
    _setErrorMessage(null);

    final url = Uri.parse('$baseUrl/innerPacking');

    try {
      final token = await AuthProvider().getToken();
      if (token == null) {
        _setErrorMessage('No token found');
        return;
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(packingData),
      );

      if (response.statusCode == 201) {
        log('Inner packing created: ${response.body}');
        await fetchAllInnerPackings(); // Refresh the list
      } else {
        _setErrorMessage('Failed to create inner packing: ${response.body}');
      }
    } catch (error) {
      _setErrorMessage('An error occurred: $error');
    } finally {
      _setLoading(false);
    }
  }

  // GET /innerPacking
  Future<void> fetchAllInnerPackings({int page = 1}) async {
    String baseUrl = await Constants.getBaseUrl();
    _setLoading(true);
    _setErrorMessage(null);

    final url = Uri.parse('$baseUrl/innerPacking?page=$page');

    try {
      final token = await AuthProvider().getToken();
      if (token == null) {
        _setErrorMessage('No token found');
        return;
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final res = json.decode(response.body);

        // Update inner packings data
        _innerPackings = List<Map<String, dynamic>>.from(res['data']['innerPacking']);

        // Update pagination info
        _currentPage = res['data']['currentPage'] ?? 1;
        _totalPages = res['data']['totalPages'] ?? 1;

        log('Inner packings fetched: $_innerPackings');
        notifyListeners();
      } else {
        _setErrorMessage('Failed to fetch inner packings: ${response.body}');
      }
    } catch (error) {
      _setErrorMessage('An error occurred: $error');
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> fetchInnerPackingById(String id) async {
    String baseUrl = await Constants.getBaseUrl();
    _setLoading(true);
    _setErrorMessage(null);

    final url = Uri.parse('$baseUrl/innerPacking/$id');

    try {
      final token = await AuthProvider().getToken();
      if (token == null) {
        _setErrorMessage('No token found');
        return null;
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        _setErrorMessage('Failed to fetch inner packing: ${response.body}');
        return null;
      }
    } catch (error) {
      _setErrorMessage('An error occurred: $error');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // PUT /innerPacking?innerPackingSku=...
  Future<void> updateInnerPacking(String sku, int quantityChanged, String reason) async {
    String baseUrl = await Constants.getBaseUrl();
    _setLoading(true);
    _setErrorMessage(null);

    final url = Uri.parse('$baseUrl/innerPacking?innerPackingSku=$sku');

    try {
      final token = await AuthProvider().getToken();
      if (token == null) {
        _setErrorMessage('No token found');
        return;
      }

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'action': 'change',
          'quantityChanged': quantityChanged,
          'reason': {'reason': reason},
        }),
      );

      if (response.statusCode == 200) {
        log('Inner packing updated: ${response.body}');
        await fetchAllInnerPackings(); // Refresh the list
      } else {
        _setErrorMessage('Failed to update inner packing: ${response.body}');
      }
    } catch (error) {
      _setErrorMessage('An error occurred: $error');
    } finally {
      _setLoading(false);
    }
  }
}
