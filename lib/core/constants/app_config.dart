class DuukaConfig {
  DuukaConfig._();

  // App Info
  static const String appName = 'Duuka';
  static const String appVersion = '1.0.0';
  static const String packageName = 'ug.duuka.app';

  // Uganda Settings
  static const String countryCode = '+256';
  static const String currencyCode = 'UGX';
  static const String currencySymbol = 'UGX';
  static const String countryName = 'Uganda';

  // Default Values
  static const int defaultReorderLevel = 5;
  static const int otpLength = 6;
  static const int otpTimeoutSeconds = 60;

  // Pagination
  static const int defaultPageSize = 20;

  // Sync
  static const int maxSyncRetries = 3;
  static const int syncIntervalMinutes = 15;

  // Receipt
  static const String receiptPrefix = 'DK';

  // Free Plan Limits
  static const int freeMaxProducts = 50;
  static const int freeMaxUsers = 1;
  static const int freeHistoryDays = 7;

  // Starter Plan Limits
  static const int starterMaxProducts = 200;
  static const int starterMaxUsers = 2;

  // Business Plan Limits
  static const int businessMaxProducts = -1; // Unlimited
  static const int businessMaxUsers = 5;

  // Categories (default for retail)
  static const List<String> defaultCategories = [
    'Beverages',
    'Food',
    'Cleaning',
    'Personal Care',
    'Electronics',
    'Stationery',
    'Other',
  ];

  // Units
  static const List<String> units = [
    'pcs',
    'kg',
    'g',
    'liters',
    'ml',
    'crates',
    'boxes',
    'packs',
    'dozen',
    'bags',
  ];
}
