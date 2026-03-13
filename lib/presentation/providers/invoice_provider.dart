import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/models.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/services/invoice_to_sale_service.dart';
import 'auth_provider.dart';

part 'invoice_provider.g.dart';

// Repository Provider
@riverpod
InvoiceRepository invoiceRepository(InvoiceRepositoryRef ref) {
  return InvoiceRepository();
}

// Invoice to Sale Service Provider
@riverpod
InvoiceToSaleService invoiceToSaleService(InvoiceToSaleServiceRef ref) {
  return InvoiceToSaleService();
}

// All Invoices Provider
@riverpod
class Invoices extends _$Invoices {
  @override
  Future<List<Invoice>> build() async {
    return await _loadInvoices();
  }

  Future<List<Invoice>> _loadInvoices() async {
    try {
      return await ref.read(invoiceRepositoryProvider).getAll();
    } catch (e) {
      throw Exception('Failed to load invoices: $e');
    }
  }

  /// Refresh invoices
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadInvoices());
  }

  /// Add new invoice
  Future<Invoice> create(Invoice invoice) async {
    try {
      final created = await ref.read(invoiceRepositoryProvider).create(invoice);
      await refresh();
      return created;
    } catch (e) {
      throw Exception('Failed to create invoice: $e');
    }
  }

  /// Update invoice
  Future<void> updateInvoice(Invoice invoice) async {
    try {
      await ref.read(invoiceRepositoryProvider).update(invoice);
      await refresh();
    } catch (e) {
      throw Exception('Failed to update invoice: $e');
    }
  }

  /// Mark invoice as sent
  Future<Invoice> markAsSent(Invoice invoice) async {
    try {
      final sent = await ref.read(invoiceRepositoryProvider).markAsSent(invoice);
      await refresh();
      return sent;
    } catch (e) {
      throw Exception('Failed to mark invoice as sent: $e');
    }
  }

  /// Record payment
  Future<Invoice> recordPayment({
    required Invoice invoice,
    required double amount,
    required InvoicePaymentMethod method,
    String? reference,
    String? notes,
  }) async {
    try {
      final paid = await ref.read(invoiceRepositoryProvider).recordPayment(
            invoice: invoice,
            amount: amount,
            method: method,
            reference: reference,
            notes: notes,
          );
      
      // Auto-convert to Sale if now fully paid
      if (paid.isPaid && paid.saleId == null) {
        try {
          await ref.read(invoiceToSaleServiceProvider).convertInvoiceToSale(paid);
        } catch (e) {
          print('Warning: Could not auto-convert invoice to sale: $e');
        }
      }
      
      await refresh();
      return paid;
    } catch (e) {
      throw Exception('Failed to record payment: $e');
    }
  }

  /// Cancel invoice
  Future<Invoice> cancel(Invoice invoice) async {
    try {
      final cancelled = await ref.read(invoiceRepositoryProvider).cancel(invoice);
      await refresh();
      return cancelled;
    } catch (e) {
      throw Exception('Failed to cancel invoice: $e');
    }
  }

  /// Delete invoice
  Future<bool> delete(int id) async {
    try {
      final deleted = await ref.read(invoiceRepositoryProvider).delete(id);
      if (deleted) {
        await refresh();
      }
      return deleted;
    } catch (e) {
      throw Exception('Failed to delete invoice: $e');
    }
  }
}

// Draft Invoices Provider
@riverpod
Future<List<Invoice>> draftInvoices(DraftInvoicesRef ref) async {
  try {
    return await ref.read(invoiceRepositoryProvider).getDrafts();
  } catch (e) {
    throw Exception('Failed to load draft invoices: $e');
  }
}

// Pending Invoices Provider
@riverpod
Future<List<Invoice>> pendingInvoices(PendingInvoicesRef ref) async {
  try {
    return await ref.read(invoiceRepositoryProvider).getPending();
  } catch (e) {
    throw Exception('Failed to load pending invoices: $e');
  }
}

// Paid Invoices Provider
@riverpod
Future<List<Invoice>> paidInvoices(PaidInvoicesRef ref) async {
  try {
    return await ref.read(invoiceRepositoryProvider).getByStatus(InvoiceStatus.paid);
  } catch (e) {
    throw Exception('Failed to load paid invoices: $e');
  }
}

// Overdue Invoices Provider
@riverpod
Future<List<Invoice>> overdueInvoices(OverdueInvoicesRef ref) async {
  try {
    return await ref.read(invoiceRepositoryProvider).getOverdue();
  } catch (e) {
    throw Exception('Failed to load overdue invoices: $e');
  }
}

// Invoices by Customer
@riverpod
Future<List<Invoice>> invoicesByCustomer(
  InvoicesByCustomerRef ref, {
  required int customerId,
}) async {
  try {
    return await ref.read(invoiceRepositoryProvider).getByCustomerId(customerId);
  } catch (e) {
    throw Exception('Failed to load customer invoices: $e');
  }
}

// Today's Invoices
@riverpod
Future<List<Invoice>> todayInvoices(TodayInvoicesRef ref) async {
  try {
    return await ref.read(invoiceRepositoryProvider).getToday();
  } catch (e) {
    throw Exception('Failed to load today\'s invoices: $e');
  }
}

// Invoice Statistics
@riverpod
Future<InvoiceStats> invoiceStats(InvoiceStatsRef ref) async {
  try {
    final userId = ref.watch(currentUserProvider).value?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    return await ref.read(invoiceRepositoryProvider).getStats(userId);
  } catch (e) {
    throw Exception('Failed to load invoice stats: $e');
  }
}

// Single Invoice by ID
@riverpod
Future<Invoice?> invoiceById(
  InvoiceByIdRef ref, {
  required int id,
}) async {
  try {
    return await ref.read(invoiceRepositoryProvider).getById(id);
  } catch (e) {
    throw Exception('Failed to load invoice: $e');
  }
}

// Next Invoice Number
@riverpod
Future<String> nextInvoiceNumber(NextInvoiceNumberRef ref) async {
  try {
    final userId = ref.watch(currentUserProvider).value?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    return await ref.read(invoiceRepositoryProvider).getNextInvoiceNumber(userId);
  } catch (e) {
    throw Exception('Failed to generate invoice number: $e');
  }
}

// Invoice Search
@riverpod
Future<List<Invoice>> searchInvoices(
  SearchInvoicesRef ref, {
  required String query,
}) async {
  try {
    final userId = ref.watch(currentUserProvider).value?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    return await ref.read(invoiceRepositoryProvider).search(query, userId);
  } catch (e) {
    throw Exception('Failed to search invoices: $e');
  }
}
