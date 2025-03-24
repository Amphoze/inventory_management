import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/constants/constants.dart';

class ProductPageApi {
  Future<Map<String, dynamic>> _fetchData(String endpoint, {int page = 1, int limit = 20, String? name}) async {
    final baseUrl = await Constants.getBaseUrl();
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final token = await AuthProvider().getToken();
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final key = endpoint == '/products/' ? 'products' : 'data';
        if (data.containsKey(key)) {
          final items = endpoint == '/products/' ? data[key] : data[key][endpoint.replaceAll('/', '').pluralize()];
          return {'success': true, 'data': List<Map<String, dynamic>>.from(items)};
        }
        log('Unexpected response format: $data');
        return {'success': false, 'message': 'Unexpected response format'};
      }
      return {'success': false, 'message': 'Failed to fetch data with status code: ${response.statusCode}'};
    } catch (error, stackTrace) {
      log('Error fetching $endpoint: $error\nStack trace: $stackTrace');
      return {'success': false, 'message': 'An error occurred: $error'};
    }
  }

  Future<Map<String, dynamic>> getAllBrandName({int page = 1, int limit = 20, String? name}) => _fetchData('/brand/', page: page, limit: limit, name: name);
  Future<Map<String, dynamic>> getLabel({int page = 1, int limit = 20, String? name}) => _fetchData('/label/', page: page, limit: limit, name: name);
  Future<Map<String, dynamic>> getBoxSize({int page = 1, int limit = 20, String? name}) => _fetchData('/boxsize/', page: page, limit: limit, name: name);
  Future<Map<String, dynamic>> getColorDrop({int page = 1, int limit = 20, String? name}) => _fetchData('/color/', page: page, limit: limit, name: name);
  Future<Map<String, dynamic>> getParentSku({int page = 1, int limit = 20, String? name}) => _fetchData('/products/', page: page, limit: limit, name: name);

  Future<http.Response> createProduct({
    BuildContext? context,
    required String displayName,
    required String parentSku,
    required String sku,
    required String ean,
    required String brand_id,
    required String outerPackage_quantity,
    required String description,
    required String technicalName,
    required String label_quantity,
    required String tax_rule,
    required String length,
    required String width,
    required String height,
    required String netWeight,
    required String grossWeight,
    required String mrp,
    required String cost,
    required bool active,
    required String labelSku,
    required String outerPackage_sku,
    required String categoryName,
    required String grade,
    required String shopifyImage,
    required String variant_name,
    required String itemQty,
  }) async {
    final baseUrl = await Constants.getBaseUrl();
    final url = Uri.parse('$baseUrl/products/');
    try {
      double? parseDouble(String value) => value.isEmpty ? null : double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? (throw Exception('Invalid number: $value'));
      int? parseInt(String value) => value.isEmpty ? null : int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? (throw Exception('Invalid integer: $value'));

      final netWeightNum = parseDouble(netWeight) ?? (throw Exception('Net weight is required'));
      final grossWeightNum = parseDouble(grossWeight) ?? (throw Exception('Gross weight is required'));
      final mrpNum = parseDouble(mrp);
      final costNum = parseDouble(cost);
      final itemQtyNum = parseInt(itemQty) ?? (throw Exception('Item quantity is required'));

      final token = await AuthProvider().getToken();
      final request = http.MultipartRequest('POST', url)
        ..headers.addAll({'Authorization': 'Bearer $token'})
        ..fields.addAll({
          'displayName': displayName,
          'parentSku': parentSku,
          'sku': sku,
          'ean': ean,
          'brand': brand_id,
          'description': description,
          'technicalName': technicalName,
          'tax_rule': tax_rule,
          'length': length,
          'width': width,
          'height': height,
          'netWeight': netWeightNum.toString(),
          'grossWeight': grossWeightNum.toString(),
          'mrp': mrpNum?.toString() ?? '',
          'cost': costNum?.toString() ?? '',
          'active': active.toString(),
          'labelSku': labelSku,
          'outerPackage_sku': outerPackage_sku,
          'categoryName': categoryName,
          'grade': grade,
          'shopifyImage': shopifyImage,
          'variant_name': variant_name,
          'itemQty': itemQtyNum.toString(),
        });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      log('Product creation response: ${response.statusCode} - ${response.body}');
      return response;
    } catch (error, stackTrace) {
      log('Error creating product: $error\nStack trace: $stackTrace');
      throw Exception('Failed to create product: $error');
    }
  }

  Future<List<int>> tata(File f) async => await f.readAsBytes();
}

extension StringExtension on String {
  String pluralize() => endsWith('y') ? '${substring(0, length - 1)}ies' : '${this}s';
}