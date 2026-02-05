import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/common/duuka_app_bar.dart';
import '../../widgets/common/empty_state.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expenseNotifierProvider);
    final todayTotalAsync = ref.watch(todayExpenseTotalProvider);
    final monthTotalAsync = ref.watch(monthExpenseTotalProvider);

    return Scaffold(
      backgroundColor: DuukaColors.background,
      appBar: DuukaAppBar(
        title: 'Expenses',
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            margin: EdgeInsets.all(16.w),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DuukaColors.error,
                  DuukaColors.error.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                Text(
                  'This Month',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 4.h),
                monthTotalAsync.when(
                  data: (total) => Text(
                    DuukaFormatters.currency(total),
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  loading: () => const CircularProgressIndicator(color: Colors.white),
                  error: (_, __) => Text(
                    'UGX 0',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.today, size: 16.sp, color: Colors.white70),
                    SizedBox(width: 4.w),
                    Text(
                      'Today: ',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white70,
                      ),
                    ),
                    todayTotalAsync.when(
                      data: (total) => Text(
                        DuukaFormatters.currency(total),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      loading: () => SizedBox(
                        width: 60.w,
                        child: LinearProgressIndicator(color: Colors.white),
                      ),
                      error: (_, __) => Text(
                        'UGX 0',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: DuukaColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: DuukaColors.primary,
              unselectedLabelColor: DuukaColors.textSecondary,
              indicatorColor: DuukaColors.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'This Month'),
                Tab(text: 'Today'),
              ],
            ),
          ),

          // Expenses List
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                final now = DateTime.now();
                final todayStart = DateTime(now.year, now.month, now.day);
                final monthStart = DateTime(now.year, now.month, 1);

                final todayExpenses = expenses.where((e) => e.date.isAfter(todayStart)).toList();
                final monthExpenses = expenses.where((e) => e.date.isAfter(monthStart)).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildExpenseList(expenses),
                    _buildExpenseList(monthExpenses),
                    _buildExpenseList(todayExpenses),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseDialog(),
        backgroundColor: DuukaColors.primary,
        icon: Icon(Icons.add, color: Colors.white, size: 24.sp),
        label: Text(
          'Add Expense',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseList(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No expenses recorded',
        description: 'Tap + to add an expense',
        actionLabel: 'Add Expense',
        onAction: () => _showAddExpenseDialog(),
      );
    }

    // Group by date
    final grouped = <String, List<Expense>>{};
    for (final expense in expenses) {
      final key = _getDateKey(expense.date);
      grouped.putIfAbsent(key, () => []).add(expense);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(expenseNotifierProvider.notifier).loadExpenses();
      },
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: 80.h),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final dateKey = grouped.keys.elementAt(index);
          final dateExpenses = grouped[dateKey]!;
          final dateTotal = dateExpenses.fold<double>(0, (sum, e) => sum + e.amount);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                color: DuukaColors.background,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateKey,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: DuukaColors.textPrimary,
                      ),
                    ),
                    Text(
                      DuukaFormatters.currency(dateTotal),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: DuukaColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              // Expenses for this date
              ...dateExpenses.map((expense) => _ExpenseListTile(
                    expense: expense,
                    onTap: () => _showExpenseDetails(expense),
                    onDelete: () => _deleteExpense(expense),
                  )),
            ],
          );
        },
      ),
    );
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final expenseDate = DateTime(date.year, date.month, date.day);

    if (expenseDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (expenseDate.isAtSameMomentAs(yesterday)) {
      return 'Yesterday';
    } else {
      return DuukaFormatters.date(date);
    }
  }

  void _showAddExpenseDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddExpenseSheet(
        onSave: (expense) async {
          Navigator.pop(context);
          final result = await ref.read(expenseNotifierProvider.notifier).addExpense(
                description: expense.description,
                amount: expense.amount,
                category: expense.category,
                date: expense.date,
                notes: expense.notes,
                vendor: expense.vendor,
                paymentMethod: expense.paymentMethod,
              );
          if (result != null && mounted) {
            context.showSuccessSnackBar('Expense added');
          }
        },
      ),
    );
  }

  void _showExpenseDetails(Expense expense) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: DuukaColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: DuukaColors.border,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: DuukaColors.errorBg,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Text(
                      Expense.getCategoryIcon(expense.category),
                      style: TextStyle(fontSize: 24.sp),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: DuukaColors.textPrimary,
                        ),
                      ),
                      Text(
                        expense.categoryName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: DuukaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  DuukaFormatters.currency(expense.amount),
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: DuukaColors.error,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            _DetailRow(icon: Icons.calendar_today, label: 'Date', value: DuukaFormatters.date(expense.date)),
            if (expense.vendor != null)
              _DetailRow(icon: Icons.store, label: 'Vendor', value: expense.vendor!),
            _DetailRow(icon: Icons.payment, label: 'Payment', value: expense.paymentMethod),
            if (expense.notes != null && expense.notes!.isNotEmpty)
              _DetailRow(icon: Icons.notes, label: 'Notes', value: expense.notes!),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteExpense(expense);
                    },
                    icon: Icon(Icons.delete_outline, size: 20.sp),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DuukaColors.error,
                      side: BorderSide(color: DuukaColors.error),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Delete "${expense.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: DuukaColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(expenseNotifierProvider.notifier).deleteExpense(expense.id);
      if (success && mounted) {
        context.showSuccessSnackBar('Expense deleted');
      }
    }
  }
}

