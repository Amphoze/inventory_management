import 'package:flutter/material.dart';

class Utils {
  Widget showMessage(BuildContext context, String title, String msg) {
    return Tooltip(
      message: msg,
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
    );
  }

  static showSnackBar(BuildContext context, String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  static showInfoDialog(BuildContext context, String message, bool success) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            success ? 'Success' : 'Failed',
            style: TextStyle(color: success ? Colors.green : Colors.red),
          ),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ok'))
          ],
        );
      },
    );
  }
}
