import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:meal_tracker/l10n/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:meal_tracker/app/router.dart';
import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/api/api_client.dart';
import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/services/analytics_service.dart';
import 'package:meal_tracker/core/services/auth_service.dart';
import 'package:meal_tracker/core/services/device_id_service.dart';
import 'package:meal_tracker/core/services/entitlement_service.dart';
import 'package:meal_tracker/core/services/notification_service.dart';
import 'package:meal_tracker/core/services/locale_service.dart';
import 'package:meal_tracker/core/services/subscription_service.dart';
import 'package:meal_tracker/core/services/theme_service.dart';
import 'package:meal_tracker/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (DefaultFirebaseOptions.isSupported) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await AnalyticsService.instance.init();
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }
  }

  await Future.wait([
    initializeDateFormatting('ru', null),
    initializeDateFormatting('en', null),
    initializeDateFormatting('de', null),
    initializeDateFormatting('es', null),
    initializeDateFormatting('fr', null),
    initializeDateFormatting('pt', null),
    AppDatabase.getInstance(),
    ApiClient().init(),
    AuthService().init(),
    // Initializes from local cache synchronously; the server refresh
    // fires from within init() and lands a beat later.
    EntitlementService().init(),
    NotificationService.init(),
    ThemeNotifier.init(),
    LocaleNotifier.init(),
  ]);

  if (!AuthService().isLoggedIn) {
    await AuthService().skipLogin();
  }

  await _wireAnalyticsUserState();

  runApp(const MealTrackerApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    SubscriptionService().init();
    NotificationService.restoreReminders();
  });
}

/// Pushes the stable device id as Firebase's userId and wires listeners
/// on entitlement / locale state so user properties stay in sync for the
/// app's lifetime.
///
/// userId source: [DeviceIdService] (per-install UUID, persisted to
/// SharedPreferences). It is the same identifier we already pass to the
/// backend as `app_account_token` for IAP verification, so server logs,
/// Firebase user-id, and StoreKit `appAccountToken` line up — joining
/// data across systems by hand becomes trivial.
Future<void> _wireAnalyticsUserState() async {
  try {
    final deviceId = await DeviceIdService.getOrCreate();
    await AnalyticsService.instance.setUserId(deviceId);
  } catch (e) {
    debugPrint('Analytics: setUserId failed: $e');
  }

  // Push current entitlement + locale snapshot, then subscribe so any
  // change after launch (server refresh, fresh purchase, locale toggle)
  // updates Firebase too.
  _pushEntitlementProperties();
  EntitlementService().addListener(_pushEntitlementProperties);

  _pushLocaleProperty();
  LocaleNotifier.instance.addListener(_pushLocaleProperty);
}

void _pushEntitlementProperties() {
  final e = EntitlementService();
  AnalyticsService.instance.setUserProperties({
    'is_premium': e.isActive ? 'true' : 'false',
    'subscription_plan': e.plan,
    'is_in_trial': e.isInTrial == null
        ? null
        : (e.isInTrial! ? 'true' : 'false'),
  });
}

void _pushLocaleProperty() {
  final locale = LocaleNotifier.instance.value;
  AnalyticsService.instance.setUserProperty('locale', locale.toLanguageTag());
}

class MealTrackerApp extends StatefulWidget {
  const MealTrackerApp({super.key});

  @override
  State<MealTrackerApp> createState() => _MealTrackerAppState();
}

class _MealTrackerAppState extends State<MealTrackerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // The user might have managed their subscription in App Store
      // settings while we were backgrounded. Refresh in case anything
      // changed; the call is cheap and a no-op when nothing did.
      EntitlementService().refresh();
    }
  }

  void _handleGlobalPointerDown(PointerDownEvent event) {
    final focus = FocusManager.instance.primaryFocus;
    final context = focus?.context;
    if (focus == null || context == null) return;

    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox) {
      final focusedBounds =
          renderObject.localToGlobal(Offset.zero) & renderObject.size;
      if (focusedBounds.contains(event.position)) return;
    }

    // Defer past tap recognition. Tap on another input fires
    // _handleTap → requestFocus on pointer-up, which lands AFTER an
    // end-of-frame callback would. 80 ms is enough for a normal tap
    // to settle. If primary focus has moved to another input by
    // then, skip the unfocus — that keeps the soft keyboard open
    // across input-to-input transitions instead of bouncing closed
    // and reopening.
    Future.delayed(const Duration(milliseconds: 80), () {
      if (FocusManager.instance.primaryFocus == focus) {
        focus.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleNotifier.instance,
      builder: (context, locale, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeNotifier.instance,
          builder: (context, themeMode, _) {
            return MaterialApp.router(
              title: 'Body Meal',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              routerConfig: router,
              locale: locale,
              supportedLocales: LocaleNotifier.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                return Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: _handleGlobalPointerDown,
                  child: child ?? const SizedBox.shrink(),
                );
              },
            );
          },
        );
      },
    );
  }
}
