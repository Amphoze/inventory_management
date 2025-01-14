import 'package:flutter/material.dart';

class ProductProvider with ChangeNotifier {
    // Other properties and methods...

    List<TextEditingController> alertBoxKeyEditingController = [];
    List<TextEditingController> alertBoxPairEditingController = [];
    int alertBoxFieldCount = 0;

    void removeTextEditingControllerInAlertBox(int index) {
        if (index >= 0 && index < alertBoxKeyEditingController.length) {
            alertBoxKeyEditingController.removeAt(index);
            alertBoxPairEditingController.removeAt(index);
            alertBoxFieldCount--; // Decrease the count
            notifyListeners(); // Notify listeners to update the UI
        }
    }
}
