import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

class Constants {
  static Future<String> getBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String baseUrl = prefs.getString('value') ?? '';
    log('Base URL: $baseUrl');
    // return baseUrl;
    return 'https://inventory-api.ko-tech.in';
    // return 'http://192.168.29.140:3001';
    // return 'http://192.168.29.162:3001';
  }
}
