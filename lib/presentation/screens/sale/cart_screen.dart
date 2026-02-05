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
import '../../providers/customer_provider.dart';
import '../../providers/credit_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  PaymentMethod? _selectedPaymentMethod = PaymentMethod.cash;
  bool _isProcessing = false;
  
  // Credit sale fields
  Customer? _selectedCustomer;
  DateTime? _agreedPaymentDate;
  double _initialPayment = 0;
  final _initialPaymentController = TextEditingController();

  @override
  void dispose() {
    _initialPaymentController.dispose();
    super.dispose();
  }

  bool get _isCredit => _selectedPaymentMethod == PaymentMethod.credit;

  Future<void> _handleCompleteSale() async {
    if (_selectedPaymentMethod == null) {
      context.showErrorSnackBar('Please select a payment method');
      return;
    }

    // Validate credit sale requirements
    if (_isCredit) {
      if (_selectedCustomer == null) {
        context.showErrorSnackBar('Please select a customer for credit sale');
        return;
      }
      if (_agreedPaymentDate == null) {
        context.showErrorSnackBar('Please set an agreed payment date');
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      print('🛒 Starting checkout...');
      print('   Payment method: $_selectedPaymentMethod');
      print('   Cart items: ${ref.read(cartProvider).items.length}');
      if (_isCredit) {
        print('   Customer: ${_selectedCustomer?.name}');
        print('   Payment date: $_agreedPaymentDate');
        print('   Initial payment: $_initialPayment');
      }
      
      final sale = await ref.read(cartProvider.notifier).checkout(
            paymentMethod: _selectedPaymentMethod!,
            customerName: _selectedCustomer?.name,
            amountPaid: _isCredit ? _initialPayment : null,
          );

      print('🛒 Checkout result: ${sale != null ? 'Success' : 'Failed'}');
      
      // If credit sale, create credit transaction
      if (sale != null && _isCredit && _selectedCustomer != null) {
        print('📝 Creating credit transaction...');
        await ref.read(creditNotifierProvider.notifier).createCreditSale(
          customerId: _selectedCustomer!.id,
          customerName: _selectedCustomer!.name,
          customerPhone: _selectedCustomer!.phone,
          saleId: sale.id,
          totalAmount: sale.total,
          agreedPaymentDate: _agreedPaymentDate!,
          initialPayment: _initialPayment,
        );
        print('✅ Credit transaction created');
      }

      setState(() => _isProcessing = false);

      if (sale != null && mounted) {
        print('🧾 Navigating to receipt: ${sale.receiptNumber}');
        context.go('/sale/receipt', extra: sale);
      } else if (mounted) {
        print('❌ Checkout returned null');
        context.showErrorSnackBar('Failed to complete sale');
      }
    } catch (e) {
      print('💥 Checkout error: $e');
      setState(() => _isProcessing = false);
      if (mounted) {
        context.showErrorSnackBar('Error: ${e.toString()}');
      }
    }
  }

  void _showCustomerSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomerSelectorSheet(
        onCustomerSelected: (customer) {
          setState(() => _selectedCustomer = customer);
          Navigator.pop(context);
        },
        onAddNew: () {
          Navigator.pop(context);
          _showAddCustomerDialog();
        },
      ),
    );
  }

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: DuukaColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Form(
            key: formKey,
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
                  'Quick Add Customer',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Name *',
                    prefixIcon: Icon(Icons.person_outline, size: 20.sp),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone *',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20.sp),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        try {
                          final customer = await ref.read(customerNotifierProvider.notifier)
                              .addCustomer(
                                name: nameController.text.trim(),
                                phone: phoneController.text.trim(),
                              );
                          if (customer != null && mounted) {
                            setState(() => _selectedCustomer = customer);
                            Navigator.pop(ctx);
                            context.showSuccessSnackBar('Customer added');
                          }
                        } catch (e) {
                          context.showErrorSnackBar(e.toString());
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DuukaColors.primary,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                    child: Text(
                      'Add & Select',
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
      ),
    );
  }

  Future<void> _selectPaymentDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _agreedPaymentDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'When should this be paid?',
    );
    if (date != null) {
      setState(() => _agreedPaymentDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);

    void safeGoBack() {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go('/home');
      }
    }

    if (cartState.isEmpty) {
      return Scaffold(
        appBar: DuukaAppBar(
          title: 'Cart',
          onBackPressed: safeGoBack,
        ),
        body: EmptyState(
          icon: Icons.shopping_cart_outlined,
          title: 'Cart is empty',
          description: 'Add products to start a sale',
          actionLabel: 'Browse Products',
          onAction: safeGoBack,
        ),
      );
    }

    return Scaffold(
      appBar: DuukaAppBar(
        title: 'Cart',
        onBackPressed: safeGoBack,
        actions: [
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clear();
              safeGoBack();
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
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cart Items List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
                        // Reset credit fields when switching methods
                        if (method != PaymentMethod.credit) {
                          _selectedCustomer = null;
                          _agreedPaymentDate = null;
                          _initialPayment = 0;
                          _initialPaymentController.clear();
                        }
                      });
                    },
                  ),

                  // Credit Sale Options
                  if (_isCredit) ...[
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: DuukaColors.warningBg,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: DuukaColors.warning),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber, color: DuukaColors.warning, size: 20.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'Credit Sale Details',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: DuukaColors.warning,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),

                          // Customer Selector
                          InkWell(
                            onTap: _showCustomerSelector,
                            borderRadius: BorderRadius.circular(8.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                color: DuukaColors.surface,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: _selectedCustomer == null
                                      ? DuukaColors.error
                                      : DuukaColors.border,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 20.sp,
                                    color: DuukaColors.textSecondary,
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      _selectedCustomer?.name ?? 'Select Customer *',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: _selectedCustomer != null
                                            ? DuukaColors.textPrimary
                                            : DuukaColors.textHint,
                                      ),
                                    ),
                                  ),
                                  if (_selectedCustomer != null)
                                    Text(
                                      _selectedCustomer!.phone,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: DuukaColors.textSecondary,
                                      ),
                                    ),
                                  SizedBox(width: 8.w),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 20.sp,
                                    color: DuukaColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),

                          // Payment Date
                          InkWell(
                            onTap: _selectPaymentDate,
                            borderRadius: BorderRadius.circular(8.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                color: DuukaColors.surface,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: _agreedPaymentDate == null
                                      ? DuukaColors.error
                                      : DuukaColors.border,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 20.sp,
                                    color: DuukaColors.textSecondary,
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      _agreedPaymentDate != null
                                          ? 'Due: ${DuukaFormatters.date(_agreedPaymentDate!)}'
                                          : 'Set Payment Date *',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: _agreedPaymentDate != null
                                            ? DuukaColors.textPrimary
                                            : DuukaColors.textHint,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 20.sp,
                                    color: DuukaColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),

                          // Initial Payment (Optional)
                          TextFormField(
                            controller: _initialPaymentController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Initial Payment (Optional)',
                              prefixText: 'UGX ',
                              filled: true,
                              fillColor: DuukaColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 10.h,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _initialPayment = double.tryParse(value) ?? 0;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 24.h),

                  // Complete Sale Button
                  DuukaButton.primary(
                    label: _isCredit ? 'Complete Credit Sale' : 'Complete Sale',
                    onPressed: _isProcessing ? null : _handleCompleteSale,
                    isLoading: _isProcessing,
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
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

class _CustomerSelectorSheet extends ConsumerStatefulWidget {
  final Function(Customer) onCustomerSelected;
  final VoidCallback onAddNew;

  const _CustomerSelectorSheet({
    required this.onCustomerSelected,
    required this.onAddNew,
  });

  @override
  ConsumerState<_CustomerSelectorSheet> createState() => _CustomerSelectorSheetState();
}

class _CustomerSelectorSheetState extends ConsumerState<_CustomerSelectorSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerNotifierProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: DuukaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: DuukaColors.border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Customer',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton.icon(
                  onPressed: widget.onAddNew,
                  icon: Icon(Icons.add, size: 18.sp),
                  label: const Text('Add New'),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: Icon(Icons.search, size: 20.sp),
                filled: true,
                fillColor: DuukaColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // List
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                final filtered = _searchQuery.isEmpty
                    ? customers
                    : customers.where((c) =>
                        c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        c.phone.contains(_searchQuery)).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_search, size: 48.sp, color: DuukaColors.textSecondary),
                        SizedBox(height: 12.h),
                        Text(
                          'No customers found',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: DuukaColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        ElevatedButton.icon(
                          onPressed: widget.onAddNew,
                          icon: Icon(Icons.add, size: 18.sp),
                          label: const Text('Add New Customer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DuukaColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final customer = filtered[index];
                    return ListTile(
                      leading: Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: DuukaColors.primaryBg,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Center(
                          child: Text(
                            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: DuukaColors.primary,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        customer.name,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        customer.phone,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: DuukaColors.textSecondary,
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right, size: 20.sp),
                      onTap: () => widget.onCustomerSelected(customer),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
