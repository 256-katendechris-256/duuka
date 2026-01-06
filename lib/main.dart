import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'data/datasources/local/database_service.dart';
import 'data/datasources/local/preferences_service.dart';
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

  // TODO: Initialize Firebase when ready
  // Uncomment and configure when Firebase is set up
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  // Run the app
  runApp(
    const ProviderScope(
      child: DuukaApp(),
    ),
  );
}

class DuukaApp extends ConsumerWidget {
  const DuukaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone 11 Pro dimensions
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Duuka',
          debugShowCheckedModeBanner: false,
          theme: DuukaTheme.lightTheme,
          routerConfig: router,
        );
      },
    );
  }
}