class _ExpenseListTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ExpenseListTile({
    required this.expense,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: DuukaColors.surface,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            // Category Icon
            Container(
              width: 44.w,
              height: 44.h,
              decoration: BoxDecoration(
                color: DuukaColors.errorBg,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Center(
                child: Text(
                  Expense.getCategoryIcon(expense.category),
                  style: TextStyle(fontSize: 20.sp),
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: DuukaColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: DuukaColors.background,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          expense.categoryName,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: DuukaColors.textSecondary,
                          ),
                        ),
                      ),
                      if (expense.vendor != null) ...[
                        SizedBox(width: 8.w),
                        Text(
                          expense.vendor!,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: DuukaColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Amount
            Text(
              DuukaFormatters.currency(expense.amount),
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: DuukaColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: DuukaColors.textSecondary),
          SizedBox(width: 12.w),
          SizedBox(
            width: 80.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: DuukaColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: DuukaColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddExpenseSheet extends StatefulWidget {
  final Function(Expense) onSave;

  const _AddExpenseSheet({required this.onSave});

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _vendorController = TextEditingController();
  final _notesController = TextEditingController();
  
  ExpenseCategory _category = ExpenseCategory.other;
  DateTime _date = DateTime.now();
  String _paymentMethod = 'Cash';

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _vendorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: DuukaColors.border,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Add Expense',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: DuukaColors.textPrimary,
                ),
              ),
              SizedBox(height: 20.h),

              // Description
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  hintText: 'e.g., Electricity bill',
                  prefixIcon: Icon(Icons.description, size: 20.sp),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              SizedBox(height: 16.h),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount *',
                  prefixText: 'UGX ',
                  prefixIcon: Icon(Icons.payments, size: 20.sp),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                validator: (v) {
                  if (v?.isEmpty == true) return 'Required';
                  if (double.tryParse(v!) == null) return 'Invalid amount';
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Category
              Text(
                'Category',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: DuukaColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: ExpenseCategory.values.map((cat) {
                  final isSelected = _category == cat;
                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(Expense.getCategoryIcon(cat)),
                        SizedBox(width: 4.w),
                        Text(_getCategoryName(cat)),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _category = cat),
                    backgroundColor: DuukaColors.surface,
                    selectedColor: DuukaColors.primaryBg,
                    labelStyle: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? DuukaColors.primary : DuukaColors.textSecondary,
                    ),
                    side: BorderSide(
                      color: isSelected ? DuukaColors.primary : DuukaColors.border,
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 16.h),

              // Date
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _date = date);
                },
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: DuukaColors.border),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 20.sp, color: DuukaColors.textSecondary),
                      SizedBox(width: 12.w),
                      Text(
                        DuukaFormatters.date(_date),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: DuukaColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Vendor (Optional)
              TextFormField(
                controller: _vendorController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Vendor (Optional)',
                  hintText: 'e.g., Umeme',
                  prefixIcon: Icon(Icons.store, size: 20.sp),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Payment Method
              Row(
                children: [
                  _PaymentChip(
                    label: 'Cash',
                    icon: Icons.payments,
                    isSelected: _paymentMethod == 'Cash',
                    onTap: () => setState(() => _paymentMethod = 'Cash'),
                  ),
                  SizedBox(width: 12.w),
                  _PaymentChip(
                    label: 'Mobile Money',
                    icon: Icons.phone_android,
                    isSelected: _paymentMethod == 'Mobile Money',
                    onTap: () => setState(() => _paymentMethod = 'Mobile Money'),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  prefixIcon: Icon(Icons.notes, size: 20.sp),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final expense = Expense.create(
                        description: _descriptionController.text.trim(),
                        amount: double.parse(_amountController.text),
                        category: _category,
                        date: _date,
                        vendor: _vendorController.text.trim().isEmpty
                            ? null
                            : _vendorController.text.trim(),
                        paymentMethod: _paymentMethod,
                        notes: _notesController.text.trim().isEmpty
                            ? null
                            : _notesController.text.trim(),
                      );
                      widget.onSave(expense);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DuukaColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  child: Text(
                    'Save Expense',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryName(ExpenseCategory cat) {
    switch (cat) {
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
        return 'Taxes';
      case ExpenseCategory.other:
        return 'Other';
    }
  }
}

class _PaymentChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? DuukaColors.primaryBg : DuukaColors.background,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? DuukaColors.primary : DuukaColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18.sp,
                color: isSelected ? DuukaColors.primary : DuukaColors.textSecondary,
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? DuukaColors.primary : DuukaColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
