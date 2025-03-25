// import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

class Constants {
  static Future<String> getBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String baseUrl = prefs.getString('value') ?? '';
    // log('baseUrl: $baseUrl');

    // return 'https://inventory-management-backend-15d0.onrender.com';

    // return 'http://localhost:3001'; // mine

    // return 'http://192.168.29.203:3001'; // mine

    // return 'http://192.168.209.122:3001';

    // return 'http://192.168.29.117:3001';

    // return 'https://stockship-3.onrender.com';

    return baseUrl; // firebase url
  }
}
