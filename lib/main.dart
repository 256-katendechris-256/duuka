import 'dart:async';
import 'dart:convert';

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

  // Load Supabase config from bundled asset (assets/config/supabase_config.json)
  final configJson =
      await rootBundle.loadString('assets/config/supabase_config.json');
  final config = jsonDecode(configJson) as Map<String, dynamic>;
  final supabaseUrl = (config['supabaseUrl'] as String?)?.trim() ?? '';
  final supabaseAnonKey = (config['supabaseAnonKey'] as String?)?.trim() ?? '';
  final googleWebClientId =
      ((config['googleWebClientId'] as String?) ?? '').trim();

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
        'Supabase configuration is missing. Please set supabaseUrl and supabaseAnonKey in assets/config/supabase_config.json');
  }

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
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await SupabaseService.handleAuthDeepLink(initial);
      }
    } catch (e) {
      // Don't crash app on link parsing/handling.
    }

    _linkSub = _appLinks.uriLinkStream.listen((uri) async {
      try {
        await SupabaseService.handleAuthDeepLink(uri);
      } catch (_) {}
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
