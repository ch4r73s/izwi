import 'package:flutter/services.dart';

class CapitalizeEachWordFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = _capitalizeEachWord(newValue.text);
    return newValue.copyWith(
      text: newText,
      selection: _updateSelection(newValue, newText),
    );
  }

  String _capitalizeEachWord(String text) {
    return text
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ');
  }

  TextSelection _updateSelection(TextEditingValue newValue, String newText) {
    final selection = newValue.selection;
    final newSelection = selection.copyWith(
      baseOffset: selection.baseOffset,
      extentOffset: selection.extentOffset,
    );
    return newSelection;
  }
}
