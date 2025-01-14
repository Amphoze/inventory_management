import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

class ApiUrls {
  static Future<String> getBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String baseUrl = prefs.getString('value') ?? '';
    log('Base URL: $baseUrl');
    // return 'https://inventory-api.ko-tech.in';
    return baseUrl;
  }
}
