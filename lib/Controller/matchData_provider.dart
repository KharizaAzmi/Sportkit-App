import 'package:flutter/material.dart';
import 'package:sportkit_statistik/Models/data_pertandingan.dart';

class MatchDataProvider with ChangeNotifier {
  MatchData? matchData;

  MatchData? get _matchData => matchData;

  void setMatchData(MatchData _matchData) {
    matchData = _matchData;
    notifyListeners();
  }
}