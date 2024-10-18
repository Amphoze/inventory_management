import 'dart:async';
import 'package:flutter/material.dart';
import 'package:inventory_management/Api/auth_provider.dart';

class CategoryProvider with ChangeNotifier {
  List<String> _categories = [];
  List<String> _filteredCategories = [];
  bool _isFetching = false;
  bool _isSearchMode = false;
  bool _isCreatingCategory = false;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController categoryNameController = TextEditingController();

  // Getters
  List<String> get categories => _filteredCategories;
  bool get isCreatingCategory => _isCreatingCategory;
  bool get isSearchMode => _isSearchMode;

  // Add this getter to access `_isFetching`
  bool get isFetching => _isFetching;

  Future<void> fetchAllCategories() async {
    List<String> allCategories = [];
    bool hasMore = true;
    int page = 1;
    _isFetching = false;
    notifyListeners();

    while (hasMore) {
      if (_isFetching) return;
      _isFetching = true;

      try {
        final result = await AuthProvider().getAllCategories(page: page);
        _isFetching = false;

        if (result['success']) {
          final List<dynamic> data = result['data'];
          if (data.isNotEmpty) {
            allCategories.addAll(
                data.map((category) => category['name'] as String).toList());
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
        _isFetching = false;
        break;
      }
    }
    _isFetching = false;
    _categories = allCategories;
    _filteredCategories = _categories;
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
