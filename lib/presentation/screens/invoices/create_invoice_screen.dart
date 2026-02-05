import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/providers.dart';
import '../../widgets/common/duuka_app_bar.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  final int? customerId;

  const CreateInvoiceScreen({
    super.key,
    this.customerId,
  });

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  int? _selectedCustomerId;
  DateTime? _dueDate;
  double _discount = 0;
  double _discountPercent = 0;
  double _taxAmount = 0;
  final _notesController = TextEditingController();
  final _cartItems = <InvoiceItem>[];

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.customerId;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;

    return Scaffold(
      appBar: DuukaAppBar(
        title: 'Create Invoice',
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: () => _submitInvoice(context, currentUser),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Selection
            _buildSectionTitle('Select Customer'),
            _buildCustomerDropdown(),
            SizedBox(height: 20.h),

            // Due Date
            _buildSectionTitle('Due Date (Optional)'),
            _buildDueDatePicker(),
            SizedBox(height: 20.h),

            // Invoice Items
            _buildSectionTitle('Items'),
            _buildAddItemButton(),
            SizedBox(height: 12.h),
            if (_cartItems.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: Text(
                    'No items added yet',
                    style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                  ),
                ),
              )
            else
              _buildItemsList(),
            SizedBox(height: 20.h),

            // Discount & Tax
            _buildSectionTitle('Discount & Tax'),
            _buildDiscountTaxSection(),
            SizedBox(height: 20.h),

            // Notes
            _buildSectionTitle('Notes (Optional)'),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add any notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // Summary
            _buildSummary(),
            SizedBox(height: 30.h),

            // Submit Button
            if (_cartItems.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _submitInvoice(context, currentUser),
                  child: const Text('Create Invoice'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCustomerDropdown() {
    return ref.watch(customerNotifierProvider).when(
          data: (customers) {
            if (customers.isEmpty) {
              return FilledButton(
                onPressed: () => _showAddCustomerDialog(),
                child: const Text('Add a Customer First'),
              );
            }

            return Column(
              children: [
                DropdownButtonFormField<int>(
                  value: _selectedCustomerId,
                  decoration: InputDecoration(
                    labelText: 'Customer',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  items: customers.map((customer) {
                    return DropdownMenuItem(
                      value: customer.id,
                      child: Text(customer.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCustomerId = value);
                  },
                  hint: const Text('Select customer'),
                ),
                SizedBox(height: 8.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showAddCustomerDialog(),
                    icon: Icon(Icons.person_add, size: 16.sp),
                    label: const Text('Add New Customer'),
                  ),
                ),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Error: $error'),
        );
  }

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final locationController = TextEditingController();
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
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Form(
              key: formKey,
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
                    'Add Customer',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: DuukaColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Name Field
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Customer Name *',
                      hintText: 'e.g., Mukasa John',
                      prefixIcon: Icon(Icons.person_outline, size: 20.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter customer name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Phone Field
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number *',
                      hintText: 'e.g., 0771234567',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter phone number';
                      }
                      if (value.trim().length < 10) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Location Field (Optional)
                  TextFormField(
                    controller: locationController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Location (Optional)',
                      hintText: 'e.g., Kampala, Ntinda',
                      prefixIcon: Icon(Icons.location_on_outlined, size: 20.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
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
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              try {
                                final newCustomer = await ref.read(customerNotifierProvider.notifier).addCustomer(
                                  name: nameController.text.trim(),
                                  phone: phoneController.text.trim(),
                                  location: locationController.text.trim().isEmpty
                                      ? null
                                      : locationController.text.trim(),
                                );
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                if (mounted) {
                                  // Auto-select the newly created customer
                                  if (newCustomer != null) {
                                    setState(() => _selectedCustomerId = newCustomer.id);
                                  }
                                  context.showSuccessSnackBar('Customer added successfully');
                                }
                              } catch (e) {
                                if (mounted) {
                                  context.showErrorSnackBar(e.toString());
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DuukaColors.primary,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                          ),
                          child: Text(
                            'Add Customer',
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
      ),
    );
  }

  Widget _buildDueDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() => _dueDate = date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Due Date',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          _dueDate == null
              ? 'Tap to select'
              : DuukaFormatters.date(_dueDate!),
        ),
      ),
    );
  }

  Widget _buildAddItemButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showAddItemDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  Widget _buildItemsList() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _cartItems.length,
        itemBuilder: (context, index) {
          final item = _cartItems[index];
          return Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              border: index < _cartItems.length - 1
                  ? Border(bottom: BorderSide(color: Colors.grey[300]!))
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.sp),
                      ),
                      Text(
                        '${item.quantity} ${item.unit} x ${DuukaFormatters.currency(item.unitPrice)}',
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  DuukaFormatters.currency(item.total),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() => _cartItems.removeAt(index));
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiscountTaxSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Discount (%)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _discountPercent = double.tryParse(value) ?? 0;
                    _discount = (subtotal * _discountPercent) / 100;
                  });
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Fixed Discount',
                  prefixText: 'UGX ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _discount = double.tryParse(value) ?? 0;
                    _discountPercent = 0;
                  });
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Tax/VAT',
            prefixText: 'UGX ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _taxAmount = double.tryParse(value) ?? 0;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', subtotal),
          if (_discount > 0 || _discountPercent > 0) ...[
            SizedBox(height: 8.h),
            _buildSummaryRow(
              'Discount (${_discountPercent > 0 ? '${_discountPercent.toStringAsFixed(1)}%' : 'Fixed'})',
              -_discount,
            ),
          ],
          if (_taxAmount > 0) ...[
            SizedBox(height: 8.h),
            _buildSummaryRow('Tax/VAT', _taxAmount),
          ],
          Divider(height: 16.h),
          _buildSummaryRow('Total', total, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 14.sp : 12.sp,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          DuukaFormatters.currency(amount),
          style: TextStyle(
            fontSize: isTotal ? 14.sp : 12.sp,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: amount < 0 ? Colors.red : Colors.black,
          ),
        ),
      ],
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(
        onAdd: (item) {
          setState(() => _cartItems.add(item));
        },
      ),
    );
  }

  double get subtotal => _cartItems.fold(0, (sum, item) => sum + item.total);
  double get total => subtotal - _discount + _taxAmount;

  Future<void> _submitInvoice(BuildContext context, AppUser? currentUser) async {
    if (currentUser == null) {
      context.showErrorSnackBar('User not authenticated');
      return;
    }

    if (_selectedCustomerId == null) {
      context.showErrorSnackBar('Please select a customer');
      return;
    }

    if (_cartItems.isEmpty) {
      context.showErrorSnackBar('Please add at least one item');
      return;
    }

    try {
      final customers = ref.read(customerNotifierProvider).value ?? [];
      Customer? customer;
      for (final c in customers) {
        if (c.id == _selectedCustomerId) {
          customer = c;
          break;
        }
      }

      // Generate invoice number
      final invoiceNumber =
          await ref.read(nextInvoiceNumberProvider.future);

      // Create invoice
      final invoice = Invoice.create(
        invoiceNumber: invoiceNumber,
        items: _cartItems,
        subtotal: subtotal,
        total: total,
        customerId: _selectedCustomerId,
        customerName: customer?.name,
        customerPhone: customer?.phone,
        userId: currentUser.id,
        userName: currentUser.name,
        discount: _discount,
        discountPercent: _discountPercent,
        taxAmount: _taxAmount,
        dueAt: _dueDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      await ref.read(invoicesProvider.notifier).create(invoice);

      if (context.mounted) {
        context.showSuccessSnackBar('Invoice created successfully');
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar('Failed to create invoice: $e');
      }
    }
  }
}

