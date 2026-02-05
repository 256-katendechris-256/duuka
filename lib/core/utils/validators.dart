class DuukaValidators {
  DuukaValidators._();

  /// Validate Ugandan phone number
  /// Accepts: 772123456, 0772123456, +256772123456, 256772123456
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove all non-digit characters
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Check various formats
    if (cleaned.length == 9) {
      // 772123456
      if (!RegExp(r'^[37][0-9]{8}').hasMatch(cleaned)) {
        return 'Invalid phone number';
      }
    } else if (cleaned.length == 10 && cleaned.startsWith('0')) {
      // 0772123456
      if (!RegExp(r'^0[37][0-9]{8}').hasMatch(cleaned)) {
        return 'Invalid phone number';
      }
    } else if (cleaned.length == 12 && cleaned.startsWith('256')) {
      // 256772123456
      if (!RegExp(r'^256[37][0-9]{8}').hasMatch(cleaned)) {
        return 'Invalid phone number';
      }
    } else {
      return 'Invalid phone number format';
    }

    return null;
  }

  /// Normalize phone to 9 digits (772123456)
  static String normalizePhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.length == 9) {
      return cleaned;
    } else if (cleaned.length == 10 && cleaned.startsWith('0')) {
      return cleaned.substring(1);
    } else if (cleaned.length == 12 && cleaned.startsWith('256')) {
      return cleaned.substring(3);
    }

    return cleaned;
  }

  /// Format phone for authentication (+256XXXXXXXXX)
  static String formatPhoneForAuth(String phone) {
    final normalized = normalizePhone(phone);
    return '+256$normalized';
  }

  /// Validate required field
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate business name
  static String? businessName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Business name is required';
    }
    if (value.trim().length < 2) {
      return 'Business name is too short';
    }
    if (value.trim().length > 50) {
      return 'Business name is too long';
    }
    return null;
  }

  /// Validate person name
  static String? personName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name is too short';
    }
    return null;
  }

  /// Validate price
  static String? price(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }

    final number = double.tryParse(value.replaceAll(',', ''));
    if (number == null) {
      return 'Invalid price';
    }
    if (number < 0) {
      return 'Price cannot be negative';
    }

    return null;
  }

  /// Validate quantity
  static String? quantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Quantity is required';
    }

    final number = int.tryParse(value);
    if (number == null) {
      return 'Invalid quantity';
    }
    if (number < 0) {
      return 'Quantity cannot be negative';
    }

    return null;
  }

  /// Validate email (optional)
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Invalid email address';
    }

    return null;
  }

  /// Validate OTP
  static String? otp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }
    if (!RegExp(r'^[0-9]{6}').hasMatch(value)) {
      return 'OTP must contain only numbers';
    }
    return null;
  }

  /// Validate TIN number (optional)
  static String? tin(String? value) {
    if (value == null || value.isEmpty) {
      return null; // TIN is optional
    }

    // Uganda TIN is typically 10 digits
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length != 10) {
      return 'TIN must be 10 digits';
    }

    return null;
  }
}
