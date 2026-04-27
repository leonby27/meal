import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:meal_tracker/core/services/auth_service.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  /// Apple sign-in is available only on iOS/macOS.
  bool get _showAppleSignIn =>
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  /// Google sign-in is configured for Android only. The iOS build lacks
  /// the URL-scheme / Firebase setup and previously crashed when tapped.
  bool get _showGoogleSignIn => kIsWeb || !Platform.isIOS;

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    final auth = AuthService();
    final ok = await auth.signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok && auth.lastSignInError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.lastSignInError!),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _loading = true);
    await AuthService().signInWithApple();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _skipLogin() async {
    setState(() => _loading = true);
    await AuthService().skipLogin();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Icon(
                Icons.restaurant_menu,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'MealTracker',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.calorieTracking,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(flex: 2),
              if (_loading)
                const SizedBox(
                  height: 176,
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                if (_showGoogleSignIn)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _signInWithGoogle,
                      icon: const Icon(Icons.account_circle, size: 24),
                      label: Text(
                        context.l10n.signInGoogle,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                if (_showAppleSignIn) ...[
                  if (_showGoogleSignIn) const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _signInWithApple,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.apple, size: 26),
                      label: Text(
                        context.l10n.signInApple,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _skipLogin,
                    child: Text(
                      context.l10n.skipLogin,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                context.l10n.signInSyncHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