class _AddItemDialog extends ConsumerStatefulWidget {
  final Function(InvoiceItem) onAdd;

  const _AddItemDialog({
    required this.onAdd,
  });

  @override
  ConsumerState<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends ConsumerState<_AddItemDialog> {
  Product? _selectedProduct;
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product Dropdown
            ref.watch(productsProvider).when(
                  data: (products) => DropdownButtonFormField<Product>(
                    value: _selectedProduct,
                    decoration: InputDecoration(
                      labelText: 'Product',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    items: products.map((product) {
                      return DropdownMenuItem(
                        value: product,
                        child: Text(product.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProduct = value;
                        if (value != null) {
                          _priceController.text =
                              value.sellPrice.toStringAsFixed(0);
                        }
                      });
                    },
                    hint: const Text('Select product'),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text('Error: $error'),
                ),
            SizedBox(height: 12.h),
            // Quantity
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            // Price
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Unit Price',
                prefixText: 'UGX ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_selectedProduct == null) {
              context.showErrorSnackBar('Select a product');
              return;
            }

            final quantity = double.tryParse(_quantityController.text);
            if (quantity == null || quantity <= 0) {
              context.showErrorSnackBar('Enter valid quantity');
              return;
            }

            final price = double.tryParse(_priceController.text);
            if (price == null || price <= 0) {
              context.showErrorSnackBar('Enter valid price');
              return;
            }

            final item = InvoiceItem.create(
              productId: _selectedProduct!.id,
              productName: _selectedProduct!.name,
              quantity: quantity,
              unitPrice: price,
              costPrice: _selectedProduct!.costPrice,
            );

            widget.onAdd(item);
            context.pop();
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
