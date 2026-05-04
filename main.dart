import 'package:flutter/material.dart';
import 'dart:async' show unawaited;
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme.dart';
import 'utils/app_state.dart';
import 'widgets/paywall_gate.dart';

import 'screens/splash_screen.dart';
import 'screens/reminders_page.dart';
import 'screens/badges_page.dart';
import 'screens/actions_page.dart';
import 'screens/dhikr_counter_page.dart';
import 'screens/salat_courses_page.dart';
import 'screens/morning_dhikr_page.dart';
import 'screens/evening_dhikr_page.dart';
import 'screens/sajda_verses_page.dart';
import 'screens/mosques_page.dart';
import 'screens/prayer_times_page.dart';
import 'services/reminder_service.dart';
import 'services/notification_service.dart';
import 'services/subscription_service.dart';
import 'services/backup_service.dart';
import 'services/maintenance_service.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'utils/language_controller.dart';
import 'utils/audio_config.dart';
import 'utils/theme_controller.dart';

// Clé globale pour la navigation et les dialogues
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialisation critique de l'audio
  await AudioConfig.ensureInitialized();
  
  // 2. Initialisation de la langue et du thème avant le lancement de l'app
  await LanguageController.loadSaved();
  await ThemeController.loadSaved();

  // 3. Gestion du Force Logout
  try {
    final shouldForce = await StorageService.consumeForceLogoutFlag();
    if (shouldForce) {
      await AuthService.signOut();
      await StorageService.resetOnboardingFlag();
    }
  } catch (e) {
    debugPrint('[ForceLogout] error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Lancement des services en arrière-plan après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServicesAsync();
    });
  }

  Future<void> _initializeServicesAsync() async {
    if (!mounted) return;

    // Initialisation des rappels avec la clé de navigation
    try {
      ReminderService.initializeWithNavigatorKey(_rootNavigatorKey);
    } catch (e) {
      debugPrint('Erreur Rappels: $e');
    }

    // Services de Notifications
    try {
      await NotificationService.initialize();
      unawaited(NotificationService.scheduleDailyEncouragements());
      unawaited(NotificationService.scheduleActiveReminders());
    } catch (e) {
      debugPrint('Erreur Notifications: $e');
    }
    
    // Services d'achats (uniquement sur mobile)
    if (!kIsWeb) {
      try {
        await SubscriptionService.initializePurchases();
        unawaited(SubscriptionService.verifySubscriptionStatus());
      } catch (e) {
        debugPrint('Erreur Achats: $e');
      }
    }

    // Tâches de maintenance silencieuses
    unawaited(BackupService.createAutoBackup());
    unawaited(MaintenanceService.initialize());
  }

  @override
  void dispose() {
    ReminderService.dispose();
    SubscriptionService.dispose();
    MaintenanceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState()..initializeUser(),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.mode,
        builder: (context, themeMode, _) {
          return ValueListenableBuilder<Locale>(
            valueListenable: LanguageController.locale,
            builder: (context, locale, _) {
              return MaterialApp(
                navigatorKey: _rootNavigatorKey,
                title: 'Sajda',
                debugShowCheckedModeBanner: false,
                theme: lightTheme,
                darkTheme: darkTheme,
                themeMode: themeMode,
                locale: locale,
                supportedLocales: const [
                  Locale('fr'),
                  Locale('en'),
                  Locale('ar'),
                ],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                builder: (context, child) {
                  return PaywallGate(
                    child: SafeArea(
                      top: false,
                      bottom: true,
                      child: child ?? const SizedBox.shrink(),
                    ),
                  );
                },
                home: const SplashScreen(),
                routes: {
                  '/reminders': (context) => const RemindersPage(),
                  '/badges': (context) => const BadgesPage(),
                  '/actions': (context) => const ActionsPage(),
                  '/dhikr': (context) => const DhikrCounterPage(),
                  '/salat-courses': (context) => const SalatCoursesPage(),
                  '/morning-dhikr': (context) => const MorningDhikrPage(),
                  '/evening-dhikr': (context) => const EveningDhikrPage(),
                  '/sajda-verses': (context) => const SajdaVersesPage(),
                  '/mosques': (context) => const MosquesPage(),
                  '/prayer-times': (context) => const PrayerTimesPage(),
                },
              );
            },
          );
        },
      ),
    );
  }
}
