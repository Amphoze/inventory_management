import 'package:flutter/material.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:http/http.dart' as http;

class UpdateQuantityBySku with ChangeNotifier {
  final String _baseUrl =
      'https://inventory-management-backend-s37u.onrender.com';
  bool _jsonHaveData = false;
  bool get jsonHaveData => _jsonHaveData;
  void updateJsonData({bool? isfalse}) {
    if (isfalse != null) {
      _jsonHaveData = false;
    } else {
      _jsonHaveData = !_jsonHaveData;
    }

    notifyListeners();
  }

  Future updateQuantityBySku(Map<String, Map<String, dynamic>> data) async {
    int count = 0;
    String? token = await AuthProvider().getToken();
    try {
      for (var label in data.keys) {
        count++;
        Uri url = Uri.parse('$_baseUrl/inventory?sku=$label');
        var response = await http.put(url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: data[label]);
        if (response.statusCode != 200 || response.statusCode != 201) {
          return {
            "res": "$count product is uploaded but rest product is failed"
          };
        }
      }
    } catch (e) {
      return {"res": "some error occurred ${e.toString()}"};
    } finally {
      // ignore: control_flow_in_finally
      _jsonHaveData = false;
      notifyListeners();
      // return {"res": "$count product is uploaded "};
    }
  }
}
