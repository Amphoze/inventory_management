// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:inventory_management/model/orders_model.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class OrdersApi {
//   final String _baseUrl =
//       '${await ApiUrls.getBaseUrl()}';
//   // Fetch orders from API
//   Future<List<Order>> getOrders({int page = 1, int limit = 20}) async {
//     // Retrieve the token from shared preferences
//     final token = await _getToken();

//     // Check if the token is valid
//     if (token == null || token.isEmpty) {
//       throw Exception('Authorization token is missing or invalid.');
//     }

//     // Set up the headers for the request
//     final headers = {
//       'Authorization': 'Bearer $token',
//       'Content-Type': 'application/json',
//     };

//     try {
//       // Make the GET request
//       final response = await http.get(
//           Uri.parse('$_baseUrl/orders?page=$page&limit=$limit'),
//           headers: headers);

//       // Print the received response for debugging
//       //print('Response status: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       if (response.statusCode == 200) {
//         final jsonBody = json.decode(response.body);

//         // Check if the response has an "orders" key
//         if (jsonBody is Map<String, dynamic> && jsonBody['orders'] != null) {
//           List<dynamic> ordersList = jsonBody['orders'];
//           return ordersList.map((data) => Order.fromJson(data)).toList();
//         } else {
//           throw Exception('Unexpected JSON format: $jsonBody');
//         }
//       } else {
//         throw Exception(
//             'Failed to load orders: ${response.statusCode} ${response.body}');
//       }
//     } catch (error) {
//       print('Error during HTTP request: $error');
//       throw Exception('An error occurred while fetching orders: $error');
//     }
//   }

//   // Fetch a specific order by its order_id
//   Future<Order?> getOrderById(String orderId) async {
//     final String? token = await _getToken(); // Retrieve the token

//     if (token == null) {
//       throw Exception('No auth token found');
//     }

//     final url =
//         '${await ApiUrls.getBaseUrl()}/orders?order_id=$orderId';

//     try {
//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           'Authorization': 'Bearer $token', // Add the token to the headers
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final jsonData = json.decode(response.body);
//         final Order order = Order.fromJson(jsonData);
//         return order;
//       } else {
//         throw Exception('Failed to load order: ${response.statusCode}');
//       }
//     } catch (error) {
//       print('Error fetching order by ID: $error');
//       return null;
//     }
//   }

//   Future<List<Order>> searchFailedOrders(String searchTerm) async {
//     final String? token = await _getToken(); // Retrieve the token

//     if (token == null) {
//       throw Exception('No auth token found');
//     }

//     final url =
//         '${await ApiUrls.getBaseUrl()}/orders?search=$searchTerm'; // No status in URL

//     try {
//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final jsonData = json.decode(response.body);
//         print(jsonData); // Print the entire JSON response to debug

//         // Assuming the list is under a key like 'orders'
//         final List<dynamic> ordersList =
//             jsonData['orders']; // Adjust 'orders' to the actual key
//         List<Order> orders =
//             List<Order>.from(ordersList.map((item) => Order.fromJson(item)));

//         return orders;
//       } else {
//         throw Exception('Failed to load orders: ${response.statusCode}');
//       }
//     } catch (error) {
//       print('Error searching failed orders: $error');
//       return [];
//     }
//   }

//   Future<List<Order>> searchReadyToConfirmOrders(String searchTerm) async {
//     final String? token = await _getToken(); // Retrieve the token

//     if (token == null) {
//       throw Exception('No auth token found');
//     }

//     final url =
//         '${await ApiUrls.getBaseUrl()}/orders?order_id=$searchTerm'; // No status in URL

//     try {
//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final jsonData = json.decode(response.body);
//         print(jsonData); // Print the entire JSON response to debug

//         // Assuming the list is under a key like 'orders'
//         final List<dynamic> ordersList =
//             jsonData['orders']; // Adjust 'orders' to the actual key
//         List<Order> orders =
//             List<Order>.from(ordersList.map((item) => Order.fromJson(item)));
//         print("Hello i am ${orders.toList()}");
//         return orders;
//       } else {
//         throw Exception('Failed to load orders: ${response.statusCode}');
//       }
//     } catch (error) {
//       print('Error searching ready-to-confirm orders: $error');
//       return [];
//     }
//   }

//   // // Add this method to the OrdersApi class
//   // Future<void> updateOrderStatus(String orderId, int newStatus) async {
//   //   final String? token = await _getToken();

