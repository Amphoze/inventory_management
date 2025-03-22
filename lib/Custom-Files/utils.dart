import 'package:flutter/material.dart';

class Utils {
  Widget showMessage(BuildContext context, String title, String msg) {
    return Tooltip(
      message: msg,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.3,
        child: Text.rich(
          textAlign: TextAlign.end,
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

  static showSnackBar(BuildContext context, String message, {String? details, Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      action: details != null
          ? SnackBarAction(
              label: 'Details',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Details'),
                      content: Text(details),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Ok'))
                      ],
                    );
                  },
                );
              },
            )
          : null,
    ));
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

  static Widget richText(String title, String subTitle) {
    return Text.rich(
      TextSpan(
        text: title,
        children: [
          TextSpan(
            text: subTitle,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
        ],
      ),
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    );
  }
}
