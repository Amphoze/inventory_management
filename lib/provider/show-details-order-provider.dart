import 'package:flutter/material.dart';

class OrderItemProvider with ChangeNotifier {
  List<List<bool>>? orderItemCheckBox;

  // List<List<bool>>? get orderItemCheckBox => orderItemCheckBox;
  void numberOfOrderCheckBox(int row, List<int> count) {
    orderItemCheckBox = List.generate(
        row, (index) => List.generate(count[index], (ind) => false));
    notifyListeners();
  }

  void updateCheckBoxValue(int row, int col) {
    orderItemCheckBox![row][col] = !orderItemCheckBox![row][col];
    notifyListeners();
  }
}
