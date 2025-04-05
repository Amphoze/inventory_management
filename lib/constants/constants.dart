import 'dart:developer';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Constants {
  static Future<String> getBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final String firebaseUrl = prefs.getString('value') ?? 'https://inventory-api.ko-tech.in';

    String? env = dotenv.env['STOCKSHIP_ENV'];

    if (env == 'beta') {
      return 'https://beta.api.stockship.ko-tech.in';
    } else if (env == 'dev') {
      return 'http://192.168.107.199:3001';
    }

    return firebaseUrl;






    // return 'https://inventory-management-backend-15d0.onrender.com'; // sanidhya

    // return 'https://stockship-3.onrender.com';

    // return 'http://192.168.67.122:3001';

    // return 'http://192.168.107.199:3001';

    // return 'http://localhost:3001';

    // return 'http://192.168.29.31:3001';

    // return 'http://192.168.29.203:3001';

  }
}
