import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/model/combo_model.dart';
import 'package:inventory_management/Api/combo_api.dart';
import 'package:multi_dropdown/multi_dropdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../Api/inventory_api.dart';

class ComboProvider with ChangeNotifier {
  Combo? _combo;
  bool _isFormVisible = false;
  List<Combo> _comboList = [];
  List<DropdownItem<String>> _items = [];
  List<DropdownItem<String>> get item => _items;
  List<Product> _products = [];
  List<Product> _selectedProducts = [];
  bool _loading = false;

  Combo? get combo => _combo;
  bool get isFormVisible => _isFormVisible;
  List<Combo> get comboList => _comboList;

  List<Product> get products => _products;
  List<Product> get selectedProducts => _selectedProducts;
  bool get loading => _loading;

  List<Map<String, dynamic>> _combosList = [];
  List<Map<String, dynamic>> get combosList => _combosList;

  List<Uint8List>? selectedImages = [];
  List<String> imageNames = [];

  ComboProvider() {
    fetchCombos();
  }

  void toggleFormVisibility() {
    _isFormVisible = !_isFormVisible;
    notifyListeners();
  }

  void setCombo(Combo combo) {
    _combo = combo;
    notifyListeners();
  }

  void addItem(String label, String value) {
    // _combo = combo;
    _items.add(DropdownItem<String>(label: label, value: value));

    print("item len  ${_items.length}");
    notifyListeners();
  }

  void addCombo(Combo combo) {
    print(combo.products);
    _comboList.add(combo);
    // _saveCombos();
    notifyListeners();
  }

  final comboApi = ComboApi();

  Future<void> createCombo(
      Combo combo, List<Uint8List>? images, List<String> productIds) async {
    try {
      final createdCombo =
          await comboApi.createCombo(combo, images, productIds);
      _combo = combo;
      notifyListeners();
    } catch (e) {
      print('Failed to create combo: $e');
    }
  }

  // Select images using file picker
  void selectImages() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image, // Only allow image files
    );

    if (result != null) {
      selectedImages = result.files.map((file) => file.bytes!).toList();
      imageNames = result.files.map((file) => file.name).toList();
      print('Selected images count: ${selectedImages!.length}');
      print('Image names count: ${imageNames.length}');
      notifyListeners();
    }
  }

  Future<void> fetchCombos({int page = 1, int limit = 10}) async {
    _loading = true;
    notifyListeners();
    try {
      _combosList = await comboApi.getCombos(page: page, limit: limit);
      //print("comboProvider.combosList : $_combosList");
    } catch (e) {
      print('Error fetching combos: $e');
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> _loadCombos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('combos') ?? [];
    _comboList =
        jsonList.map((json) => Combo.fromJson(jsonDecode(json))).toList();
    notifyListeners();
  }

  Future<void> _saveCombos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList =
        _comboList.map((combo) => jsonEncode(combo.toJson())).toList();
    await prefs.setStringList('combos', jsonList);
  }

  void clearCombo() {
    _combo = null;
    notifyListeners();
  }

  void clearCombos() {
    _comboList.clear();
    notifyListeners();
  }


  Future<void> fetchProducts() async {
    _loading = true;
    notifyListeners();
    try {
      final api = ComboApi();

      final response = await api.getAllProducts();

      if (response.containsKey('products') && response['products'] is List) {

        final productList = response['products'];
        print("Raw productList in provider: $productList");

        _products = productList.map<Product>((json) => Product.fromJson(json)).toList();
        print("Mapped products in provider: $_products");
      }

      else {
        print("Error: 'products' key not found or not a list in response.");
      }
    } catch (e, stacktrace) {
      // Log error details
      print('Error fetching products: $e');
      print('Stacktrace: $stacktrace');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }


  List<Map<String, dynamic>> _warehouses = [];

  List<Map<String, dynamic>> get warehouses => _warehouses;
  Future<void> fetchWarehouses() async {
    _loading = true;
    notifyListeners();

    try {
      final api = AuthProvider();
      final response = await api.getAllWarehouses();


      if (response['success'] == true) {
        final warehouseList = response['data']['warehouses'];
        print("Raw warehouseList in provider: $warehouseList");

        _warehouses = warehouseList;

        print("Mapped warehouses in provider: $_warehouses");
      } else {
        print("Error: ${response['message']}");
      }
    } catch (e, stacktrace) {

      print('Error fetching warehouses: $e');
      print('Stacktrace: $stacktrace');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }



  // Method to select products by IDs
  void selectProductsByIds(List<String?> productIds) {
    _selectedProducts =
        _products.where((product) => productIds.contains(product.id)).toList();
    notifyListeners();
  }
}
