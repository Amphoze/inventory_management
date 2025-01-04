// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// class AuthProvider with ChangeNotifier {
//   final String _baseUrl =
//       '${await ApiUrls.getBaseUrl()}';

//   bool _isLoading = false;
//   String? _errorMessage;
//   String? _token;

//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;
//   String? get token => _token;
//   // String? get selectedIndex => _selectedIndex;

//   Future<void> register(String userName, String email, String password) async {
//     _isLoading = true;
//     notifyListeners();

//     try {
//       print("hahahhaha $_baseUrl");
//       final response = await http.post(
//         Uri.parse(
//             '${await ApiUrls.getBaseUrl()}/register'),
//         headers: <String, String>{
//           'Content-Type': 'application/json; charset=UTF-8'
//         },
//         body: json.encode({
//           "username": "divyansh",
//           "email": "ksp@gmail.com",
//           "password": "123456"
//         }),
//       );
//       print("hahahhaha $_baseUrl");

//       // Debugging: Print the status code and response body
//       print('Response status: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['success']) {
//           _token = data['token'];
//         } else {
//           _errorMessage = data['message'];
//         }
//       } else {
//         _errorMessage =
//             'Failed to register. Status code: ${response.statusCode}';
//       }
//     } catch (error) {
//       print("aosjjknknjkn $error");
//       _errorMessage = 'Error during registration: $error';
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
// }
