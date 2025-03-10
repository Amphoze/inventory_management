import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

class Constants {
  static Future<String> getBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String baseUrl = prefs.getString('value') ?? '';
    // log('Base URL: $baseUrl');

    // return 'http://192.168.125.122:3001'; // lahar's url
    // return 'http://192.168.29.148:3001'; // lahar's url
    // return 'http://192.168.71.122:3001'; // lahar's url

    // return 'http://192.168.29.139:3001'; // nitesh's url
    // return 'http://192.168.29.117:3001'; // nitesh's url
    // return 'http://192.168.209.178:3001'; // nitesh's url

    // return 'https://stockship-2.onrender.com';

    return baseUrl; // firebase url
  }
}
