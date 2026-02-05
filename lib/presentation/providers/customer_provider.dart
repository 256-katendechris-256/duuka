import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../data/repositories/customer_repository.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

/// All customers provider
final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final repository = ref.watch(customerRepositoryProvider);
  return await repository.getAll();
});

/// Search customers provider
final customerSearchProvider = FutureProvider.family<List<Customer>, String>((ref, query) async {
  final repository = ref.watch(customerRepositoryProvider);
  return await repository.search(query);
});

/// Single customer provider
final customerProvider = FutureProvider.family<Customer?, int>((ref, id) async {
  final repository = ref.watch(customerRepositoryProvider);
  return await repository.getById(id);
});

/// Customer by phone provider
final customerByPhoneProvider = FutureProvider.family<Customer?, String>((ref, phone) async {
  final repository = ref.watch(customerRepositoryProvider);
  return await repository.getByPhone(phone);
});

/// Customer count provider
final customerCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(customerRepositoryProvider);
  return await repository.getCount();
});

/// Customer management notifier
class CustomerNotifier extends StateNotifier<AsyncValue<List<Customer>>> {
  final CustomerRepository _repository;
  final Ref _ref;

  CustomerNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    state = const AsyncValue.loading();
    try {
      final customers = await _repository.getAll();
      state = AsyncValue.data(customers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Customer?> addCustomer({
    required String name,
    required String phone,
    String? location,
    String? notes,
  }) async {
    try {
      // Check if phone already exists
      final existing = await _repository.getByPhone(phone);
      if (existing != null) {
        throw Exception('A customer with this phone number already exists');
      }

      final customer = Customer.create(
        name: name,
        phone: phone,
        location: location,
        notes: notes,
      );
      
      final id = await _repository.save(customer);
      customer.id = id;
      
      await loadCustomers();
      _ref.invalidate(customerCountProvider);
      
      return customer;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateCustomer(Customer customer) async {
    try {
      await _repository.save(customer);
      await loadCustomers();
      _ref.invalidate(customerProvider(customer.id));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCustomer(int id) async {
    try {
      final result = await _repository.delete(id);
      if (result) {
        await loadCustomers();
        _ref.invalidate(customerCountProvider);
      }
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<List<Customer>> search(String query) async {
    return await _repository.search(query);
  }
}

final customerNotifierProvider = StateNotifierProvider<CustomerNotifier, AsyncValue<List<Customer>>>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return CustomerNotifier(repository, ref);
});
