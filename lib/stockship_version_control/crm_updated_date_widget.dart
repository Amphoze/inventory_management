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
              final prefs = await SharedPreferences.getInstance();
              if ((prefs.getBool('_isSuperAdminAssigned') ?? false) || (prefs.getBool('_isAdminAssigned') ?? false)) {
                showDialog(
                  context: context,
                  builder: (context) => const CrmDeveloperNotesDialog(),
                );
              }
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

                context.read<VersionController>().setLatest(latestVersion);

                if (latestNote['releaseNotes']?.isNotEmpty ?? false) {
                  releaseNotes = (latestNote['releaseNotes'] as List).map((note) => DevelopmentNotesModel.fromJson(note)).toList();
                }

                if (latestVersion != null && (versionController.currentVersion != latestVersion)) {
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Tooltip(
        message: label,
        child: Text(
          version,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: label == 'Latest' ? Colors.blue.shade700 : Colors.black54,
          ),
        ),
      ),
    );
  }
}

// import 'dart:developer';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:inventory_management/Api/auth_provider.dart';
// import 'package:inventory_management/stockship_version_control/version_controller.dart';
// import 'package:logger/logger.dart';
// import 'package:provider/provider.dart';
// import 'crm_update_version_dialog.dart';
// import 'model/development_notes_model.dart';
//
// class CrmUpdatedDateWidget extends StatelessWidget {
//   const CrmUpdatedDateWidget({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     List<DevelopmentNotesModel> releaseNotes = [];
//
//     Future<void> showUpdateDialog(BuildContext context) async {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (BuildContext context) => CrmUpdateVersionDialog(devNotes: releaseNotes),
//       );
//     }
//
//     return Consumer2<AuthProvider, VersionController>(
//       builder: (context, authProvi, versionController, child) {
//         return InkWell(
//           borderRadius: BorderRadius.circular(24),
//           onTap: () async {
//             // tap functionality will be implemented later
//           },
//           child: StreamBuilder<QuerySnapshot>(
//             stream: FirebaseFirestore.instance.collectionGroup('ReleaseNotes').snapshots(),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return _buildVersionChip(loading: true);
//               }
//
//               if (snapshot.hasError) {
//                 log("Error Fetching Release Time ${snapshot.error}");
//                 return _buildVersionChip(error: true);
//               }
//
//               if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                 return _buildVersionChip(empty: true);
//               }
//
//               final allNotes = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList()
//                 ..sort((a, b) {
//                   final dateTimeA = DateTime.tryParse(a['datetime'] ?? '') ?? DateTime(0);
//                   final dateTimeB = DateTime.tryParse(b['datetime'] ?? '') ?? DateTime(0);
//                   return dateTimeB.compareTo(dateTimeA);
//                 });
//
//               final latestNote = allNotes.first;
//               final latestVersion = latestNote['version'] ?? "";
//
//               if (latestNote['releaseNotes']?.isNotEmpty ?? false) {
//                 releaseNotes = (latestNote['releaseNotes'] as List).map((note) => DevelopmentNotesModel.fromJson(note)).toList();
//               }
//
//               final needsUpdate = double.tryParse(latestVersion) != null && versionController.currentVersion < double.parse(latestVersion);
//
//               if (needsUpdate) {
//                 showUpdateDialog(context);
//               }
//
//               Logger().e('latest version: $latestVersion');
//
//               return _buildVersionChip(
//                 latestVersion: latestVersion.toString(),
//                 currentVersion: versionController.currentVersion.toString(),
//                 needsUpdate: needsUpdate,
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildVersionChip({
//     bool loading = false,
//     bool error = false,
//     bool empty = false,
//     String latestVersion = '',
//     String currentVersion = '',
//     bool needsUpdate = false,
//   }) {
//     return Container(
//       height: 34,
//       padding: const EdgeInsets.symmetric(horizontal: 10),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: needsUpdate ? [Colors.blue.shade100, Colors.indigo.shade50] : [Colors.blue.shade50, Colors.blue.shade50],
//           begin: Alignment.centerLeft,
//           end: Alignment.centerRight,
//         ),
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(color: needsUpdate ? Colors.blue.shade200 : Colors.blue.shade100),
//         boxShadow: needsUpdate ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.2), blurRadius: 2, offset: const Offset(0, 1))] : null,
//       ),
//       child: loading
//           ? _buildLoadingChip()
//           : error || empty
//               ? _buildErrorChip()
//               : _buildVersionInfoChip(latestVersion, currentVersion, needsUpdate),
//     );
//   }
//
//   Widget _buildLoadingChip() {
//     return const Center(
//       child: SizedBox(
//         height: 14,
//         width: 14,
//         child: CircularProgressIndicator(
//           strokeWidth: 2,
//           color: Colors.blue,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildErrorChip() {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(
//           Icons.info_outline,
//           size: 12,
//           color: Colors.blue.shade700,
//         ),
//         const SizedBox(width: 4),
//         Text(
//           'v?.?',
//           style: TextStyle(
//             fontSize: 15,
//             color: Colors.blue.shade700,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildVersionInfoChip(String latestVersion, String currentVersion, bool needsUpdate) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         // Current version
//         Tooltip(
//           message: 'Current version: v$currentVersion',
//           child: Row(
//             children: [
//               Text(
//                 'v$currentVersion',
//                 style: TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.blue.shade700,
//                 ),
//               ),
//               if (!needsUpdate) ...[
//                 const SizedBox(width: 2),
//                 Icon(
//                   Icons.check_circle,
//                   size: 12,
//                   color: Colors.green.shade500,
//                 ),
//               ],
//             ],
//           ),
//         ),
//         Container(
//           height: 14,
//           width: 1,
//           color: Colors.blue.shade200,
//           margin: const EdgeInsets.symmetric(horizontal: 8),
//         ),
//         // Latest version
//         Tooltip(
//           message: 'Latest version: v$latestVersion',
//           child: Row(
//             children: [
//               Text(
//                 'v$latestVersion',
//                 style: TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w600,
//                   color: needsUpdate ? Colors.indigo.shade700 : Colors.blue.shade700,
//                 ),
//               ),
//               if (needsUpdate) ...[
//                 const SizedBox(width: 4),
//                 Container(
//                   padding: const EdgeInsets.all(2),
//                   decoration: BoxDecoration(
//                     color: Colors.indigo.shade100,
//                     borderRadius: BorderRadius.circular(10),
//                     border: Border.all(color: Colors.indigo.shade200, width: 0.5),
//                   ),
//                   child: Icon(
//                     Icons.arrow_upward_rounded,
//                     size: 8,
//                     color: Colors.indigo.shade600,
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
