import 'package:isar/isar.dart';
import '../datasources/local/database_service.dart';
import '../models/models.dart';

class InvoiceRepository {
  final Isar _isar = DatabaseService.instance;

  /// Create new invoice (starts in draft status)
  Future<Invoice> create(Invoice invoice) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.invoices.put(invoice);
      });
      return invoice;
    } catch (e) {
      throw Exception('Failed to create invoice: $e');
    }
  }

  /// Get all invoices sorted by date (newest first)
  Future<List<Invoice>> getAll() async {
    try {
      return await _isar.invoices
          .where()
          .sortByCreatedAtDesc()
          .findAll();
    } catch (e) {
      throw Exception('Failed to fetch invoices: $e');
    }
  }

  /// Get invoice by ID
  Future<Invoice?> getById(int id) async {
    try {
      return await _isar.invoices.get(id);
    } catch (e) {
      throw Exception('Failed to fetch invoice: $e');
    }
  }

  /// Get invoice by invoice number
  Future<Invoice?> getByNumber(String invoiceNumber) async {
    try {
      return await _isar.invoices
          .where()
          .invoiceNumberEqualTo(invoiceNumber)
          .findFirst();
    } catch (e) {
      throw Exception('Failed to fetch invoice: $e');
    }
  }

  /// Get invoices for a specific customer
  Future<List<Invoice>> getByCustomerId(int customerId) async {
    try {
      return await _isar.invoices
          .filter()
          .customerIdEqualTo(customerId)
          .sortByCreatedAtDesc()
          .findAll();
    } catch (e) {
      throw Exception('Failed to fetch customer invoices: $e');
    }
  }

  /// Get invoices by status
  Future<List<Invoice>> getByStatus(InvoiceStatus status) async {
    try {
      return await _isar.invoices
          .filter()
          .statusEqualTo(status)
          .sortByCreatedAtDesc()
          .findAll();
    } catch (e) {
      throw Exception('Failed to fetch invoices by status: $e');
    }
  }

  /// Get draft invoices (not yet sent)
  Future<List<Invoice>> getDrafts() async {
    try {
      return await _isar.invoices
          .filter()
          .statusEqualTo(InvoiceStatus.draft)
          .sortByCreatedAtDesc()
          .findAll();
    } catch (e) {
      throw Exception('Failed to fetch draft invoices: $e');
    }
  }

  /// Get pending invoices (sent but not fully paid)
  Future<List<Invoice>> getPending() async {
    try {
      return await _isar.invoices
          .filter()
          .statusEqualTo(InvoiceStatus.sent)
          .or()
          .statusEqualTo(InvoiceStatus.partial)
          .or()
          .statusEqualTo(InvoiceStatus.overdue)
          .sortByCreatedAtDesc()
          .findAll();
    } catch (e) {
      throw Exception('Failed to fetch pending invoices: $e');
    }
  }

  /// Get invoices created today
  Future<List<Invoice>> getToday() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      return await _isar.invoices
          .filter()
          .createdAtBetween(startOfDay, endOfDay)
          .sortByCreatedAtDesc()
          .findAll();
    } catch (e) {
      throw Exception('Failed to fetch today\'s invoices: $e');
    }
  }

  /// Get invoices by date range
  Future<List<Invoice>> getByDateRange(DateTime start, DateTime end) async {
    try {
      return await _isar.invoices
          .filter()
          .createdAtBetween(start, end)
          .sortByCreatedAtDesc()
          .findAll();
    } catch (e) {
      throw Exception('Failed to fetch invoices by date range: $e');
    }
  }

  /// Get overdue invoices
  Future<List<Invoice>> getOverdue() async {
    try {
      return await _isar.invoices
          .filter()
          .statusEqualTo(InvoiceStatus.overdue)
          .sortByCreatedAtDesc()
          .findAll();
    } catch (e) {
      throw Exception('Failed to fetch overdue invoices: $e');
    }
  }

  /// Update invoice
  Future<Invoice> update(Invoice invoice) async {
    try {
      invoice.updatedAt = DateTime.now();
      await _isar.writeTxn(() async {
        await _isar.invoices.put(invoice);
      });
      return invoice;
    } catch (e) {
      throw Exception('Failed to update invoice: $e');
    }
  }

  /// Mark invoice as sent to customer
  Future<Invoice> markAsSent(Invoice invoice) async {
    try {
      invoice.status = InvoiceStatus.sent;
      invoice.updatedAt = DateTime.now();
      await _isar.writeTxn(() async {
        await _isar.invoices.put(invoice);
      });
      return invoice;
    } catch (e) {
      throw Exception('Failed to mark invoice as sent: $e');
    }
  }

  /// Record payment for invoice
  /// Returns updated invoice
  Future<Invoice> recordPayment({
    required Invoice invoice,
    required double amount,
    required InvoicePaymentMethod method,
    String? reference,
    String? notes,
  }) async {
    try {
      // Create new payment record
      final payment = InvoicePayment.create(
        amount: amount,
        method: method,
        reference: reference,
        notes: notes,
      );

      // Create a new growable list from existing payments and add the new one
      // (Isar returns fixed-length lists, so we can't add directly)
      final updatedPayments = List<InvoicePayment>.from(invoice.payments)..add(payment);
      invoice.payments = updatedPayments;

      // Update payment tracking
      invoice.amountPaid += amount;
      invoice.balance = invoice.total - invoice.amountPaid;

      // Update status
      if (invoice.amountPaid >= invoice.total) {
        invoice.status = InvoiceStatus.paid;
      } else if (invoice.amountPaid > 0) {
        invoice.status = InvoiceStatus.partial;
      }

      invoice.updatedAt = DateTime.now();

      await _isar.writeTxn(() async {
        await _isar.invoices.put(invoice);
      });

      return invoice;
    } catch (e) {
      throw Exception('Failed to record payment: $e');
    }
  }

  /// Cancel invoice
  Future<Invoice> cancel(Invoice invoice) async {
    try {
      invoice.status = InvoiceStatus.cancelled;
      invoice.updatedAt = DateTime.now();
      await _isar.writeTxn(() async {
        await _isar.invoices.put(invoice);
      });
      return invoice;
    } catch (e) {
      throw Exception('Failed to cancel invoice: $e');
    }
  }

  /// Delete invoice (only drafts can be deleted)
  Future<bool> delete(int id) async {
    try {
      final invoice = await getById(id);
      if (invoice == null) return false;
      
      if (invoice.status != InvoiceStatus.draft) {
        throw Exception('Only draft invoices can be deleted');
      }

      await _isar.writeTxn(() async {
        await _isar.invoices.delete(id);
      });
      return true;
    } catch (e) {
      throw Exception('Failed to delete invoice: $e');
    }
  }

  /// Get next invoice number for a business
  Future<String> getNextInvoiceNumber(int userId) async {
    try {
      // Get all invoices for this user, sorted by creation date
      final invoices = await _isar.invoices
          .filter()
          .userIdEqualTo(userId)
          .sortByCreatedAtDesc()
          .findAll();

      // Extract the counter from the last invoice number (e.g., INV-2025-001)
      int nextNumber = 1;
      if (invoices.isNotEmpty) {
        final lastNumber = invoices.first.invoiceNumber;
        final parts = lastNumber.split('-');
        if (parts.length == 3) {
          nextNumber = (int.tryParse(parts[2]) ?? 0) + 1;
        }
      }

      final year = DateTime.now().year;
      return 'INV-$year-${nextNumber.toString().padLeft(3, '0')}';
    } catch (e) {
      throw Exception('Failed to generate invoice number: $e');
    }
  }

  /// Get invoice statistics
  Future<InvoiceStats> getStats(int userId) async {
    try {
      final invoices = await _isar.invoices
          .filter()
          .userIdEqualTo(userId)
          .findAll();

      double totalValue = 0;
      double totalPaid = 0;
      int draftCount = 0;
      int sentCount = 0;
      int paidCount = 0;

      for (final inv in invoices) {
        totalValue += inv.total;
        totalPaid += inv.amountPaid;

        if (inv.status == InvoiceStatus.draft) draftCount++;
        if (inv.status == InvoiceStatus.sent || inv.status == InvoiceStatus.overdue) sentCount++;
        if (inv.status == InvoiceStatus.paid) paidCount++;
      }

      return InvoiceStats(
        totalInvoices: invoices.length,
        draftCount: draftCount,
        sentCount: sentCount,
        paidCount: paidCount,
        totalValue: totalValue,
        totalPaid: totalPaid,
        totalOutstanding: totalValue - totalPaid,
      );
    } catch (e) {
      throw Exception('Failed to get invoice stats: $e');
    }
  }

  /// Search invoices
  Future<List<Invoice>> search(String query, int userId) async {
    try {
      final lowerQuery = query.toLowerCase();
      return await _isar.invoices
          .filter()
          .userIdEqualTo(userId)
          .and()
          .group((q) => q
              .invoiceNumberContains(query, caseSensitive: false)
              .or()
              .customerNameContains(query, caseSensitive: false)
              .or()
              .customerPhoneContains(query, caseSensitive: false))
          .sortByCreatedAtDesc()
          .findAll();
    } catch (e) {
      throw Exception('Failed to search invoices: $e');
    }
  }
}

/// Invoice statistics
class InvoiceStats {
  final int totalInvoices;
  final int draftCount;
  final int sentCount;
  final int paidCount;
  final double totalValue;
  final double totalPaid;
  final double totalOutstanding;

  InvoiceStats({
    required this.totalInvoices,
    required this.draftCount,
    required this.sentCount,
    required this.paidCount,
    required this.totalValue,
    required this.totalPaid,
    required this.totalOutstanding,
  });
}
