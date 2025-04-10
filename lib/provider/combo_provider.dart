import 'dart:convert';
import 'dart:developer';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/model/combo_model.dart';
import 'package:inventory_management/Api/combo_api.dart';
import 'package:multi_dropdown/multi_dropdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../Api/inventory_api.dart';

class ComboProvider with ChangeNotifier {
  int totalCombos = 0;
  Combo? _combo;
  bool _isFormVisible = false;
  List<Combo> _comboList = [];
  final List<DropdownItem<String>> _items = [];
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

  bool isRefreshingOrders = false;

  void setRefreshingOrders(bool value) {
    isRefreshingOrders = value;
    notifyListeners();
  }

  void clearSelectedImages() {
    selectedImages = [];
    imageNames = [];
    notifyListeners();
  }

  // Method to remove selected image
  void removeSelectedImage(int index) {
    if (selectedImages != null && index >= 0 && index < selectedImages!.length) {
      selectedImages!.removeAt(index);
      imageNames.removeAt(index); // Remove corresponding name
      notifyListeners(); // Update listeners
    }
  }

  ComboProvider() {
    fetchCombos();
  }

  void toggleFormVisibility() {
    _isFormVisible = !_isFormVisible;
    if (!isFormVisible) {
      clearSelectedImages();
    }
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
    // print(combo.products);
    _comboList.add(combo);
    // _saveCombos();
    notifyListeners();
  }

  final comboApi = ComboApi();

  Future<void> createCombo(Combo combo, List<Uint8List>? images, List<String> productIds) async {
    try {
      final createdCombo = await comboApi.createCombo(combo, images, productIds);
      _combo = combo;
      notifyListeners();
    } catch (e) {
      print('Failed to create combo: $e');
    }
  }

  Future<String> updateCombo(String comboId, String name, String weight) async {
    try {
      return await comboApi.updateCombo(comboId, name, weight);
    } catch (e) {
      return 'Failed to create combo: $e';
    }
  }

  Future<void> selectImages() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );

    if (result != null) {
      for (var file in result.files) {
        if (file.bytes != null) {
          selectedImages!.add(file.bytes!);
          imageNames.add(file.name);
        }
      }
      notifyListeners();
    }
    // Print each image name
    for (String name in imageNames) {
      print('Image name: $name');
    }

    print('Selected images count: ${selectedImages!.length}');
    print('Image names count: ${imageNames.length}');
    notifyListeners();
  }

  Future<void> fetchCombos({int page = 1, int limit = 10}) async {
    _loading = true;
    setRefreshingOrders(true);
    notifyListeners();
    try {
      // _combosList = await comboApi.getCombos(page: page, limit: limit);
      final res = await comboApi.getCombos(page: page, limit: limit);
      _combosList = res['combos'] as List<Map<String, dynamic>>;
      totalCombos = res['totalCombos'] as int;
    } catch (e) {
      print('Error fetching combos: $e');
    }

    _loading = false;
    setRefreshingOrders(false);
    notifyListeners();
  }

  Future<int?> fetchQuantityBySku(String query) async {
    try {
      String baseUrl = await Constants.getBaseUrl();
      final pref = await SharedPreferences.getInstance();
      final warehouseId = pref.getString('warehouseId');

      if (warehouseId == null) {
        log('Warehouse ID is not set in preferences.');
        return null;
      }

      final url = Uri.parse('$baseUrl/inventory/warehouse?warehouse=$warehouseId&productSku=$query');
      log('URL: $url');

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
          final inventories = List<Map<String, dynamic>>.from(data["data"]['inventories']);

          for (var item in inventories) {
            final subInventories = item['subInventory'] ?? [];
            for (var subInventory in subInventories) {
              if (subInventory['warehouseId']['_id'] == warehouseId) {
                return subInventory['quantity']; // Return quantity directly
              }
            }
          }
          log('No matching warehouseId found.');
          return null;
        } else {
          log('Unexpected response format: $data');
          return null;
        }
      } else {
        log('Failed to fetch inventory: Status code ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('Error occurred: $e');
      return null;
    }
  }

  Future<void> searchCombos(String query) async {
    _loading = true;
    setRefreshingOrders(true);
    notifyListeners();
    try {
      _combosList = await comboApi.searchCombo(query);
      //print("comboProvider.combosList : $_combosList");
    } catch (e) {
      print('Error fetching combos: $e');
    }

    _loading = false;
    setRefreshingOrders(false);
    notifyListeners();
  }

  Future<void> _loadCombos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('combos') ?? [];
    _comboList = jsonList.map((json) => Combo.fromJson(jsonDecode(json))).toList();
    notifyListeners();
  }

  Future<void> _saveCombos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _comboList.map((combo) => jsonEncode(combo.toJson())).toList();
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
        // print("Raw productList in provider: $productList");

        _products = productList.map<Product>((json) => Product.fromJson(json)).toList();
        // log("Mapped products in provider: $_products");
      } else {
        // print("Error: 'products' key not found or not a list in response.");
      }
    } catch (e, stacktrace) {
      // Log error details
      log('Error fetching products: $e');
      log('Stacktrace: $stacktrace');
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
        // print("Raw warehouseList in provider: $warehouseList");

        _warehouses = warehouseList;

        // print("Mapped warehouses in provider: $_warehouses");
      } else {
        print("Error: ${response['message']}");
      }
    } catch (e, stacktrace) {
      log('Error fetching warehouses: $e');
      print('Stacktrace: $stacktrace');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Method to select products by IDs
  void selectProductsByIds(List<String?> productIds) {
    _selectedProducts = _products.where((product) => productIds.contains(product.id)).toList();
    notifyListeners();
  }

  void addMoreProducts(String displayName) async {
    log("displayName: $displayName");
    String baseUrl = await Constants.getBaseUrl();
    String url = '$baseUrl/products?displayName=${Uri.encodeComponent(displayName)}';

    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse(url), // Ensure URL is parsed
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Check the response status code
      if (response.statusCode == 200) {
        print("Response Status: ${response.statusCode}");
        // log("Response Body: ${response.body}");

        final productList = json.decode(response.body)['products'];
        final newProducts = productList.map<Product>((json) => Product.fromJson(json)).toList();
        _products.addAll(newProducts);

        notifyListeners();

        // log(_products.toString());
      }
    } catch (error) {
      log("catched: $error");
    }
    notifyListeners();
  }
}
