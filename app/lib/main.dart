import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:meal_tracker/app/router.dart';
import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/api/api_client.dart';
import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);
  await AppDatabase.getInstance();
  await ApiClient().init();
  await NotificationService.init();
  await NotificationService.restoreReminders();
  runApp(const MealTrackerApp());
}

class MealTrackerApp extends StatelessWidget {
  const MealTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MealTracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      locale: const Locale('ru'),
    );
  }
}
