import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:meal_tracker/app/route_observer.dart';
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
import 'package:meal_tracker/features/onboarding/widgets/onboarding_flow.dart';
import 'package:meal_tracker/features/onboarding/widgets/paywall_screen.dart';
import 'package:meal_tracker/features/scanner/widgets/barcode_scanner_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  observers: [appRouteObserver],
  initialLocation: '/diary',
  refreshListenable: AuthService(),
  redirect: (context, state) {
    final auth = AuthService();
    final location = state.matchedLocation;
    final isOnboardingRoute = location == '/onboarding';
    final isPaywallRoute = location == '/paywall';

    // 1. Онбординг не пройден → онбординг
    if (!auth.onboardingCompleted && !isOnboardingRoute) {
      return '/onboarding';
    }

    // 2. Не premium + лимит исчерпан → hard paywall
    if (auth.onboardingCompleted &&
        !auth.isPremium &&
        auth.freeTrialExhausted &&
        !isPaywallRoute) {
      return '/paywall';
    }

    // 3. Premium — не пускать на paywall/onboarding
    if (auth.onboardingCompleted &&
        auth.isPremium &&
        (isPaywallRoute || isOnboardingRoute)) {
      return '/diary';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OnboardingFlow(),
    ),
    GoRoute(
      path: '/paywall',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PaywallScreen(),
    ),
    GoRoute(
      path: '/diary',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DiaryScreen(),
    ),
    GoRoute(
      path: '/profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/stats',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const StatsScreen(),
    ),
    GoRoute(
      path: '/favorites',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/search',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final mealType = state.uri.queryParameters['meal_type'] ?? 'snack';
        final dateStr = state.uri.queryParameters['date'];
        final query = state.uri.queryParameters['query'];
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: SearchScreen(
            mealType: mealType,
            dateStr: dateStr,
            initialQuery: query,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final offsetAnimation = animation.drive(
              Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic)),
            );
            return SlideTransition(position: offsetAnimation, child: child);
          },
        );
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
    GoRoute(
      path: '/scanner',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final mealType = state.uri.queryParameters['meal_type'] ?? 'snack';
        final dateStr = state.uri.queryParameters['date'];
        return BarcodeScannerScreen(mealType: mealType, dateStr: dateStr);
      },
    ),
  ],
);
