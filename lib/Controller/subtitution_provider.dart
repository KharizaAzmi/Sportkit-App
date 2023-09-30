import 'package:flutter/material.dart';

class TerangGelapProvider with ChangeNotifier {
  List<String> activeTerang = [];
  List<String> activeGelap = [];

  // List<String> get activeTerang => _activeTerang;
  // List<String> get activeGelap => _activeGelap;

  void addToActiveTerang(String data) {
    activeTerang.add(data);
    notifyListeners();
  }

  void addToActiveGelap(String data) {
    activeGelap.add(data);
    notifyListeners(); // Beri tahu listener (widget) bahwa data telah berubah
  }

// Metode lain yang Anda butuhkan untuk mengelola data
}
