import 'dart:io' show Platform;
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SupabaseService {
  static GoogleSignIn? _googleSignIn;
  static SupabaseClient? _client;
  static String? _googleWebClientId;
  static String? _supabaseUrl;

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('SupabaseService not initialized. Call initialize() first.');
    }
    return _client!;
  }

  static GoTrueClient get auth => client.auth;

  /// Handle OAuth redirect deep link (desktop) and exchange code for session.
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

      print('🟣 Handling OAuth deep link callback (code present: true)');
      await auth.exchangeCodeForSession(code);
      print('🟢 OAuth code exchanged for session');
      return true;
    } catch (e) {
      print('🔴 Failed to handle auth deep link: $e');
      rethrow;
    }
  }

  /// Check if running on desktop platform
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  static Future<void> initialize({
    required String url,
    required String anonKey,
    String? googleWebClientId,
  }) async {
    _googleWebClientId = googleWebClientId;
    // Guard against misconfigured env vars (e.g. missing scheme).
    // If SUPABASE_URL is provided as "project-ref.supabase.co", force https.
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

    // Initialize Google Sign-In if web client ID is provided (for mobile only)
    if (!isDesktop && googleWebClientId != null && googleWebClientId.isNotEmpty) {
      _googleSignIn = GoogleSignIn(
        serverClientId: googleWebClientId,
      );
    }
  }

  /// Get current session
  static Session? get currentSession => _client?.auth.currentSession;

  /// Get current user
  static User? get currentUser => _client?.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentSession != null;

  /// Get user ID
  static String? get userId => currentUser?.id;

  /// Get user phone
  static String? get userPhone => currentUser?.phone;

  /// Listen to auth state changes
  static Stream<AuthState> get onAuthStateChange => auth.onAuthStateChange;

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

  /// Sign in with Google
  /// On desktop, uses browser-based OAuth. On mobile, uses native Google Sign-In.
  static Future<AuthResponse> signInWithGoogle() async {
    print('🔵 SupabaseService.signInWithGoogle: Starting...');
    print('🔵 Platform: isDesktop=$isDesktop');

    if (isDesktop) {
      // Desktop: Use browser-based OAuth
      return await _signInWithGoogleDesktop();
    } else {
      // Mobile: Use native Google Sign-In
      return await _signInWithGoogleMobile();
    }
  }

  /// Desktop Google Sign-In using browser-based OAuth
  static Future<AuthResponse> _signInWithGoogleDesktop() async {
    print('🔵 Using browser-based OAuth for desktop...');

    // For desktop OAuth with Supabase:
    // 1. The redirect URI in Google Cloud Console should be: 
    //    https://iellujtngoahicjgdexr.supabase.co/auth/v1/callback
    // 2. Supabase will handle the OAuth callback and redirect to a deep link
    // 3. We use a custom deep link scheme that the app can handle
    // 4. The deep link must be registered in Supabase dashboard under Redirect URLs
    
    // Use a deep link scheme for desktop callback
    // This must be registered in Supabase Dashboard > Authentication > URL Configuration > Redirect URLs
    const deepLinkScheme = 'duuka://login-callback';
    
    print('🔵 Using deep link callback: $deepLinkScheme');
    
    // Use Supabase's OAuth flow which opens the default browser
    // After Google OAuth completes, Supabase will redirect to the deep link
    final res = await auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: deepLinkScheme,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );

    if (!res) {
      throw Exception('Failed to initiate Google Sign-In');
    }

    // Wait for the auth state to change (user completes login in browser)
    // The deep link will trigger Supabase to complete the auth flow
    print('🔵 Waiting for auth callback via deep link...');
    
    // Set a timeout to prevent hanging forever
    try {
      final completer = await auth.onAuthStateChange
          .timeout(
            const Duration(minutes: 5),
            onTimeout: (sink) {
              sink.addError(Exception('OAuth timeout - please complete login in browser and ensure deep link is configured'));
            },
          )
          .firstWhere(
            (state) => state.event == AuthChangeEvent.signedIn,
          );

      if (completer.session == null) {
        throw Exception('No session after Google Sign-In');
      }

      print('🟢 Desktop Google Sign-In complete');
      return AuthResponse(session: completer.session, user: completer.session?.user);
    } catch (e) {
      print('🔴 Desktop OAuth error: $e');
      rethrow;
    }
  }

  /// Mobile Google Sign-In using native SDK
  static Future<AuthResponse> _signInWithGoogleMobile() async {
    print('🔵 Using native Google Sign-In for mobile...');

    if (_googleSignIn == null) {
      print('🔴 Google Sign-In not initialized');
      throw Exception(
        'Google Sign-In not initialized. Provide googleWebClientId in initialize().',
      );
    }

    // Trigger Google Sign-In flow
    print('🔵 Triggering Google Sign-In flow...');
    final googleUser = await _googleSignIn!.signIn();
    if (googleUser == null) {
      print('🔴 Google Sign-In was cancelled by user');
      throw Exception('Google Sign-In was cancelled.');
    }
    print('🟢 Got Google user: ${googleUser.email}');

    // Get auth details from Google
    print('🔵 Getting Google auth tokens...');
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;
    print('🟢 Got tokens - idToken: ${idToken != null}, accessToken: ${accessToken != null}');

    if (idToken == null) {
      print('🔴 No ID token from Google');
      throw Exception('Failed to get ID token from Google.');
    }

    // Sign in to Supabase with the Google ID token
    print('🔵 Signing in to Supabase with Google token...');
    final response = await auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
    print('🟢 Supabase sign-in complete');

    return response;
  }

  /// Sign out from Google (call this alongside regular signOut)
  static Future<void> signOutGoogle() async {
    if (_googleSignIn != null) {
      await _googleSignIn!.signOut();
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    // Sign out from Google if active
    await signOutGoogle();
    // Sign out from Supabase
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
