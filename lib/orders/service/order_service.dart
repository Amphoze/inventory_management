import 'dart:developer';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:inventory_management/constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderService {

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  static Future<String> _getBaseUrl() async {
    return await Constants.getBaseUrl();
  }

  static Future<bool> writeRemark({
    required String orderId,
    required String message,
    required String remark,
  }) async {
    try {

      final token = await _getToken();

      if (token == null || token.isEmpty) {
        return false;
      }

      final baseUrl = await _getBaseUrl();

      final url = '$baseUrl/orders?order_id=$orderId';

      final prefs = await SharedPreferences.getInstance();
      String? email = prefs.getString('email');

      log('Writing Remark for order id $orderId at URL :- $url');

      final body = {
        "messages": {
          message:
          [
            {
              "message": remark,
              "timestamp": DateTime.now().toIso8601String(),
              "author": email ?? "Unknown",
            }
          ]
        }
      };

      final payload = jsonEncode(body);

      log('Remark Payload :- $payload');

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: payload,
      );

      if (response.statusCode == 200) {
        log('Remark Submitted Successfully :)');
        return true;
      } else {
        log('Failed to submit remark with status code ${response.statusCode} and response as ${response.body}');
        return false;
      }

    } catch (e, s) {
      log('Error submitting remark :- $e\n$s');
      return false;
    }
  }

}