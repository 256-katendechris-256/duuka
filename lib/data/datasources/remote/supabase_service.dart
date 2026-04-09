import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SupabaseService {
  static SupabaseClient? _client;
  static String? _supabaseUrl;

  static bool get isInitialized => _client != null;

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('SupabaseService not initialized. Call initialize() first with SUPABASE_URL and SUPABASE_ANON_KEY (e.g. via --dart-define).');
    }
    return _client!;
  }

  static GoTrueClient get auth => client.auth;

  /// Handle OAuth redirect deep link (mobile + desktop) and exchange code for session.
  /// Returns true if the link was recognized and processed.
  static Future<bool> handleAuthDeepLink(Uri uri) async {
    try {
      // Expecting: duuka://login-callback?code=...&state=...
      if (uri.scheme != 'duuka') return false;
      if (uri.host != 'login-callback') return false;

      final code = uri.queryParameters['code'];
      if (code == null || code.isEmpty) {
        throw Exception('Missing OAuth code in callback URL');
      }

      // supabase_flutter already processes OAuth deeplinks automatically on mobile.
      // If a session exists, avoid exchanging code again (prevents flow_state_not_found).
      if (!kIsWeb && auth.currentSession != null) {
        print('🟣 Deep link received but session already exists; skipping manual exchange');
        return true;
      }

      print('🟣 Handling OAuth deep link callback (code present: true)');
      await auth.exchangeCodeForSession(code);
      print('🟢 OAuth code exchanged for session');
      return true;
    } on AuthApiException catch (e) {
      if (e.code == 'flow_state_not_found') {
        // Harmless when callback is handled twice (SDK + app_links listener).
        print('🟡 Ignoring duplicate OAuth callback: ${e.message}');
        return true;
      }
      print('🔴 Failed to handle auth deep link: $e');
      rethrow;
    } catch (e) {
      print('🔴 Failed to handle auth deep link: $e');
      rethrow;
    }
  }

  static Future<void> initialize({
    required String url,
    required String anonKey,
    String? googleWebClientId,
  }) async {
    // Kept for bundled config compatibility; browser OAuth uses Supabase + GCP Web client from dashboard.
    if (kDebugMode && googleWebClientId != null && googleWebClientId.isNotEmpty) {
      debugPrint('SupabaseService: googleWebClientId present (browser OAuth; native SHA not required).');
    }
    final normalizedUrl = url.trim().startsWith(RegExp(r'https?://'))
        ? url.trim()
        : 'https://${url.trim()}';
    _supabaseUrl = normalizedUrl;

    await Supabase.initialize(
      url: normalizedUrl,
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _client = Supabase.instance.client;
  }

  /// Get current session (null when not initialized or signed out)
  static Session? get currentSession =>
      _client == null ? null : _client!.auth.currentSession;

  /// Get current user (null when not initialized or signed out)
  static User? get currentUser =>
      _client == null ? null : _client!.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentSession != null;

  /// Get user ID
  static String? get userId => currentUser?.id;

  /// Get user phone
  static String? get userPhone => currentUser?.phone;

  /// Listen to auth state changes (empty stream when not initialized)
  static Stream<AuthState> get onAuthStateChange =>
      _client == null ? const Stream.empty() : _client!.auth.onAuthStateChange;

  /// Sign in with OTP (phone)
  static Future<void> signInWithOtp({
    required String phone,
  }) async {
    await auth.signInWithOtp(
      phone: phone,
      shouldCreateUser: true,
    );
  }

  /// Verify OTP
  static Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  }) async {
    return await auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  /// Sign in with Google via Supabase OAuth (browser / Custom Tabs).
  /// Avoids native `google_sign_in` + Android OAuth SHA fingerprint issues.
  static Future<AuthResponse> signInWithGoogle() async {
    print('🔵 SupabaseService.signInWithGoogle: Starting...');
    if (auth.currentSession != null) {
      print('🟣 Existing session found; skipping OAuth launch');
      return AuthResponse(session: auth.currentSession, user: auth.currentUser);
    }
    if (kIsWeb) {
      return await _signInWithGoogleWeb();
    }
    return await _signInWithGoogleOAuth();
  }

  static Future<AuthResponse> _signInWithGoogleWeb() async {
    print('🔵 Using OAuth for web...');
    final redirectTo = Uri.base.origin;
    final res = await auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo.toString(),
    );
    if (!res) {
      throw Exception('Failed to initiate Google Sign-In');
    }
    final state = await auth.onAuthStateChange
        .timeout(
          const Duration(minutes: 5),
          onTimeout: (sink) {
            sink.addError(Exception('OAuth timeout'));
          },
        )
        .firstWhere((s) => s.event == AuthChangeEvent.signedIn);
    if (state.session == null) {
      throw Exception('No session after Google Sign-In');
    }
    return AuthResponse(session: state.session, user: state.session?.user);
  }

  /// Google Sign-In (Android, iOS, desktop): browser-based OAuth + deep link or redirect.
  static Future<AuthResponse> _signInWithGoogleOAuth() async {
    print('🔵 Using browser-based OAuth (Supabase + Google)...');

    // Register in Supabase Dashboard → Authentication → URL Configuration → Redirect URLs.
    const deepLinkScheme = 'duuka://login-callback';

    print('🔵 Using redirect callback: $deepLinkScheme');

    final res = await auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: deepLinkScheme,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );

    if (!res) {
      throw Exception('Failed to initiate Google Sign-In');
    }

    print('🔵 Waiting for auth callback...');

    try {
      final state = await auth.onAuthStateChange
          .timeout(
            const Duration(minutes: 5),
            onTimeout: (sink) {
              sink.addError(Exception(
                'OAuth timeout — complete sign-in in the browser and ensure redirect URL is allowed in Supabase.',
              ));
            },
          )
          .firstWhere((s) => s.event == AuthChangeEvent.signedIn);

      if (state.session == null) {
        throw Exception('No session after Google Sign-In');
      }

      print('🟢 Google Sign-In complete');
      return AuthResponse(session: state.session, user: state.session?.user);
    } catch (e) {
      print('🔴 OAuth error: $e');
      rethrow;
    }
  }

  /// Sign out from Google (native flow unused; kept for API compatibility)
  static Future<void> signOutGoogle() async {}

  /// Sign out
  static Future<void> signOut() async {
    await signOutGoogle();
    await auth.signOut();
  }

  /// Refresh session
  static Future<AuthResponse> refreshSession() async {
    return await auth.refreshSession();
  }

  // Database helpers
  static SupabaseQueryBuilder from(String table) => client.from(table);

  /// Insert a record
  static Future<Map<String, dynamic>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    final response = await client.from(table).insert(data).select().single();
    return response;
  }

  /// Update a record
  static Future<Map<String, dynamic>> update(
    String table,
    Map<String, dynamic> data, {
    required String matchColumn,
    required dynamic matchValue,
  }) async {
    final response = await client
        .from(table)
        .update(data)
        .eq(matchColumn, matchValue)
        .select()
        .single();
    return response;
  }

  /// Upsert a record
  static Future<Map<String, dynamic>> upsert(
    String table,
    Map<String, dynamic> data,
  ) async {
    final response = await client.from(table).upsert(data).select().single();
    return response;
  }

  /// Delete a record
  static Future<void> delete(
    String table, {
    required String matchColumn,
    required dynamic matchValue,
  }) async {
    await client.from(table).delete().eq(matchColumn, matchValue);
  }

  /// Select records
  static Future<List<Map<String, dynamic>>> select(
    String table, {
    String columns = '*',
    Map<String, dynamic>? filters,
  }) async {
    var query = client.from(table).select(columns);

    if (filters != null) {
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  /// Select single record
  static Future<Map<String, dynamic>?> selectSingle(
    String table, {
    String columns = '*',
    required String matchColumn,
    required dynamic matchValue,
  }) async {
    final response = await client
        .from(table)
        .select(columns)
        .eq(matchColumn, matchValue)
        .maybeSingle();
    return response;
  }
}
