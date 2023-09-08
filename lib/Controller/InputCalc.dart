import 'package:get/get.dart';

class InputController extends GetxController {
  final inputText = ''.obs;

  void updateInputText(String newText) {
    inputText.value = newText;
  }
}