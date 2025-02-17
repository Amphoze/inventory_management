import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/stockship_version_control/version_controller.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'crm_developer_notes_dialog.dart';
import 'crm_update_version_dialog.dart';
import 'model/development_notes_model.dart';

class CrmUpdatedDateWidget extends StatelessWidget {
  const CrmUpdatedDateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    List<DevelopmentNotesModel> releaseNotes = [];

    Future<void> showUpdateDialog(BuildContext context) async {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => CrmUpdateVersionDialog(devNotes: releaseNotes),
      );
    }

    return Consumer2<AuthProvider, VersionController>(
      builder: (context, authProvi, versionController, child) {
        return Card(
          elevation: 0,
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              // final prefs = await SharedPreferences.getInstance();
              // if ((prefs.getBool('_isSuperAdminAssigned') ?? false) || (prefs.getBool('_isAdminAssigned') ?? false)) {
              //   showDialog(
              //     context: context,
              //     builder: (context) => const CrmDeveloperNotesDialog(),
              //   );
              // }
            },
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collectionGroup('ReleaseNotes').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildVersionContainer(loading: true);
                }

                if (snapshot.hasError) {
                  log("Error Fetching Release Time ${snapshot.error}");
                  return _buildVersionContainer(error: true);
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildVersionContainer(empty: true);
                }

                final allNotes = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList()
                  ..sort((a, b) {
                    final dateTimeA = DateTime.tryParse(a['datetime'] ?? '') ?? DateTime(0);
                    final dateTimeB = DateTime.tryParse(b['datetime'] ?? '') ?? DateTime(0);
                    return dateTimeB.compareTo(dateTimeA);
                  });

                final latestNote = allNotes.first;
                final latestVersion = latestNote['version'] ?? "";

                if (latestNote['releaseNotes']?.isNotEmpty ?? false) {
                  releaseNotes = (latestNote['releaseNotes'] as List).map((note) => DevelopmentNotesModel.fromJson(note)).toList();
                }

                if (int.tryParse(latestVersion) != null && versionController.currentVersion < int.parse(latestVersion)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    showUpdateDialog(context);
                  });
                }

                Logger().e('latest version: $latestVersion');

                return _buildVersionContainer(
                  latestVersion: latestVersion.toString(),
                  currentVersion: versionController.currentVersion.toString(),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildVersionContainer({
    bool loading = false,
    bool error = false,
    bool empty = false,
    String latestVersion = '',
    String currentVersion = '',
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: loading
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blue,
              ),
            )
          : error || empty
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Version info unavailable',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildVersionText('v$latestVersion', 'Latest'),
                    Container(
                      height: 12,
                      width: 1,
                      color: Colors.blue.shade200,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    _buildVersionText('v$currentVersion', 'Current'),
                  ],
                ),
    );
  }

  Widget _buildVersionText(String version, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          version,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($label)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue.shade600,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
