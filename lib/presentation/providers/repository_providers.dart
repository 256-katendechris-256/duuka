import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/business_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/sale_repository.dart';
import '../../data/repositories/customer_repository.dart';

/// Repository Providers for Dependency Injection
/// These providers are used throughout the app to access repository instances

// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Business Repository Provider
final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BusinessRepository();
});

// Product Repository Provider
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

// Sale Repository Provider
final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SaleRepository();
});

// Customer Repository Provider
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});
