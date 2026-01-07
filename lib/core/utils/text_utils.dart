import 'package:flutter/material.dart';

class TextUtils {
  static bool isArabic(String text) {
    if (text.isEmpty) return false;
    // Regex for Arabic Unicode block
    final RegExp arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
    // Check if the first strong character is Arabic? Or if it contains any?
    // User wants "Most dynamic content... will be Arabic".
    // Usually standard `Bidi` checks the first strong character.
    
    // Simple heuristic: If it starts with Arabic (ignoring non-letters), it's RTL.
    // Or simpler: does it contain Arabic?
    return arabicRegex.hasMatch(text);
  }

  static TextDirection getDirection(String text) {
    return isArabic(text) ? TextDirection.rtl : TextDirection.ltr;
  }
}
