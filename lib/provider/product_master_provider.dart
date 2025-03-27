import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/model/product_master_model.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class ProductMasterProvider with ChangeNotifier {
  final int _itemsPerPage = 30;
  final List<Product> _products = [];
  int totalProducts = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _showCreateProduct = false;
  int _currentPage = 1;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _searchbarController = TextEditingController();
  final String _selectedSearchOption = 'Display Name';

  // Getters
  List<Product> get products => _products;
  int get totalProductsCount => totalProducts;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  bool get showCreateProduct => _showCreateProduct;
  TextEditingController get searchController => _searchController;
  TextEditingController get searchbarController => _searchbarController;
  String get selectedSearchOption => _selectedSearchOption;

  @override
  void dispose() {
    _searchController.dispose();
    _searchbarController.dispose();
    super.dispose();
  }

  Future<void> loadMoreProducts([BuildContext? context]) async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final authProvider = context != null
          ? Provider.of<AuthProvider>(context, listen: false)
          : null;
      final response = await authProvider!.getAllProducts(
          page: _currentPage, itemsPerPage: _itemsPerPage);

      log('loadMoreProducts response: $response');

      if (response['success'] == true) {
        final List<dynamic> productData = response['data'];
        final newProducts = productData.map((data) => Product.fromJson(data)).toList();

        totalProducts = response['totalProducts'];
        _products.addAll(newProducts);
        _hasMore = newProducts.length == _itemsPerPage;
        if (_hasMore) _currentPage++;
      } else {
        _hasMore = false;
      }
    } catch (error) {
      _hasMore = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleCreateProduct() {
    _showCreateProduct = !_showCreateProduct;
    notifyListeners();
  }

  Future<void> performSearch(BuildContext context) async {
    if (_searchbarController.text.trim().isEmpty) {
      // refreshPage();
      return;
    }

    _isLoading = true;
    _hasMore = false;
    notifyListeners();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final searchTerm = _searchbarController.text.trim();

    Logger().e("Search Term: $searchTerm");

    try {
      final response = searchTerm.contains('-')
          ? await authProvider.searchProductsBySKU(searchTerm)
          : await authProvider.searchProductsByDisplayName(searchTerm);

      if (response['success'] == true) {
        final List<dynamic>? productData = response['products'] ?? response['data'];

        Logger().e("Product Data: $productData");

        _products.clear();
        if (productData != null) {
          _products.addAll(productData.map((data) => Product.fromJson(data)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'No products found.')),
          );
        }
      } else {
        _handleError(context, response['message']);
      }
    } catch (error) {
      log("Error - $error");
      _handleError(context, 'An error occurred: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void refreshPage(BuildContext context) {
    _products.clear();
    _searchbarController.clear();
    _currentPage = 1; // Reset page
    _hasMore = true;
    loadMoreProducts(context);
  }

  void _handleError(BuildContext context, String? message) {
    _products.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Something went wrong.')),
    );
    notifyListeners();
  }
}