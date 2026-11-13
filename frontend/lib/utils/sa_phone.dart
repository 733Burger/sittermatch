import 'package:flutter/services.dart';

// Regex for South African phone number formats
final RegExp saPhoneRegex = RegExp(r'^0[1-8][0-9]{8}$');

// Shows a stored number as "063 111 1111". A +27 number is shown in its local 0 form;
// anything that isn't a valid SA number is returned unchanged.
String formatSaPhoneForDisplay(String raw) {
  var digits = SaPhoneInputFormatter.digitsOf(raw);
  if (digits.length == 11 && digits.startsWith('27')) digits = '0${digits.substring(2)}';
  return saPhoneRegex.hasMatch(digits) ? SaPhoneInputFormatter.format(digits) : raw.trim();
}

// Locks the phone field to 10 digits and shows them grouped as "063 111 1111".
class SaPhoneInputFormatter extends TextInputFormatter {
  static const int _maxDigits = 10;
  static final RegExp _nonDigits = RegExp(r'\D');

  static String digitsOf(String text) => text.replaceAll(_nonDigits, '');

  static String format(String text) {
    final digits = digitsOf(text);
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length && i < _maxDigits; i++) {
      if (i == 3 || i == 6) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final oldDigits = digitsOf(oldValue.text);
    var digits = digitsOf(newValue.text);
    final cursor = newValue.selection.end.clamp(0, newValue.text.length);
    var digitsBeforeCursor = digitsOf(newValue.text.substring(0, cursor)).length;

    // Backspacing over a separator space removes the digit before it instead.
    if (digits == oldDigits &&
        newValue.text.length < oldValue.text.length &&
        digitsBeforeCursor > 0) {
      digits = digits.substring(0, digitsBeforeCursor - 1) + digits.substring(digitsBeforeCursor);
      digitsBeforeCursor--;
    }

    if (digits.length > _maxDigits) {
      // Typing into a full number is ignored, a long paste is trimmed to fit.
      if (oldDigits.length >= _maxDigits) return oldValue;
      digits = digits.substring(0, _maxDigits);
    }
    if (digitsBeforeCursor > digits.length) digitsBeforeCursor = digits.length;

    final offset = digitsBeforeCursor + (digitsBeforeCursor > 3 ? 1 : 0) + (digitsBeforeCursor > 6 ? 1 : 0);
    return TextEditingValue(
      text: format(digits),
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
