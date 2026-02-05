import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import '../../providers/credit_provider.dart';

class RecordPaymentSheet extends ConsumerStatefulWidget {
  final CreditTransaction transaction;

  const RecordPaymentSheet({Key? key, required this.transaction}) : super(key: key);

  @override
  ConsumerState<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<RecordPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = 'Cash';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with remaining balance
    _amountController.text = widget.transaction.balance.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
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
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
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
                  'Record Payment',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: DuukaColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),

                // Transaction Info
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: DuukaColors.background,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.transaction.customerName,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: DuukaColors.textPrimary,
                              ),
                            ),
                            if (widget.transaction.productName != null)
                              Text(
                                widget.transaction.productName!,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: DuukaColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Balance',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: DuukaColors.textSecondary,
                            ),
                          ),
                          Text(
                            DuukaFormatters.currency(widget.transaction.balance),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: DuukaColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // Amount Field
                Text(
                  'Payment Amount',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: DuukaColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    prefixText: 'UGX ',
                    prefixStyle: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: DuukaColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: DuukaColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount';
                    }
                    if (amount > widget.transaction.balance) {
                      return 'Amount exceeds balance';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8.h),

                // Quick amount buttons
                Wrap(
                  spacing: 8.w,
                  children: [
                    _QuickAmountChip(
                      label: 'Full',
                      onTap: () => _amountController.text = 
                          widget.transaction.balance.toStringAsFixed(0),
                    ),
                    _QuickAmountChip(
                      label: 'Half',
                      onTap: () => _amountController.text = 
                          (widget.transaction.balance / 2).toStringAsFixed(0),
                    ),
                    _QuickAmountChip(
                      label: '10K',
                      onTap: () => _amountController.text = '10000',
                    ),
                    _QuickAmountChip(
                      label: '20K',
                      onTap: () => _amountController.text = '20000',
                    ),
                    _QuickAmountChip(
                      label: '50K',
                      onTap: () => _amountController.text = '50000',
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Payment Method
                Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: DuukaColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    _PaymentMethodOption(
                      icon: Icons.payments_outlined,
                      label: 'Cash',
                      isSelected: _paymentMethod == 'Cash',
                      onTap: () => setState(() => _paymentMethod = 'Cash'),
                    ),
                    SizedBox(width: 12.w),
                    _PaymentMethodOption(
                      icon: Icons.phone_android,
                      label: 'Mobile Money',
                      isSelected: _paymentMethod == 'Mobile Money',
                      onTap: () => setState(() => _paymentMethod = 'Mobile Money'),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'e.g., Transaction ID, receipt number...',
                    filled: true,
                    fillColor: DuukaColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          side: BorderSide(color: DuukaColors.border),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _recordPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DuukaColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Record Payment',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _recordPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final amount = double.parse(_amountController.text);
    
    final success = await ref.read(creditNotifierProvider.notifier).recordPayment(
      transactionId: widget.transaction.id,
      amount: amount,
      paymentMethod: _paymentMethod,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context);
      if (success) {
        final isFullPayment = amount >= widget.transaction.balance;
        context.showSuccessSnackBar(
          isFullPayment 
              ? 'Payment recorded! Balance cleared 🎉' 
              : 'Payment of ${DuukaFormatters.currency(amount)} recorded',
        );
      } else {
        context.showErrorSnackBar('Failed to record payment');
      }
    }
  }
}

class _QuickAmountChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAmountChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: DuukaColors.background,
      labelStyle: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: DuukaColors.primary,
      ),
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodOption({
    required this.icon,
    required this.label,
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
          child: Column(
            children: [
              Icon(
                icon,
                size: 24.sp,
                color: isSelected ? DuukaColors.primary : DuukaColors.textSecondary,
              ),
              SizedBox(height: 4.h),
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
