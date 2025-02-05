import 'package:flutter/material.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/Custom-Files/product-card.dart';
import 'package:logger/logger.dart';

// import 'products.dart';

class ProductsProvider with ChangeNotifier {
  final AuthProvider authProvider;

  ProductsProvider(this.authProvider);

  final int itemsPerPage = 30;
  final List<Product> _products = [];
  int totalProducts = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  Future<void> loadMoreProducts() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await authProvider.getAllProducts(
        page: _currentPage,
        itemsPerPage: itemsPerPage,
      );

      if (response['success']) {
        final List<dynamic> productData = response['data'];
        final newProducts = productData.map((data) {
          return Product(
            sku: data['sku'] ?? '',
            parentSku: data['parentSku'] ?? '',
            ean: data['ean'] ?? '',
            description: data['description'] ?? '',
            categoryName: data['categoryName'] ?? '',
            brand: data['brand'] ?? '',
            colour: data['colour'] ?? '',
            netWeight: data['netWeight']?.toString() ?? '',
            grossWeight: data['grossWeight']?.toString() ?? '',
            labelSku: data['labelSku'] ?? '',
            outerPackage_quantity: data['outerPackage_quantity']?.toString() ?? '',
            outerPackage_name: data['outerPackage_name'] ?? '',
            grade: data['grade'] ?? '',
            technicalName: data['technicalName'] ?? '',
            length: data['length']?.toString() ?? '',
            width: data['width']?.toString() ?? '',
            height: data['height']?.toString() ?? '',
            mrp: data['mrp']?.toString() ?? '',
            cost: data['cost']?.toString() ?? '',
            tax_rule: data['tax_rule']?.toString() ?? '',
            shopifyImage: data['shopifyImage'] ?? '',
            createdDate: data['createdAt'] ?? '',
            lastUpdated: data['updatedAt'] ?? '',
            displayName: data['displayName'] ?? '',
            variantName: data['variant_name'] ?? '',
          );
        }).toList();

        totalProducts = response['totalProducts'];
        _products.addAll(newProducts);
        _hasMore = newProducts.length == itemsPerPage;

        if (_hasMore) _currentPage++;
      } else {
        _hasMore = false;
      }
    } catch (error) {
      Logger().e('Error loading products: $error');
      _hasMore = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _products.clear();
    _currentPage = 1;
    _hasMore = true;
    totalProducts = 0;
    notifyListeners();
  }
}
