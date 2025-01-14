import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/invoice_model.dart';

class InvoiceProvider with ChangeNotifier {
  List<Invoice> _invoices = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalInvoices = 0;
  final int _pageSize = 20; // Keep it 20 invoices per page

  List<Invoice> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  // late final String apiUrl;

  // InvoiceProvider() {
  //   _initialize();
  // }

  // Future<void> _initialize() async {
  //   apiUrl = await ApiUrls.getBaseUrl();
  // }

  Future<void> fetchInvoices({int page = 1}) async {
    String apiUrl = await ApiUrls.getBaseUrl();
    _isLoading = true;
    _error = null;
    _currentPage = page;
    notifyListeners();

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      notifyListeners();
      print('Token is missing. Please log in again.');
      return;
    }

    try {
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };
      final response = await http.get(
          Uri.parse('$apiUrl/invoice?page=$page&limit=$_pageSize'),
          headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final invoicesData = data['invoices'] as List<dynamic>;
        _invoices = invoicesData.map((json) => Invoice.fromJson(json)).toList();
        _totalInvoices = data['totalInvoices'];
        _totalPages = data['totalPages'];
      } else {
        _error = 'Failed to load invoices';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void nextPage() {
    if (_currentPage < _totalPages) {
      fetchInvoices(page: _currentPage + 1);
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      fetchInvoices(page: _currentPage - 1);
    }
  }

  void goToPage(int page) {
    if (page > 0 && page <= _totalPages) {
      fetchInvoices(page: page);
    }
  }

  // Go directly to the first page
  void goToFirstPage() {
    if (_currentPage != 1) {
      fetchInvoices(page: 1);
    }
  }

  // Go directly to the last page
  void goToLastPage() {
    if (_currentPage != _totalPages) {
      fetchInvoices(page: _totalPages);
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // Search invoices by invoice number
  // Future<void> searchInvoiceByNumber(String invoiceNumber) async {
  //   _isLoading = true;
  //   _error = null;
  //   notifyListeners();
  //
  //   try {
  //   } catch (e) {
  //     _error = e.toString();
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }
  Future<void> searchInvoiceByNumber(String invoiceNumber) async {
    String apiUrl = await ApiUrls.getBaseUrl();
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (invoiceNumber.isEmpty) {
      fetchInvoices();
      return;
    }

    log('Searching for invoice: $invoiceNumber');

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      notifyListeners();
      print('Token is missing. Please log in again.');
      return;
    }

    try {
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };
      final response = await http.get(
          Uri.parse('$apiUrl/invoice?invoice_number=$invoiceNumber'),
          headers: headers);

      log('Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['invoices'];
        _invoices = data.map((json) => Invoice.fromJson(json)).toList();

        log('Invoices: $_invoices');
      } else {
        _error = 'No invoice found with that number';
        log("No invoice found with that number");
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
