class DevelopmentNotesModel {
  final String? noteTitle;
  final String? notesText;
  final String? notePriority;

  DevelopmentNotesModel({
    this.noteTitle,
    this.notesText,
    this.notePriority,
  });

  // Convert a DevelopmentNotesModel into a map (for Firebase)
  Map<String, dynamic> toJson() {
    return {
      'noteTitle': noteTitle,
      'notesText': notesText,
      'notePriority': notePriority,
    };
  }

  // Create a DevelopmentNotesModel from a map (when retrieving data from Firebase)
  factory DevelopmentNotesModel.fromJson(Map<String, dynamic> json) {
    return DevelopmentNotesModel(
      noteTitle: json['noteTitle'],
      notesText: json['notesText'],
      notePriority: json['notePriority'],
    );
  }
}
