import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

class Constants {
  static Future<String> getBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String baseUrl = prefs.getString('value') ?? '';

    // return 'https://stockship-3.onrender.com';

    return 'http://192.168.29.117:3001';

    // return baseUrl; // firebase url
  }
}
