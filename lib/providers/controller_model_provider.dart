import 'package:flutter/material.dart';

class ControllerModel with ChangeNotifier {
  List<List<dynamic>> _items = [];

  List<List<dynamic>> get items => _items;

  void addItem(String text) {
    final controller = TextEditingController();
    controller.text = text;
    _items.add([text, controller]);
    notifyListeners();
  }

  void updateItem(int index, String newText) {
    if (index >= 0 && index < _items.length) {
      _items[index][0] = newText;
      _items[index][1].text = newText;
      notifyListeners();
    }
  }

  void updateControllerText(int index, String newText) {
    if (index >= 0 && index < _items.length) {
      _items[index][1].text = newText;
      notifyListeners();
    }
  }

  void clearAll() {
    _items.clear();
    notifyListeners();
  }
}
