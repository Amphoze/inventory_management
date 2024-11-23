// ignore_for_file: prefer_final_fields

import 'dart:convert';
import 'dart:developer';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/model/label-model.dart';

class LabelPageApi extends ChangeNotifier {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _labelSkuController = TextEditingController();
  TextEditingController _imageController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  GlobalKey _dipu = GlobalKey();

  String _productId = '';
  bool _isloading = false;
  bool _buttonTap = false;
  List<int> _selectedIndex = [];
  final TextEditingController _quantityController = TextEditingController();
  List<Map<String, dynamic>> _productDetails = [];

  // New controller for DropdownSearch
  List<String> _selectedProducts = [];

  final String baseUrl =
      'https://inventory-management-backend-s37u.onrender.com';

  //getter for all controller
  TextEditingController get nameController => _nameController;
  TextEditingController get labelSkuController => _labelSkuController;
  TextEditingController get imageController => _imageController;
  TextEditingController get descriptionController => _descriptionController;
  TextEditingController get quantityController => _quantityController;

  // Getter and setter for productId
  String get productId => _productId;
  bool get isloading => _isloading;
  bool get buttonTap => _buttonTap;
  List<int> get selectedIndex => _selectedIndex;
  GlobalKey get dipu => _dipu;

  List<Map<String, dynamic>> get productDeatils => _productDetails;

  // Getter for the new controller
  List<String> get selectedProducts => _selectedProducts;

  void clearSelectedItemDrop({bool noti = false}) {
    _selectedIndex.clear();
    if (noti) {
      notifyListeners();
    }
  }

  void updateSelectedIndex(List<int> val) {
    _selectedIndex.addAll(val);
  }

  void selectedListIndexClear() {
    _selectedIndex.clear();
  }

  void buttonTapStatus() {
    _buttonTap = !buttonTap;
    notifyListeners();
  }

  // Method to update selected products
  void updateSelectedProducts(List<String> products) {
    _selectedProducts = products;
    notifyListeners();
  }

  // Method to print controller values
  void printControllerValues() {
    log("Name: ${_nameController.text}");
    log("Label SKU: ${_labelSkuController.text}");
    log("Image URL: ${_imageController.text}");
    log("Description: ${_descriptionController.text}");
    log("Quantity: ${_quantityController.text}");
    log("Selected Products: ${_selectedProducts.join(', ')}");
  }

  //create label
  Future<Map<String, dynamic>> createLabel() async {
    log("create label");
    printControllerValues();
    List<Map<String, String>> productIdMap = [];
    for (int i = 0; i < _selectedIndex.length; i++) {
      print("heeeli ${_productDetails[_selectedIndex[i]]['_id'].toString()}");
      productIdMap.add(
          {'productId': _productDetails[_selectedIndex[i]]['_id'].toString()});
    }
    print("lenght ${productIdMap.length}");
    final url = Uri.parse('$baseUrl/label/');
    LabelModel model = LabelModel(
        name: _nameController.text,
        labelSku: _labelSkuController.text,
        image: _imageController.text,
        description: _descriptionController.text,
        products: productIdMap,
        quantity: int.parse(_quantityController.text));
    try {
      final token = await AuthProvider().getToken();
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(model.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("respose body is here ${response.body.toString()}");
        return {"res": "success"};
      } else {
        print(response.body.toString());
        return {"res": response.body.toString()};
      }
    } catch (e) {
      // print("i ma gete with eororor");
      return {"res": e.toString()};
      // throw Exception('Failed to create label: $e');
    }
  }

  //get product details
  Future getProductDetails() async {
    final token = await AuthProvider().getToken();
    var response = await http.get(
      Uri.parse("$baseUrl/products"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['products'] is List) {
        _productDetails = List<Map<String, dynamic>>.from(data['products']);
        _isloading = true;
        // print("i am succesfill");
        notifyListeners();
        return {'success': true};
      } else {
        // print('Unexpected response format: $data');
        return {'success': false, 'message': 'Unexpected response format'};
      }
    } else {
      return {
        'success': false,
        'message':
            'Failed to fetch product details with status code: ${response.statusCode}'
      };
    }
  }

  //get product details

  @override
  void dispose() {
    super.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _labelSkuController.dispose();
    _quantityController.dispose();
    _imageController.dispose();
  }

  void clearControllers(GlobalKey<DropdownSearchState> key) {
    _nameController.clear();
    _labelSkuController.clear();
    _imageController.clear();
    _descriptionController.clear();
    _quantityController.clear();
    _productId = '';
    _selectedProducts.clear(); // Clear the selected products
    key.currentState?.clear();
    notifyListeners();
  }
}
