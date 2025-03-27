import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inventory_management/constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductApi {
// late final String _baseUrl;

//   ProductApi() {
//     _initialize();
//   }

//   Future<void> _initialize() async {
//     _baseUrl = await ApiUrls.getBaseUrl();
//   }
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<Map<String, dynamic>> searchProductsByDisplayName(
      String displayName) async {
    String baseUrl = await Constants.getBaseUrl();
    final url = '$baseUrl?displayName=${Uri.encodeComponent(displayName)}';

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
        return json.decode(response.body);
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
}

// class ProductAPI {
//   static const String _baseUrl =
//       '${await ApiUrls.getBaseUrl()}';

//   // Fetch token from SharedPreferences
//   Future<String?> _getToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('authToken');
//   }

//   // Search products by display name
//   Future<Map<String, dynamic>> searchProductsByDisplayName(
//       String displayName) async {
//     String query = 'displayName=$displayName';
//     return await _searchProducts(query);
//   }

//   // Search products by SKU
//   Future<Map<String, dynamic>> searchProductsBySku(String sku) async {
//     String query = 'sku=$sku';
//     return await _searchProducts(query);
//   }

//   // Search products by description
//   Future<Map<String, dynamic>> searchProductsByDescription(
//       String description) async {
//     String query = 'description=$description';
//     return await _searchProducts(query);
//   }

//   // Search products by category
//   Future<Map<String, dynamic>> searchProductsByCategory(String category) async {
//     String query = 'category=$category';
//     return await _searchProducts(query);
//   }

//   // Private method to handle the common logic for searching products
//   Future<Map<String, dynamic>> _searchProducts(String query) async {
//     final token = await _getToken();
//     if (token == null) {
//       return {
//         'success': false,
//         'message': 'Error: Authorization token not found.',
//       };
//     }

//     try {
//       final response = await http.get(
//         Uri.parse('$_baseUrl/products?$query'), // Properly format the URL
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );

//       // Log response details for debugging
//       print('Response Status Code: ${response.statusCode}');
//       print('Response Body: ${response.body}');

//       if (response.statusCode == 200) {
//         print(response.body);
//         return json.decode(response.body);
//       } else {
//         return {
//           'success': false,
//           'message': 'Error: ${response.statusCode} - ${response.body}',
//         };
//       }
//     } catch (error) {
//       return {
//         'success': false,
//         'message': 'Network error: $error',
//       };
//     }
//   }
// }
