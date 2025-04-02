import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:inventory_management/constants/constants.dart';
import 'package:inventory_management/model/marketplace_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MarketplaceApi {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();

    if (token == null) {
      throw Exception('Authentication token not found');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> createMarketplace(Marketplace marketplace) async {
    String baseUrl = await Constants.getBaseUrl();
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse("$baseUrl/marketplace"),
      headers: headers,
      body: jsonEncode(marketplace.toJson()),
    );

    log('Create Market Place Status Code :- ${response.statusCode}');
    log('Create Market Place Response :- ${response.body}');

    if (response.statusCode != 201) {
      throw Exception('Failed to create marketplace: ${response.body}');
    }
  }

  Future<List<Marketplace>> getMarketplaces() async {
    String baseUrl = '${await Constants.getBaseUrl()}/marketplace?limit=100';
    final url = Uri.parse(baseUrl);
    log('Getting Market Places from URL :- $url');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    // log("getMarketplaces response: ${response.body}");

    try {
      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);

        if (responseJson.containsKey('data') && (responseJson['data']?.containsKey('marketplaces') ?? false)) {
          final List<dynamic> marketplaceJson = responseJson['data']?['marketplaces'] ?? [];
          // log('marketplaceJson: $marketplaceJson');
          return marketplaceJson.map((json) => Marketplace.fromJson(json)).toList();
        } else {
          throw Exception('Expected "marketplaces" field not found in response');
        }
      } else {
        throw Exception('Failed to load marketplaces: ${response.body}');
      }
    } catch (e, s) {
      log("Error in getMarketplaces: $e $s");
    }
    return [];
  }

  Future<Marketplace> getMarketplaceById(String id) async {
    String baseUrl = await Constants.getBaseUrl();
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl$id'), headers: headers);

    if (response.statusCode == 200) {
      return Marketplace.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load marketplace: ${response.body}');
    }
  }

  Future<void> updateMarketplace(String id, Marketplace marketplace) async {
    String baseUrl = await Constants.getBaseUrl();
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/marketplace/$id'),
      headers: headers,
      body: jsonEncode(marketplace.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update marketplace: ${response.body}');
    }
  }

  Future<void> deleteMarketplace(String id) async {
    String baseUrl = await Constants.getBaseUrl();
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/marketplace/$id'), headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete marketplace: ${response.body}');
    }
  }
}
