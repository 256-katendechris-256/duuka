/// Utility to convert numbers to words (English)
class NumberToWords {
  static const List<String> _ones = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
    'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
    'Seventeen', 'Eighteen', 'Nineteen'
  ];

  static const List<String> _tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
  ];

  static const List<String> _thousands = [
    '', 'Thousand', 'Million', 'Billion', 'Trillion'
  ];

  /// Convert a number to words
  /// Example: 475000 -> "Four Hundred Seventy-Five Thousand"
  static String convert(double amount, {String currency = 'Shillings'}) {
    if (amount == 0) return 'Zero $currency';

    // Round to nearest whole number for currency
    int number = amount.round();

    if (number < 0) {
      return 'Negative ${convert(amount.abs(), currency: currency)}';
    }

    String words = _convertToWords(number);
    return '$words $currency Only';
  }

  static String _convertToWords(int number) {
    if (number == 0) return '';

    if (number < 20) {
      return _ones[number];
    }

    if (number < 100) {
      String result = _tens[number ~/ 10];
      if (number % 10 != 0) {
        result += '-${_ones[number % 10]}';
      }
      return result;
    }

    if (number < 1000) {
      String result = '${_ones[number ~/ 100]} Hundred';
      if (number % 100 != 0) {
        result += ' ${_convertToWords(number % 100)}';
      }
      return result;
    }

    // For larger numbers, process in groups of 3 digits
    String result = '';
    int groupIndex = 0;

    while (number > 0) {
      int group = number % 1000;
      if (group != 0) {
        String groupWords = _convertToWords(group);
        if (_thousands[groupIndex].isNotEmpty) {
          groupWords += ' ${_thousands[groupIndex]}';
        }
        if (result.isNotEmpty) {
          result = '$groupWords $result';
        } else {
          result = groupWords;
        }
      }
      number ~/= 1000;
      groupIndex++;
    }

    return result.trim();
  }

  /// Convert with cents/decimals
  /// Example: 475000.50 -> "Four Hundred Seventy-Five Thousand Shillings and Fifty Cents"
  static String convertWithCents(double amount, {String currency = 'Shillings', String cents = 'Cents'}) {
    if (amount == 0) return 'Zero $currency';

    int wholePart = amount.floor();
    int centsPart = ((amount - wholePart) * 100).round();

    String result = _convertToWords(wholePart);
    if (result.isEmpty) result = 'Zero';
    result += ' $currency';

    if (centsPart > 0) {
      result += ' and ${_convertToWords(centsPart)} $cents';
    }

    return '$result Only';
  }
}
