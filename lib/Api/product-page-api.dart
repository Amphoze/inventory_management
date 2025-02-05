// import 'dart:html' as html;
// import 'dart:js_interop';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
// import 'dart:io';
// import 'dart:typed_data';
import 'package:flutter/material.dart';

// import 'package:http_parser/http_parser.dart';
// import 'package:flutter/services.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_management/constants/constants.dart';
// import 'package:path/path.dart' as path;

class ProductPageApi {
  Future<Map<String, dynamic>> getAllBrandName(
      {int page = 1, int limit = 20, String? name}) async {
    String baseUrl = await Constants.getBaseUrl();
    final url = Uri.parse('$baseUrl/brand/');

    try {
      final token = await AuthProvider().getToken();
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('token is here: $token');
      // print('Get All brand  Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('brands') && data['brands'] is List) {
          print("here is barndd ${data['brands']}");
          // List brand;

          // brand = parseJsonToList(response.body.toString(), 'brands');
          // }
          // print("i am dipu us here wiht success");
          return {
            'success': true,
            'data': List<Map<String, dynamic>>.from(data['brands'])
          };
        } else {
          print('Unexpected response format: $data');
          return {'success': false, 'message': 'Unexpected response format'};
        }
      } else {
        return {
          'success': false,
          'message':
              'Failed to fetch categories with status code: ${response.statusCode}'
        };
      }
    } catch (error, stackTrace) {
      print('An error occurred while fetching categories: $error');
      print('Stack trace: $stackTrace');
      return {'success': false, 'message': 'An error occurred: $error'};
    }
  }

  //label url
  Future<Map<String, dynamic>> getLabel(
      {int page = 1, int limit = 20, String? name}) async {
    String baseUrl = await Constants.getBaseUrl();
    final url = Uri.parse('$baseUrl/label/');

    try {
      final token = await AuthProvider().getToken();
      print("token is heree $token");
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // print('Get All brand Response: ${response.statusCode}');
      // print('Get All brand  Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          // List<Map<String,dynamic>>dup=data.cast(List<Map<String,dynamic>>);
          print("techna e data is here ${data.runtimeType}  ");
          final labels = data['data'];
          print("lable of label is here ${labels.toString()}");
          return {
            'success': true,
            'data': List<Map<String, dynamic>>.from(labels['labels'])
          };
        } else {
          print('Unexpected response format: $data');
          return {'success': false, 'message': 'Unexpected response format'};
        }
      } else {
        return {
          'success': false,
          'message':
              'Failed to fetch categories with status code: ${response.statusCode}'
        };
      }
    } catch (error, stackTrace) {
      print('An error occurred while fetching categories: $error');
      print('Stack trace: $stackTrace');
      return {'success': false, 'message': 'An error occurred: $error'};
    }
  }

  //boxsize
  Future<Map<String, dynamic>> getBoxSize(
      {int page = 1, int limit = 20, String? name}) async {
    String baseUrl = await Constants.getBaseUrl();
    final url = Uri.parse('$baseUrl/boxsize/');

    try {
      final token = await AuthProvider().getToken();
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // print('Get All brand Response: ${response.statusCode}');
      // print('Get All brand  Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // print("jajajjhjhj");
        final data = json.decode(response.body);
        if (data.containsKey('data')) {
          return {
            'success': true,
            'data': List<Map<String, dynamic>>.from(data['data']['boxsizes'])
          };
        } else {
          print('Unexpected response format: $data');
          return {'success': false, 'message': 'Unexpected response format'};
        }
      } else {
        return {
          'success': false,
          'message':
              'Failed to fetch categories with status code: ${response.statusCode}'
        };
      }
    } catch (error, stackTrace) {
      print('An error occurred while fetching categories: $error');
      print('Stack trace: $stackTrace');
      return {'success': false, 'message': 'An error occurred: $error'};
    }
  }

  //colors dropdown api
  Future<Map<String, dynamic>> getColorDrop(
      {int page = 1, int limit = 20, String? name}) async {
    String baseUrl = await Constants.getBaseUrl();
    final url = Uri.parse('$baseUrl/color/');

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
        //  print("here is color data ${data['data']['colors'].toString()}");
        return {
          'success': true,
          'data': List<Map<String, dynamic>>.from(data['data']['colors'])
        };
        // }
      } else {
        return {
          'success': false,
          'message':
              'Failed to fetch categories with status code: ${response.statusCode}'
        };
      }
    } catch (error, stackTrace) {
      print('An error occurred while fetching categories: $error');
      print('Stack trace: $stackTrace');
      return {'success': false, 'message': 'An error occurred: $error'};
    }
  }

  Future<Map<String, dynamic>> getParentSku(
      {int page = 1, int limit = 20, String? name}) async {
    String baseUrl = await Constants.getBaseUrl();
    final url = Uri.parse('$baseUrl/products/');

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
        // print("jajajjhjhj");
        final data = json.decode(response.body);

        // print(${data})
        if (data.containsKey('products') && data['products'] is List) {
          List<Map<String, dynamic>> data =
              parseJsonToList(response.body.toString(), 'products');

          return {'success': true, 'data': data};
        } else {
          print('Unexpected response format: $data');
          return {'success': false, 'message': 'Unexpected response format'};
        }
      } else {
        return {
          'success': false,
          'message':
              'Failed to fetch categories with status code: ${response.statusCode}'
        };
      }
    } catch (error, stackTrace) {
      print('An error occurred while fetching categories: $error');
      print('Stack trace: $stackTrace');
      return {'success': false, 'message': 'An error occurred: $error'};
    }
  }

