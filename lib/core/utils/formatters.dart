import 'package:intl/intl.dart';

class DuukaFormatters {
  DuukaFormatters._();

  static final _currencyFormat = NumberFormat('#,###', 'en_US');
  static final _dateFormat = DateFormat('MMM d, yyyy');
  static final _shortDateFormat = DateFormat('MMM d');
  static final _timeFormat = DateFormat('h:mm a');
  static final _dateTimeFormat = DateFormat('MMM d, yyyy • h:mm a');
  static final _receiptDateFormat = DateFormat('dd/MM/yyyy HH:mm');

  /// Format amount as UGX currency
  /// Example: 1234567 -> "UGX 1,234,567"
  static String currency(double amount) {
    return 'UGX ${_currencyFormat.format(amount.round())}';
  }

  /// Format amount without currency symbol
  /// Example: 1234567 -> "1,234,567"
  static String number(double amount) {
    return _currencyFormat.format(amount.round());
  }

  /// Format as short currency (for cards)
  /// Example: 1234567 -> "1.2M"
  static String currencyShort(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.round().toString();
  }

  /// Format as compact number with suffix
  static String compact(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Format date
  static String date(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Format short date
  static String shortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }

  /// Format time
  static String time(DateTime date) {
    return _timeFormat.format(date);
  }

  /// Format date and time
  static String dateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Format for receipt
  static String receiptDate(DateTime date) {
    return _receiptDateFormat.format(date);
  }

  /// Format phone number
  /// Example: 772123456 -> "+256 772 123 456"
  static String phone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length == 9) {
      return '+256 ${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6)}';
    } else if (cleaned.length == 12 && cleaned.startsWith('256')) {
      final number = cleaned.substring(3);
      return '+256 ${number.substring(0, 3)} ${number.substring(3, 6)} ${number.substring(6)}';
    }
    return phone;
  }

  /// Get greeting based on time of day
  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Format relative time
  static String relativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return _dateFormat.format(date);
  }

  /// Format percentage
  static String percentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  /// Format percentage change with sign
  static String percentageChange(double value) {
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(1)}%';
  }

  /// Generate receipt number
  /// Format: DK-YYYYMMDD-XXXX
  static String receiptNumber(int sequence) {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return 'DK-$dateStr-${sequence.toString().padLeft(4, '0')}';
  }

  /// Get initials from name
  static String initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '??';
  }
}
