import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Api/notification_service.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _orderId;
  String? _currentUserEmail;
  String? _currentUserRole;

  void initializeChat(String orderId, String userEmail, String userRole) {
    _orderId = orderId;
    _currentUserEmail = userEmail;
    _currentUserRole = userRole;
    _listenForNewMessages();
    _sendSystemMessageIfFirstTime(); // Check if the user is new and send a system message
    notifyListeners();
  }

  Future<void> _sendSystemMessageIfFirstTime() async {
    final messagesRef = _firestore.collection('orders').doc(_orderId).collection('messages');

    final querySnapshot = await messagesRef.get();
    if (querySnapshot.docs.isEmpty) {
      // If no messages exist, send system message
      await messagesRef.add({
        'sender': 'System',
        'text': 'Welcome! Use this chat to report issues about this order and inform others once resolved.',
        'timestamp': FieldValue.serverTimestamp(),
        'userRole': 'system',
      });
    }
  }

  void _listenForNewMessages() {
    _firestore
        .collection('orders')
        .doc(_orderId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        var data = snapshot.docs.first.data();
      }
    });
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final body = {
      'sender': _currentUserEmail,
      'text': message.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': {_currentUserEmail: true},
      'userRole': _currentUserRole, // Added userRole to message data
    };

    log('message body: $body');

    try {
      await _firestore.collection('orders').doc(_orderId).collection('messages').add(body);

      log("Message sent successfully!");
    } catch (e) {
      log("Error sending message: $e");
      rethrow; // Rethrow to handle error in UI
    }

    notifyListeners();
  }

  Future<void> sendMessageForOrder({
    required String orderId,
    required String message,
    String? senderEmail,
    String? userRole,
  }) async {
    if (message.trim().isEmpty) return;

    final pref = await SharedPreferences.getInstance();

    String? email = pref.getString('email');
    String? userRole = pref.getString('userPrimaryRole');

    if (email == null || userRole == null) return;

    final body = {
      'sender': email,
      'text': message.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': {email: true},
      'userRole': userRole,
    };

    log('message body for order $orderId: $body');

    try {
      await _firestore.collection('orders').doc(orderId).collection('messages').add(body);
      log("Message sent successfully for order $orderId!");
    } catch (e) {
      log("Error sending message for order $orderId: $e");
      rethrow;
    }

    notifyListeners();
  }

  Future<void> deleteMessage(String messageId) async {
    if (_orderId == null) return;

    try {
      await _firestore.collection('orders').doc(_orderId).collection('messages').doc(messageId).delete();

      log("Message deleted successfully!");
    } catch (e) {
      log("Error deleting message: $e");
      rethrow; // Propagate the error to handle it in UI
    }
  }

  Future<int> getUnreadMessagesCount() async {
    if (_orderId == null || _currentUserEmail == null) return 0;

    final querySnapshot = await _firestore
        .collection('orders')
        .doc(_orderId)
        .collection('messages')
        .where('readBy.$_currentUserEmail', isNull: true) // Messages not marked as read
        .get();

    return querySnapshot.docs.length;
  }

  Future<void> markMessagesAsRead() async {
    if (_orderId == null || _currentUserEmail == null) return;

    final querySnapshot = await _firestore
        .collection('orders')
        .doc(_orderId)
        .collection('messages')
        .where('readBy.$_currentUserEmail', isNull: true) // Unread messages
        .get();

    final batch = _firestore.batch();
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'readBy.$_currentUserEmail': true});
    }

    await batch.commit();
  }
}
