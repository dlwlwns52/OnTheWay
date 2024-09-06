import 'package:flutter/material.dart';

class Grade {
  final double value;
  final String letter;
  final Color color;
  final Color color2;
  final Border border;
  final String letterProfile;

  Grade(this.value)
      : letter = _convertGradeToLetter(value),
        color = _getColor(value),
        color2 = _getColor2(value),
        border = _getBorder(value),
        letterProfile = _convertGradeToLetterProfile(value);

  static String _convertGradeToLetter(double grade) {
    if (grade >= 4.2) return 'A+';
    if (grade >= 4.0) return 'A   ';
    if (grade >= 3.5) return 'B+';
    if (grade >= 3.0) return 'B   ';
    if (grade >= 2.5) return 'C+';
    if (grade >= 2.0) return 'C   ';
    if (grade >= 1.5) return 'D+';
    if (grade >= 1.0) return 'D   ';
    if (grade >= 0.0) return 'F   ';
    return 'F   ';
  }

  static String _convertGradeToLetterProfile(double grade) {
    if (grade >= 4.2) return 'A+';
    if (grade >= 4.0) return 'A';
    if (grade >= 3.5) return 'B+';
    if (grade >= 3.0) return 'B';
    if (grade >= 2.5) return 'C+';
    if (grade >= 2.0) return 'C';
    if (grade >= 1.5) return 'D+';
    if (grade >= 1.0) return 'D';
    if (grade >= 0.0) return 'F';
    return 'F   ';
  }

  static Color _getColor(double grade) {
    // if (grade >= 4.2) return Color(0xffdeca3a);
    // if (grade >= 4.0) return Color(0xFF000000);
    // if (grade >= 3.5) return Colors.indigo;
    // if (grade >= 3.0) return Colors.indigoAccent;
    // if (grade >= 2.5) return Colors.purple.shade500;
    // if (grade >= 2.0) return Colors.purple.shade300;
    // if (grade >= 1.5) return Colors.red.shade500;
    // if (grade >= 1.0) return Colors.red.shade300;
    if (1 > grade && grade >= 0.0 ) return Colors.grey;
    return Color(0xFF000000);
  }

  static Color _getColor2(double grade) {
    if (grade >= 4.2) return Color(0xffe0b531); // Gold
    if (grade >= 4.0) return Color(0xffe8bd50); // Silver
    if (grade >= 3.5) return Color(0xFF1D4786); // Indigo
    if (grade >= 3.0) return Colors.indigo; // Indigo Accent
    if (grade >= 2.5) return Colors.purple.shade300; // Purple
    if (grade >= 2.0) return Colors.purple.shade200; // Light Purple
    if (grade >= 1.5) return Colors.red.shade400; // Dark Red
    if (grade >= 1.0) return Colors.red.shade200; // Light Red
    if (grade >= 0.0) return Colors.grey; // Grey for grades >= 0.0 and < 1.0
    return Colors.red; // Default Red
  }



  static Border _getBorder(double grade) {
    // Color(0xffe8ca72)
    if (grade >= 4.2) return Border.all(color: Color(0xffe8bd50), width: 3); // Gold
    if (grade >= 4.0) return Border.all(color: Color(0xffe8ca72), width: 3); // Silver
    if (grade >= 3.5) return Border.all(color: Color(0xFF1D4786), width: 3); // Indigo
    if (grade >= 3.0) return Border.all(color: Colors.indigo.shade300, width: 3); // Indigo Accent
    if (grade >= 2.5) return Border.all(color: Colors.purple.shade300, width: 2); // Purple
    if (grade >= 2.0) return Border.all(color: Colors.purple.shade200, width: 2); // Light Purple
    if (grade >= 1.5) return Border.all(color: Colors.red.shade400, width: 2); // Dark Red
    if (grade >= 1.0) return Border.all(color: Colors.red.shade200, width: 2); // Light Red
    if (grade >= 0.0) return Border.all(color: Colors.grey, width: 2); // Light Red
    return Border.all(color: Colors.red, width: 2); // Default Red
  }
}
