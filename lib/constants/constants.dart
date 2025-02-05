import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

class Constants {
  static Future<String> getBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String baseUrl = prefs.getString('value') ?? '';
    log('Base URL: $baseUrl');
    // return 'http://192.168.0.134:3001';
    return baseUrl;
  }
}
