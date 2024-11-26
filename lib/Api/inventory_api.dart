import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

//class InventoryApi extends ChangeNotifier {
   String _baseUrl =
      'https://inventory-management-backend-s37u.onrender.com';
  bool _isAuthenticated = false;
  List<Map<String, dynamic>> filteredInventories = [];

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getString('authToken') != null;
    return prefs.getString('authToken');
  }

  Future<Map<String, dynamic>> getAllInventory({int limit = 10}) async {
    final url = Uri.parse('$_baseUrl/inventory');
    List<Map<String, dynamic>> allInventories = [];
    int currentPage = 1;

    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      while (true) {
        final response = await http.get(
          url.replace(queryParameters: {
            'page': currentPage.toString(),
            'limit': limit.toString(), // Add limit to the query
          }),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          final data = responseData['data']['inventories'] as List<dynamic>;

          if (data.isEmpty) break; // Exit the loop if no more data

          final inventory = data.map((item) {
            final product = item['product_id'] ?? {};
            final category = product['category'] ?? {};
            final brand = product['brand'] ?? {};
            final boxsize = product['boxSize'] ?? {};
            return {
              'COMPANY NAME': 'KATYAYANI ORGANICS',
              'CATEGORY': category['name'] ?? '-',
              'IMAGE': product['shopifyImage'] ?? '-',
              'BRAND': brand['name'] ?? '-',
              'SKU': product['sku'] ?? '-',
              'PRODUCT NAME': product['displayName'] ?? '-',
              'MRP': product['mrp']?.toString() ?? '-',
              'BOXSIZE': boxsize['box_name'] ?? "_",
              'QUANTITY': item['total']?.toString() ?? '0',
              'FLIPKART': product['flipkart'] ?? '-',
              'SNAPDEAL': product['snapdeal'] ?? '-',
              'AMAZON.IN': product['amazon'] ?? '-',
              'inventoryLogs': item['inventoryLogs'] ?? [],
            };
          }).toList();

          allInventories.addAll(inventory);
          currentPage++; // Increment page for the next iteration
        } else {
          return {
            'success': false,
            'message':
            'Failed to load inventories. Status code: ${response.statusCode}',
          };
        }
        // return {
        //   'success': true,
        //   'data': {'inventories': filteredInventories},
        // };
      }

      // Print the fetched data in the terminal
      print('Fetched Inventory Data:');
      for (var item in allInventories) {
        print(item);
      }

      return {
        'success': true,
        'data': {'inventories': allInventories},
      };
    } catch (error) {
      print('Error fetching inventories: $error'); // Print error in terminal
      return {
        'success': false,
        'message': 'Error fetching inventories: $error'
      };
    }
  }






