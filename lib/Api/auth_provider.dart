import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  final String _baseUrl =
      'https://inventory-management-backend-s37u.onrender.com';

  bool get isAuthenticated => _isAuthenticated;
  Future<Map<String, dynamic>> register(String email, String password) async {
    final url = Uri.parse('$_baseUrl/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        await _saveCredentials(email, password);
        return {'success': true, 'data': json.decode(response.body)};
      } else if (response.statusCode == 400) {
        final errorResponse = json.decode(response.body);
        if (errorResponse['error'] == 'Email already exists') {
          return {
            'success': false,
            'message':
                'This email is already registered. Please use a different email or log in.'
          };
        }
        return {'success': false, 'message': 'Registration failed'};
      } else {
        return {
          'success': false,
          'message':
              'Registration failed with status code: ${response.statusCode}'
        };
      }
    } catch (error) {
      print('An error occurred during registration: $error');
      return {'success': false, 'message': 'An error occurred'};
    }
  }

  Future<Map<String, dynamic>> registerOtp(
      String email, String otp, String password) async {
    final url = Uri.parse('$_baseUrl/register-otp');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otp': otp,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        print(
            'OTP verification failed with status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return {'success': false, 'message': 'OTP verification failed'};
      }
    } catch (error) {
      print('An error occurred during OTP verification: $error');
      return {'success': false, 'message': 'An error occurred'};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Login Response: ${response.statusCode}');
      print('Login Response Body: ${response.body}');
      print('Response Headers: ${response.headers}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Parsed Response Data: $responseData');

        // Directly extract the token from the response body
        final token = responseData['token'];

        if (token != null && token.isNotEmpty) {
          await _saveToken(token);
          print('Token retrieved and saved: $token');
          await _saveCredentials(email, password);
          return {'success': true, 'data': responseData};
        } else {
          print('Token not retrieved');
          return {'success': false, 'data': responseData};
        }
      } else if (response.statusCode == 400) {
        final errorResponse = json.decode(response.body);
        return {'success': false, 'message': errorResponse['error']};
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'User does not exist'};
      } else {
        return {
          'success': false,
          'message': 'Login failed with status code: ${response.statusCode}'
        };
      }
    } catch (error) {
      print('An error occurred during login: $error');
      return {'success': false, 'message': 'An error occurred'};
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
    await prefs.setString(
        'date', DateFormat('dd-MMMM-yyyy').format(DateTime.now()));
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final url = Uri.parse('$_baseUrl/forgot-password');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      print('Forgot Password Response: ${response.statusCode}');
      print('Forgot Password Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'OTP sent to email'};
      } else if (response.statusCode == 400) {
        final errorResponse = json.decode(response.body);
        return {'success': false, 'message': errorResponse['error']};
      } else {
        return {
          'success': false,
          'message':
              'Forgot password request failed with status code: ${response.statusCode}'
        };
      }
    } catch (error) {
      print('An error occurred during forgot password request: $error');
      return {'success': false, 'message': 'An error occurred'};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final url = Uri.parse('$_baseUrl/verify-otp');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'otp': otp}),
      );

      print('Verify OTP Response: ${response.statusCode}');
      print('Verify OTP Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'OTP verified successfully'};
      } else {
        final errorResponse = json.decode(response.body);
        return {'success': false, 'message': errorResponse['error']};
      }
    } catch (error) {
      print('An error occurred during OTP verification: $error');
      return {'success': false, 'message': 'An error occurred'};
    }
  }

  Future<Map<String, dynamic>> resetPassword(
      String email, String newPassword) async {
    final url = Uri.parse('$_baseUrl/reset-password');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'newPassword': newPassword,
        }),
      );

      print('Reset Password Response: ${response.statusCode}');
      print('Reset Password Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Password reset successfully'};
      } else if (response.statusCode == 400) {
        final errorResponse = json.decode(response.body);
        return {'success': false, 'message': errorResponse['error']};
      } else {
        return {
          'success': false,
          'message':
              'Password reset failed with status code: ${response.statusCode}'
        };
      }
    } catch (error) {
      print('An error occurred during password reset: $error');
      return {'success': false, 'message': 'An error occurred'};
    }
  }

  Future<Map<String, dynamic>> getAllCategories(
      {int page = 1, int limit = 70, String? name}) async {
    final url = Uri.parse('$_baseUrl/category/?page=$page&limit=$limit');

    try {
      final token = await getToken();
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get All Categories Response: ${response.statusCode}');
      print('Get All Categories Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('categories') && data['categories'] is List) {
          List categories = data['categories'];

          // If a name is provided, filter the categories by the name
          if (name != null && name.isNotEmpty) {
            categories = categories
                .where((category) =>
                    category['name'].toString().toLowerCase() ==
                    name.toLowerCase())
                .toList();

            if (categories.isEmpty) {
              return {
                'success': false,
                'message': 'Category with name "$name" not found'
              };
            }
          }

          return {'success': true, 'data': categories};
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

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getString('authToken') != null &&
        prefs.getString('date') ==
            DateFormat('dd-MMMM-yyyy').format(DateTime.now());
    // notifyListeners();
    return prefs.getString('authToken');
  }

  Future<Map<String, dynamic>> createCategory(String name) async {
    final url = Uri.parse('$_baseUrl/category/');

    try {
      final token = await getToken();

      if (token == null) {
        return {'success': false, 'message': 'No token provided'};
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Include token in headers
        },
        body: json.encode({
          'name': name,
        }),
      );

      // print('Create Category Response: ${response.statusCode}');
      // print('Create Category Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': json.decode(response.body)};
      } else if (response.statusCode == 400) {
        final errorResponse = json.decode(response.body);
        return {
          'success': false,
          'message': errorResponse['error'] ?? 'Failed to create category'
        };
      } else {
        return {
          'success': false,
          'message':
              'Create category failed with status code: ${response.statusCode}'
        };
      }
    } catch (error, stackTrace) {
      print('An error occurred while creating the category: $error');
      print('Stack trace: $stackTrace');
      return {'success': false, 'message': 'An error occurred: $error'};
    }
  }

  Future<Map<String, dynamic>> getCategoryById(String id) async {
    final url = Uri.parse('$_baseUrl/category/$id');

    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get Category By ID Response: ${response.statusCode}');
      print('Get Category By ID Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        print('Failed to load category. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return {'success': false, 'message': 'Failed to load category'};
      }
    } catch (error) {
      print('Error fetching category by ID: $error');
      return {'success': false, 'message': 'Error fetching category by ID'};
    }
  }

  Future<Map<String, dynamic>> getAllProducts(
      {int page = 1, int itemsPerPage = 10}) async {
    // Append query parameters for pagination (page number and items per page)
    final url = Uri.parse('$_baseUrl/products?page=$page&limit=$itemsPerPage');

    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get All Products Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['products'];

        // Extract required fields and log them
        final products = data.map((product) {
          final extractedProduct = {
            'id': product['_id'] ?? '-',
            'displayName': product['displayName'] ?? '-',
            'parentSku': product['parentSku'] ?? '-',
            'sku': product['sku'] ?? '-',
            'netWeight': product['netWeight']?.toString() ?? '-',
            'grossWeight': product['grossWeight']?.toString() ?? '-',
            'ean': product['ean'] ?? '-',
            'description': product['description'] ?? '-',
            'technicalName': product['technicalName'] ?? '-',
            'labelSku': product['label']?['labelSku'] ?? '-',
            'box_name': product['boxSize']?['box_name'] ?? '-',
            'categoryName': product['category']?['name'] ?? '-',
            'length': product['dimensions']?['length']?.toString() ?? '-',
            'width': product['dimensions']?['width']?.toString() ?? '-',
            'height': product['dimensions']?['height']?.toString() ?? '-',
            'tax_rule': product['tax_rule'] ?? '-',
            //'weight': product['weight'] ?? '-',
            'mrp': product['mrp']?.toString() ?? '-',
            'cost': product['cost']?.toString() ?? '-',
            'grade': product['grade'] ?? '-',
            'shopifyImage': product['shopifyImage'] ?? '-',
            'createdAt': product['createdAt'] ?? '-',
            'updatedAt': product['updatedAt'] ?? '-',
          };

          // Print each product's required fields
          //print('Product Details: $extractedProduct');
          //print('------------------------------------------------');
          return extractedProduct;
        }).toList();

        return {'success': true, 'data': products};
      } else {
        return {
          'success': false,
          'message':
              'Failed to load products. Status code: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('Error fetching products: $error');
      return {'success': false, 'message': 'Error fetching products'};
    }
  }

  Future<Map<String, dynamic>> getAllWarehouses() async {
    final url = Uri.parse('$_baseUrl/warehouse');

    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Include token in headers
        },
      );

      print('Get All Warehouses Response: ${response.statusCode}');
      print('Get All Warehouses Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data =
            json.decode(response.body)['data']['warehouses'] as List<dynamic>;

        // Extract the required fields for each warehouse
        final warehouses = data.map((warehouse) {
          final pincodeList = warehouse['pincode'] as List<dynamic>? ?? [];
          return {
            'name': warehouse['name'] ?? '-',
            '_id': warehouse['_id'] ?? '-',
            'location': warehouse['location'] ?? '-',
            'warehousePincode': warehouse['warehousePincode'] ?? '-',
            'pincode': pincodeList.isNotEmpty ? pincodeList.join(', ') : '-',
            'createdAt': warehouse['createdAt'] ?? '-',
            'updatedAt': warehouse['updatedAt'] ?? '-',
          };
        }).toList();

        // Print the data for debugging
        for (var warehouse in warehouses) {
          print('--- Warehouse ---');
          print('Name: ${warehouse['name']}');
          print('ID: ${warehouse['_id']}');
          print('Location: ${warehouse['location']}');
          print('Warehouse Pincode: ${warehouse['warehousePincode']}');
          print('Pincode List: ${warehouse['pincode']}');
          print('Created At: ${warehouse['createdAt']}');
          print('Updated At: ${warehouse['updatedAt']}');
          print('------------------');
        }

        return {
          'success': true,
          'data': {'warehouses': warehouses}
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to load warehouses. Status code: ${response.statusCode}'
        };
      }
    } catch (error) {
      print('Error fetching warehouses: $error');
      return {'success': false, 'message': 'Error fetching warehouses'};
    }
  }

  Future<Map<String, dynamic>> createWarehouse({
    required String name,
    required String email,
    required int taxIdentificationNumber,
    required String billingAddressLine1,
    required String billingAddressLine2,
    required String billingCountry,
    required String billingState,
    required String billingCity,
    required int billingZipCode,
    required int billingPhoneNumber,
    required String shippingAddressLine1,
    required String shippingAddressLine2,
    required String shippingCountry,
    required String shippingState,
    required String shippingCity,
    required int shippingZipCode,
    required int shippingPhoneNumber,
    required String locationType,
    required bool holdStocks,
    required bool copyMasterSkuFromPrimary,
    required List<String> pincodes,
    required int warehousePincode,
  }) async {
    final url = Uri.parse('$_baseUrl/warehouse');
    final body = {
      "location": {
        "otherDetails": {
          "taxIdentificationNumber": taxIdentificationNumber,
        },
        "billingAddress": {
          "addressLine1": billingAddressLine1,
          "addressLine2": billingAddressLine2,
          "country": billingCountry,
          "state": billingState,
          "city": billingCity,
          "zipCode": billingZipCode,
          "phoneNumber": billingPhoneNumber,
        },
        "shippingAddress": {
          "addressLine1": shippingAddressLine1,
          "addressLine2": shippingAddressLine2,
          "country": shippingCountry,
          "state": shippingState,
          "city": shippingCity,
          "zipCode": shippingZipCode,
          "phoneNumber": shippingPhoneNumber,
        },
        "locationType": locationType,
        "holdStocks": holdStocks,
        "copyMasterSkuFromPrimary": copyMasterSkuFromPrimary,
      },
      "name": name,
      "pincode": pincodes,
      "warehousePincode": warehousePincode,
    };

    try {
      final token = await getToken();
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create warehouse: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred while creating warehouse: $e');
      throw Exception('Error creating warehouse: $e');
    }
  }

  // Method to fetch warehouse data using the warehouse ID
  Future<Map<String, dynamic>> fetchWarehouseById(String warehouseId) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/warehouse/$warehouseId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load warehouse data');
      }
    } catch (error) {
      print('Error fetching warehouse data: $error');
      throw error;
    }
  }

  Future<void> _saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('password', password);
  }

  Future<Map<String, String?>> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    final password = prefs.getString('password');
    return {
      'email': email,
      'password': password,
    };
  }

  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('password');
    await prefs.remove('authToken'); // Clear the token
  }

  Future<Map<String, dynamic>> searchCategoryByName(String name) async {
    final url =
        Uri.parse('$_baseUrl/category?name=${Uri.encodeComponent(name)}');

    try {
      final token = await getToken();
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}'); // Debugging line
      print('Response body: ${response.body}'); // Debugging line

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['categories'] is List) {
          return {
            'success': true,
            'data': data['categories'],
          };
        } else {
          print('Unexpected response format: ${data}'); // Debugging line
          return {'success': false, 'message': 'Unexpected response format'};
        }
      } else {
        return {
          'success': false,
          'message':
              'Failed to search categories with status code: ${response.statusCode}'
        };
      }
    } catch (error) {
      print('Error: $error'); // Debugging line
      return {'success': false, 'message': 'An error occurred'};
    }
  }

  Future<Map<String, dynamic>?> createProduct(
      List<Map<String, dynamic>> productData) async {
    final url = Uri.parse('$_baseUrl/products/');
    try {
      final token = await getToken();
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'products': productData}),
      );

      // Print the full response for debugging purposes
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print(
            'Response Data: ${jsonEncode(responseData)}'); // Print structured response

        return {
          'message':
              responseData['message'] ?? 'Products uploaded successfully.',
          'successfulProducts': responseData['successfulProducts'],
          'failedProducts': responseData['failedProducts'],
        };
      } else {
        final errorResponse = json.decode(response.body);
        String errorMessage;

        if (response.statusCode == 400) {
          errorMessage = 'Validation error: ${errorResponse['message']}';
        } else if (response.statusCode == 401) {
          errorMessage = 'Authorization failed. Please check your credentials.';
        } else {
          errorMessage =
              'Failed to create product. Status code: ${response.statusCode} - ${errorResponse['message'] ?? 'Unknown error'}';
        }

        print(
            'Error Response: ${jsonEncode(errorResponse)}'); // Print structured error response

        return {
          'message': errorMessage,
          'successfulProducts': [],
          'failedProducts': [],
        };
      }
    } catch (e) {
      print('Error occurred while creating product: $e');
      return {
        'message': 'An unexpected error occurred: $e',
        'successfulProducts': [],
        'failedProducts': [],
      };
    }
  }

  Future<String?> createLabel(Map<String, dynamic> labelData) async {
    final url = Uri.parse('$_baseUrl/label/');
    try {
      final token = await getToken();
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(labelData),
      );

      if (response.statusCode == 201) {
        return 'Label created successfully!';
      } else {
        return 'Failed to create label: ${response.statusCode}\n${response.body}';
      }
    } catch (e) {
      print('Error occurred while creating label: $e');
      return 'Error occurred while creating label: $e';
    }
  }

  Future<bool> deleteWarehouse(String warehouseId) async {
    final String url = "$_baseUrl/warehouse/$warehouseId";

    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print("-----------------------");
        print("Error deleting warehouse: ${response.statusCode}");
        print("Warehouse with ID $warehouseId deleted successfully.");
        print("-----------------------");
        return true;
      } else {
        print("-----------------------");
        print("Error deleting warehouse: ${response.statusCode}");
        print("Response body: ${response.body}");
        print("-----------------------");
        return false;
      }
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>> searchProductsByDisplayName(
      String displayName) async {
    final url =
        '$_baseUrl/products?displayName=${Uri.encodeComponent(displayName)}';

    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      // Make the HTTP GET request
      final response = await http.get(
        Uri.parse(url), // Ensure URL is parsed
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Check the response status code
      if (response.statusCode == 200) {
        print("Response Status: ${response.statusCode}");
        print("Response Body: ${response.body}");

        // Return the whole response as a Map
        return {
          'success': true,
          'products': json.decode(response.body)['products'],
          'totalProducts': json.decode(response.body)['totalProducts'],
          'totalPages': json.decode(response.body)['totalPages'],
          'currentPage': json.decode(response.body)['currentPage'],
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to load products, status code: ${response.statusCode}',
        };
      }
    } catch (error) {
      // Handle exceptions (network errors, JSON parsing errors, etc.)
      return {
        'success': false,
        'message': 'An error occurred: $error',
      };
    }
  }

  Future<Map<String, dynamic>> searchProductsBySKU(String sku) async {
    final url = '$_baseUrl/products?sku=${Uri.encodeComponent(sku)}';

    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      // Make the HTTP GET request
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Check the response status code
      if (response.statusCode == 200) {
        //print("Response Status: ${response.statusCode}");
        //print("Response Body: ${response.body}");

        // Correctly parsing the 'products' key from the response
        final data = json.decode(response.body);

        if (data != null && data['products'] != null) {
          return {'success': true, 'data': data['products']};
        } else {
          return {
            'success': false,
            'message': 'No products found',
          };
        }
      } else {
        return {
          'success': false,
          'message':
              'Failed to load products, status code: ${response.statusCode}',
        };
      }
    } catch (error) {
      // Handle exceptions (network errors, JSON parsing errors, etc.)
      return {
        'success': false,
        'message': 'An error occurred: $error',
      };
    }
  }

