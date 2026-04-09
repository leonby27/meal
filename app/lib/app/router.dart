import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:meal_tracker/core/services/auth_service.dart';
import 'package:meal_tracker/features/auth/widgets/login_screen.dart';
import 'package:meal_tracker/features/diary/widgets/diary_screen.dart';
import 'package:meal_tracker/features/search/widgets/search_screen.dart';
import 'package:meal_tracker/features/stats/widgets/stats_screen.dart';
import 'package:meal_tracker/features/profile/widgets/profile_screen.dart';
import 'package:meal_tracker/features/favorites/widgets/favorites_screen.dart';
import 'package:meal_tracker/features/camera/widgets/camera_screen.dart';
import 'package:meal_tracker/features/products/widgets/my_products_screen.dart';
import 'package:meal_tracker/features/products/widgets/add_product_screen.dart';
import 'package:meal_tracker/features/products/widgets/add_recipe_screen.dart';
import 'package:meal_tracker/features/history/widgets/history_screen.dart';
import 'package:meal_tracker/features/profile/widgets/reminders_screen.dart';
import 'package:meal_tracker/app/shell_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/diary',
  refreshListenable: AuthService(),
  redirect: (context, state) {
    final loggedIn = AuthService().isLoggedIn;
    final isLoginRoute = state.matchedLocation == '/login';
    if (!loggedIn && !isLoginRoute) return '/login';
    if (loggedIn && isLoginRoute) return '/diary';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
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
        final source = state.uri.queryParameters['source'];
        return CameraScreen(mealType: mealType, dateStr: dateStr, autoSource: source);
      },
    ),
    GoRoute(
      path: '/my-products',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MyProductsScreen(),
    ),
    GoRoute(
      path: '/add-product',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddProductScreen(),
    ),
    GoRoute(
      path: '/add-recipe',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddRecipeScreen(),
    ),
    GoRoute(
      path: '/reminders',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RemindersScreen(),
    ),
  ],
);
