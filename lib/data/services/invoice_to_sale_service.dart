import 'package:isar/isar.dart';
import '../datasources/local/database_service.dart';
import '../models/models.dart';

class InvoiceToSaleService {
  final Isar _isar = DatabaseService.instance;

  /// Convert a paid invoice to a Sale record
  /// This deducts stock and creates a permanent record
  Future<Sale> convertInvoiceToSale(Invoice invoice) async {
    try {
      if (!invoice.isPaid) {
        throw Exception('Invoice must be fully paid before conversion');
      }

      // Create sale items from invoice items
      final saleItems = invoice.items.map((invItem) {
        return SaleItem()
          ..productId = invItem.productId
          ..productName = invItem.productName
          ..quantity = invItem.quantity
          ..unitPrice = invItem.unitPrice
          ..costPrice = invItem.costPrice
          ..total = invItem.total
          ..unit = invItem.unit
          ..isMeasurable = invItem.isMeasurable
          ..specifications = invItem.specifications
              .map((spec) => SaleItemSpecification.create(
                    name: spec.name,
                    value: spec.value,
                  ))
              .toList();
      }).toList();

      // Create sale record
      final sale = Sale()
        ..receiptNumber = 'INV-${invoice.invoiceNumber}' // Link to invoice
        ..items = saleItems
        ..subtotal = invoice.subtotal
        ..discount = invoice.discount
        ..discountPercent = invoice.discountPercent
        ..total = invoice.total
        ..paymentMethod = _getPaymentMethod(invoice.payments)
        ..paymentStatus = PaymentStatus.paid
        ..amountPaid = invoice.amountPaid
        ..balance = 0
        ..customerId = invoice.customerId
        ..customerName = invoice.customerName
        ..userId = invoice.userId
        ..userName = invoice.userName
        ..notes = invoice.notes
        ..syncStatus = SyncStatus.pending
        ..createdAt = DateTime.now();

      // Save sale in transaction
      await _isar.writeTxn(() async {
        await _isar.sales.put(sale);

        // Update invoice with sale reference
        invoice.saleId = sale.id;
        invoice.convertedToSaleAt = DateTime.now();
        invoice.syncStatus = SyncStatus.pending;
        await _isar.invoices.put(invoice);

        // Deduct stock for each item
        for (final item in saleItems) {
          final product = await _isar.products.get(item.productId);
          if (product != null) {
            product.stockQuantity -= item.quantity;
            product.syncStatus = SyncStatus.pending;
            await _isar.products.put(product);
          }
        }
      });

      return sale;
    } catch (e) {
      throw Exception('Failed to convert invoice to sale: $e');
    }
  }

  /// Get payment method from invoice payments (most common one)
  PaymentMethod _getPaymentMethod(List<InvoicePayment> payments) {
    if (payments.isEmpty) return PaymentMethod.cash;

    // Count each method
    int cashCount = 0;
    int mobileCount = 0;
    int bankCount = 0;

    for (final payment in payments) {
      switch (payment.method) {
        case InvoicePaymentMethod.cash:
          cashCount++;
          break;
        case InvoicePaymentMethod.mobileMoney:
          mobileCount++;
          break;
        case InvoicePaymentMethod.bankTransfer:
          bankCount++;
          break;
        case InvoicePaymentMethod.other:
          break;
      }
    }

    // Return the most used method
    if (mobileCount > cashCount && mobileCount > bankCount) {
      return PaymentMethod.mobileMoney;
    } else if (bankCount > cashCount) {
      return PaymentMethod.mobileMoney; // Treat bank as mobile money
    }
    return PaymentMethod.cash;
  }

  /// Get unpaid invoices that are overdue
  Future<List<Invoice>> getOverdueInvoices(int userId) async {
    try {
      final now = DateTime.now();
      return await _isar.invoices
          .filter()
          .userIdEqualTo(userId)
          .and()
          .group((q) => q
              .statusEqualTo(InvoiceStatus.sent)
              .or()
              .statusEqualTo(InvoiceStatus.partial))
          .and()
          .dueAtLessThan(now)
          .findAll();
    } catch (e) {
      throw Exception('Failed to get overdue invoices: $e');
    }
  }

  /// Auto-mark overdue invoices
  Future<void> markOverdueInvoices(int userId) async {
    try {
      final overdue = await getOverdueInvoices(userId);
      await _isar.writeTxn(() async {
        for (final invoice in overdue) {
          invoice.status = InvoiceStatus.overdue;
          invoice.updatedAt = DateTime.now();
          await _isar.invoices.put(invoice);
        }
      });
    } catch (e) {
      throw Exception('Failed to mark overdue invoices: $e');
    }
  }
}
