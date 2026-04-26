import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:meal_tracker/l10n/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:meal_tracker/app/router.dart';
import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/api/api_client.dart';
import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/services/auth_service.dart';
import 'package:meal_tracker/core/services/notification_service.dart';
import 'package:meal_tracker/core/services/locale_service.dart';
import 'package:meal_tracker/core/services/subscription_service.dart';
import 'package:meal_tracker/core/services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    NotificationService.init(),
    ThemeNotifier.init(),
    LocaleNotifier.init(),
  ]);

  if (!AuthService().isLoggedIn) {
    await AuthService().skipLogin();
  }

  runApp(const MealTrackerApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    SubscriptionService().init();
    NotificationService.restoreReminders();
  });
}

class MealTrackerApp extends StatelessWidget {
  const MealTrackerApp({super.key});

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

    focus.unfocus();
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
              title: 'MealTracker',
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
