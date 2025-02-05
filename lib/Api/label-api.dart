import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:logger/logger.dart';

class LabelApi with ChangeNotifier {
  List<Map<String, dynamic>> _labelInformation = [];
  List<Map<String, dynamic>> _replication = [];
  // List<Map<String, dynamic>> _replication = [];
  int _currentPage = 1;
  int _totalPage = 0;
  bool _loading = false;
  
  List<Map<String, dynamic>> get labelInformation => _labelInformation;
  int get totalPage => _totalPage;
  int get currentPage => _currentPage;
  bool get loading => _loading;

  void updateCurrentPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  void loadingStatus(bool value) {
    // _currentPage=page;
    _loading = value;
    notifyListeners();
  }

  void goToPage(int page) {
    if (page >= 1 && page <= _totalPage) {
      _currentPage = page;
      getLabel(page: page);
    }
    notifyListeners();
  }

  Future<void> updateLabelQuantity(
      String labelId, int newQuantity, String reason) async {
    String baseUrl = await Constants.getBaseUrl();
    loadingStatus(true);
    log("Id $labelId");

    final url = Uri.parse('$baseUrl/label/$labelId');
    log("Id 1: $labelId");

    final token = await AuthProvider().getToken();
    if (token == null) {
      loadingStatus(false);
      return;
    }

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'action': 'change',
          'quantityChanged': newQuantity,
          'reason': {
            'reason': reason,
          },
        }),
      );

      Logger().e('code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('Inventory updated: $data');

        final index =
            _labelInformation.indexWhere((item) => item['_id'] == labelId);
        if (index != -1) {
          _labelInformation[index]['QUANTITY'] = newQuantity.toString();
          notifyListeners();
        }
      } else {
        // Print error details for better debugging
        // _errorMessage =
        //     'Failed to update inventory. Status code: ${response.statusCode}. Response: ${response.body}';
        // log(_errorMessage.toString());
      }
    } catch (error) {
      // _errorMessage = 'An error occurred: $error';
      log('An error occurred: $error');
    } finally {
      loadingStatus(false);
    }
  }

  Future<Map<String, dynamic>> getLabel({int page = 1}) async {
    String baseUrl = await Constants.getBaseUrl();
    loadingStatus(true);

    final url = Uri.parse('$baseUrl/label?page=$page');

    try {
      final token = await AuthProvider().getToken();
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('data')) {
          //       "totalPages": 16,
          // "currentPage": 1
          _labelInformation =
              (List<Map<String, dynamic>>.from(data["data"]['labels']));
          _replication = (List<Map<String, dynamic>>.from(
              _labelInformation)); // Create a copy
          _totalPage = data["data"]['totalPages'];
          // if(!wait){
          loadingStatus(false);

          // }
          log('label: $_labelInformation');
          notifyListeners();
          return {'success': true, 'data': []};
        } else {
          print('Unexpected response format: $data');
          return {'success': false, 'message': 'Unexpected response format'};
        }
      } else {
        return {
          'success': false,
          'message':
              'Failed to fetch labels with status code: ${response.statusCode}'
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'An error occurred: $error'};
    } finally {
      loadingStatus(false);
    }
  }

  // Search by label
  Future<Map<String, dynamic>> searchByLabel(String lbl) async {
    String baseUrl = await Constants.getBaseUrl();
    final url = Uri.parse('$baseUrl/label?labelSku=$lbl');
    try {
      final token = await AuthProvider().getToken();
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('data')) {
          // _labelInformation.clear();
          // print("heeelo ${_labelInformation.length}   ${_replication.length}");
          _labelInformation =
              List<Map<String, dynamic>>.from(data["data"]['labels']);
          notifyListeners();
          return {
            'success': true,
            'data': _labelInformation
          }; // Dispatched updated labels
        } else {
          print('Unexpected response format: $data');
          return {'success': false, 'message': 'Unexpected response format'};
        }
      } else {
        return {
          'success': false,
          'message':
              'Failed to fetch labels with status code: ${response.statusCode}'
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'An error occurred: $error'};
    }
  }

  void filterLable(String query) async {
    if (query.isEmpty) {
      // print("prarthin  ###");
      _labelInformation = List<Map<String, dynamic>>.from(_replication);
    } else {
      // print("prarthin  ###uunhn");
      _labelInformation = (await searchByLabel(query))["data"];
    }
    notifyListeners();
  }

  void cancel() async {
    _labelInformation = List<Map<String, dynamic>>.from(_replication);

    notifyListeners();
  }
}
