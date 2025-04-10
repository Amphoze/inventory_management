import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:inventory_management/Api/combo_api.dart';
import 'package:inventory_management/model/combo_model.dart'; // Product model
import 'package:inventory_management/model/marketplace_model.dart';
import 'package:inventory_management/Api/marketplace_api.dart';

class MarketplaceProvider with ChangeNotifier {
  int totalMarketplace = 0;
  bool _isFormVisible = false;
  final TextEditingController nameController = TextEditingController();
  final List<SkuMap> _skuMaps = [];
  List<Marketplace> _marketplaces = [];
  List<Marketplace> _filteredMarketplaces = [];
  String _searchQuery = '';
  List<Product> _products = [];
  bool _loading = false;
  bool isSaving = false;

  bool get isFormVisible => _isFormVisible;
  List<Marketplace> get filteredMarketplaces => _filteredMarketplaces;
  String get searchQuery => _searchQuery;
  List<Marketplace> get marketplaces => _marketplaces;
  List<SkuMap> get skuMaps => _skuMaps;
  List<Product> get products => _products;
  bool get loading => _loading;

  final marketplaceApi = MarketplaceApi();
  final comboApi = ComboApi();

  Future<void> fetchMarketplaces() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await marketplaceApi.getMarketplaces();
      _marketplaces = res['marketplaces'];
      totalMarketplace = res['totalMarketplace'];
      _filteredMarketplaces = _marketplaces;
    } catch (e, s) {
      log('Error fetching marketplaces: $e $s');
      _filteredMarketplaces = [];
      _marketplaces = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProducts() async {
    _loading = true;
    notifyListeners();
    try {
      final response = await comboApi.getAllProducts();
      final productList = response['products'] ?? [];
      _products = productList.map<Product>((json) => Product.fromJson(json)).toList();
    } catch (e, s) {
      log('Error fetching products: $e\n\n$s');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void updateSkuMap(int index, String sku, Product? selectedProduct) {
    final productId = selectedProduct?.id ?? '';
    _skuMaps[index] = SkuMap(
      mktpSku: sku,
      productId: productId,
      product: selectedProduct,
    );
    // No notifyListeners() here; UI will handle temporary state
  }

  void addSkuMapRow() {
    _skuMaps.add(SkuMap(mktpSku: '', productId: '', product: null));
    notifyListeners();
  }

  void removeSkuMapRow(int index) {
    _skuMaps.removeAt(index);
    notifyListeners();
  }

  void toggleForm() {
    _isFormVisible = !_isFormVisible;
    if (!_isFormVisible) {
      _skuMaps.clear();
      nameController.clear();
    }
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    filterMarketplaces();
    notifyListeners();
  }

  void filterMarketplaces() {
    if (_searchQuery.isEmpty) {
      _filteredMarketplaces = _marketplaces;
    } else {
      _filteredMarketplaces = _marketplaces
          .where((marketplace) => marketplace.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  Future<void> saveMarketplace() async {
    isSaving = true;
    notifyListeners();

    final invalidSkuMaps = skuMaps.where((skuMap) => skuMap.mktpSku.isEmpty).toList();
    if (nameController.text.isEmpty || invalidSkuMaps.isNotEmpty) {
      log('Error: Name or some SKU maps are invalid.');
      isSaving = false;
      notifyListeners();
      return;
    }

    final newMarketplace = Marketplace(
      name: nameController.text,
      skuMap: List.from(skuMaps),
    );

    try {
      await marketplaceApi.createMarketplace(newMarketplace);
      await fetchMarketplaces();
      toggleForm();
    } catch (e) {
      log('Error creating marketplace: $e');
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteMarketplace(String id) async {
    try {
      await marketplaceApi.deleteMarketplace(id);
      fetchMarketplaces();
    } catch (e) {
      log('Error deleting marketplace: $e');
    }
  }
}