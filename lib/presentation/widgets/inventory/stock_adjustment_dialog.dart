import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/models.dart';
import '../common/duuka_button.dart';
import '../common/duuka_text_field.dart';
import '../../providers/product_provider.dart';

class StockAdjustmentDialog extends ConsumerStatefulWidget {
  final Product product;

  const StockAdjustmentDialog({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  ConsumerState<StockAdjustmentDialog> createState() =>
      _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends ConsumerState<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isAdding = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _adjustStock() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final quantity = double.parse(_quantityController.text);
      final change = _isAdding ? quantity : -quantity;

      final success = await ref
          .read(productsProvider.notifier)
          .adjustStock(widget.product.id, change, _reasonController.text.trim());

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock adjusted successfully'),
            backgroundColor: DuukaColors.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to adjust stock'),
            backgroundColor: DuukaColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: DuukaColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStock = widget.product.safeStockQuantity.toInt();
    final newQuantity = _quantityController.text.isEmpty
        ? currentStock
        : currentStock +
            (_isAdding ? 1 : -1) * int.parse(_quantityController.text);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Adjust Stock',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: DuukaColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      size: 24.sp,
                      color: DuukaColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              // Product Info
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
                            widget.product.name,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: DuukaColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Current: ${widget.product.formatQuantity(widget.product.safeStockQuantity)}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: DuukaColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Add/Remove Toggle
              Container(
                decoration: BoxDecoration(
                  color: DuukaColors.background,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isAdding = true),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            color: _isAdding
                                ? DuukaColors.success
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                size: 20.sp,
                                color: _isAdding
                                    ? Colors.white
                                    : DuukaColors.textSecondary,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Add Stock',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: _isAdding
                                      ? Colors.white
                                      : DuukaColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isAdding = false),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            color: !_isAdding
                                ? DuukaColors.error
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.remove,
                                size: 20.sp,
                                color: !_isAdding
                                    ? Colors.white
                                    : DuukaColors.textSecondary,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Remove Stock',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: !_isAdding
                                      ? Colors.white
                                      : DuukaColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Quantity Input
              DuukaTextField(
                label: 'Quantity *',
                hint: '0',
                controller: _quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Quantity is required';
                  }
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity <= 0) {
                    return 'Invalid quantity';
                  }
                  if (!_isAdding && quantity > widget.product.safeStockQuantity) {
                    return 'Cannot remove more than current stock';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Reason Input
              DuukaTextField(
                label: 'Reason (Optional)',
                hint: 'e.g., New stock arrival, Damaged items',
                controller: _reasonController,
                maxLines: 2,
              ),
              SizedBox(height: 16.h),

              // Preview
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: DuukaColors.primaryBg,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: DuukaColors.primary, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Stock Level:',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: DuukaColors.primary,
                      ),
                    ),
                    Text(
                      '$newQuantity ${widget.product.unit}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: DuukaColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Save Button
              DuukaButton.primary(
                label: _isLoading ? 'Adjusting...' : 'Confirm Adjustment',
                onPressed: _isLoading ? null : _adjustStock,
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
