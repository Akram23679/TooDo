import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Run both checks in parallel
  final results = await Future.wait([
    _initProvider(),
    shouldShowOnboarding(),
  ]);

  final provider = results[0] as TaskProvider;
  final showOnboarding = results[1] as bool;

  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: TooDoApp(showOnboarding: showOnboarding),
    ),
  );
}

Future<TaskProvider> _initProvider() async {
  final provider = TaskProvider();
  await provider.init();
  return provider;
}

class TooDoApp extends StatelessWidget {
  final bool showOnboarding;
  const TooDoApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Too Do',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: Consumer<TaskProvider>(
        builder: (ctx, provider, _) {
          // Show spinner while data loads
          if (!provider.isLoaded) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          // First launch → onboarding
          if (showOnboarding) {
            return const OnboardingScreen();
          }
          // Returning user → app
          return const MainShell();
        },
      ),
    );
  }
}