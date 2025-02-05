import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/model/marketplace_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MarketplaceApi {
  // final String baseUrl = '${await ApiUrls.getBaseUrl()}/marketplace/';

  // late final String baseUrl;

  // MarketplaceApi() {
  //   _initialize();
  // }

  // Future<void> _initialize() async {
  //   baseUrl = '${await ApiUrls.getBaseUrl()}/marketplace/';
  // }

  // Method to get the token from shared preferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // Method to get the headers with the token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken(); // Retrieve the token
    //print(token);
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization':
          'Bearer $token', // Attach the token to the Authorization header
    };
  }

  // Create a new marketplace
  Future<void> createMarketplace(Marketplace marketplace) async {
    String baseUrl = await Constants.getBaseUrl();
    final headers = await _getHeaders(); // Get headers with token
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonEncode(marketplace.toJson()), // Send marketplace as JSON
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create marketplace: ${response.body}');
    }
  }

  // Get all marketplaces
  Future<List<Marketplace>> getMarketplaces() async {
    String baseUrl = '${await Constants.getBaseUrl()}/marketplace/';
    final headers = await _getHeaders(); // Get headers with token
    final response = await http.get(Uri.parse(baseUrl), headers: headers);

    if (response.statusCode == 200) {
      // Decode the response as a Map (JSON object)
      final Map<String, dynamic> responseJson = jsonDecode(response.body);

      // Access the 'marketplaces' list within the 'data' field
      if (responseJson.containsKey('data') &&
          responseJson['data'].containsKey('marketplaces')) {
        final List<dynamic> marketplaceJson =
            responseJson['data']['marketplaces'];
        return marketplaceJson
            .map((json) => Marketplace.fromJson(json))
            .toList();
      } else {
        throw Exception('Expected "marketplaces" field not found in response');
      }
    } else {
      throw Exception('Failed to load marketplaces: ${response.body}');
    }
  }

  // Get marketplace by ID
  Future<Marketplace> getMarketplaceById(String id) async {
    String baseUrl = await Constants.getBaseUrl();
    final headers = await _getHeaders(); // Get headers with token
    final response = await http.get(Uri.parse('$baseUrl$id'), headers: headers);

    if (response.statusCode == 200) {
      return Marketplace.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load marketplace: ${response.body}');
    }
  }

  // Update marketplace by ID
  Future<void> updateMarketplace(String id, Marketplace marketplace) async {
    String baseUrl = await Constants.getBaseUrl();
    final headers = await _getHeaders(); // Get headers with token
    final response = await http.put(
      Uri.parse('$baseUrl$id'),
      headers: headers,
      body:
          jsonEncode(marketplace.toJson()), // Send updated marketplace as JSON
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update marketplace: ${response.body}');
    }
  }

  // Delete marketplace by ID
  Future<void> deleteMarketplace(String id) async {
    String baseUrl = await Constants.getBaseUrl();
    final headers = await _getHeaders(); // Get headers with token
    final response =
        await http.delete(Uri.parse('$baseUrl$id'), headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete marketplace: ${response.body}');
    }
  }
}
