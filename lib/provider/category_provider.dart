import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:logger/logger.dart';

import '../model/product_master_model.dart';

class CategoryProvider with ChangeNotifier {
  List<String> _categories = [];
  List<String> _filteredCategories = [];
  List<Product> _categoryProducts = [];
  int _currentProductsPage = 1;
  int _totalProductsPages = 1;
  int _totalCategoryProducts = 0;
  bool _isFetchingCategories = false;
  bool _isFetchingProducts = false;
  bool _isSearchMode = false;
  bool _isCreatingCategory = false;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController categoryNameController = TextEditingController();

  // Getters
  List<String> get categories => _filteredCategories;
  List<Product> get categoryProducts => _categoryProducts;
  bool get isCreatingCategory => _isCreatingCategory;
  bool get isSearchMode => _isSearchMode;
  bool get isFetching => _isFetchingCategories;
  bool get isFetchingProducts => _isFetchingProducts;
  bool isRefreshingOrders = false;
  int get currentProductsPage => _currentProductsPage;
  int get totalProductsPages => _totalProductsPages;
  int get totalCategoryProducts => _totalCategoryProducts;

  void setRefreshingOrders(bool value) {
    isRefreshingOrders = value;
    notifyListeners();
  }

  void setFetchingProducts(bool value) {
    _isFetchingProducts = value;
    notifyListeners();
  }

  Future<void> fetchCategoryProducts(String categoryName, {int page = 1}) async {
    setFetchingProducts(true);

    try {
      final result = await AuthProvider().fetchCategoryProducts(categoryName, page: page);
      Logger().e('total products: ${result['totalProducts']}');

      if (result['success']) {
        final List<dynamic> products = result['products'];
        _categoryProducts = products.map((product) => Product.fromJson(product)).toList();
        _currentProductsPage = result['currentPage'];
        _totalProductsPages = result['totalPages'];
        _totalCategoryProducts = result['totalProducts'];
      Logger().e('_totalCategoryProducts: $_totalCategoryProducts');
      } else {
        _categoryProducts = [];
        _currentProductsPage = 1;
        _totalProductsPages = 1;
        _totalCategoryProducts = 0;
        log('Failed to fetch category products: ${result['message']}');
      }
    } catch (e) {
      _categoryProducts = [];
      _currentProductsPage = 1;
      _totalProductsPages = 1;
      _totalCategoryProducts = 0;
      log('Exception occurred while fetching category products: $e');
    } finally {
      setFetchingProducts(false);
      notifyListeners();
    }
  }

  Future<void> fetchAllCategories() async {
    List<String> allCategories = [];
    bool hasMore = true;
    int page = 1;
    _isFetchingCategories = false;
    setRefreshingOrders(true);
    notifyListeners();

    while (hasMore) {
      if (_isFetchingCategories) return;
      _isFetchingCategories = true;

      try {
        final result = await AuthProvider().getAllCategories(page: page);
        _isFetchingCategories = false;

        if (result['success']) {
          final List<dynamic> data = result['data'];
          if (data.isNotEmpty) {
            allCategories.addAll(data.map((category) => category['name'] as String).toList());
            hasMore = data.length == 20;
            page++;
          } else {
            hasMore = false;
          }
        } else {
          print('Failed to fetch categories: ${result['message']}');
          hasMore = false;
        }
      } catch (e) {
        print('Exception occurred while fetching categories: $e');
        _isFetchingCategories = false;
        break;
      }
    }
    _isFetchingCategories = false;
    _categories = allCategories;
    _filteredCategories = _categories;
    setRefreshingOrders(false);
    notifyListeners();
  }

  Future<List<String>> searchCategories(String name) async {
    try {
      final result = await AuthProvider().searchCategoryByName(name);
      if (result['success']) {
        final List<dynamic> data = result['data'];
        return data.map((category) => category['name'] as String).toList();
      } else {
        print('Failed to search categories: ${result['message']}');
        return [];
      }
    } catch (e) {
      print('Exception occurred while searching categories: $e');
      return [];
    }
  }

  void toggleSearchMode() {
    _isSearchMode = !_isSearchMode;
    if (!_isSearchMode) {
      searchController.clear();
      _filteredCategories = _categories;
    }
    notifyListeners();
  }

  void toggleCreateCategoryMode() {
    _isCreatingCategory = !_isCreatingCategory;
    if (_isCreatingCategory) {
      searchController.clear();
      _filteredCategories = _categories;
      _isSearchMode = false;
    }
    notifyListeners();
  }

  Future<void> createCategory() async {
    final name = categoryNameController.text;
    if (name.isNotEmpty) {
      try {
        final result = await AuthProvider().createCategory(name);
        if (result['success']) {
          await fetchAllCategories();
          searchController.clear();
          categoryNameController.clear();
          _isCreatingCategory = false;
          notifyListeners();
        } else {
          print('Failed to create category: ${result['message']}');
        }
      } catch (e) {
        print('Exception occurred while creating category: $e');
      }
    }
  }

  void filterCategories(String query) async {
    if (query.isEmpty) {
      _filteredCategories = _categories;
    } else {
      _filteredCategories = await searchCategories(query);
    }
    notifyListeners();
  }
}
