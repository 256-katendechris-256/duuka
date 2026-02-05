import 'package:isar/isar.dart';
import 'product.dart' show SyncStatus;

part 'expense.g.dart';

/// Expense categories
enum ExpenseCategory {
  rent,
  utilities,
  salaries,
  transport,
  supplies,
  maintenance,
  marketing,
  taxes,
  other,
}

@collection
class Expense {
  Id id = Isar.autoIncrement;

  /// Expense description/title
  @Index()
  late String description;

  /// Amount spent
  late double amount;

  /// Expense category
  @Enumerated(EnumType.name)
  late ExpenseCategory category;

  /// Date of expense
  @Index()
  late DateTime date;

  /// Optional notes
  String? notes;

  /// Receipt photo path (optional)
  String? receiptPath;

  /// Payment method used
  String paymentMethod = 'Cash';

  /// Vendor/Payee name
  String? vendor;

  /// Is this a recurring expense?
  bool isRecurring = false;

  /// Created timestamp
  late DateTime createdAt;

  /// Remote ID for sync
  String? remoteId;

  /// Sync status
  @Enumerated(EnumType.name)
  SyncStatus syncStatus = SyncStatus.pending;

  Expense();

  Expense.create({
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
    this.receiptPath,
    this.paymentMethod = 'Cash',
    this.vendor,
    this.isRecurring = false,
  }) : createdAt = DateTime.now();

  /// Get category display name
  String get categoryName {
    switch (category) {
      case ExpenseCategory.rent:
        return 'Rent';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.salaries:
        return 'Salaries';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.supplies:
        return 'Supplies';
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.marketing:
        return 'Marketing';
      case ExpenseCategory.taxes:
        return 'Taxes & Fees';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  /// Get category icon
  static String getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.rent:
        return '🏠';
      case ExpenseCategory.utilities:
        return '💡';
      case ExpenseCategory.salaries:
        return '👥';
      case ExpenseCategory.transport:
        return '🚗';
      case ExpenseCategory.supplies:
        return '📦';
      case ExpenseCategory.maintenance:
        return '🔧';
      case ExpenseCategory.marketing:
        return '📢';
      case ExpenseCategory.taxes:
        return '📋';
      case ExpenseCategory.other:
        return '💰';
    }
  }

  @override
  String toString() => 'Expense(id: $id, description: $description, amount: $amount)';
}
