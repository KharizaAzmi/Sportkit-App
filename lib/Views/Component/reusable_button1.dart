import 'package:flutter/material.dart';

class ReusableButton1 extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final String value;
  final Color backgroundColor;
  final Color textColor;
  final double width;
  final double height;

  const ReusableButton1({
    required this.text,
    required this.onPressed,
    required this.value,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
    this.width = 57, // Nilai default lebar
    this.height = 50, // Nilai default tinggi
  });

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 9.0),
          primary: backgroundColor,
          onPrimary: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                Text(text,
                style: TextStyle(
                  fontSize: 20,
                ),)
              ],
            ),
          ],
        ),
      ),
    );
  }
}