//get all brand name
//  Future<Map<String, dynamic>> getAllBrandName(
//       {int page = 1, int limit = 20, String? name}) async {
//     final url = Uri.parse('$_baseUrl/brand/');

//     try {
//       final token = await getToken();
//       final response = await http.get(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );

//       print('Get All brand Response: ${response.statusCode}');
//       print('Get All brand  Response Body: ${response.body}');

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data.containsKey('brands') && data['brands'] is List) {

//           print("i am dipu");
//           List brand;

//               brand=parseJsonToList(response.body.toString(),'brands');
//           // }
//           // print("i am dipu us here wiht success");
//           return {'success': true, 'data': brand};
//         } else {
//           print('Unexpected response format: $data');
//           return {'success': false, 'message': 'Unexpected response format'};
//         }
//       } else {
//         return {
//           'success': false,
//           'message':
//               'Failed to fetch categories with status code: ${response.statusCode}'
//         };
//       }
//     } catch (error, stackTrace) {
//       print('An error occurred while fetching categories: $error');
//       print('Stack trace: $stackTrace');
//       return {'success': false, 'message': 'An error occurred: $error'};
//     }
//   }

// List<Map<String, dynamic>> parseJsonToList(String jsonString,String key) {
//   // Decode the JSON string
//   final Map<String, dynamic> jsonData = json.decode(jsonString);

//   // Access the array of objects
//   final List<dynamic> categories = jsonData[key];

//   // Convert the List<dynamic> to List<Map<String, dynamic>>
//   return categories.map((item) => item as Map<String, dynamic>).toList();
// }
}
