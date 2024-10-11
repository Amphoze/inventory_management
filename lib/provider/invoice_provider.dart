import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../model/invoice_model.dart';

class InvoiceProvider with ChangeNotifier {
  List<Invoice> _invoices = [];
  bool _isLoading = false;
  String? _error;

  List<Invoice> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get error => _error;
  final String apiUrl = 'https://inventory-management-backend-s37u.onrender.com';

  Future<void> fetchInvoices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('https://inventory-management-backend-s37u.onrender.com/invoice/'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['invoices'];
        _invoices = data.map((json) => Invoice.fromJson(json)).toList();
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

}
