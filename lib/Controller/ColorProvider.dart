import 'package:flutter/material.dart';

class ColorProvider extends ChangeNotifier {
  Color _selectedColor1 = Colors.blue;
  Color _selectedColor2 = Colors.white;
  Color _selectedColor3 = Colors.red;
  Color _selectedColor4 = Colors.black;

  Color get selectedColor1 => _selectedColor1;
  Color get selectedColor2 => _selectedColor2;
  Color get selectedColor3 => _selectedColor3;
  Color get selectedColor4 => _selectedColor4;


  void setSelectedColors(Color color1, Color color2, Color color3, Color color4) {
    _selectedColor1 = color1;
    _selectedColor2 = color2;
    _selectedColor3 = color3;
    _selectedColor4 = color4;
    notifyListeners();
  }
}
