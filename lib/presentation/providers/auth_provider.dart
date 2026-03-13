import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../data/models/models.dart';
import '../../data/models/business.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/datasources/local/database_service.dart';
import '../../data/datasources/local/preferences_service.dart';
import '../../data/datasources/remote/supabase_service.dart';
import '../../data/services/pin_service.dart';
import 'device_provider.dart';
import 'pin_provider.dart';

part 'auth_provider.g.dart';

// Repository Provider
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository();
}

/// Current logged-in user (from auth state). Used by invoice and other features.
final currentUserProvider = Provider<AsyncValue<AppUser?>>((ref) {
  final auth = ref.watch(authProvider);
  if (auth.status == AuthStatus.authenticated && auth.user != null) {
    return AsyncValue.data(auth.user);
  }
  if (auth.status == AuthStatus.loading ||
      auth.status == AuthStatus.otpSent ||
      auth.status == AuthStatus.otpVerifying) {
    return const AsyncValue.loading();
  }
  return AsyncValue.data(null);
});

// Auth State
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  otpSent,
  otpVerifying,
  pinRequired,
  pinSetupRequired,
  pendingApproval,
  error,
}

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? error;
  final String? phoneNumber;
  final bool isNewUser;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.phoneNumber,
    this.isNewUser = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? error,
    String? phoneNumber,
    bool? isNewUser,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isNewUser: isNewUser ?? this.isNewUser,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading || status == AuthStatus.otpVerifying;
  bool get needsPin => status == AuthStatus.pinRequired;
  bool get needsPinSetup => status == AuthStatus.pinSetupRequired;
}

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  StreamSubscription<supabase.AuthState>? _authSubscription;
  bool _isInitialized = false;

  @override
  AuthState build() {
    ref.onDispose(() {
      _authSubscription?.cancel();
    });

    // Schedule initialization after build completes
    Future.delayed(Duration.zero, () {
      if (!_isInitialized) {
        _isInitialized = true;
        _initAuthListener();
        _checkAuthStatus();
      }
    });

    return const AuthState();
  }

  void _initAuthListener() {
    _authSubscription = SupabaseService.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == supabase.AuthChangeEvent.signedIn && session != null) {
        _handleSignIn(session);
      } else if (event == supabase.AuthChangeEvent.signedOut) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      } else if (event == supabase.AuthChangeEvent.tokenRefreshed && session != null) {
        // Session refreshed, just update the user if needed
      }
    });
  }

  Future<void> _checkAuthStatus() async {
    print('');
    print('========================================');
    print('🔍 _checkAuthStatus CALLED');
    print('========================================');
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final session = SupabaseService.currentSession;
      print('🔍 Session exists: ${session != null}');

      if (session != null) {
        print('🔍 Session user ID: ${session.user.id}');
        // Owner with Supabase session
        final user = await ref.read(authRepositoryProvider).getCurrentUser();
        print('🔍 Local user found: ${user != null}');
        if (user != null) {
          print('🔍 Local user: ${user.name} / ${user.email} / UID: ${user.uid}');
        }

        if (user == null) {
          // User has session but no local profile - fetch from remote
          print('🔍 NO local user - calling _handleSignIn to restore...');
          await _handleSignIn(session);
          return;
        }

        // Refresh approval status from remote (user may have been approved since last session)
        if (user.uid.isNotEmpty && !user.uid.startsWith('local_')) {
          try {
            final remoteUser = await _fetchRemoteUser(session.user.id);
            if (remoteUser != null && !remoteUser.isApproved) {
              user.isApproved = false;
              await ref.read(authRepositoryProvider).saveUser(user);
              print('🔍 User not yet approved (will check at dashboard entry)');
            }
            if (remoteUser != null && remoteUser.isApproved && !user.isApproved) {
              user.isApproved = true;
              await ref.read(authRepositoryProvider).saveUser(user);
              print('🟢 User has been approved!');
            }
          } catch (e) {
            print('⚠️ Could not check approval status: $e');
          }
        }

        // Let the user proceed to PIN/onboarding/home.
        // Approval is checked by the splash screen before entering dashboard.
        print('🔍 Local user EXISTS - going to PIN check');
        await _checkPinAndSetState(user);
        return;
      }

      // No Supabase session - check for local user (team member who logged in via invitation)
      final localUser = await _checkForLocalUser();

      if (localUser != null) {
        print('🟢 Found local user (team member): ${localUser.name ?? localUser.phone}');
        // Team member found, check PIN status
        await _checkPinAndSetState(localUser);
        return;
      }

      // No session and no local user - unauthenticated
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (e) {
      print('🔴 Error checking auth status: $e');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  /// Check for locally stored user (team member who logged in via invitation code)
  Future<AppUser?> _checkForLocalUser() async {
    try {
      final userId = PreferencesService.userId;
      if (userId == null) return null;

      final isar = DatabaseService.instance;

      // Try to find user by stored ID
      final localUserId = int.tryParse(userId);
      if (localUserId != null) {
        final user = await isar.appUsers.get(localUserId);
        if (user != null && user.isActive) {
          return user;
        }
      }

      // Try to find by uid (for users stored with uid as string)
      final userByUid = await isar.appUsers
          .filter()
          .uidEqualTo(userId)
          .findFirst();

      if (userByUid != null && userByUid.isActive) {
        return userByUid;
      }

      return null;
    } catch (e) {
      print('🔴 Error checking for local user: $e');
      return null;
    }
  }

  /// Check PIN status and set appropriate auth state
  Future<void> _checkPinAndSetState(AppUser user) async {
    final hasPin = await PinService.hasPin();
    final pinVerified = PreferencesService.pinVerifiedThisSession;

    if (!hasPin) {
      state = state.copyWith(
        status: AuthStatus.pinSetupRequired,
        user: user,
      );
    } else if (!pinVerified) {
      state = state.copyWith(
        status: AuthStatus.pinRequired,
        user: user,
      );
    } else {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    }
  }

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      phoneNumber: phoneNumber,
      clearError: true,
    );

    try {
      // Format phone number for Supabase (ensure it starts with +)
      final formattedPhone = phoneNumber.startsWith('+')
          ? phoneNumber
          : '+$phoneNumber';

      await SupabaseService.signInWithOtp(phone: formattedPhone);

      state = state.copyWith(
        status: AuthStatus.otpSent,
        phoneNumber: formattedPhone,
      );
    } on supabase.AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: _mapAuthError(e),
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: 'Failed to send OTP. Please try again.',
      );
    }
  }

  Future<bool> verifyOtp(String otp) async {
    if (state.phoneNumber == null) {
      state = state.copyWith(error: 'Phone number not found. Please try again.');
      return false;
    }

    state = state.copyWith(status: AuthStatus.otpVerifying, clearError: true);

    try {
      final response = await SupabaseService.verifyOtp(
        phone: state.phoneNumber!,
        token: otp,
      );

      if (response.session != null) {
        await _handleSignIn(response.session!);
        return true;
      }

      state = state.copyWith(
        status: AuthStatus.error,
        error: 'Verification failed. Please try again.',
      );
      return false;
    } on supabase.AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: _mapAuthError(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: 'Verification failed. Please try again.',
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    print('🔵 Google Sign-In: Starting...');

    try {
      final response = await SupabaseService.signInWithGoogle();
      print('🟢 Google Sign-In: Got response');

      if (response.session != null) {
        await _handleSignIn(response.session!);
        return true;
      }

      state = state.copyWith(
        status: AuthStatus.error,
        error: 'Google Sign-In failed. Please try again.',
      );
      return false;
    } on supabase.AuthException catch (e) {
      print('🔴 Google Sign-In AuthException: ${e.message}');
      state = state.copyWith(
        status: AuthStatus.error,
        error: _mapAuthError(e),
      );
      return false;
    } catch (e) {
      print('🔴 Google Sign-In Error: $e');
      final errorMessage = e.toString();
      if (errorMessage.contains('cancelled')) {
        // User cancelled, just return to unauthenticated
        state = state.copyWith(status: AuthStatus.unauthenticated, clearError: true);
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          error: errorMessage.contains('not initialized')
              ? 'Google Sign-In is not configured.'
              : 'Google Sign-In failed. Please try again.',
        );
      }
      return false;
    }
  }

  bool _isHandlingSignIn = false;  // Prevent double sign-in handling

  Future<void> _handleSignIn(supabase.Session session) async {
    // Prevent double calls (from auth listener + direct call)
    if (_isHandlingSignIn) {
      print('🔵 _handleSignIn: Already handling, skipping duplicate call');
      return;
    }
    _isHandlingSignIn = true;

    print('🔵 _handleSignIn: Starting...');
    try {
      final supabaseUser = session.user;
      final repository = ref.read(authRepositoryProvider);
      final isar = DatabaseService.instance;
      print('🔵 _handleSignIn: Supabase user ID: ${supabaseUser.id}');

      // ── User-switch detection: clear old data if a different user signs in ──
      final previousUid = PreferencesService.userId;
      if (previousUid != null && previousUid != supabaseUser.id) {
        print('⚠️ _handleSignIn: DIFFERENT USER detected (was: $previousUid, now: ${supabaseUser.id})');
        print('⚠️ _handleSignIn: Clearing old local data to prevent data leakage...');
        await PinService.resetPin(); // Clear old user's PIN from secure storage
        await DatabaseService.clear();
        await PreferencesService.setOnboardingComplete(false);
        await PreferencesService.clearAuth();
        print('✅ _handleSignIn: Old data cleared');
      }

      // Check if user exists locally by uid (not by preferences)
      var user = await isar.appUsers
          .filter()
          .uidEqualTo(supabaseUser.id)
          .findFirst();
      bool isNewUser = false;
      print('🔵 _handleSignIn: Local user exists: ${user != null}');

      if (user == null) {
        // Check if user exists in remote database
        print('🔵 _handleSignIn: User NOT found locally, checking remote...');
        final remoteUser = await _fetchRemoteUser(supabaseUser.id);
        print('🔵 _handleSignIn: Remote user result: ${remoteUser != null ? "FOUND" : "NOT FOUND"}');

        if (remoteUser != null) {
          // Existing user - restore their data
          print('');
          print('🟢🟢🟢 EXISTING USER - WILL RESTORE DATA 🟢🟢🟢');
          print('   Remote user: ${remoteUser.name} / ${remoteUser.email}');
          print('');
          user = remoteUser;
          await repository.saveUser(user);

          // Restore user's business and data from Supabase
          print('🔵 _handleSignIn: Calling _restoreUserData...');
          await _restoreUserData(user, supabaseUser.id);
          print('🔵 _handleSignIn: _restoreUserData completed');
        } else {
          // New user - create profile
          print('🟢 _handleSignIn: Creating new user profile');
          isNewUser = true;
          user = AppUser()
            ..uid = supabaseUser.id
            ..phone = supabaseUser.phone ?? state.phoneNumber ?? ''
            ..email = supabaseUser.email
            ..name = supabaseUser.userMetadata?['full_name'] as String? ??
                supabaseUser.userMetadata?['name'] as String?
            ..photoUrl = supabaseUser.userMetadata?['avatar_url'] as String? ??
                supabaseUser.userMetadata?['picture'] as String?
            ..role = UserRole.owner
            ..isActive = true
            ..isApproved = false // New users require admin approval
            ..createdAt = DateTime.now();

          // Save locally
          await repository.saveUser(user);

          // Create remote profile
          await _createRemoteUser(user);
        }
      } else {
        // User exists locally - just update preferences
        print('🟢 _handleSignIn: User already exists locally, updating preferences');
        await PreferencesService.setUserId(user.uid);
      }

      // Always store current uid for user-switch detection on next sign-in
      await PreferencesService.setUserId(supabaseUser.id);

      // Update last login
      user.lastLoginAt = DateTime.now();
      await isar.writeTxn(() async {
        await isar.appUsers.put(user!);
      });
      print('🟢 _handleSignIn: User saved with ID: ${user.id}, UID: ${user.uid}');

      // Register device
      print('🔵 _handleSignIn: Registering device...');
      await ref.read(deviceNotifierProvider.notifier).registerDevice(
            userId: user.uid,
            isPrimary: isNewUser,
          );

      // For new users: let them set up PIN and create business first.
      // Approval will be checked when they try to enter the dashboard.
      // For existing users: check approval now.
      if (!user.isApproved && !isNewUser) {
        print('🟡 _handleSignIn: Existing user pending approval');
        state = state.copyWith(
          status: AuthStatus.pendingApproval,
          user: user,
          isNewUser: false,
        );
        return;
      }

      // Check PIN status
      final hasPin = await PinService.hasPin();
      print('🔵 _handleSignIn: Has PIN: $hasPin, isNewUser: $isNewUser');

      if (isNewUser) {
        // New users: set as authenticated → navigateAfterAuth will send
        // them to onboarding which includes PIN setup as step 5.
        print('🟢 _handleSignIn: New user → authenticated (onboarding will handle PIN)');
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isNewUser: true,
        );
      } else if (!hasPin) {
        // Returning user without PIN (was reset on signOut) → PIN setup
        print('🟢 _handleSignIn: Returning user, no PIN → pinSetupRequired');
        state = state.copyWith(
          status: AuthStatus.pinSetupRequired,
          user: user,
          isNewUser: false,
        );
      } else {
        // Returning user with existing PIN
        await PreferencesService.setPinVerifiedThisSession(true);
        print('🟢 _handleSignIn: Returning user with PIN → authenticated');
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isNewUser: false,
        );
      }
      print('🟢 _handleSignIn: Final status: ${state.status}');
    } catch (e) {
      print('🔴 _handleSignIn: Error: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        error: 'Failed to complete sign in: $e',
      );
    } finally {
      _isHandlingSignIn = false;
    }
  }

  Future<AppUser?> _fetchRemoteUser(String authId) async {
    try {
      final data = await SupabaseService.selectSingle(
        'users',
        matchColumn: 'auth_id',
        matchValue: authId,
      );

      if (data == null) return null;

      return AppUser()
        ..uid = authId
        ..phone = data['phone'] as String? ?? ''
        ..name = data['name'] as String?
        ..email = data['email'] as String?
        ..photoUrl = data['photo_url'] as String?
        ..role = _parseRole(data['role'] as String?)
        ..isActive = data['is_active'] as bool? ?? true
        ..isApproved = data['is_approved'] as bool? ?? true
        ..createdAt = DateTime.parse(data['created_at'] as String)
        ..remoteId = data['id'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<void> _createRemoteUser(AppUser user) async {
    try {
      final phone = (user.phone != null && user.phone!.trim().isNotEmpty) ? user.phone : null;
      final data = {
        'auth_id': user.uid,
        'phone': phone,
        'name': user.name,
        'email': user.email,
        'role': user.role.name,
        'is_active': user.isActive,
        'is_approved': false, // New users require admin approval
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await SupabaseService.insert('users', data);
      user.remoteId = response['id'] as String?;
    } catch (e) {
      print('❌ Failed to create remote user profile: $e');
    }
  }

  /// Restore user's business and data from Supabase after reinstall
  Future<void> _restoreUserData(AppUser user, String authId) async {
    print('');
    print('========================================');
    print('🔄 RESTORE USER DATA CALLED');
    print('   Auth ID: $authId');
    print('   User: ${user.name} / ${user.email}');
    print('========================================');
    try {
      final isar = DatabaseService.instance;

      // First, get the user's remote ID from Supabase
      final userData = await SupabaseService.selectSingle(
        'users',
        matchColumn: 'auth_id',
        matchValue: authId,
      );

      if (userData == null) {
        print('   ❌ User not found in Supabase');
        return;
      }

      final userRemoteId = userData['id'] as String;
      user.remoteId = userRemoteId;
      print('   ✅ User remote ID: $userRemoteId');

      // Check if user owns a business
      final businessData = await SupabaseService.from('businesses')
          .select()
          .eq('owner_id', userRemoteId)
          .eq('is_active', true)
          .maybeSingle();

      if (businessData != null) {
        print('   ✅ Found existing business: ${businessData['name']}');

        // Restore business locally
        final business = Business()
          ..remoteId = businessData['id'] as String
          ..name = businessData['name'] as String? ?? ''
          ..ownerName = user.name ?? ''
          ..phone = businessData['phone'] as String?
          ..email = businessData['email'] as String?
          ..address = businessData['address'] as String?
          ..businessType = _parseBusinessType(businessData['type'] as String?)
          ..businessSize = BusinessSize.small
          ..createdAt = DateTime.tryParse(businessData['created_at'] as String? ?? '') ?? DateTime.now()
          ..updatedAt = DateTime.now();

        await isar.writeTxn(() async {
          await isar.business.put(business);
        });
        print('   ✅ Business restored locally with ID: ${business.id}');

        // Update user's business reference
        user.businessId = business.id;
        await isar.writeTxn(() async {
          await isar.appUsers.put(user);
        });

        // Save business ID to preferences
        await PreferencesService.setBusinessId(business.id);

        // Mark onboarding as complete since user has a business
        await PreferencesService.setOnboardingComplete(true);
        print('   ✅ Onboarding marked as complete');

        // Restore products
        final businessRemoteId = businessData['id'] as String;
        print('');
        print('   ====== STARTING DATA RESTORE ======');
        print('   Business Remote ID: $businessRemoteId');

        print('   >>> Calling _restoreProducts...');
        try {
          await _restoreProducts(isar, businessRemoteId);
          print('   <<< _restoreProducts completed');
        } catch (e, stack) {
          print('   ❌ Products restore failed: $e');
          print('   Stack: $stack');
        }

        print('   >>> Calling _restoreCustomers...');
        try {
          await _restoreCustomers(isar, businessRemoteId);
          print('   <<< _restoreCustomers completed');
        } catch (e, stack) {
          print('   ❌ Customers restore failed: $e');
          print('   Stack: $stack');
        }

        print('   >>> Calling _restoreSales...');
        try {
          await _restoreSales(isar, businessRemoteId);
          print('   <<< _restoreSales completed');
        } catch (e, stack) {
          print('   ❌ Sales restore failed: $e');
          print('   Stack: $stack');
        }

        print('   >>> Calling _restoreExpenses...');
        try {
          await _restoreExpenses(isar, businessRemoteId);
          print('   <<< _restoreExpenses completed');
        } catch (e, stack) {
          print('   ❌ Expenses restore failed: $e');
          print('   Stack: $stack');
        }

        print('   ====== DATA RESTORE COMPLETE ======');
        print('');
      } else {
        // Check if user is a team member of a business
        final teamMemberData = await SupabaseService.from('team_members')
            .select('*, businesses(*)')
            .eq('user_id', userRemoteId)
            .eq('is_active', true)
            .maybeSingle();

        if (teamMemberData != null && teamMemberData['businesses'] != null) {
          print('   ✅ Found team membership');
          final businessInfo = teamMemberData['businesses'];

          // Restore business locally
          final business = Business()
            ..remoteId = businessInfo['id'] as String
            ..name = businessInfo['name'] as String? ?? ''
            ..ownerName = ''
            ..phone = businessInfo['phone'] as String?
            ..email = businessInfo['email'] as String?
            ..address = businessInfo['address'] as String?
            ..businessType = _parseBusinessType(businessInfo['type'] as String?)
            ..businessSize = BusinessSize.small
            ..createdAt = DateTime.tryParse(businessInfo['created_at'] as String? ?? '') ?? DateTime.now()
            ..updatedAt = DateTime.now();

          await isar.writeTxn(() async {
            await isar.business.put(business);
          });

          // Update user role from team membership
          final roleStr = teamMemberData['role'] as String?;
          user.businessId = business.id;
          user.role = _parseRole(roleStr);
          await isar.writeTxn(() async {
            await isar.appUsers.put(user);
          });

          await PreferencesService.setBusinessId(business.id);
          await PreferencesService.setOnboardingComplete(true);
          print('   ✅ Team member data restored');

          // Restore products, customers, sales, and expenses
          await _restoreProducts(isar, businessInfo['id'] as String);
          await _restoreCustomers(isar, businessInfo['id'] as String);
          await _restoreSales(isar, businessInfo['id'] as String);
          await _restoreExpenses(isar, businessInfo['id'] as String);
        } else {
          print('   ℹ️ No business found for user - will need to complete onboarding');
        }
      }
    } catch (e) {
      print('❌ Error restoring user data: $e');
    }
  }

  /// Restore products from Supabase
  Future<void> _restoreProducts(Isar isar, String businessId) async {
    try {
      print('   📦 Fetching products for business: $businessId');
      final remoteProducts = await SupabaseService.from('products')
          .select()
          .eq('business_id', businessId);

      print('   📦 Found ${remoteProducts.length} products to restore');

      if (remoteProducts.isEmpty) {
        print('   ℹ️ No products found in Supabase for this business');
        return;
      }

      // Get existing remote IDs (outside transaction)
      final existingProducts = await isar.products.where().findAll();
      final existingRemoteIds = existingProducts
          .where((p) => p.remoteId != null)
          .map((p) => p.remoteId!)
          .toSet();

      // Filter to only new products
      final newProducts = <Product>[];
      for (final remote in remoteProducts) {
        final remoteId = remote['id'] as String;

        if (existingRemoteIds.contains(remoteId)) {
          print('      ⏭️ Product already exists: ${remote['name']}');
          continue;
        }

        final createdAtStr = remote['created_at'] as String?;
        final createdAt = createdAtStr != null ? DateTime.tryParse(createdAtStr) : DateTime.now();
        final updatedAtStr = remote['updated_at'] as String?;
        final updatedAt = updatedAtStr != null ? DateTime.tryParse(updatedAtStr) : DateTime.now();

        final product = Product()
          ..remoteId = remoteId
          ..name = remote['name'] as String? ?? ''
          ..description = remote['description'] as String?
          ..category = remote['category'] as String?
          ..barcode = remote['barcode'] as String?
          ..costPrice = (remote['buying_price'] as num?)?.toDouble() ?? 0
          ..sellPrice = (remote['selling_price'] as num?)?.toDouble() ?? 0
          ..stockQuantity = (remote['quantity'] as num?)?.toDouble() ?? 0
          ..reorderLevel = (remote['min_stock_level'] as num?)?.toInt() ?? 0
          ..isActive = remote['is_active'] as bool? ?? true
          ..syncStatus = SyncStatus.synced
          ..createdAt = createdAt ?? DateTime.now()
          ..updatedAt = updatedAt ?? DateTime.now();

        newProducts.add(product);
      }

      // Batch insert new products
      if (newProducts.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.products.putAll(newProducts);
        });
        for (final p in newProducts) {
          print('      ✓ Restored product: ${p.name}');
        }
      }

      print('   ✅ Products restored (${newProducts.length} new)');
    } catch (e) {
      print('   ⚠️ Error restoring products: $e');
    }
  }

  /// Restore customers from Supabase
  Future<void> _restoreCustomers(Isar isar, String businessId) async {
    try {
      print('   👥 Fetching customers for business: $businessId');
      final remoteCustomers = await SupabaseService.from('customers')
          .select()
          .eq('business_id', businessId);

      print('   👥 Found ${remoteCustomers.length} customers to restore');

      if (remoteCustomers.isEmpty) {
        print('   ℹ️ No customers found in Supabase for this business');
        return;
      }

      // Get existing customers (outside transaction)
      final existingCustomers = await isar.customers.where().findAll();
      final existingRemoteIds = existingCustomers
          .where((c) => c.remoteId != null)
          .map((c) => c.remoteId!)
          .toSet();
      final existingPhones = existingCustomers
          .where((c) => c.phone.isNotEmpty)
          .map((c) => c.phone)
          .toSet();

      // Filter to only new customers and customers to update
      final newCustomers = <Customer>[];
      final customersToUpdate = <Customer>[];

      for (final remote in remoteCustomers) {
        final remoteId = remote['id'] as String;

        if (existingRemoteIds.contains(remoteId)) {
          print('      ⏭️ Customer already exists: ${remote['name']}');
          continue;
        }

        final phone = remote['phone'] as String? ?? '';
        if (phone.isNotEmpty && existingPhones.contains(phone)) {
          // Find and update existing customer
          final existing = existingCustomers.firstWhere((c) => c.phone == phone);
          existing.remoteId = remoteId;
          existing.syncStatus = SyncStatus.synced;
          customersToUpdate.add(existing);
          print('      ⏭️ Customer phone exists, will link: ${existing.name}');
          continue;
        }

        final createdAtStr = remote['created_at'] as String?;
        final createdAt = createdAtStr != null ? DateTime.tryParse(createdAtStr) : DateTime.now();

        final customer = Customer()
          ..remoteId = remoteId
          ..name = remote['name'] as String? ?? ''
          ..phone = phone
          ..location = remote['address'] as String?
          ..syncStatus = SyncStatus.synced
          ..createdAt = createdAt ?? DateTime.now();

        newCustomers.add(customer);
      }

      // Batch insert/update
      if (newCustomers.isNotEmpty || customersToUpdate.isNotEmpty) {
        await isar.writeTxn(() async {
          if (newCustomers.isNotEmpty) {
            await isar.customers.putAll(newCustomers);
          }
          if (customersToUpdate.isNotEmpty) {
            await isar.customers.putAll(customersToUpdate);
          }
        });
        for (final c in newCustomers) {
          print('      ✓ Restored customer: ${c.name}');
        }
      }

      print('   ✅ Customers restored (${newCustomers.length} new, ${customersToUpdate.length} linked)');
    } catch (e) {
      print('   ⚠️ Error restoring customers: $e');
    }
  }

  /// Restore sales from Supabase
  Future<void> _restoreSales(Isar isar, String businessId) async {
    try {
      print('   🧾 Fetching sales for business: $businessId');
      final remoteSales = await SupabaseService.from('sales')
          .select('*, sale_items(*)')
          .eq('business_id', businessId);

      print('   🧾 Found ${remoteSales.length} sales to restore');

      if (remoteSales.isEmpty) {
        print('   ℹ️ No sales found in Supabase for this business');
        return;
      }

      // Get existing sales (outside transaction)
      final existingSales = await isar.sales.where().findAll();
      final existingRemoteIds = existingSales
          .where((s) => s.remoteId != null)
          .map((s) => s.remoteId!)
          .toSet();
      final existingReceiptNumbers = existingSales
          .where((s) => s.receiptNumber.isNotEmpty)
          .map((s) => s.receiptNumber)
          .toSet();

      // Track receipt numbers we're adding in this batch to avoid duplicates
      final addedReceiptNumbers = <String>{};

      int restoredCount = 0;
      int linkedCount = 0;
      int skippedCount = 0;

      for (final remote in remoteSales) {
        final remoteId = remote['id'] as String;
        var saleNumber = remote['sale_number'] as String? ?? '';

        if (existingRemoteIds.contains(remoteId)) {
          print('      ⏭️ Sale already exists (by remoteId): $saleNumber');
          skippedCount++;
          continue;
        }

        // Check if sale exists by receipt number (created locally but not synced)
        if (saleNumber.isNotEmpty && existingReceiptNumbers.contains(saleNumber)) {
          final existing = existingSales.firstWhere((s) => s.receiptNumber == saleNumber);
          existing.remoteId = remoteId;
          existing.syncStatus = SyncStatus.synced;
          try {
            await isar.writeTxn(() async {
              await isar.sales.put(existing);
            });
            linkedCount++;
            print('      🔗 Linked existing sale: $saleNumber');
          } catch (e) {
            print('      ⚠️ Failed to link sale $saleNumber: $e');
          }
          continue;
        }

        // Generate unique receipt number if empty or already used
        if (saleNumber.isEmpty ||
            existingReceiptNumbers.contains(saleNumber) ||
            addedReceiptNumbers.contains(saleNumber)) {
          // Generate a unique receipt number using remote ID
          saleNumber = 'R-${remoteId.substring(0, 8).toUpperCase()}';
          print('      📝 Generated receipt number: $saleNumber');
        }

        // Track this receipt number to avoid duplicates in this batch
        addedReceiptNumbers.add(saleNumber);

        // Parse sale items
        final itemsData = remote['sale_items'] as List<dynamic>? ?? [];
        final saleItems = itemsData.map((item) {
          // product_id is a UUID string from Supabase, not an int
          // We'll set productId to 0 since we can't easily map UUID to local ID
          return SaleItem()
            ..productId = 0  // UUID from Supabase can't be converted to int
            ..productName = item['product_name'] as String? ?? ''
            ..quantity = (item['quantity'] as num?)?.toDouble() ?? 1
            ..unitPrice = (item['unit_price'] as num?)?.toDouble() ?? 0
            ..costPrice = (item['cost_price'] as num?)?.toDouble() ?? 0
            ..total = (item['total'] as num?)?.toDouble() ?? 0
            ..unit = item['unit'] as String? ?? 'pcs';
        }).toList();

        // Parse status to payment status (Supabase uses 'completed'/'pending')
        final statusStr = remote['status'] as String?;
        final paymentStatus = statusStr == 'completed' ? PaymentStatus.paid : PaymentStatus.unpaid;

        // Use sold_at for the sale date (not created_at)
        final soldAtStr = remote['sold_at'] as String?;
        final soldAt = soldAtStr != null ? DateTime.tryParse(soldAtStr) : null;
        final createdAtStr = remote['created_at'] as String?;
        final createdAt = createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;

        final sale = Sale()
          ..remoteId = remoteId
          ..receiptNumber = saleNumber
          ..items = saleItems
          ..subtotal = (remote['subtotal'] as num?)?.toDouble() ?? 0
          ..discount = (remote['discount'] as num?)?.toDouble() ?? 0
          ..discountPercent = (remote['discount_percent'] as num?)?.toDouble() ?? 0
          ..total = (remote['total'] as num?)?.toDouble() ?? 0
          ..paymentMethod = _parsePaymentMethod(remote['payment_method'] as String?)
          ..paymentStatus = paymentStatus
          ..amountPaid = (remote['amount_paid'] as num?)?.toDouble() ?? 0
          ..balance = (remote['balance'] as num?)?.toDouble() ?? 0
          ..customerId = null
          ..customerName = remote['customer_name'] as String?
          ..userId = 1
          ..userName = remote['user_name'] as String?
          ..notes = remote['notes'] as String?
          ..syncStatus = SyncStatus.synced
          ..createdAt = soldAt ?? createdAt ?? DateTime.now();

        // Insert each sale individually to handle duplicates gracefully
        try {
          await isar.writeTxn(() async {
            await isar.sales.put(sale);
          });
          restoredCount++;
          print('      ✓ Restored sale: ${sale.receiptNumber}');
        } catch (e) {
          print('      ⚠️ Failed to restore sale ${sale.receiptNumber}: $e');
          skippedCount++;
        }
      }

      print('   ✅ Sales restored: $restoredCount new, $linkedCount linked, $skippedCount skipped');
    } catch (e) {
      print('   ⚠️ Error restoring sales: $e');
    }
  }

  /// Restore expenses from Supabase
  Future<void> _restoreExpenses(Isar isar, String businessId) async {
    try {
      print('   💸 Fetching expenses for business: $businessId');
      final remoteExpenses = await SupabaseService.from('expenses')
          .select()
          .eq('business_id', businessId);

      print('   💸 Found ${remoteExpenses.length} expenses to restore');

      if (remoteExpenses.isEmpty) {
        print('   ℹ️ No expenses found in Supabase for this business');
        return;
      }

      // Get existing expenses (outside transaction)
      final existingExpenses = await isar.expenses.where().findAll();
      final existingRemoteIds = existingExpenses
          .where((e) => e.remoteId != null)
          .map((e) => e.remoteId!)
          .toSet();

      // Filter to only new expenses
      final newExpenses = <Expense>[];
      for (final remote in remoteExpenses) {
        final remoteId = remote['id'] as String;

        if (existingRemoteIds.contains(remoteId)) {
          print('      ⏭️ Expense already exists: ${remote['description']}');
          continue;
        }

        // Use expense_date field (not date)
        final expenseDateStr = remote['expense_date'] as String?;
        final expenseDate = expenseDateStr != null ? DateTime.tryParse(expenseDateStr) : null;
        final createdAtStr = remote['created_at'] as String?;
        final createdAt = createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;

        final expense = Expense()
          ..remoteId = remoteId
          ..description = remote['description'] as String? ?? ''
          ..amount = (remote['amount'] as num?)?.toDouble() ?? 0
          ..category = _parseExpenseCategory(remote['category'] as String?)
          ..date = expenseDate ?? createdAt ?? DateTime.now()
          ..notes = remote['notes'] as String?
          ..paymentMethod = remote['payment_method'] as String? ?? 'Cash'
          ..vendor = remote['vendor'] as String?
          ..isRecurring = remote['is_recurring'] as bool? ?? false
          ..syncStatus = SyncStatus.synced
          ..createdAt = createdAt ?? DateTime.now();

        newExpenses.add(expense);
      }

      // Batch insert new expenses
      if (newExpenses.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.expenses.putAll(newExpenses);
        });
        for (final e in newExpenses) {
          print('      ✓ Restored expense: ${e.description}');
        }
      }

      print('   ✅ Expenses restored (${newExpenses.length} new)');
    } catch (e) {
      print('   ⚠️ Error restoring expenses: $e');
    }
  }

  /// Parse payment method from string
  PaymentMethod _parsePaymentMethod(String? method) {
    if (method == null) return PaymentMethod.cash;
    return PaymentMethod.values.firstWhere(
      (m) => m.name.toLowerCase() == method.toLowerCase(),
      orElse: () => PaymentMethod.cash,
    );
  }

  /// Parse payment status from string
  PaymentStatus _parsePaymentStatus(String? status) {
    if (status == null) return PaymentStatus.paid;
    return PaymentStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == status.toLowerCase(),
      orElse: () => PaymentStatus.paid,
    );
  }

  /// Parse expense category from string
  ExpenseCategory _parseExpenseCategory(String? category) {
    if (category == null) return ExpenseCategory.other;
    return ExpenseCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == category.toLowerCase(),
      orElse: () => ExpenseCategory.other,
    );
  }

  /// Parse business type from string
  BusinessType _parseBusinessType(String? type) {
    if (type == null) return BusinessType.retail;
    return BusinessType.values.firstWhere(
      (t) => t.name.toLowerCase() == type.toLowerCase(),
      orElse: () => BusinessType.retail,
    );
  }

  UserRole _parseRole(String? role) {
    if (role == null) return UserRole.owner;
    return UserRole.values.firstWhere(
      (r) => r.name == role,
      orElse: () => UserRole.owner,
    );
  }

  String _mapAuthError(supabase.AuthException e) {
    final message = e.message.toLowerCase();
    print('🔴 Supabase Auth Error: ${e.message}'); // Debug log

    if (message.contains('rate limit') || message.contains('too many')) {
      return 'Too many attempts. Please wait a few minutes and try again.';
    }
    if (message.contains('invalid') && message.contains('otp')) {
      return 'Invalid verification code. Please check and try again.';
    }
    if (message.contains('expired')) {
      return 'Verification code has expired. Please request a new one.';
    }
    if (message.contains('phone')) {
      return 'Phone error: ${e.message}'; // Show actual error for debugging
    }

    return e.message;
  }

  void onPinVerified() {
    if (state.user != null) {
      state = state.copyWith(status: AuthStatus.authenticated);
    }
  }

  void onPinSetupComplete() {
    if (state.user != null) {
      state = state.copyWith(status: AuthStatus.authenticated);
    }
  }

  /// Called when admin approves the user from the pending approval screen
  void onApproved(AppUser user) {
    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: user,
    );
  }

  Future<void> signOut({bool clearLocalAuth = false}) async {
    final isLocalUser = state.user?.uid?.startsWith('local_') == true;

    // For local team members, default to a lock-screen style logout.
    if (isLocalUser && !clearLocalAuth) {
      await ref.read(pinProvider.notifier).clearSession();
      state = state.copyWith(status: AuthStatus.pinRequired);
      return;
    }

    try {
      // Clear PIN from secure storage (prevents stale PIN for next user)
      await PinService.resetPin();

      // Clear PIN session
      await ref.read(pinProvider.notifier).clearSession();

      // Clear device
      await ref.read(deviceNotifierProvider.notifier).clear();

      // Clear ALL local data (Isar DB + preferences) to prevent data leakage
      await DatabaseService.clear();
      await PreferencesService.clearAll();

      // Sign out from Supabase
      await SupabaseService.signOut();

      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      // Still mark as unauthenticated even if signout fails
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> updateUserProfile(String name, String? email) async {
    if (state.user == null) return;

    try {
      final updatedUser = state.user!
        ..name = name
        ..email = email;

      await ref.read(authRepositoryProvider).saveUser(updatedUser);

      // Update remote
      if (updatedUser.remoteId != null) {
        await SupabaseService.update(
          'users',
          {'name': name, 'email': email},
          matchColumn: 'id',
          matchValue: updatedUser.remoteId,
        );
      }

      state = state.copyWith(user: updatedUser);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Manually trigger data restoration from Supabase
  /// This can be called from Settings to restore data without re-login
  Future<bool> restoreDataFromCloud() async {
    print('');
    print('========================================');
    print('🔄 MANUAL RESTORE FROM CLOUD TRIGGERED');
    print('========================================');

    if (state.user == null) {
      print('❌ No user logged in');
      return false;
    }

    final authId = state.user!.uid;
    if (authId == null) {
      print('❌ User has no auth ID');
      return false;
    }

    print('   User: ${state.user!.name} / ${state.user!.email}');
    print('   Auth ID: $authId');

    try {
      await _restoreUserData(state.user!, authId);
      print('✅ Manual restore completed');
      return true;
    } catch (e) {
      print('❌ Manual restore failed: $e');
      return false;
    }
  }

  void resendOtp() {
    if (state.phoneNumber != null) {
      sendOtp(state.phoneNumber!);
    }
  }

  /// Login with invitation code (for team members who don't need Supabase auth)
  /// This sets the user as authenticated locally without requiring OTP/Google
  Future<void> loginWithInvitation(AppUser user) async {
    try {
      // Save user to local database
      await ref.read(authRepositoryProvider).saveUser(user);

      // Save user ID to preferences
      await PreferencesService.setUserId(user.id.toString());

      // Mark PIN as verified (invitation login doesn't require PIN initially)
      await PreferencesService.setPinVerifiedThisSession(true);

      // Check if user has PIN set up
      final hasPin = await PinService.hasPin();

      if (!hasPin) {
        // New team member needs to set up PIN
        state = state.copyWith(
          status: AuthStatus.pinSetupRequired,
          user: user,
          isNewUser: true,
        );
      } else {
        // Existing team member with PIN - mark as authenticated
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isNewUser: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: 'Failed to complete login: $e',
      );
    }
  }

  /// Join a business using an invitation code
  /// This updates the user's business association and role
  Future<bool> joinWithInvitationCode({
    required String phone,
    required String code,
    required int businessId,
    required UserRole role,
  }) async {
    if (state.user == null) {
      state = state.copyWith(error: 'User not authenticated');
      return false;
    }

    try {
      final user = state.user!;

      // Update local user with new business association
      user.businessId = businessId;
      user.role = role;

      // Save locally
      await ref.read(authRepositoryProvider).saveUser(user);

      // Save business ID to preferences
      await PreferencesService.setBusinessId(businessId);

      // Update state
      state = state.copyWith(user: user);

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to join business: $e');
      return false;
    }
  }

  /// Update user's business association (after joining a team)
  Future<void> updateUserBusiness(int businessId, UserRole role) async {
    if (state.user == null) return;

    try {
      final user = state.user!;
      user.businessId = businessId;
      user.role = role;

      await ref.read(authRepositoryProvider).saveUser(user);
      await PreferencesService.setBusinessId(businessId);

      state = state.copyWith(user: user);
    } catch (e) {
      print('Error updating user business: $e');
    }
  }
}

// Convenience provider to check if onboarding is complete
@riverpod
bool isOnboardingComplete(IsOnboardingCompleteRef ref) {
  return PreferencesService.isOnboardingComplete;
}

// Combined auth state provider for easy access
@riverpod
bool isFullyAuthenticated(IsFullyAuthenticatedRef ref) {
  final authState = ref.watch(authProvider);
  final pinState = ref.watch(pinProvider);

  return authState.isAuthenticated && pinState.isVerified;
}
