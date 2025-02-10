import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/stockship_version_control/version_controller.dart';
import 'package:provider/provider.dart';

import 'model/development_notes_model.dart';

class CrmDeveloperNotesDialog extends StatefulWidget {
  const CrmDeveloperNotesDialog({super.key});

  @override
  State<CrmDeveloperNotesDialog> createState() => _CrmDeveloperNotesDialogState();
}

class _CrmDeveloperNotesDialogState extends State<CrmDeveloperNotesDialog> {
  List<DevelopmentNotesModel> developmentNotes = [];
  final TextEditingController noteTitleController = TextEditingController();
  final TextEditingController noteTextController = TextEditingController();
  final TextEditingController notePriorityController = TextEditingController();

  void addDevelopmentNotes() {
    if (noteTitleController.text.isNotEmpty &&
        noteTextController.text.isNotEmpty &&
        notePriorityController.text.isNotEmpty) {
      setState(() {
        developmentNotes.add(DevelopmentNotesModel(
          noteTitle: noteTitleController.text.trim(),
          notesText: noteTextController.text.trim(),
          notePriority: notePriorityController.text.trim(),
        ));
      });

      noteTitleController.clear();
      noteTextController.clear();
      notePriorityController.clear();
      log("Added Development Notes");
      log("Development Notes length: ${developmentNotes.length}");
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Validation Error'),
          content: const Text('Please fill out all fields before adding a note.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VersionController>(
      builder: (context, versionController, child) {
        return Dialog(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            width: MediaQuery.of(context).size.width * 0.4,
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
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputFields(),
                        const SizedBox(height: 24),
                        _buildNotesList(),
                      ],
                    ),
                  ),
                ),
                _buildFooter(versionController),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.update, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Row(
            children: [
              Text(
                'STOCKSHIP',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              Text(
                ' - Update Section',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: noteTitleController,
                hintText: "Note Title",
                prefixIcon: Icons.title,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 150,
              child: _buildTextField(
                controller: notePriorityController,
                hintText: "Priority",
                prefixIcon: Icons.priority_high,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: noteTextController,
          hintText: "Enter your notes here...",
          prefixIcon: Icons.note,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: addDevelopmentNotes,
            icon: const Icon(Icons.add, color: Colors.white,),
            label: const Text('Add Note'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: AppColors.primaryBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryBlue),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildNotesList() {
    if (developmentNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_add, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No notes added yet',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: developmentNotes.length,
      itemBuilder: (context, index) {
        final note = developmentNotes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        note.noteTitle ?? "Unknown",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Priority: ${note.notePriority}',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  note.notesText ?? "Unknown",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter(VersionController versionController) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () {
              if (developmentNotes.isEmpty) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('No Notes'),
                    content: const Text(
                      'Please add at least one development note before publishing.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
                return;
              }
              versionController.addDeveloperReleaseTime(
                datetime: DateTime.now().toString(),
                version: "${versionController.currentVersion + 1}",
                notes: developmentNotes,
              );
              Navigator.pop(context);
            },
            icon: const Icon(Icons.publish, color: Colors.white,),
            label: const Text('Publish Update'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}