import 'package:flutter/foundation.dart';

class ButtonStatusModel extends ChangeNotifier {
  List<String> selectedNumbers = [];

  void toggleButton(String angka) {
    if (selectedNumbers.contains(angka)) {
      selectedNumbers.remove(angka);
    } else {
      selectedNumbers.add(angka);
    }
    notifyListeners();
  }
}
