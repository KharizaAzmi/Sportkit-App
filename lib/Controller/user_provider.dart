import 'package:flutter/material.dart';

class UserDataProvider extends ChangeNotifier {
  String id = '';

  void setId(String newId) {
    id = newId;
    notifyListeners();
  }
}
