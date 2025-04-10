import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart';

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

  static showSnackBar(BuildContext context, String message, {String? details, Color? color, int seconds = 3, bool toRemoveCurr = false, bool isError = false}) {
    if(toRemoveCurr) ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: Duration(seconds: isError ? 5 : seconds),
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      showCloseIcon: details == null,
      backgroundColor: isError ? AppColors.cardsred : color,
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
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ok'))],
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
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ok'))],
        );
      },
    );
  }

  static showLoadingDialog(BuildContext context, String message) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 8),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  static Widget richText(String title, String subTitle, {double? fontSize}) {
    return Text.rich(
      TextSpan(
        text: title,
        children: [
          TextSpan(
            text: subTitle,
            style: const TextStyle(fontWeight: FontWeight.normal),
          ),
        ],
      ),
      style: TextStyle(fontSize: fontSize ?? 14, fontWeight: FontWeight.bold),
    );
  }

  static void showUnauthorized(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation1, animation2) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation,
            child: Dialog(
              elevation: 8,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: AppColors.primaryBlue,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Unauthorized',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You do not have permission to access this feature.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
