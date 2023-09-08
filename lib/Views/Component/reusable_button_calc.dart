import 'package:flutter/material.dart';

class ReusableButton extends StatelessWidget {
  final String text1;
  final String text2;
  final VoidCallback onPressed;
  final String value;
  final Color backgroundColor;
  final Color textColor;
  final double width;
  // final double height;

  const ReusableButton({
    required this.text1,
    required this.text2,
    required this.onPressed,
    required this.value,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
    this.width = 0, // Nilai default lebar
    // this.height, // Nilai default tinggi
  });

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      // width: width,
      // height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 9.0, vertical: 7.0), // Sesuaikan padding sesuai kebutuhan
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
                Text(text1,
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
                // SizedBox(height: 8), // Jarak antara teks pertama dan kedua
                Text(text2,
                  style: TextStyle(
                    fontSize: 8,
                  ),
                ),
                SizedBox(height: 5)
              ],
            ),
          ],
        ),
      ),
    );
  }
}

