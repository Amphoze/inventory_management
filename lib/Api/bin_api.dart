import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:logger/logger.dart';

class BinApi with ChangeNotifier {
  List<String> _bins = [];
  List<Map<String, dynamic>> _products = [];
  bool _isLoadingBins = false;
  bool _isLoadingProducts = false;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _toShowBins = true;
  int _binQty = 0;
  String _binName = '';
  final TextEditingController _textEditingController = TextEditingController();

// late final String _baseUrl;

//   BinApi() {
//     _initialize();
//   }

//   Future<void> _initialize() async {
//     _baseUrl = await ApiUrls.getBaseUrl();
//   }
  // Get all labels
  List<String> get bins => _bins;
  List<Map<String, dynamic>> get products => _products;
  bool get isLoadingBins => _isLoadingBins;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get toShowBins => _toShowBins;
  int get binQty => _binQty;
  String get binName => _binName;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  TextEditingController get textEditingController => _textEditingController;

  void setBinsLoadingStatus(bool value) {
    // _currentPage=page;
    _isLoadingBins = value;
    notifyListeners();
  }

  void setProductsLoadingStatus(bool value) {
    _isLoadingProducts = value;
    notifyListeners();
  }

  void toggle(bool value) {
    _toShowBins = value;
    notifyListeners();
  }

  void goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    _currentPage = page;
    print('Current page set to: $_currentPage'); // Debugging line
    fetchBinProducts(binName);
    notifyListeners();
  }

  void setBinName(String bin) {
    _binName = bin;
    notifyListeners();
  }

  Future<void> fetchBins(BuildContext context) async {
    String baseUrl = await ApiUrls.getBaseUrl();
    final url = Uri.parse('$baseUrl/inventory/bins');
    setBinsLoadingStatus(true);

    Logger().e('url: $url');

    try {
      final token = await AuthProvider().getToken();
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('data')) {
          _bins = List<String>.from(data['data'].map((bin) => bin['binName']));

          log("bins: $bins");

          notifyListeners();
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Failed to fetch bins: ${response.statusCode}');
      }
    } catch (error) {
      log('error hai: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setBinsLoadingStatus(false);
    }
  }

  Future<void> fetchBinProducts(String binName) async {
    setProductsLoadingStatus(true);
    log('called');
    String baseUrl = await ApiUrls.getBaseUrl();
    final url =
        Uri.parse('$baseUrl/inventory/bin?binName=$binName&page=$_currentPage');

    log('url: $url');

    try {
      final token = await AuthProvider().getToken();
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res.containsKey('data')) {
          _products = (res['data'][0]['products'] as List)
              .map((product) => {
                    'sku': product['product']['parentSku'].toString(),
                    'displayName': product['product']['displayName'].toString(),
                    'qty': product['qty'].toString(),
                  })
              .toList();

          _binQty = res['data'][0]['binQty'] as int;
          _currentPage = res['data'][0]['currentPage'] as int;
          _totalPages = res['data'][0]['totalPages'] as int;

          log("products: $_products");

          notifyListeners();
        } else {
          _products = [];
          throw Exception('Unexpected response format');
        }
      } else {
        _products = [];
        throw Exception('Failed to fetch bins: ${response.statusCode}');
      }
    } catch (error) {
      log('e: $error');
      _products = [];
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(error.toString()),
      //     backgroundColor: Colors.red,
      //   ),
      // );
    } finally {
      setProductsLoadingStatus(false);
    }
  }
}
