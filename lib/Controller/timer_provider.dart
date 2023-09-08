import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimerProvider with ChangeNotifier {
  late Timer _timer;
  bool _isActive = false;
  int _totalSeconds = 0; // Total waktu dalam detik
  int _remainingSeconds = 0; // Waktu sisa dalam detik

  bool get isActive => _isActive;
  int get remainingSeconds => _remainingSeconds;

  void startTimer(int minutes) {
    if (!_isActive) {
      // Hanya mulai timer jika tidak sedang aktif
      _totalSeconds = minutes * 60; // Konversi menit ke detik
      _remainingSeconds = _totalSeconds;
      _isActive = true;

      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_remainingSeconds == 0) {
          stopTimer();
        } else {
          _remainingSeconds--;
          notifyListeners();
        }
      });
    }
  }

  void pauseTimer() {
    if (_isActive) {
      _timer.cancel();
      _isActive = false;
    }
    notifyListeners();
  }

  void stopTimer() {
    if (_isActive) {
      _timer.cancel();
      _isActive = false;
    }
    _remainingSeconds = 0;
    notifyListeners();
  }

  void resumeTimer() {

  }

}
