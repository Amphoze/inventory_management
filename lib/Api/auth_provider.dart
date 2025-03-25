import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:inventory_management/constants/constants.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isSuperAdminAssigned = false;
  bool _isAdminAssigned = false;
  bool _isConfirmerAssigned = false;
  bool _isBookerAssigned = false;
  bool _isAccountsAssigned = false;
  bool _isPickerAssigned = false;
  bool _isPackerAssigned = false;
  bool _isCheckerAssigned = false;
  bool _isRackerAssigned = false;
  bool _isManifestAssigned = false;
  bool _isOutboundAssigned = false;
  bool _isSupportAssigned = false;
  bool _isCreateOrderAssigned = false;
  bool _isGGVAssigned = false;

  bool get isSuperAdminAssigned => _isSuperAdminAssigned;
  bool get isAdminAssigned => _isAdminAssigned;
  bool get isConfirmerAssigned => _isConfirmerAssigned;
  bool get isBookerAssigned => _isBookerAssigned;
  bool get isAccountsAssigned => _isAccountsAssigned;
  bool get isPickerAssigned => _isPickerAssigned;
  bool get isPackerAssigned => _isPackerAssigned;
  bool get isCheckerAssigned => _isCheckerAssigned;
  bool get isRackerAssigned => _isRackerAssigned;
  bool get isManifestAssigned => _isManifestAssigned;
  bool get isOutboundAssigned => _isOutboundAssigned;
  bool get isSupportAssigned => _isSupportAssigned;
  bool get isCreateOrderAssigned => _isCreateOrderAssigned;
  bool get isGGVAssigned => _isGGVAssigned;

  String? assignedRole;

  bool get isAuthenticated => _isAuthenticated;

  final Set<String> importantRoles = {'superAdmin', 'admin', 'confirmer', 'accounts', 'booker', 'support'};

  String? userPrimaryRole;

  void resetRoles() {
    _isSuperAdminAssigned = false;
    _isAdminAssigned = false;
    _isPickerAssigned = false;
    _isPackerAssigned = false;
    _isCheckerAssigned = false;
    _isRackerAssigned = false;
    _isManifestAssigned = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> register(String email, String password, List<Map<String, dynamic>> assignedRoles) async {
    String baseUrl = await Constants.getBaseUrl();

    final url = Uri.parse('$baseUrl/register');

    log(assignedRoles.toString());
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'userRoles': assignedRoles,
        }),
      );

      log({
        'email': email,
        'password': password,
        'userRoles': assignedRoles,
      }.toString());

      if (response.statusCode == 200) {
        // await _saveCredentials(email, password, '');
        return {'success': true, 'data': json.decode(response.body)};
      } else if (response.statusCode == 400) {
        final errorResponse = json.decode(response.body);
        if (errorResponse['error'] == 'Email already exists') {
          return {'success': false, 'message': 'This email is already registered. Please use a different email or log in.'};
        }
        return {'success': false, 'message': 'Registration failed'};
      } else {
        return {'success': false, 'message': 'Registration failed with status code: ${response.statusCode}'};
      }
    } catch (error) {
      print('An error occurred during registration: $error');
      return {'success': false, 'message': 'An error occurred'};
    }
  }

  Future<Map<String, dynamic>> registerOtp(String email, String otp, String password) async {
    String baseUrl = await Constants.getBaseUrl();

    final url = Uri.parse('$baseUrl/register-otp');

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
        print('OTP verification failed with status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return {'success': false, 'message': 'OTP verification failed'};
      }
    } catch (error) {
      print('An error occurred during OTP verification: $error');
      return {'success': false, 'message': 'An error occurred'};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    String baseUrl = await Constants.getBaseUrl();

    final url = Uri.parse('$baseUrl/login');

    Logger().e('login url: $url');

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
        final token = responseData['token'] ?? '';

        Logger().e('token hai: $token');

        // Fetch user roles from responseData
        final List<dynamic> userRoles = responseData['userRoles'];
        for (var role in userRoles) {
          if (role['isAssigned'] == true) {
            if (userPrimaryRole == null && importantRoles.contains(role['roleName'])) {
              userPrimaryRole = role['roleName'];
            }

            assignedRole = role['roleName'];
            switch (assignedRole) {
              case 'superAdmin':
                _isSuperAdminAssigned = true;
                log('isSuperAdmin: $_isSuperAdminAssigned');
                break;
              case 'admin':
                _isAdminAssigned = true;
                log('isAdmin: $_isAdminAssigned');
                break;
              case 'confirmer':
                _isConfirmerAssigned = true;
                log('isConfirmer: $_isConfirmerAssigned');
                break;
              case 'booker':
                _isBookerAssigned = true;
                log('isBooker: $_isBookerAssigned');
                break;
              case 'account':
                _isAccountsAssigned = true;
                log('isAccounts: $_isAccountsAssigned');
                break;
              case 'picker':
                _isPickerAssigned = true;
                log('isPicker: $_isPickerAssigned');
                break;
              case 'packer':
                _isPackerAssigned = true;
                log('isPacker: $_isPackerAssigned');
                break;
              case 'checker':
                _isCheckerAssigned = true;
                log('isChecker: $_isCheckerAssigned');
                break;
              case 'racker':
                _isRackerAssigned = true;
                log('isRacker: $_isRackerAssigned');
                break;
              case 'manifest':
                _isManifestAssigned = true;
                log('isManifest: $_isManifestAssigned');
                break;
              case 'outbound':
                _isOutboundAssigned = true;
                log('isOutbound: $_isOutboundAssigned');
                break;
              case 'support':
                _isSupportAssigned = true;
                log('isSupport: $_isSupportAssigned');
                break;
              case 'createOrder':
                _isCreateOrderAssigned = true;
                log('isCreateOrder: $_isCreateOrderAssigned');
                break;
              case 'ggv':
                _isGGVAssigned = true;
                log('isGGV: $_isGGVAssigned');
                break;
            }
          }
        }

        // for (var role in userRoles) {
        //   if (role['isAssigned'] == true && importantRoles.contains(role['roleName'])) {
        //     userPrimaryRole = role['roleName'];
        //     break; // Stop at the first assigned role found
        //   }
        // }

        Logger().d('userName: ${responseData['userName']}');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('_isSuperAdminAssigned', _isSuperAdminAssigned);
        await prefs.setBool('_isAdminAssigned', _isAdminAssigned);
        await prefs.setBool('_isConfirmerAssigned', _isConfirmerAssigned);
        await prefs.setBool('_isBookerAssigned', _isBookerAssigned);
        await prefs.setBool('_isAccountsAssigned', _isAccountsAssigned);
        await prefs.setBool('_isPickerAssigned', _isPickerAssigned);
        await prefs.setBool('_isPackerAssigned', _isPackerAssigned);
        await prefs.setBool('_isCheckerAssigned', _isCheckerAssigned);
        await prefs.setBool('_isRackerAssigned', _isRackerAssigned);
        await prefs.setBool('_isManifestAssigned', _isManifestAssigned);
        await prefs.setBool('_isOutboundAssigned', _isOutboundAssigned);
        await prefs.setBool('_isSupportAssigned', _isSupportAssigned);
        await prefs.setBool('_isCreateOrderAssigned', _isCreateOrderAssigned);
        await prefs.setBool('_isGGVAssigned', _isGGVAssigned);
        await prefs.setString('userPrimaryRole', userPrimaryRole ?? 'none');
        await prefs.setString('userName', responseData['userName'] ?? '');

        // log('Assigned Role: $assignedRole'); // Debugging line

        if (token != null && token.isNotEmpty) {
          await _saveToken(token);
          print('Token retrieved and saved: $token');
          await _saveCredentials(email, password);

          // log("responseData: $responseData"); ////////////////////////

          return {
            'success': true,
            'data': responseData,
            'role': assignedRole,
          };
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
        return {'success': false, 'message': 'Login failed with status code: ${response.statusCode}'};
      }
    } catch (error) {
      print('An error occurred during login: $error');
      return {'success': false, 'message': 'An error occurred'};
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
    await prefs.setString('date', DateFormat('dd-MMMM-yyyy').format(DateTime.now()));
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    String baseUrl = await Constants.getBaseUrl();

    final url = Uri.parse('$baseUrl/forgot-password');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      log('Forgot Password Response: ${response.statusCode}');
      log('Forgot Password Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'OTP sent to email'};
      } else if (response.statusCode == 400) {
        final errorResponse = json.decode(response.body);
        return {'success': false, 'message': errorResponse['error']};
      } else {
        return {'success': false, 'message': 'Forgot password request failed with status code: ${response.statusCode}'};
      }
    } catch (error) {
      print('An error occurred during forgot password request: $error');
      return {'success': false, 'message': 'An error occurred'};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    String baseUrl = await Constants.getBaseUrl();

    final url = Uri.parse('$baseUrl/verify-otp');

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

  Future<Map<String, dynamic>> resetPassword(String email, String newPassword) async {
    String baseUrl = await Constants.getBaseUrl();

    final url = Uri.parse('$baseUrl/reset-password');

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
        return {'success': false, 'message': 'Password reset failed with status code: ${response.statusCode}'};
      }
    } catch (error) {
      print('An error occurred during password reset: $error');
      return {'success': false, 'message': 'An error occurred'};
    }
  }

  Future<Map<String, dynamic>> getAllCategories({int page = 1, int limit = 70, String? name}) async {
    String baseUrl = await Constants.getBaseUrl();

    final url = Uri.parse('$baseUrl/category/?page=$page&limit=$limit');

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
            categories = categories.where((category) => category['name'].toString().toLowerCase() == name.toLowerCase()).toList();

            if (categories.isEmpty) {
              return {'success': false, 'message': 'Category with name "$name" not found'};
            }
          }

          return {'success': true, 'data': categories};
        } else {
          print('Unexpected response format: $data');
          return {'success': false, 'message': 'Unexpected response format'};
        }
      } else {
        return {'success': false, 'message': 'Failed to fetch categories with status code: ${response.statusCode}'};
      }
    } catch (error, stackTrace) {
      print('An error occurred while fetching categories: $error');
      print('Stack trace: $stackTrace');
      return {'success': false, 'message': 'An error occurred: $error'};
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getString('authToken') != null && prefs.getString('date') == DateFormat('dd-MMMM-yyyy').format(DateTime.now());
    // notifyListeners();
    return prefs.getString('authToken');
  }

  Future<String?> getWarehouseId() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getString('authToken') != null && prefs.getString('date') == DateFormat('dd-MMMM-yyyy').format(DateTime.now());
    // notifyListeners();
    return prefs.getString('warehouseId');
  }

  Future<String?> getWarehouseName() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getString('authToken') != null && prefs.getString('date') == DateFormat('dd-MMMM-yyyy').format(DateTime.now());
    // notifyListeners();
    return prefs.getString('warehouseName');
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getString('authToken') != null && prefs.getString('date') == DateFormat('dd-MMMM-yyyy').format(DateTime.now());
    // notifyListeners();
    return prefs.getString('email');
  }

  Future<Map<String, dynamic>> createCategory(String name) async {
    String baseUrl = await Constants.getBaseUrl();

    final url = Uri.parse('$baseUrl/category/');

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
        return {'success': false, 'message': errorResponse['error'] ?? 'Failed to create category'};
      } else {
        return {'success': false, 'message': 'Create category failed with status code: ${response.statusCode}'};
      }
    } catch (error, stackTrace) {
      print('An error occurred while creating the category: $error');
      print('Stack trace: $stackTrace');
      return {'success': false, 'message': 'An error occurred: $error'};
    }
  }

  Future<Map<String, dynamic>> getCategoryById(String id) async {
    String baseUrl = await Constants.getBaseUrl();

    final url = Uri.parse('$baseUrl/category/$id');

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

  Future<Map<String, dynamic>> getAllProducts({int page = 1, int itemsPerPage = 10}) async {
    String baseUrl = await Constants.getBaseUrl();

    final url = Uri.parse('$baseUrl/products?page=$page&limit=$itemsPerPage');

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
        final Map<String, dynamic> res = json.decode(response.body);
        final List<dynamic> data = json.decode(response.body)['products'];

        // Extract required fields and log them
        final products = data.map((product) {
          final extractedProduct = {
            'id': product['_id'] ?? '',
            'displayName': product['displayName'] ?? '',
            'parentSku': product['parentSku'] ?? '',
            'sku': product['sku'] ?? '',
            'description': product['description'] ?? '',
            'brand': product['brand']?['name'] ?? '',
            'categoryName': product['category']?['name'] ?? '',
            'netWeight': product['netWeight']?.toString() ?? '',
            'grossWeight': product['grossWeight']?.toString() ?? '',
            'ean': product['ean'] ?? '',
            'technicalName': product['technicalName'] ?? '',
            'labelSku': product['label']?['labelSku'] ?? '',
            'colour': product['color']?['name'] ?? '',
            'outerPackage_quantity': product['outerPackage_quantity']?.toString() ?? '',
            'outerPackage_name': product['outerPackage']?['outerPackage_name'] ?? '',
            'length': product['dimensions']?['length']?.toString() ?? '',
            'width': product['dimensions']?['width']?.toString() ?? '',
            'height': product['dimensions']?['height']?.toString() ?? '',
            'tax_rule': product['tax_rule'] ?? '',
            //'weight': product['weight'] ?? '-',
            'mrp': product['mrp']?.toString() ?? '',
            'cost': product['cost']?.toString() ?? '',
            'grade': product['grade'] ?? '',
            'shopifyImage': product['shopifyImage'] ?? '',
            'createdAt': product['createdAt'] ?? '',
            'updatedAt': product['updatedAt'] ?? '',
          };

          // Print each product's required fields
          //print('Product Details: $extractedProduct');
          //print('------------------------------------------------');
          return extractedProduct;
        }).toList();

        return {'success': true, 'data': products, 'totalProducts': res['totalProducts']};
      } else {
        return {
          'success': false,
          'message': 'Failed to load products. Status code: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('Error fetching products: $error');
      return {'success': false, 'message': 'Error fetching products'};
    }
  }

  Future<Map<String, dynamic>> fetchCategoryProducts(String categoryName, {int page = 1}) async {
    String baseUrl = await Constants.getBaseUrl();
    final String url = '$baseUrl/category/products/$categoryName?page=$page';

    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}'); // Debugging line
      // print('Response body: ${response.body}'); // Debugging line

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        final data = res['products'] as List;

        return {
          'success': true,
          'products': data,
          'totalProducts': res['totalProducts'],
          'currentPage': res['currentPage'],
          'totalPages': res['totalPages'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch products, status code: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('Error fetching products for category: $categoryName, Error: $error');

      return {'success': false, 'message': 'Error fetching products'};
    }
  }

  Future<Map<String, dynamic>> getAllWarehouses({int page = 1}) async {
    String baseUrl = await Constants.getBaseUrl();
    final url = Uri.parse('$baseUrl/warehouse?page=$page');

    // Logger().e('getAllWarehouses url: $url');

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

      // print('Get All Warehouses Response: ${response.statusCode}');
      // print('Get All Warehouses Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        final data = res['data']['warehouses'] as List<dynamic>;

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
        // for (var warehouse in warehouses) {
        //   print('--- Warehouse ---');
        //   print('Name: ${warehouse['name']}');
        //   print('ID: ${warehouse['_id']}');
        //   print('Location: ${warehouse['location']}');
        //   print('Warehouse Pincode: ${warehouse['warehousePincode']}');
        //   print('Pincode List: ${warehouse['pincode']}');
        //   print('Created At: ${warehouse['createdAt']}');
        //   print('Updated on: ${warehouse['updatedAt']}');
        //   print('------------------');
        // }

        return {
          'success': true,
          'data': {'warehouses': warehouses},
          'totalPages': res['data']['totalPages'],
        };
      } else {
        return {'success': false, 'message': 'Failed to load warehouses. Status code: ${response.statusCode}'};
      }
    } catch (error) {
      log('Error fetching warehouses: $error');
      return {'success': false, 'message': 'Error fetching warehouses'};
    }
  }

  Future<Map<String, dynamic>> createWarehouse({
    required Map<String, dynamic>? warehouseData,
    // required String name,
    // required String email,
    // required int taxIdentificationNumber,
    // required String billingAddressLine1,
    // required String billingAddressLine2,
    // required String billingCountry,
    // required String billingState,
    // required String billingCity,
    // required int billingZipCode,
    // required int billingPhoneNumber,
    // required String shippingAddressLine1,
    // required String shippingAddressLine2,
    // required String shippingCountry,
    // required String shippingState,
    // required String shippingCity,
    // required int shippingZipCode,
    // required int shippingPhoneNumber,
    // required String locationType,
    // required bool holdStocks,
    // required bool copyMasterSkuFromPrimary,
    // required List<String> pincodes,
    // required int warehousePincode,
  }) async {
    String baseUrl = await Constants.getBaseUrl();
    final url = Uri.parse('$baseUrl/warehouse');
    // final body = {
    //   "location": {
    //     "otherDetails": {
    //       "taxIdentificationNumber": taxIdentificationNumber,
    //     },
    //     "billingAddress": {
    //       "addressLine1": billingAddressLine1,
    //       "addressLine2": billingAddressLine2,
    //       "country": billingCountry,
    //       "state": billingState,
    //       "city": billingCity,
    //       "zipCode": billingZipCode,
    //       "phoneNumber": billingPhoneNumber,
    //     },
    //     "shippingAddress": {
    //       "addressLine1": shippingAddressLine1,
    //       "addressLine2": shippingAddressLine2,
    //       "country": shippingCountry,
    //       "state": shippingState,
    //       "city": shippingCity,
    //       "zipCode": shippingZipCode,
    //       "phoneNumber": shippingPhoneNumber,
    //     },
    //     "locationType": locationType,
    //     "holdStocks": holdStocks,
    //     "copyMasterSkuFromPrimary": copyMasterSkuFromPrimary,
    //   },
    //   "name": name,
    //   "pincode": pincodes,
    //   "warehousePincode": warehousePincode,
    // };

    // final body = {
    //   "name": name,
    //   "pinCodes": pincodes,
    //   "isPrimary": isPrimary,
    // };

    try {
      final token = await getToken();
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(warehouseData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create warehouse: ${response.statusCode}');
      }
    } catch (e) {
      log('Error occurred while creating warehouse: $e');
      throw Exception('Error creating warehouse: $e');
    }
  }

  // Method to fetch warehouse data using the warehouse ID
  Future<Map<String, dynamic>> fetchWarehouseById(String warehouseId) async {
    String baseUrl = await Constants.getBaseUrl();

    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/warehouse/$warehouseId'),
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
      rethrow;
    }
  }

  Future<void> _saveCredentials(
    String email,
    String password,
  ) async {
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
    String baseUrl = await Constants.getBaseUrl();

    final url = Uri.parse('$baseUrl/category?name=${Uri.encodeComponent(name)}');

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
          print('Unexpected response format: $data'); // Debugging line
          return {'success': false, 'message': 'Unexpected response format'};
        }
      } else {
        return {'success': false, 'message': 'Failed to search categories with status code: ${response.statusCode}'};
      }
    } catch (error) {
      print('Error: $error'); // Debugging line
      return {'success': false, 'message': 'An error occurred'};
    }
  }

  Future<Map<String, dynamic>?> createProduct(List<Map<String, dynamic>> productData) async {
    String baseUrl = await Constants.getBaseUrl();

    final url = Uri.parse('$baseUrl/products/');
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
        print('Response Data: ${jsonEncode(responseData)}'); // Print structured response

        return {
          'message': responseData['message'] ?? 'Products uploaded successfully.',
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
          errorMessage = 'Failed to create product. Status code: ${response.statusCode} - ${errorResponse['message'] ?? 'Unknown error'}';
        }

        print('Error Response: ${jsonEncode(errorResponse)}'); // Print structured error response

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
    String baseUrl = await Constants.getBaseUrl();

    final url = Uri.parse('$baseUrl/label/');
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
    String baseUrl = await Constants.getBaseUrl();

    final String url = "$baseUrl/warehouse/$warehouseId";

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

  Future<Map<String, dynamic>> searchProductsByDisplayName(String displayName) async {
    log('searchProductsByDisplayName');
    String baseUrl = await Constants.getBaseUrl();

    final url = '$baseUrl/products?displayName=${Uri.encodeComponent(displayName)}';

    Logger().e("Request URL: $url");

    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      Logger().e("Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        // Logger().e("Response Body: $decodedBody");

        if (res['products'] is! List || res['totalProducts'] is! int || res['totalPages'] is! int || res['currentPage'] is! int) {
          return {
            'success': false,
            'message': 'Unexpected response format',
          };
        }

        final products = res['products'].map((product) {
          final extractedProduct = {
            'id': product['_id'] ?? '',
            'displayName': product['displayName'] ?? '',
            'parentSku': product['parentSku'] ?? '',
            'sku': product['sku'] ?? '',
            'description': product['description'] ?? '',
            'brand': product['brand']?['name'] ?? '',
            'categoryName': product['category']?['name'] ?? '',
            'netWeight': product['netWeight']?.toString() ?? '',
            'grossWeight': product['grossWeight']?.toString() ?? '',
            'ean': product['ean'] ?? '',
            'technicalName': product['technicalName'] ?? '',
            'labelSku': product['label']?['labelSku'] ?? '',
            'colour': product['color']?['name'] ?? '',
            'outerPackage_quantity': product['outerPackage_quantity']?.toString() ?? '',
            'outerPackage_name': product['outerPackage']?['outerPackage_name'] ?? '',
            'length': product['dimensions']?['length']?.toString() ?? '',
            'width': product['dimensions']?['width']?.toString() ?? '',
            'height': product['dimensions']?['height']?.toString() ?? '',
            'tax_rule': product['tax_rule'] ?? '',
            //'weight': product['weight'] ?? '-',
            'mrp': product['mrp']?.toString() ?? '',
            'cost': product['cost']?.toString() ?? '',
            'grade': product['grade'] ?? '',
            'shopifyImage': product['shopifyImage'] ?? '',
            'createdAt': product['createdAt'] ?? '',
            'updatedAt': product['updatedAt'] ?? '',
          };

          // Print each product's required fields
          //print('Product Details: $extractedProduct');
          //print('------------------------------------------------');
          return extractedProduct;
        }).toList();

        log('lets see: ${res['products']}');
        return {
          'success': true,
          'products': products,
          'totalProducts': res['totalProducts'],
          'totalPages': res['totalPages'],
          'currentPage': res['currentPage'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load products, status code: ${response.statusCode}',
        };
      }
    } catch (error) {
      log('error in catch: $error');
      // Logger().e('error in catch: $error');
      return {
        'success': false,
        'message': 'An error occurred: $error',
      };
    }
  }

  Future<Map<String, dynamic>> searchProductsBySKU(String displayName) async {
    log('searchProductsByDisplayName');
    String baseUrl = await Constants.getBaseUrl();

    final url = '$baseUrl/products?sku=${Uri.encodeComponent(displayName)}';

    Logger().e("Request URL: $url");

    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      Logger().e("Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        // Logger().e("Response Body: $decodedBody");

        if (res['products'] is! List || res['totalProducts'] is! int || res['totalPages'] is! int || res['currentPage'] is! int) {
          return {
            'success': false,
            'message': 'Unexpected response format',
          };
        }

        final products = res['products'].map((product) {
          final extractedProduct = {
            'id': product['_id'] ?? '',
            'displayName': product['displayName'] ?? '',
            'parentSku': product['parentSku'] ?? '',
            'sku': product['sku'] ?? '',
            'description': product['description'] ?? '',
            'brand': product['brand']?['name'] ?? '',
            'categoryName': product['category']?['name'] ?? '',
            'netWeight': product['netWeight']?.toString() ?? '',
            'grossWeight': product['grossWeight']?.toString() ?? '',
            'ean': product['ean'] ?? '',
            'technicalName': product['technicalName'] ?? '',
            'labelSku': product['label']?['labelSku'] ?? '',
            'colour': product['color']?['name'] ?? '',
            'outerPackage_quantity': product['outerPackage_quantity']?.toString() ?? '',
            'outerPackage_name': product['outerPackage']?['outerPackage_name'] ?? '',
            'length': product['dimensions']?['length']?.toString() ?? '',
            'width': product['dimensions']?['width']?.toString() ?? '',
            'height': product['dimensions']?['height']?.toString() ?? '',
            'tax_rule': product['tax_rule'] ?? '',
            //'weight': product['weight'] ?? '-',
            'mrp': product['mrp']?.toString() ?? '',
            'cost': product['cost']?.toString() ?? '',
            'grade': product['grade'] ?? '',
            'shopifyImage': product['shopifyImage'] ?? '',
            'createdAt': product['createdAt'] ?? '',
            'updatedAt': product['updatedAt'] ?? '',
          };

          // Print each product's required fields
          //print('Product Details: $extractedProduct');
          //print('------------------------------------------------');
          return extractedProduct;
        }).toList();

        log('lets see: ${res['products']}');
        return {
          'success': true,
          'products': products,
          'totalProducts': res['totalProducts'],
          'totalPages': res['totalPages'],
          'currentPage': res['currentPage'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load products, status code: ${response.statusCode}',
        };
      }
    } catch (error) {
      log('error in catch: $error');
      // Logger().e('error in catch: $error');
      return {
        'success': false,
        'message': 'An error occurred: $error',
      };
    }
  }

  // Future<Map<String, dynamic>> searchProductsByDisplayName(
  //     String displayName) async {
  //   final url =
  //       '$_baseUrl/products?displayName=${Uri.encodeComponent(displayName)}';
  //   Logger().e(
  //     "url: $url",
  //   );
  //   try {
  //     final token = await getToken();
  //     if (token == null) {
  //       return {'success': false, 'message': 'No token found'};
  //     }
  //     // Make the HTTP GET request
  //     final response = await http.get(
  //       Uri.parse(url), // Ensure URL is parsed
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer $token',
  //       },
  //     );
  //     // Check the response status code
  //     if (response.statusCode == 200) {
  //       print("Response Status: ${response.statusCode}");
  //       // print("Response Body: ${response.body}");
  //       // Dispatched the whole response as a Map
  //       return {
  //         'success': true,
  //         'products': json.decode(response.body)['products'],
  //         'totalProducts': json.decode(response.body)['totalProducts'],
  //         'totalPages': json.decode(response.body)['totalPages'],
  //         'currentPage': json.decode(response.body)['currentPage'],
  //       };
  //     } else {
  //       return {
  //         'success': false,
  //         'message':
  //             'Failed to load products, status code: ${response.statusCode}',
  //       };
  //     }
  //   } catch (error) {
  //     // Handle exceptions (network errors, JSON parsing errors, etc.)
  //     return {
  //       'success': false,
  //       'message': 'An error occurred: $error',
  //     };
  //   }
  // }

  // Future<Map<String, dynamic>> searchProductsBySKU(String sku) async {
  //   log('searchProductsBySKU');
  //   String baseUrl = await Constants.getBaseUrl();

  //   final url = '$baseUrl/products?sku=${Uri.encodeComponent(sku)}';

  //   try {
  //     final token = await getToken();
  //     if (token == null) {
  //       return {
  //         'success': false,
  //         'message': 'No token found'
  //       };
  //     }

  //     // Make the HTTP GET request
  //     final response = await http.get(
  //       Uri.parse(url),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer $token',
  //       },
  //     );

  //     // Check the response status code
  //     if (response.statusCode == 200) {
  //       //print("Response Status: ${response.statusCode}");
  //       //print("Response Body: ${response.body}");

  //       // Correctly parsing the 'products' key from the response
  //       final res = json.decode(response.body);

  //       log('ye le res: $res');

  //       if (res != null && res['products'] != null) {
  //         return {
  //           'success': true,
  //           'data': res['products']
  //         };
  //       } else {
  //         return {
  //           'success': false,
  //           'message': 'No products found',
  //         };
  //       }
  //     } else {
  //       return {
  //         'success': false,
  //         'message': 'Failed to load products, status code: ${response.statusCode}',
  //       };
  //     }
  //   } catch (error) {
  //     // Handle exceptions (network errors, JSON parsing errors, etc.)
  //     // log('error in catch: $error');
  //     Logger().e('le ye error: $error');
  //     return {
  //       'success': false,
  //       'message': 'An error occurred: $error',
  //     };
  //   }
  // }

  Future<String> getTemplateURL(BuildContext context, String title) async {
    // Retrieve the token from shared preferences
    String baseUrl = await Constants.getBaseUrl();
    final token = await getToken();

    // Check if the token is valid
    if (token == null || token.isEmpty) {
      throw Exception('Authorization token is missing or invalid.');
    }

    // Set up the headers for the request
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      // Make the GET request
      final response = await http.get(Uri.parse('$baseUrl/links?title=$title'), headers: headers);

      // Print the received response for debugging
      //print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);

        log("jsonBody: $jsonBody");

        // Check if the response has an "orders" key
        return jsonBody['data']['url'];
      } else {
        throw Exception('Failed to load template: ${response.statusCode} ${response.body}');
      }
    } catch (error) {
      print('Error during HTTP request: $error');
      throw Exception('An error occurred while loading template: $error');
    }
  }

  Future<void> downloadTemplate(BuildContext context, String title) async {
    try {
      final templateURL = getTemplateURL(context, title);
      final fileUrl = Uri.parse(await templateURL);

      log("fileUrl: $fileUrl");

      if (await canLaunchUrl(fileUrl)) {
        await launchUrl(fileUrl);
        // Optionally, show a message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template download initiated.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch URL.')),
        );
      }

      // final response = await http.get(Uri.parse(apiUrl));

      // if (response.statusCode == 200) {
      //   final res = json.decode(response.body);
      //   final String fileUrl = res['data']['url']; // Extract the URL from the response

      // if (await canLaunch(fileUrl)) {
      //   await launch(fileUrl);
      //   // Optionally, show a message to the user
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Template download initiated.')),
      //   );
      // } else {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Could not launch URL.')),
      //   );
      // }
      // } else {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Failed to fetch template URL: ${response.statusCode}')),
      //   );
      // }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  bool _isReversing = false;
  bool get isReversing => _isReversing;

  void setReversing(bool value) {
    _isReversing = value;
    notifyListeners();
  }

  Future<Map<String, dynamic>> reverseOrder(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    String url = '${await Constants.getBaseUrl()}/orders/reverse';

    if (token == null) {
      print('Token is missing. Please log in again.');
      return {'success': false, 'message': 'Token is missing. Please log in again.'};
    }

    Logger().e('reverseOrder url: $url');

    try {
      setReversing(true);

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {'order_id': orderId, 'order_status': '1'},
        ),
      );

      final data = jsonDecode(response.body);

      log('reverse status: ${response.statusCode}');
      // Logger().e('reverseOrder body: $data');

      if (response.statusCode == 200) {
        Logger().e('reverseOrder body: ${{'success': true, 'message': data['message'], 'newOrderId': data['order']?['order_id'] ?? ''}}');
        return {'success': true, 'message': data['message'], 'newOrderId': data['order']?['order_id'] ?? ''};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      log('caught error: $e');
      return {'success': false, 'message': 'Error: $e'};
    } finally {
      setReversing(false);
    }
  }
}
