import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'model/development_notes_model.dart';

class VersionController extends ChangeNotifier {
  FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

  ///////////////////////////////////////////////////////////////////////
  /// 1. Change this currentVersion first.                            ///
  /// 2. flutter build web --release                                  ///
  /// 3. firebase deploy                                              ///
  /// 4. Change version in firebase to match this currentVersion.     ///
  ///////////////////////////////////////////////////////////////////////
  String currentVersion = '6.6.8';
  String? latestVersion = '';

  void setLatest(String value) {
    latestVersion = value;
  }

  Future<void> addDeveloperReleaseTime({
    required String datetime,
    required String version,
    required List<DevelopmentNotesModel> notes,
  }) async {
    try {
      // Convert the list of DevelopmentNotesModel to a list of maps (JSON format)
      List<Map<String, dynamic>> notesList = notes.map((note) => note.toJson()).toList();

      final releaseNotes = {
        'datetime': datetime,
        'version': version,
        'releaseNotes': notesList, // Store notes as a list of JSON objects
      };

      final date = DateTime.now().toIso8601String();
      final docRef = firebaseFirestore.collection('DeveloperNotes').doc(date);

      await docRef.collection("ReleaseNotes").add(releaseNotes);

      log("Release Notes added successfully at ${releaseNotes['datetime']} and Version : $version");
    } catch (e, stacktrace) {
      log("Failed to add release notes: $e");
      log("Stacktrace: $stacktrace");
    }
  }

  Future<Map<String, dynamic>?> getLatestDeveloperReleaseTime() async {
    try {
      final querySnapshot = await firebaseFirestore.collectionGroup('ReleaseNotes').orderBy('timestamp', descending: true).limit(1).get();

      if (querySnapshot.docs.isNotEmpty) {
        final latestNote = querySnapshot.docs.first.data();
        log("Latest Release Note: $latestNote");
        return latestNote;
      } else {
        log("No release notes found.");
        return null;
      }
    } catch (e, stacktrace) {
      log("Failed to get latest release notes: $e");
      log("Stacktrace: $stacktrace");
      return null;
    }
  }

  Future<String> getLatestVersion() async {
    try {
      // Query the 'ReleaseNotes' collection to get the data
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('ReleaseNotes')
          .orderBy('datetime', descending: true) // Order by datetime descending
          .limit(1) // Limit to the most recent entry
          .get();

      if (snapshot.docs.isEmpty) {
        return 'N/A';
      }

      final latestNote = snapshot.docs.first.data();
      Logger().i("Latest Version : ${latestNote['version'] ?? 'N/A'}");
      return latestNote['version'] ?? 'N/A';
    } catch (e) {
      log("Error getting latest version: $e");
      return 'Error';
    }
  }
}
