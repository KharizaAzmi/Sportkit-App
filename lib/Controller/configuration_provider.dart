import 'dart:core';

import 'package:dialogflow_grpc/generated/google/type/datetime.pb.dart';
import 'package:flutter/material.dart';

class ConfigurationDataProvider extends ChangeNotifier {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _jerseyController = TextEditingController();
  TextEditingController _colorsController = TextEditingController();
  TextEditingController _nameController2 = TextEditingController();
  TextEditingController _jerseyController2 = TextEditingController();
  TextEditingController _colorsController2 = TextEditingController();
  TextEditingController _quarterController = TextEditingController();
  TextEditingController _periodtimesController = TextEditingController();
  TextEditingController _timesController = TextEditingController();
  TextEditingController _matchController = TextEditingController();
  TextEditingController _venueController = TextEditingController();
  int quarters = 4;
  int period = 10;
  int overtime = 5;
  String MatchTitle = '';
  DateTime tanggal = DateTime();
  DateTime jam = DateTime();
  String terang = '';


  // void setId(String newId) {
  //   id = newId;
  //   notifyListeners();
  // }

  void setQuarters(int newQuarters) {
    quarters = newQuarters;
    notifyListeners();
  }

  void setPeriod(int newPeriod) {
    period = newPeriod;
    notifyListeners();
  }

  void setOvertime(int newOvertime) {
    period = newOvertime;
    notifyListeners();
  }

  void setMatchTitle(String newMatchTitle) {
    MatchTitle = newMatchTitle;
    notifyListeners();
  }

  void setTanggal(DateTime newTanggal) {
    tanggal = newTanggal;
    notifyListeners();
  }

  void setJam(DateTime newJam) {
    jam = newJam;
    notifyListeners();
  }

  void updateName(String newName) {
    _nameController.text = newName;
    notifyListeners();
  }

  Map<String, dynamic> get configurationData => {
    'terang' : terang,
  };

}