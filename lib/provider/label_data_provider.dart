import 'package:flutter/material.dart';

class LabelDataProvider with ChangeNotifier {
  List<Map<String, String>> _labelDataGroups = [];
  bool _isUploading = false;
  bool _isUploadSuccessful = false;
  bool _isLoadingDataGroups = false;

  List<Map<String, String>> get labelDataGroups => _labelDataGroups;
  bool get isUploading => _isUploading;
  bool get isUploadSuccessful => _isUploadSuccessful;
  bool get isLoadingDataGroups => _isLoadingDataGroups;

  void setDataGroups(List<Map<String, String>> newGroups) {
    _labelDataGroups = newGroups;
    _isUploadSuccessful = newGroups.isNotEmpty;
    notifyListeners();
  }

  void setUploading(bool uploading) {
    _isUploading = uploading;
    notifyListeners();
  }

  void reset() {
    _labelDataGroups = [];
    _isUploadSuccessful = false;
    notifyListeners();
  }

  void setLoadingDataGroups(bool value) {
    _isLoadingDataGroups = value;
    notifyListeners();
  }
}
