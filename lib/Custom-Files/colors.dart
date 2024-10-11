import 'package:flutter/material.dart';

class AppColors {
  static const Color googleColor = Color.fromRGBO(219, 68, 55, 1);
  static const Color facebookColor = Color.fromRGBO(24, 119, 242, 1);
  static const Color linkedinColor = Color.fromRGBO(0, 119, 181, 1);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color shadowblack = Color.fromRGBO(0, 0, 0, 0.451);
  static const Color shadowblack1 = Color.fromRGBO(0, 0, 0, 0.259);
  static const Color grey = Colors.grey;
  static const Color primaryBlue = Color.fromRGBO(6, 90, 216, 1);
  static const Color primaryBlueLight = Color.fromRGBO(6, 90, 216, 0.7);
  static const Color primaryGreen = Color.fromRGBO(37, 128, 69, 1);
  static const Color lightGrey = Color.fromRGBO(240, 240, 240, 1);
  static const Color greyBackground = Color.fromRGBO(238, 238, 238, 1);
  static const Color greyText = Color.fromRGBO(135, 135, 135, 1);
  static const Color drawerBackground = Colors.grey;
  static const Color cardsred = Colors.redAccent;
  static const Color cardsgreen = Colors.greenAccent;
  static const Color green = Colors.green;
  static const Color blueAccent = Color.fromRGBO(68, 138, 255, 1);
  static const Color orange = Colors.orange;
// <<<<<<< HEAD
// <<<<<<< HEAD
// =======
// >>>>>>> f739855e4312bceed673e57a85e5f13ee337e5ee
  //getWidth
  double getWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  // static const double MediaQuery.of(context).
  TextStyle get headerStyle {
    return const TextStyle(
      fontWeight: FontWeight.w600,
    );
  }

  TextStyle get simpleHeadingStyle {
    return const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 15,
    );
  }

// <<<<<<< HEAD
// =======
  static const Color lightBlue = Color.fromRGBO(3, 169, 244, 1);
  static const Color tealcolor = Color.fromRGBO(38, 166, 154, 1);
// >>>>>>> d730f9b8e18daf06e72f376d49e2a1dcb3bb96e2
// =======
// >>>>>>> f739855e4312bceed673e57a85e5f13ee337e5ee
}
