import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:meal_tracker/features/diary/widgets/diary_screen.dart';
import 'package:meal_tracker/features/search/widgets/search_screen.dart';
import 'package:meal_tracker/features/stats/widgets/stats_screen.dart';
import 'package:meal_tracker/features/profile/widgets/profile_screen.dart';
import 'package:meal_tracker/features/favorites/widgets/favorites_screen.dart';
import 'package:meal_tracker/features/camera/widgets/camera_screen.dart';
import 'package:meal_tracker/app/shell_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/diary',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(
          path: '/diary',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DiaryScreen(),
          ),
        ),
        GoRoute(
          path: '/stats',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: StatsScreen(),
          ),
        ),
        GoRoute(
          path: '/favorites',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: FavoritesScreen(),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/search',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final mealType = state.uri.queryParameters['meal_type'] ?? 'snack';
        final dateStr = state.uri.queryParameters['date'];
        return SearchScreen(mealType: mealType, dateStr: dateStr);
      },
    ),
    GoRoute(
      path: '/camera',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final mealType = state.uri.queryParameters['meal_type'] ?? 'snack';
        final dateStr = state.uri.queryParameters['date'];
        return CameraScreen(mealType: mealType, dateStr: dateStr);
      },
    ),
  ],
);
