import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:app_links/app_links.dart';

import 'core/theme/app_theme.dart';
import 'data/datasources/local/database_service.dart';
import 'data/datasources/local/preferences_service.dart';
import 'data/datasources/remote/supabase_service.dart';
import 'routes/app_router.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (portrait only)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Initialize Hive for local preferences
  await Hive.initFlutter();
  await PreferencesService.initialize();

  // Initialize Isar database
  await DatabaseService.initialize();

  // Initialize Supabase - credentials must be provided via environment variables
  // Run with: flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  // Or create a .env file and use a package like flutter_dotenv
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Google Web Client ID for OAuth - get this from Google Cloud Console
  const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  // Validate required environment variables
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
      'Missing required environment variables!\n'
      'Please provide SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define:\n'
      'flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key',
    );
  }

  // Initialize Supabase (primary auth backend)
  await SupabaseService.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    googleWebClientId: googleWebClientId.isNotEmpty ? googleWebClientId : null,
  );

  // Run the app
  runApp(
    const ProviderScope(
      child: DuukaApp(),
    ),
  );
}

class DuukaApp extends ConsumerStatefulWidget {
  const DuukaApp({super.key});

  @override
  ConsumerState<DuukaApp> createState() => _DuukaAppState();
}

class _DuukaAppState extends ConsumerState<DuukaApp> {
  late final GoRouter _router;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    // Read router once during initialization to prevent rebuilds
    _router = ref.read(routerProvider);

    // Handle OAuth deep link callbacks (desktop).
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Handle initial link (cold start).
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await SupabaseService.handleAuthDeepLink(initial);
      }
    } catch (e) {
      // Don't crash app on link parsing/handling.
      // The auth flow can still complete via other means.
    }

    // Handle incoming links (warm).
    _linkSub = _appLinks.uriLinkStream.listen((uri) async {
      try {
        await SupabaseService.handleAuthDeepLink(uri);
      } catch (_) {
        // Errors are logged inside SupabaseService.handleAuthDeepLink
      }
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone 11 Pro dimensions
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Duuka',
          debugShowCheckedModeBanner: false,
          theme: DuukaTheme.lightTheme,
          routerConfig: _router,
        );
      },
    );
  }
}
