import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/model/combo_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';

class ComboApi with ChangeNotifier {
  // late final String baseUrl;

  // ComboApi() {
  //   _initialize();
  // }

  // Future<void> _initialize() async {
  //   baseUrl = await ApiUrls.getBaseUrl();
  // }

  Future<List<Map<String, dynamic>>> searchCombo(String query) async {
    String baseUrl = await ApiUrls.getBaseUrl();
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      var url =
          '$baseUrl/combo?${query.contains('-') ? 'comboSku' : 'name'}=$query';

      log('url: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      //print('Response status: ${response.statusCode}');
      //print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        //print('Decoded response: $decodedResponse');

        // Handle different response structures here
        if (decodedResponse is List) {
          // If it's a list, return it directly
          //print("list");
          return List<Map<String, dynamic>>.from(decodedResponse);
        } else if (decodedResponse is Map) {
          // If it's a map, check if it contains the list under a specific key
          //print("map");
          final comboList = decodedResponse['combos'] as List<dynamic>? ?? [];
          //print("comboList: $comboList");
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

  Future<void> createCombo(
      Combo combo, List<Uint8List>? images, List<String> imageNames) async {
    String baseUrl = await ApiUrls.getBaseUrl();
    try {
      // Get the token using the token retrieval method
      final token = await _getToken();
      if (token == null) {
        throw Exception("Authentication token is missing.");
      }

      var uri = Uri.parse('$baseUrl/combo');
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // // Add combo fields as text
      request.fields['name'] = combo.name;
      request.fields['mrp'] = combo.mrp;
      request.fields['cost'] = combo.cost;
      request.fields['comboSku'] = combo.comboSku;
      request.fields['products'] = jsonEncode(combo.products);

      // Attach selected images to the request
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

      // Send the request
      var response = await request.send();
      debugPrint('Response status: ${response.statusCode}');

      // Handle response
      if (response.statusCode == 201) {
        // Change this to check for 201
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

  // Get all combos
  Future<List<Map<String, dynamic>>> getCombos(
      {int page = 1, int limit = 10}) async {
    String baseUrl = await ApiUrls.getBaseUrl();
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/combo?page=$page&limit=$limit'),
        headers: {'Authorization': 'Bearer $token'},
      );

      //print('Response status: ${response.statusCode}');
      //print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        //print('Decoded response: $decodedResponse');

        // Handle different response structures here
        if (decodedResponse is List) {
          // If it's a list, return it directly
          //print("list");
          return List<Map<String, dynamic>>.from(decodedResponse);
        } else if (decodedResponse is Map) {
          // If it's a map, check if it contains the list under a specific key
          //print("map");
          final comboList = decodedResponse['combos'] as List<dynamic>? ?? [];
          //print("comboList: $comboList");
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

  Future<Map<String, dynamic>> getAllProducts() async {
    String baseUrl = await ApiUrls.getBaseUrl();
    try {
      final token = await _getToken(); // Fetch token dynamically

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

      //print('get products response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Dispatched the full JSON response
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (error) {
      print('Error in getAllProducts: $error');
      throw Exception('Error: $error');
    }
  }

  Future<Product> getProductById(String productId) async {
    String baseUrl = await ApiUrls.getBaseUrl();
    try {
      final token = await _getToken();
      //print(token);
      final response = await http.get(
        Uri.parse('$baseUrl/products/search/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      //print(response.body);
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
