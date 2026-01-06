import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/models.dart';
import '../../data/repositories/customer_repository.dart';

part 'customer_provider.g.dart';

// Repository Provider
@riverpod
CustomerRepository customerRepository(CustomerRepositoryRef ref) {
  return CustomerRepository();
}

// Customers Provider
@riverpod
class Customers extends _$Customers {
  @override
  Future<List<Customer>> build() async {
    return await _loadCustomers();
  }

  Future<List<Customer>> _loadCustomers() async {
    try {
      return await ref.read(customerRepositoryProvider).getAll();
    } catch (e) {
      throw Exception('Failed to load customers: $e');
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadCustomers());
  }

  Future<bool> addCustomer(Customer customer) async {
    try {
      await ref.read(customerRepositoryProvider).save(customer);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCustomer(Customer customer) async {
    try {
      await ref.read(customerRepositoryProvider).save(customer);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCustomer(int id) async {
    try {
      await ref.read(customerRepositoryProvider).delete(id);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> recordPayment(int customerId, double amount) async {
    try {
      await ref.read(customerRepositoryProvider).subtractFromBalance(customerId, amount);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> recordCreditSale(int customerId, double amount) async {
    try {
      final repository = ref.read(customerRepositoryProvider);
      await repository.addToBalance(customerId, amount);
      await repository.recordPurchase(customerId, amount);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Single Customer Provider
@riverpod
Future<Customer?> customer(CustomerRef ref, int id) async {
  try {
    return await ref.read(customerRepositoryProvider).getById(id);
  } catch (e) {
    return null;
  }
}

// Customers with Debt Provider
@riverpod
Future<List<Customer>> customersWithDebt(CustomersWithDebtRef ref) async {
  try {
    return await ref.read(customerRepositoryProvider).getWithDebt();
  } catch (e) {
    return [];
  }
}

// Customer Search Provider
@riverpod
class CustomerSearch extends _$CustomerSearch {
  @override
  Future<List<Customer>> build(String query) async {
    return await ref.read(customerRepositoryProvider).search(query);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

// Debt Stats Class
class DebtStats {
  final double totalOwed;
  final double overdueAmount;
  final int customerCount;

  const DebtStats({
    required this.totalOwed,
    required this.overdueAmount,
    required this.customerCount,
  });

  DebtStats copyWith({
    double? totalOwed,
    double? overdueAmount,
    int? customerCount,
  }) {
    return DebtStats(
      totalOwed: totalOwed ?? this.totalOwed,
      overdueAmount: overdueAmount ?? this.overdueAmount,
      customerCount: customerCount ?? this.customerCount,
    );
  }
}

// Debt Stats Provider
@riverpod
Future<DebtStats> debtStats(DebtStatsRef ref) async {
  try {
    final repository = ref.read(customerRepositoryProvider);

    final totalOwed = await repository.getTotalDebt();
    final customersWithDebt = await repository.getWithDebt();
    final overdueCount = await repository.getOverdueCount();

    // Calculate overdue amount (customers over credit limit)
    final overdueAmount = customersWithDebt
        .where((c) => c.isOverLimit)
        .fold(0.0, (sum, c) => sum + c.balance);

    return DebtStats(
      totalOwed: totalOwed,
      overdueAmount: overdueAmount,
      customerCount: customersWithDebt.length,
    );
  } catch (e) {
    return const DebtStats(
      totalOwed: 0,
      overdueAmount: 0,
      customerCount: 0,
    );
  }
}
