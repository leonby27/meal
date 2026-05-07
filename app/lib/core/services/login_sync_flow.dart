import 'package:flutter/material.dart';

import 'package:meal_tracker/core/services/login_sync_service.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';

/// UI orchestration around [LoginSyncService] — runs after a successful
/// social sign-in to reconcile pre-login local data with the user's
/// cloud account.
///
/// Two callers use this: the dedicated `LoginScreen` and the
/// "sign-in from guest" affordance on the profile screen.
class LoginSyncFlow {
  const LoginSyncFlow._();

  /// Decide what to do with local pre-login data, prompt the user if
  /// needed, run the sync, and surface any error via a snackbar. The
  /// caller is responsible for [_loading] state on its own widget — this
  /// helper shows its own modal progress dialog while the sync runs.
  ///
  /// Returns when the flow has finished (success or otherwise). Never
  /// throws.
  static Future<void> runAfterSignIn(BuildContext context) async {
    final service = LoginSyncService();

    bool hasLocal;
    try {
      hasLocal = await service.hasLocalData();
    } catch (e) {
      debugPrint('LoginSyncFlow.hasLocalData failed: $e');
      return;
    }
    if (!context.mounted) return;

    bool migrate = false;
    if (hasLocal) {
      final answer = await _askMigrate(context);
      if (!context.mounted) return;
      migrate = answer ?? false;
    }

    await _runWithLoader(context, () async {
      if (migrate) {
        await service.migrateAndPull();
      } else {
        await service.pullOnly();
      }
    });
  }

  static Future<bool?> _askMigrate(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(ctx.l10n.mergeLocalDataTitle),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(ctx.l10n.mergeLocalDataReplace),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(ctx.l10n.mergeLocalDataKeep),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _runWithLoader(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 16),
              Flexible(child: Text(ctx.l10n.loginSyncing)),
            ],
          ),
        ),
      ),
    );

    Object? caughtError;
    try {
      await action();
    } catch (e) {
      caughtError = e;
      debugPrint('LoginSyncFlow sync failed: $e');
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (caughtError != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.loginSyncFailed)),
      );
    }
  }
}