//   //   if (token == null) {
//   //     throw Exception('No auth token found');
//   //   }

//   //   // Fetch the current order to get its current status
//   //   Order? currentOrder = await getOrderById(orderId);
//   //   if (currentOrder == null) {
//   //     throw Exception('Order not found');
//   //   }

//   //   // Check if the new status is valid
//   //   if (newStatus != currentOrder.orderStatus + 1) {
//   //     throw Exception(
//   //         'Invalid status change. You can only change the status to the next value.');
//   //   }

//   //   // Define the URL for the update
//   //   final String url = '$_baseUrl/orders/$orderId';

//   //   // Set up the headers for the request
//   //   final headers = {
//   //     'Authorization': 'Bearer $token',
//   //     'Content-Type': 'application/json',
//   //   };

//   //   // Prepare the request body
//   //   final body = json.encode({'status': newStatus});

//   //   try {
//   //     // Make the PUT request
//   //     final response = await http.put(
//   //       Uri.parse(url),
//   //       headers: headers,
//   //       body: body,
//   //     );

//   //     if (response.statusCode == 200) {
//   //       print('Order status updated successfully');
//   //     } else {
//   //       throw Exception(
//   //           'Failed to update order status: ${response.statusCode} ${response.body}');
//   //     }
//   //   } catch (error) {
//   //     print('Error during HTTP request: $error');
//   //     throw Exception(
//   //         'An error occurred while updating the order status: $error');
//   //   }
//   // }
//   // Update status for failed orders
//   Future<void> updateFailedOrders(
//       BuildContext context, List<String> failedOrderIds) async {
//     final String? token = await _getToken();
//     if (token == null) {
//       _showSnackbar(context, 'No auth token found');
//       return;
//     }

//     for (String orderId in failedOrderIds) {
//       print(
//           'Updating order ID: $orderId to status: 1'); // Print order ID and new status
//       await updateOrderStatus(
//           context, orderId, 1); // Update status to 1 for failed orders
//     }
//   }

// // Update status for ready-to-confirm orders
//   Future<void> updateReadyToConfirmOrders(
//       BuildContext context, List<String> readyToConfirmOrderIds) async {
//     final String? token = await _getToken();
//     if (token == null) {
//       _showSnackbar(context, 'No auth token found');
//       return;
//     }

//     for (String orderId in readyToConfirmOrderIds) {
//       print(
//           'Updating order ID: $orderId to status: 2'); // Print order ID and new status
//       await updateOrderStatus(context, orderId,
//           2); // Update status to 2 for ready-to-confirm orders
//     }
//   }

// // Existing updateOrderStatus function
//   Future<void> updateOrderStatus(
//       BuildContext context, String orderId, int newStatus) async {
//     final String? token = await _getToken();
//     if (token == null) {
//       _showSnackbar(context, 'No auth token found');
//       return;
//     }

//     // Define the URL for the update with query parameters
//     final String url = '$_baseUrl/orders?orderId=$orderId&status=$newStatus';

//     // Set up the headers for the request
//     final headers = {
//       'Authorization': 'Bearer $token',
//       'Content-Type': 'application/json',
//     };

//     print('Sending request to URL: $url'); // Print the URL being called

//     try {
//       // Make the PUT request
//       final response = await http.put(
//         Uri.parse(url),
//         headers: headers,
//       );

//       print('Response status: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       if (response.statusCode == 200) {
//         print('Order status updated successfully');
//         _showSnackbar(context, 'Order status updated successfully');
//       } else {
//         final errorResponse = json.decode(response.body);
//         String errorMessage =
//             errorResponse['message'] ?? 'Failed to update order status';
//         _showSnackbar(context, errorMessage);
//         throw Exception(
//             'Failed to update order status: ${response.statusCode} ${response.body}');
//       }
//     } catch (error) {
//       print('Error during HTTP request: $error');
//       _showSnackbar(
//           context, 'An error occurred while updating the order status: $error');
//       throw Exception(
//           'An error occurred while updating the order status: $error');
//     }
//   }

//   // Method to display a snackbar
//   void _showSnackbar(BuildContext context, String message) {
//     final snackBar = SnackBar(content: Text(message));
//     ScaffoldMessenger.of(context).showSnackBar(snackBar);
//   }

//   // Method to get the token from shared preferences
//   Future<String?> _getToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('authToken');
//   }
// }
