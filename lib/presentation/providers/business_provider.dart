import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/models.dart';
import '../../data/repositories/business_repository.dart';
import '../../data/datasources/local/preferences_service.dart';

part 'business_provider.g.dart';

// Repository Provider
@riverpod
BusinessRepository businessRepository(BusinessRepositoryRef ref) {
  return BusinessRepository();
}

// Business Provider
@riverpod
class BusinessNotifier extends _$BusinessNotifier {
  @override
  Future<Business?> build() async {
    return await _loadBusiness();
  }

  Future<Business?> _loadBusiness() async {
    try {
      return await ref.read(businessRepositoryProvider).getCurrent();
    } catch (e) {
      return null;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadBusiness());
  }

  Future<bool> saveBusiness(Business business) async {
    try {
      final id = await ref.read(businessRepositoryProvider).save(business);
      business.id = id;
      state = AsyncValue.data(business);

      // Mark onboarding as complete
      await PreferencesService.setOnboardingComplete(true);

      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> updateBusiness(Business business) async {
    try {
      await ref.read(businessRepositoryProvider).update(business);
      state = AsyncValue.data(business);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> exists() async {
    try {
      return await ref.read(businessRepositoryProvider).exists();
    } catch (e) {
      return false;
    }
  }
}

// Onboarding State Providers
@riverpod
class BusinessTypeNotifier extends _$BusinessTypeNotifier {
  @override
  BusinessType? build() => null;

  void select(BusinessType type) {
    state = type;
  }

  void clear() {
    state = null;
  }
}

@riverpod
class BusinessSizeNotifier extends _$BusinessSizeNotifier {
  @override
  BusinessSize? build() => null;

  void select(BusinessSize size) {
    state = size;
  }

  void clear() {
    state = null;
  }
}

// Onboarding Data Class
class OnboardingData {
  final String? businessName;
  final String? ownerName;
  final String? phone;
  final BusinessType? businessType;
  final BusinessSize? businessSize;
  final String? district;
  final String? area;

  const OnboardingData({
    this.businessName,
    this.ownerName,
    this.phone,
    this.businessType,
    this.businessSize,
    this.district,
    this.area,
  });

  OnboardingData copyWith({
    String? businessName,
    String? ownerName,
    String? phone,
    BusinessType? businessType,
    BusinessSize? businessSize,
    String? district,
    String? area,
  }) {
    return OnboardingData(
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      businessType: businessType ?? this.businessType,
      businessSize: businessSize ?? this.businessSize,
      district: district ?? this.district,
      area: area ?? this.area,
    );
  }

  bool get isValid =>
      businessName != null &&
      businessName!.isNotEmpty &&
      ownerName != null &&
      ownerName!.isNotEmpty &&
      businessType != null &&
      businessSize != null;

  Business toBusiness() {
    return Business()
      ..name = businessName!
      ..ownerName = ownerName!
      ..phone = phone
      ..businessType = businessType!
      ..businessSize = businessSize!
      ..district = district
      ..area = area
      ..plan = SubscriptionPlan.free
      ..onTrial = true
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
  }
}

// Onboarding Data Provider
@riverpod
class OnboardingDataNotifier extends _$OnboardingDataNotifier {
  @override
  OnboardingData build() => const OnboardingData();

  void updateBusinessName(String name) {
    state = state.copyWith(businessName: name);
  }

  void updateOwnerName(String name) {
    state = state.copyWith(ownerName: name);
  }

  void updatePhone(String phone) {
    state = state.copyWith(phone: phone);
  }

  void updateBusinessType(BusinessType type) {
    state = state.copyWith(businessType: type);
  }

  void updateBusinessSize(BusinessSize size) {
    state = state.copyWith(businessSize: size);
  }

  void updateDistrict(String district) {
    state = state.copyWith(district: district);
  }

  void updateArea(String area) {
    state = state.copyWith(area: area);
  }

  void clear() {
    state = const OnboardingData();
  }

  Future<bool> complete() async {
    if (!state.isValid) return false;

    try {
      final business = state.toBusiness();
      final notifier = ref.read(businessNotifierProvider.notifier);
      final success = await notifier.saveBusiness(business);

      if (success) {
        clear();
      }

      return success;
    } catch (e) {
      return false;
    }
  }
}
