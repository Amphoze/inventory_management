// ignore_for_file: prefer_final_fields

// import 'dart:async';
// import 'dart:core';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/Api/product-page-api.dart';

// import 'package:inventory_management/Api/auth_provider.dart';
// import 'package:inventory_management/Api/product-page-api.dart';

class ProductProvider extends ChangeNotifier {
  int _countVariationField = 1;
  int _alertBoxFieldCount = 1;
  int _dropFailIndex = 0;
  bool _isloading=false;
  bool _activeStatus=false;
  bool _noData=false;
  String _grade='';
  bool _saveButtonClick=false;
  String _selectedProductCategory='Create Simple Product';
  List<TextEditingController> _colors = [TextEditingController()];
  List<TextEditingController> _sizes = [TextEditingController()];
  List<TextEditingController> _eanUpcs = [TextEditingController()];
  List<TextEditingController> _skus = [TextEditingController()];
  List<TextEditingController> _alertBoxKeyEditingController = [TextEditingController()];
  List<TextEditingController> _alertBoxPairEditingController = [TextEditingController()];
  //list of values for all custom field
  List<Map<String, dynamic>> _cat=[{"name":"Select option"}];
  List<Map<String, dynamic>> _brand=[{"name":"Select option"}];
  List<Map<String, dynamic>> _label=[{"labelSku":"Select option"}];
  List<Map<String, dynamic>> _boxSize=[{"box_name":"Select option"}];
  List<Map<String, dynamic>> _parentSku=[{"name":"Select option"}];
  List<Map<String, dynamic>> _colorDrop=[{"name":"Select option"}];
  List<File> _file=[];

  // Getters
  List<TextEditingController> get color => _colors;
  List<TextEditingController> get size => _sizes;
  List<TextEditingController> get eanUpc=> _eanUpcs;
  List<TextEditingController> get sku => _skus;
  List<TextEditingController> get alertBoxKeyEditingController => _alertBoxKeyEditingController;
  List<TextEditingController> get alertBoxPairEditingController =>_alertBoxPairEditingController;
  int get dropFailIndex =>_dropFailIndex;

  bool get isloading=>_isloading;
  bool get activeStatus=>_activeStatus;
  bool get noData=>_noData;
  bool get saveButtonClick=>_saveButtonClick;

  String get selectedProductCategory =>_selectedProductCategory;
  int get countVariationFields => _countVariationField;
  int get alertBoxFieldCount => _alertBoxFieldCount;
  String get gradee => _grade;

  //get values for all cutom field
  List<Map<String, dynamic>> get cat=>_cat;
  List<Map<String, dynamic>> get boxSize=>_boxSize;
  List<Map<String, dynamic>> get brand=>_brand;
  List<Map<String, dynamic>> get label=>_label;
  List<Map<String, dynamic>> get parentSku=>_parentSku;
  List<Map<String, dynamic>> get colorDrop=>_colorDrop;
  List<File> get images=>_file;

  void update(){
    _noData=!noData;
    notifyListeners();
    Future.delayed(const Duration(seconds:15)).whenComplete((){
      _noData=!_noData;
    });
    // _noData=!noData;
  }
   void grade(String val){
    print("i am updating grade  $val");
    _grade=val;
    // _noData=!noData;
  }
   void saveButtonClickStatus(){
    _saveButtonClick=!_saveButtonClick;
    notifyListeners();
   
  }
  //
  void failedIndex(){
    notifyListeners();
    // _noData=!noData;
  }

  // Adding a new set of controllers
  void addNewTextEditingController() {
    _colors.add(TextEditingController());
    _sizes.add(TextEditingController());
    _eanUpcs.add(TextEditingController());
    _skus.add(TextEditingController());
    _countVariationField++;
    print("heelo is ahere$_countVariationField");
    notifyListeners();
  }
  
   

  

  void addNewTextEditingControllerInAlertBox() {
    _alertBoxKeyEditingController.add(TextEditingController());
    _alertBoxPairEditingController.add(TextEditingController());
    // _eanUpcs.add(TextEditingController());
    // _skus.add(TextEditingController());
      _alertBoxFieldCount++;
    // print("heelo is ahere${_countVariationField}");
    notifyListeners();
  }

  //get images
   Future setImage(List<File>img)async{
      _file=img;
      notifyListeners();
  }
    //get all custom dropvalue
   Future getCategories() async {
  
    _cat.addAll((await AuthProvider().getAllCategories())['data']
        .cast<Map<String, dynamic>>());
 

    _brand.addAll((await ProductPageApi().getAllBrandName())['data']
        .cast<Map<String, dynamic>>());
    _boxSize.addAll((await ProductPageApi().getBoxSize())['data']);
    _label.addAll((await ProductPageApi().getLabel())['data']);
   _colorDrop.addAll((await ProductPageApi().getColorDrop())['data']);
    _isloading=true;
    notifyListeners();
    // _isloading=false;
   
  }
  void changeActiveStaus(){
    _activeStatus=!activeStatus;
    notifyListeners();
  }



  void updateSelectedProductCategory(String val){
    _selectedProductCategory=val;
    notifyListeners();
  }

  // Deleting the last set of controllers
  void deleteTextEditingController(int index) {
    if (_countVariationField > 1) {
      _colors.elementAt(index).dispose();
      _sizes.elementAt(index).dispose();
      _eanUpcs.elementAt(index).dispose();
      _skus.elementAt(index).dispose();

      _colors.removeAt(index);
      _sizes.removeAt(index);
      _eanUpcs.removeAt(index);
      _skus.removeAt(index);

      _countVariationField--;
      // print("heelo is ahere${_countVariationField}");
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (var controller in _colors) {
      controller.dispose();
    }
    for (var controller in _sizes) {
      controller.dispose();
    }
    for (var controller in _eanUpcs) {
      controller.dispose();
    }
    for (var controller in _skus) {
      controller.dispose();
    }
    super.dispose();
  }
}
