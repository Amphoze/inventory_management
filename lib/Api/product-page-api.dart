// import 'dart:html' as html;
// import 'dart:js_interop';
import 'dart:convert';
import 'dart:io';
// import 'dart:io';
// import 'dart:typed_data';
import 'package:flutter/material.dart';

// import 'package:http_parser/http_parser.dart';
// import 'package:flutter/services.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:http/http.dart' as http;
// import 'package:path/path.dart' as path;

class ProductPageApi {
  final String _baseUrl =
      'https://inventory-management-backend-s37u.onrender.com';
  Future<Map<String, dynamic>> getAllBrandName(
      {int page = 1, int limit = 20, String? name}) async {
    final url = Uri.parse('$_baseUrl/brand/');

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
    final url = Uri.parse('$_baseUrl/label/');

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
    final url = Uri.parse('$_baseUrl/boxsize/');

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
    final url = Uri.parse('$_baseUrl/color/');

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
    final url = Uri.parse('$_baseUrl/products/');

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

  Future createProduct({
    BuildContext? context,
    required String productName,
    required String parentSku,
    required String sku,
    required String ean,
    required String description,
    required String brandId,
    required String category,
    required String technicalName,
    required String labelSku,
    required String colorId,
    required String taxRule,
    required Map<String, dynamic> dimensions,
    required String weight,
    required String netWeight,
    required String grossWeight,
    required String shopifyImage,
    required String boxName,
    required String mrp,
    required String cost,
    required bool active,
  }) async {
    final url = Uri.parse('$_baseUrl/products/');
    print('''
Product Name: $productName
Parent SKU: $parentSku
SKU: $sku
EAN: $ean
Description: $description
Brand ID: $brandId
Category: $category
Technical Name: $technicalName
Label SKU: $labelSku
Color ID: $colorId
Tax Rule: $taxRule
Dimensions: $dimensions
Weight: $weight
Net Weight: $netWeight
Gross Weight: $grossWeight
Shopify Image: $shopifyImage
Box Name: $boxName
MRP: $mrp
Cost: $cost
Active: $active
''');

    try {
      final token = await AuthProvider().getToken();
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        "Content-Type": "multipart/form-data",
        "Authorization": "Bearer $token",
      });

      // var file =await Provider.of<ProductProvider>(context!,listen:false).images[0];
      // List<int> bytes = await file.readAsBytes();
      //     //  Uint8List.fromList(bytes);
      // print("hjjh");
      // var multipartFile = http.MultipartFile.fromBytes(
      //       'images',
      //      bytes,
      //       filename: 'product_image.jpg',
      //       contentType: MediaType('image', 'jpg'),
      //     );
//   request.files.add(await http.MultipartFile.fromPath(
//   "images",
//   file.path,

// ));

      // request.files.add(multipartFile);
      request.fields['displayName'] = productName;
      request.fields['sku'] = parentSku;
      request.fields['parentSku'] = parentSku;
      request.fields['labelSku'] = labelSku;
      request.fields['ean'] = "123";
      request.fields['description'] = "tet -1";
      request.fields['brand_id'] = brandId;
      request.fields['categoryName'] = category;
      request.fields['technicalName'] = technicalName;
      request.fields['color_id'] = colorId;
      request.fields['tax_rule'] = taxRule;
      request.fields['weight'] = weight.toString();
      request.fields['mrp'] = mrp.toString();
      request.fields['cost'] = cost.toString();
      request.fields['active'] = active.toString();
      request.fields['length'] = dimensions['length'].toString();
      request.fields['breadth'] = dimensions['breadth'].toString();
      request.fields['height'] = dimensions['height'].toString();
      request.fields['box_name'] = boxName;
      request.fields['garde'] = 'A';
      request.fields['netWeight'] = netWeight;
      request.fields['grossWeight'] = grossWeight;
      request.fields['shopifyImage'] = shopifyImage;

// print("divyansh patidadr4544656");
      final response = await request.send();

      final responseBody = await response.stream.bytesToString();
      final Map<String, dynamic> jsonData = json.decode(responseBody);

      jsonData['success'] = true;
      print(
          "Product is created successfully:${response.statusCode}$response $responseBody ---> ${jsonData["success"]}");

      return response;
    } catch (error, stackTrace) {
      print('An error occurred while creating the product: $error');
      print('Stack trace: $stackTrace');
      return {'success': false, 'message': 'An error occurred: $error'};
    }
  }

  Future tata(File f) async {
    var l = await f.readAsBytes();
    return l;
  }

// Future createProduct({
//   required String productName,
//   required String parentSku,
//   required String sku,
//   required String ean,
//   required String description,
//   required String brand,
//   required String category,
//   required String technicalName,
//   required String label,
//   required String color,
//   required String taxRule,
//   required Map<String, dynamic> dimensions,
//   required double weight,
//   required String boxSize,
//   required double mrp,
//   required double cost,
//   required bool active,
// }) async {
//   final url = Uri.parse('$_baseUrl/products/');

//   try {
//     final token = await AuthProvider().getToken();
//      print('Some error is occuredddddddddd');
//     final response = await http.post(
//       url,
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       },

//       body: json.encode({
//         "displayName": productName,
//         "parentSku":sku,
//         "sku":sku,
//         "ean": ean,
//         "description": description,
//         "brand": brand,
//         "category": category,
//         "technicalName": technicalName,
//         "label": label,
//         "color": color,
//         "tax_rule": taxRule,
//         "dimensions": dimensions,
//         "weight": weight,
//         "boxSize": boxSize,
//         "Mrp": mrp,
//         "Cost": cost,
//         "active": active,
//       }),
//     );
//     final Map<String, dynamic> jsonData = json.decode(response.body);
//     jsonData['success']=true;
//     // if(response.body=="1 product(s) created successfully"){
//       print("product is created succesfully${response.body} ---> ${jsonData["success"]}");
//     // }
//  return jsonData;

//     // return

//   } catch (error, stackTrace) {
//     print('An error occurred while fetching categories: $error');
//     print('Stack trace: $stackTrace');
//     return {'success': false, 'message': 'An error occurred: $error'};
//   }
// }

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
