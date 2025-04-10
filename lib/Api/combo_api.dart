import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/model/combo_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ComboApi with ChangeNotifier {
  Future<String> updateCombo(String comboId, String name, String weight) async {
    String baseUrl = await Constants.getBaseUrl();
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = '$baseUrl/combo/$comboId';

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'comboWeight': weight,
        }),
      );

      final res = jsonDecode(response.body);

      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return res['message'];
      } else {
        return res['message'];
      }
    } catch (e) {
      log('Error updating combo: $e');
      return 'Error updating combo: $e';
    }
  }

  Future<List<Map<String, dynamic>>> searchCombo(String query) async {
    String baseUrl = await Constants.getBaseUrl();
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      var url = '$baseUrl/combo?${query.contains('-') ? 'comboSku' : 'name'}=$query';

      log('url: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        if (decodedResponse is List) {
          return List<Map<String, dynamic>>.from(decodedResponse);
        } else if (decodedResponse is Map) {
          final comboList = decodedResponse['combos'] as List<dynamic>? ?? [];

          return List<Map<String, dynamic>>.from(comboList);
        } else {
          throw Exception('Unexpected JSON format');
        }
      } else {
        throw Exception('Failed to load combos: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching combos: $e');
      throw Exception('Error fetching combos: $e');
    }
  }

  Future<void> createCombo(Combo combo, List<Uint8List>? images, List<String> imageNames) async {
    String baseUrl = await Constants.getBaseUrl();
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("Authentication token is missing.");
      }

      var uri = Uri.parse('$baseUrl/combo');
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['name'] = combo.name;
      request.fields['mrp'] = combo.mrp;
      request.fields['cost'] = combo.cost;
      request.fields['comboSku'] = combo.comboSku;
      request.fields['products'] = jsonEncode(combo.products);

      if (images != null && images.isNotEmpty) {
        for (int i = 0; i < images.length; i++) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'images',
              images[i],
              filename: imageNames[i],
              contentType: MediaType('image', 'png'),
            ),
          );
          debugPrint('Added image: ${imageNames[i]}');
        }
      }

      var response = await request.send();
      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        print('Combo created successfully');
        var responseData = await http.Response.fromStream(response);
        print('Response Data: ${responseData.body}');
      } else {
        print('Failed to create combo: ${response.statusCode}');
        var responseData = await http.Response.fromStream(response);
        debugPrint('Response Body: ${responseData.body}');
        throw Exception('Failed to create combo: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
      throw Exception('Error creating combo: $e');
    }
  }

  Future<Map<String, dynamic>> getCombos({int page = 1, int limit = 10}) async {
    String baseUrl = await Constants.getBaseUrl();
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/combo?page=$page&limit=$limit'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final res = json.decode(response.body);

        return {
          "combos": List<Map<String, dynamic>>.from(res['combos'] as List<dynamic>? ?? []),
          "totalCombos": res['totalCombos'] ?? 0,
        };

        // if (res is List) {
        //   return List<Map<String, dynamic>>.from(res);
        // } else if (res is Map) {
        //   final comboList = res['combos'] as List<dynamic>? ?? [];
        //
        //   return List<Map<String, dynamic>>.from(comboList);
        // } else {
        //   throw Exception('Unexpected JSON format');
        // }
      } else {
        throw Exception('Failed to load combos: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching combos: $e');
      throw Exception('Error fetching combos: $e');
    }
  }

  Future<Map<String, dynamic>> getAllProducts() async {
    String baseUrl = await Constants.getBaseUrl();
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/products/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (error) {
      log('Error in getAllProducts: $error');

      return {};
    }
  }

  Future<Product> getProductById(String productId) async {
    String baseUrl = await Constants.getBaseUrl();
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/products/search/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return Product.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load product');
      }
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }
}
