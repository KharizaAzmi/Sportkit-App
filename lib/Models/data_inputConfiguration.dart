import 'package:flutter/material.dart';

class ConfigurationModel extends ChangeNotifier {
  //TextEditingController periodtimesController = TextEditingController();
  //int inputValue = 0;
  String name1 = '';
  String jersey1 = '';
  String name2 = '';
  String jersey2 = '';
  String colors = '';
  String colors2 = '';
  int time = 0;

  void updateStart(int newTime) {
    time = newTime;
    notifyListeners();
  }

  void updateData(String newName, String newJersey, String newColors, String newName2, String newJersey2, String newColors2, int newTime) {
    name1 = newName;
    jersey1 = newJersey;
    name1 = newName2;
    jersey1 = newJersey2;
    colors = newColors;
    colors2 = newColors2;
    time = newTime;
    //time = newTime;
    notifyListeners();
  }

  Map<String, dynamic> get configurationData => {
    'name1': name1,
    'jersey1': jersey1,
    'name2': name2,
    'jersey2': jersey2,
    'colors': colors,
    'colors2': colors2,
    'periods': time,
  };

  get configurationTime => {
    'time': time,
  };

}


