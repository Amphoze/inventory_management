import 'package:flutter/material.dart';

class Utils {
  Widget showMessage(BuildContext context, String title, String msg) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(msg),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      },
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
}
