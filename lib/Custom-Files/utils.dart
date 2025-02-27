import 'package:flutter/material.dart';

import 'colors.dart';

class Utils {
  Widget showMessage(BuildContext context, String title, String msg) {
    return Tooltip(
      message: msg,
      child: Flexible(
        child: Text.rich(
          TextSpan(
            text: "$title: ",
            children: [
              TextSpan(
                text: msg,
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  static showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}
