import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ButtonStatusModel with ChangeNotifier {
  // Gunakan Map untuk menyimpan status tombol untuk setiap ID pertandingan
  Map<String, List<bool>> buttonStatusMap = {};
  Map<String, List<bool>> buttonStatusMap2 = {};

  // Tambahkan metode untuk mengubah status tombol sesuai indeks dan ID pertandingan
  void toggleButton(String id, int index) {
    if (!buttonStatusMap.containsKey(id)) {
      buttonStatusMap[id] = List.generate(
        50, // Ganti dengan panjang yang sesuai
            (index) => false, // Atau sesuaikan dengan nilai awal yang Anda butuhkan
      );
    }

    buttonStatusMap[id]![index] = !buttonStatusMap[id]![index];
    notifyListeners();
  }

  void toggleButton2(String id, int index) {
    if (!buttonStatusMap2.containsKey(id)) {
      buttonStatusMap2[id] = List.generate(
        50, // Ganti dengan panjang yang sesuai
            (index) => false, // Atau sesuaikan dengan nilai awal yang Anda butuhkan
      );
    }

    buttonStatusMap2[id]![index] = !buttonStatusMap2[id]![index];
    notifyListeners();
  }

  void saveButtonStatusToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final buttonStatusJson = buttonStatusMap.map((id, statusList) {
      return MapEntry(id, statusList.map((status) => status ? 1 : 0).toList());
    });
    prefs.setString('buttonStatus', json.encode(buttonStatusJson));
  }

  Future<void> loadButtonStatusFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final buttonStatusJsonString = prefs.getString('buttonStatus');
    if (buttonStatusJsonString != null) {
      final buttonStatusJson = json.decode(buttonStatusJsonString);
      buttonStatusMap = buttonStatusJson.map((id, statusList) {
        return MapEntry(id, statusList.map<int>((status) => status == 1).toList());
      });
      notifyListeners();
    }
  }

}
