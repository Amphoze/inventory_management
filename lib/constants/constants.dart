// import 'dart:developer';
import 'dart:developer';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Constants {
  static Future<String> getBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String firebaseUrl = prefs.getString('value') ?? 'https://inventory-api.ko-tech.in';
    // log('baseUrl: $firebaseUrl');

    String? env = dotenv.env['STOCKSHIP_ENV'];

    if (env == 'beta') {
      return 'https://beta.api.stockship.ko-tech.in';
    }

    return firebaseUrl;

    // return 'https://inventory-management-backend-15d0.onrender.com'; // sanidhya

    // return 'https://stockship-3.onrender.com';

    // return 'http://localhost:3001';
  }
}
