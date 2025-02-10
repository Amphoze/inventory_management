import 'package:flutter/material.dart';
import 'package:inventory_management/stockship_version_control/version_controller.dart';
import 'package:provider/provider.dart';

import '../Custom-Files/colors.dart';
import 'model/development_notes_model.dart';

class CrmUpdateVersionDialog extends StatefulWidget {
  final List<DevelopmentNotesModel> devNotes;

  const CrmUpdateVersionDialog({super.key, required this.devNotes});

  @override
  State<CrmUpdateVersionDialog> createState() => _CrmUpdateVersionDialogState();
}

class _CrmUpdateVersionDialogState extends State<CrmUpdateVersionDialog> with SingleTickerProviderStateMixin {
  bool showNewFeatures = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // String latestVersion = "2.0.0"; // Replace with actual version

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: FadeTransition(
        opacity: _animation,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.4,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: showNewFeatures ? _buildFeaturesView() : _buildUpdateView(),
        ),
      ),
    );
  }

  Widget _buildUpdateView() {
    final currentVersion = context.read<VersionController>().currentVersion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader("New Update Available", Icons.system_update, AppColors.primaryBlue),
        const SizedBox(height: 24),
        Text(
          'Version $currentVersion is now available',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'This update includes new features, bug fixes, and performance improvements. Please update the software to continue using it.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        _buildKeyboardShortcut(),
        const Spacer(),
        _buildDivider(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // TextButton(
            //   onPressed: () => Navigator.pop(context),
            //   child: const Text('Remind me later'),
            // ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => showNewFeatures = true);
                _controller.reset();
                _controller.forward();
              },
              icon: const Icon(
                Icons.new_releases_outlined,
                color: Colors.white,
              ),
              label: const Text("What's New"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeaturesView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('What\'s New', Icons.new_releases_outlined, Colors.white),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            itemCount: widget.devNotes.length,
            itemBuilder: (context, index) {
              final devNote = widget.devNotes[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getFeatureIcon(devNote.noteTitle ?? ""),
                          size: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            devNote.noteTitle ?? "Unknown",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      devNote.notesText ?? "Unknown",
                      style: TextStyle(
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        _buildDivider(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() => showNewFeatures = false);
                _controller.reset();
                _controller.forward();
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
            // ElevatedButton.icon(
            //   onPressed: () {
            //     // Implement update functionality
            //   },
            //   icon: const Icon(
            //     Icons.download,
            //     color: Colors.white,
            //   ),
            //   label: const Text('Update Now'),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Theme.of(context).primaryColor,
            //     foregroundColor: Colors.white,
            //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(8),
            //     ),
            //   ),
            // ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          // size: 32,
          color: color,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            // color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildKeyboardShortcut() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Keyboard Shortcut',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildKeyButton('Ctrl'),
              _buildPlusIcon(),
              _buildKeyButton('Shift'),
              _buildPlusIcon(),
              _buildKeyButton('R'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildPlusIcon() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(Icons.add, size: 20, color: Colors.grey[600]),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey[300], thickness: 1);
  }

  IconData _getFeatureIcon(String title) {
    // Add more cases based on your common note titles
    final lowercaseTitle = title.toLowerCase();
    if (lowercaseTitle.contains('fix')) return Icons.bug_report;
    if (lowercaseTitle.contains('new')) return Icons.star;
    if (lowercaseTitle.contains('improve')) return Icons.trending_up;
    if (lowercaseTitle.contains('update')) return Icons.update;
    return Icons.check_circle;
  }
}
