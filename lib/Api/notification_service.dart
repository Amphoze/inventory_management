import 'dart:html' as html;

class NotificationService {
  static Future<void> requestNotificationPermission() async {
    String status = await html.Notification.requestPermission();
    if (status == 'granted') {
      print("Notification permission granted");
    } else {
      print("Notification permission denied");
    }
  }

  static Future<void> showBrowserNotification(String sender, String message) async {
    // Ensure permission is requested before attempting to show a notification
    if (html.Notification.permission == 'default') {
      // Request permission if not already determined
      await requestNotificationPermission();
    }

    if (html.Notification.permission == 'granted') {
      // Show notification only if permission is granted
      html.Notification("New message from $sender", body: message);
    }
  }
}