//multi part request

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
    String baseUrl = await Constants.getBaseUrl();
    final url = Uri.parse('$baseUrl/products/');

    try {
      // Validate and parse numeric fields
      double? parseDouble(String value) {
        return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
      }

      // Validate required numeric fields
      final netWeightNum = parseDouble(netWeight);
      final grossWeightNum = parseDouble(grossWeight);
      final mrpNum = parseDouble(mrp);
      final costNum = parseDouble(cost);

      if (netWeightNum == null ||
          grossWeightNum == null ||
          mrpNum == null ||
          costNum == null) {
        throw Exception(
            'Invalid numeric values provided for weight, mrp, or cost');
      }

      final numericQuantity = int.tryParse(
              outerPackage_quantity.replaceAll(RegExp(r'[^0-9]'), '')) ??
          1;
      // final numericLabelQty =
      //     int.tryParse(label_quantity.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;

      final token = await AuthProvider().getToken();
      final request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        "Content-Type": "multipart/form-data",
        "Authorization": "Bearer $token",
      });

      request.fields['displayName'] = displayName;
      request.fields['parentSku'] = parentSku;
      request.fields['sku'] = sku;
      request.fields['ean'] = ean;
      request.fields['brand'] = brand_id;
      // request.fields['outerPackage_quantity'] = numericQuantity.toString();
      request.fields['description'] = description;
      request.fields['technicalName'] = technicalName;
      // request.fields['label_quantity'] = numericLabelQty.toString();
      request.fields['tax_rule'] = tax_rule;
      request.fields['length'] = length;
      request.fields['width'] = width;
      request.fields['height'] = height;
      request.fields['netWeight'] = netWeightNum.toString();
      request.fields['grossWeight'] = grossWeightNum.toString();
      request.fields['mrp'] = mrpNum.toString();
      request.fields['cost'] = costNum.toString();
      request.fields['active'] = active.toString();
      request.fields['labelSku'] = labelSku;
      request.fields['outerPackage_sku'] = outerPackage_sku;
      request.fields['categoryName'] = categoryName;
      request.fields['grade'] = grade;
      request.fields['shopifyImage'] = shopifyImage;
      request.fields['variant_name'] = variant_name;
      request.fields['itemQty'] = numericQuantity.toString();

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      log('Product creation response: ${response.statusCode} - ${response.body}');
      return response;
    } catch (error, stackTrace) {
      log('Error creating product: $error');
      log('Stack trace: $stackTrace');
      throw Exception('Failed to create product: $error');
    }
  }

  Future tata(File f) async {
    var l = await f.readAsBytes();
    return l;
  }

  List<Map<String, dynamic>> parseJsonToList(String jsonString, String key) {
    // Decode the JSON string
    print("heee;loo i am dipu $jsonString");
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    print("jason data is her $jsonData");
    // Access the array of objects
    final List<dynamic> categories = jsonData[key];

    // Convert the List<dynamic> to List<Map<String, dynamic>>
    return categories.map((item) => item as Map<String, dynamic>).toList();
  }
}
