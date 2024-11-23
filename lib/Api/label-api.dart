import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/Api/auth_provider.dart';

class LabelApi with ChangeNotifier {
  List<Map<String, dynamic>> _labelInformation = [];
  List<Map<String, dynamic>> _replication = [];
  // List<Map<String, dynamic>> _replication = [];
  int _currentPage = 1;
  int _totalPage = 0;
  bool _loading = true;
  final String _baseUrl =
      'https://inventory-management-backend-s37u.onrender.com';

  // Get all labels
  List<Map<String, dynamic>> get labelInformation => _labelInformation;
  int get totalPage => _totalPage;
  int get currentPage => _currentPage;
  bool get loading => _loading;

  void updateCurrentPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  void loadingStaus() {
    // _currentPage=page;
    _loading = !_loading;
    notifyListeners();
  }

  Future<Map<String, dynamic>> getLabel() async {
    final url = Uri.parse('$_baseUrl/label?page=$currentPage');

    _loading = !_loading;

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
          print("total pages hehebun ${_labelInformation.length}");
          _totalPage = data["data"]['totalPages'];
          // if(!wait){
          _loading = !_loading;
          // }
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
    }
  }

  // Search by label
  Future<Map<String, dynamic>> searchByLabel(String lbl) async {
    final url = Uri.parse('$_baseUrl/label?labelSku=$lbl');
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
