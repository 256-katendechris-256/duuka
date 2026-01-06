import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/models.dart';
import '../../widgets/common/duuka_app_bar.dart';
import '../../widgets/common/duuka_button.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/sale/cart_item_tile.dart';
import '../../widgets/sale/payment_method_selector.dart';
import '../../providers/sale_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  PaymentMethod? _selectedPaymentMethod = PaymentMethod.cash;
  bool _isProcessing = false;

  Future<void> _handleCompleteSale() async {
    if (_selectedPaymentMethod == null) {
      context.showErrorSnackBar('Please select a payment method');
      return;
    }

    setState(() => _isProcessing = true);

    final sale = await ref.read(cartProvider.notifier).checkout(
          paymentMethod: _selectedPaymentMethod!,
        );

    setState(() => _isProcessing = false);

    if (sale != null && mounted) {
      context.go('/receipt', extra: sale);
    } else if (mounted) {
      context.showErrorSnackBar('Failed to complete sale');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);

    if (cartState.isEmpty) {
      return Scaffold(
        appBar: const DuukaAppBar(title: 'Cart'),
        body: EmptyState(
          icon: Icons.shopping_cart_outlined,
          title: 'Cart is empty',
          description: 'Add products to start a sale',
          actionLabel: 'Browse Products',
          onAction: () => context.pop(),
        ),
      );
    }

    return Scaffold(
      appBar: DuukaAppBar(
        title: 'Cart',
        actions: [
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clear();
              context.pop();
            },
            child: Text(
              'Clear',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: DuukaColors.error,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Cart Items List
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              itemCount: cartState.items.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: DuukaColors.divider,
              ),
              itemBuilder: (context, index) {
                final item = cartState.items[index];
                return CartItemTile(
                  item: item,
                  onQuantityChanged: (quantity) {
                    ref
                        .read(cartProvider.notifier)
                        .updateQuantity(item.productId, quantity);
                  },
                  onRemove: () {
                    ref.read(cartProvider.notifier).removeItem(item.productId);
                  },
                );
              },
            ),
          ),

          // Summary Section
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: DuukaColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Summary Rows
                  _SummaryRow(
                    label: 'Subtotal',
                    value: DuukaFormatters.currency(cartState.subtotal),
                  ),
                  if (cartState.discountAmount > 0) ...[
                    SizedBox(height: 8.h),
                    _SummaryRow(
                      label: 'Discount',
                      value: '-${DuukaFormatters.currency(cartState.discountAmount)}',
                      valueColor: DuukaColors.error,
                    ),
                  ],
                  SizedBox(height: 8.h),
                  Divider(color: DuukaColors.divider),
                  SizedBox(height: 8.h),
                  _SummaryRow(
                    label: 'Total',
                    value: DuukaFormatters.currency(cartState.total),
                    isTotal: true,
                  ),
                  SizedBox(height: 24.h),

                  // Payment Method Selector
                  Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: DuukaColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  PaymentMethodSelector(
                    selectedMethod: _selectedPaymentMethod,
                    onMethodSelected: (method) {
                      setState(() {
                        _selectedPaymentMethod = method;
                      });
                    },
                  ),
                  SizedBox(height: 24.h),

                  // Complete Sale Button
                  DuukaButton.primary(
                    label: 'Complete Sale',
                    onPressed: _isProcessing ? null : _handleCompleteSale,
                    isLoading: _isProcessing,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isTotal;

  const _SummaryRow({
    Key? key,
    required this.label,
    required this.value,
    this.valueColor,
    this.isTotal = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18.sp : 15.sp,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: DuukaColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20.sp : 15.sp,
            fontWeight: FontWeight.w700,
            color: valueColor ?? (isTotal ? DuukaColors.primary : DuukaColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
