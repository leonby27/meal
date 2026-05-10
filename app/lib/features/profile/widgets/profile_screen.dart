import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:meal_tracker/app/route_observer.dart';
import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/build_info.dart';
import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/services/auth_service.dart';
import 'package:meal_tracker/core/services/locale_service.dart';
import 'package:meal_tracker/core/services/login_sync_flow.dart';
import 'package:meal_tracker/core/services/theme_service.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/core/widgets/edit_goals_sheet.dart';
import 'package:meal_tracker/core/widgets/methodology_sources_sheet.dart';

/// When `true`, Profile shows the app theme row again (`ThemeNotifier` + picker).
const bool kShowAppThemePicker = true;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RouteAware {
  late AppDatabase _db;
  bool _dbReady = false;
  bool _anyPushReminderEnabled = false;
  bool _isDeletingAccount = false;
  double _calorieGoal = 2000;
  double _proteinGoal = 100;
  double _fatGoal = 70;
  double _carbsGoal = 250;

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<void>) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    _refreshPushRemindersFromDb();
  }

  Future<bool> _anyPushReminderEnabledFromDb() async {
    for (final k in ['breakfast', 'lunch', 'dinner', 'snack']) {
      final val = await _db.getSetting('reminder_$k');
      if (val != null && val.isNotEmpty && val.contains(':')) {
        return true;
      }
    }
    return false;
  }

  Future<void> _refreshPushRemindersFromDb() async {
    if (!_dbReady) return;
    final any = await _anyPushReminderEnabledFromDb();
    if (mounted) setState(() => _anyPushReminderEnabled = any);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _initDb() async {
    _db = await AppDatabase.getInstance();
    await _loadGoals();
    final anyPushReminders = await _anyPushReminderEnabledFromDb();
    if (mounted) {
      setState(() {
        _dbReady = true;
        _anyPushReminderEnabled = anyPushReminders;
      });
    }
  }

  Future<void> _loadGoals() async {
    final cal = await _db.getSetting('calorie_goal');
    final prot = await _db.getSetting('protein_goal');
    final fat = await _db.getSetting('fat_goal');
    final carbs = await _db.getSetting('carbs_goal');
    if (!mounted) return;
    setState(() {
      _calorieGoal = double.tryParse(cal ?? '') ?? 2000;
      _proteinGoal = double.tryParse(prot ?? '') ?? 100;
      _fatGoal = double.tryParse(fat ?? '') ?? 70;
      _carbsGoal = double.tryParse(carbs ?? '') ?? 250;
    });
  }

  Future<void> _openGoalsSheet() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xCC000000),
      builder: (ctx) => EditGoalsSheet(
        initialCalories: _calorieGoal,
        initialProtein: _proteinGoal,
        initialFat: _fatGoal,
        initialCarbs: _carbsGoal,
      ),
    );
    if (saved == true && mounted) {
      await _loadGoals();
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.signOutConfirm),
        content: Text(ctx.l10n.signOutLocalDataKept),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.signOut),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await AuthService().signOut();
    if (mounted) setState(() {});
  }

  Future<void> _deleteAccount() async {
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.deleteAccountConfirmTitle),
        content: Text(ctx.l10n.deleteAccountConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.deleteAccount),
          ),
        ],
      ),
    );
    if (firstConfirm != true || !mounted) return;

    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.deleteAccountFinalConfirmTitle),
        content: Text(ctx.l10n.deleteAccountFinalConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.delete),
          ),
        ],
      ),
    );
    if (finalConfirm != true || !mounted) return;

    setState(() => _isDeletingAccount = true);
    try {
      await AuthService().deleteAccount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.deleteAccountSuccess)),
      );
      context.go('/onboarding');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.deleteAccountFailed)));
    } finally {
      if (mounted) setState(() => _isDeletingAccount = false);
    }
  }

  Future<void> _signInFromGuest() async {
    final auth = AuthService();
    final success = await auth.signInWithGoogle();
    if (!mounted) return;
    if (!success) {
      if (auth.lastSignInError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.lastSignInError!),
            duration: const Duration(seconds: 6),
          ),
        );
      }
      return;
    }
    await LoginSyncFlow.runAfterSignIn(context);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.signedInSnackbar)));
    setState(() {});
  }

  Future<void> _signInWithAppleFromGuest() async {
    final success = await AuthService().signInWithApple();
    if (!mounted || !success) return;
    await LoginSyncFlow.runAfterSignIn(context);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.signedInSnackbar)));
    setState(() {});
  }

  Future<void> _startOverOnboarding() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.startOverOnboardingConfirm),
        content: Text(ctx.l10n.startOverOnboardingHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.startOverOnboarding),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await AuthService().resetOnboarding();
    if (!mounted) return;
    context.go('/onboarding');
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return context.l10n.themeSystem;
      case ThemeMode.light:
        return context.l10n.themeLight;
      case ThemeMode.dark:
        return context.l10n.themeDark;
    }
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in ThemeMode.values)
              ListTile(
                title: Text(_themeModeLabel(mode)),
                trailing: ThemeNotifier.instance.value == mode
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  ThemeNotifier.instance.setThemeMode(mode);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final locale in LocaleNotifier.supportedLocales)
              ListTile(
                title: Text(LocaleNotifier.localeName(locale)),
                trailing:
                    LocaleNotifier.instance.value.languageCode ==
                        locale.languageCode
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  LocaleNotifier.instance.setLocale(locale);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_dbReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final auth = AuthService();

    final scaffoldBg = _isDark ? AppColors.darkBack2 : AppColors.lightBack2;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(context.l10n.profileTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _sectionLabel(context.l10n.myProfile),
          const SizedBox(height: 8),
          _buildUserCard(auth),
          const SizedBox(height: 24),
          _sectionLabel(context.l10n.subscription),
          const SizedBox(height: 8),
          auth.isPremium
              ? _buildPremiumSubscriptionCard(auth)
              : _buildFreeSubscriptionCard(),
          const SizedBox(height: 24),
          _sectionLabel(context.l10n.myGoals),
          const SizedBox(height: 8),
          _buildGoalsCard(),
          const SizedBox(height: 24),
          _sectionLabel(context.l10n.myProducts),
          const SizedBox(height: 8),
          _buildProductsCard(),
          const SizedBox(height: 24),
          _sectionLabel(context.l10n.settings),
          const SizedBox(height: 8),
          _buildSettingsCard(),
          if (auth.hasSocialAccount) ...[
            const SizedBox(height: 24),
            _destructiveButton(
              label: context.l10n.deleteAccount,
              icon: Icons.delete_outline,
              isLoading: _isDeletingAccount,
              onTap: _deleteAccount,
            ),
          ],
          const SizedBox(height: 24),
          _buildVersionFooter(),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 18 / 14,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4,
        borderRadius: BorderRadius.circular(20),
        border: AppTheme.cardEdgeBorder(isDark: _isDark),
        boxShadow: AppTheme.cardElevatedShadows(isDark: _isDark),
      ),
      child: child,
    );
  }

  Widget _iconCircle(IconData icon, Color bg) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(child: Icon(icon, size: 20, color: Colors.white)),
    );
  }

  // ── User Card ───────────────────────────────────────────────

  Widget _buildUserCard(AuthService auth) {
    // Apple only returns email on the FIRST authorization, so we can't rely
    // on `userEmail`. `hasSocialAccount` tracks whether a real sign-in
    // (Google/Apple) completed, independent of what fields Apple returned.
    final hasAccount = auth.hasSocialAccount;
    final subtitle =
        auth.userEmail ??
        (hasAccount
            ? (auth.authProvider == AuthService.providerApple
                  ? 'Apple ID'
                  : context.l10n.defaultUserName)
            : context.l10n.guestMode);

    return _card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: auth.userPhotoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            auth.userPhotoUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            (auth.userName ?? context.l10n.defaultUserName)
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              height: 32 / 24,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.userName ?? context.l10n.defaultUserName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 20 / 15,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 14 / 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasAccount)
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: context.l10n.signOut,
                    onPressed: _signOut,
                  ),
              ],
            ),
            if (!hasAccount) ...[
              const SizedBox(height: 15),
              if (Platform.isIOS)
                _neutralButton(
                  label: context.l10n.signInApple,
                  icon: Icons.apple,
                  onTap: _signInWithAppleFromGuest,
                )
              else
                _neutralButton(
                  label: context.l10n.signInGoogle,
                  icon: Icons.account_circle,
                  onTap: _signInFromGuest,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _neutralButton({
    required String label,
    IconData? icon,
    String? svgAsset,
    required VoidCallback onTap,
  }) {
    final contentColor = _isDark
        ? AppColors.neutralBtnContent
        : AppColors.neutralBtnContentLight;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: _isDark
              ? AppColors.neutralBtnBack
              : AppColors.neutralBtnBackLight,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (svgAsset != null)
              SvgPicture.asset(
                svgAsset,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(contentColor, BlendMode.srcIn),
              )
            else if (icon != null)
              Icon(icon, size: 20, color: contentColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 18 / 14,
                color: contentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _destructiveButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    final color = Theme.of(context).colorScheme.error;
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: color.withAlpha(_isDark ? 28 : 18),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else
              Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 18 / 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _displayPlanName(String? planName) {
    switch (planName) {
      case 'yearly':
        return context.l10n.planYearly;
      default:
        return context.l10n.planWeekly;
    }
  }

  // ── Subscription Cards ──────────────────────────────────────

  Widget _buildFreeSubscriptionCard() {
    final auth = AuthService();
    final remaining = auth.freeEntriesRemaining;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDark
              ? [const Color(0xFF1A2340), const Color(0xFF162035)]
              : [const Color(0xFFEEF4FF), const Color(0xFFE0ECFF)],
        ),
        border: AppTheme.cardEdgeBorder(isDark: _isDark),
        boxShadow: AppTheme.cardElevatedShadows(isDark: _isDark),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  context.l10n.proTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 22 / 17,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              auth.freeTrialExhausted
                  ? context.l10n.freeLimitReached
                  : context.l10n.freeEntriesRemaining(remaining),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 18 / 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => context.push('/paywall'),
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Text(
                    context.l10n.getPro,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 18 / 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumSubscriptionCard(AuthService auth) {
    return _card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
        child: Column(
          children: [
            Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  context.l10n.proTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 22 / 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    context.l10n.proActive,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  context.l10n.planLabel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 20 / 15,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  _displayPlanName(auth.planName),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 20 / 15,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  context.l10n.billingLabel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 20 / 15,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  auth.nextBillingDate ?? '—',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 20 / 15,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _neutralButton(
              label: context.l10n.manageSubscription,
              svgAsset: 'assets/icons/settings_adjust.svg',
              onTap: () {
                final url = Platform.isIOS
                    ? 'https://apps.apple.com/account/subscriptions'
                    : 'https://play.google.com/store/account/subscriptions';
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Goals Card ──────────────────────────────────────────────

  Widget _buildGoalsCard() {
    final cs = Theme.of(context).colorScheme;
    final secondary = _isDark
        ? AppColors.darkSecondaryDark
        : AppColors.lightSecondaryDark;
    final pillBg = _isDark ? AppColors.darkSurface2 : AppColors.lightScaffold;
    final pillText = _isDark
        ? AppColors.darkPrimaryLight
        : AppColors.lightPrimaryLight;

    return _card(
      child: GestureDetector(
        onTap: _openGoalsSheet,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.myGoals,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 22 / 16,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: pillBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/edit.svg',
                          width: 14,
                          height: 14,
                          colorFilter: ColorFilter.mode(
                            pillText,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.l10n.edit,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 16 / 13,
                            color: pillText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _GoalSummaryCell(
                      iconAsset: 'assets/icons/cal.svg',
                      value: _calorieGoal.toInt().toString(),
                      unit: 'kcal',
                      primary: cs.onSurface,
                      secondary: secondary,
                    ),
                  ),
                  Expanded(
                    child: _GoalSummaryCell(
                      iconAsset: 'assets/icons/belok.svg',
                      value: _proteinGoal.toInt().toString(),
                      unit: 'g',
                      primary: cs.onSurface,
                      secondary: secondary,
                    ),
                  ),
                  Expanded(
                    child: _GoalSummaryCell(
                      iconAsset: 'assets/icons/uglevod.svg',
                      value: _carbsGoal.toInt().toString(),
                      unit: 'g',
                      primary: cs.onSurface,
                      secondary: secondary,
                    ),
                  ),
                  Expanded(
                    child: _GoalSummaryCell(
                      iconAsset: 'assets/icons/fat.svg',
                      value: _fatGoal.toInt().toString(),
                      unit: 'g',
                      primary: cs.onSurface,
                      secondary: secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Products Card ───────────────────────────────────────────

  Widget _buildProductsCard() {
    return _card(
      child: GestureDetector(
        onTap: () => context.push('/my-products'),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _iconCircle(Icons.restaurant_menu, AppColors.sepia),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.productsList,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 18 / 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.allProducts,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 18 / 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Settings Card ───────────────────────────────────────────

  Widget _buildSettingsCard() {
    return _card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (kShowAppThemePicker) ...[
              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeNotifier.instance,
                builder: (context, mode, _) {
                  return _settingsRow(
                    icon: Icons.nightlight_round,
                    iconBg: AppColors.error,
                    label: context.l10n.appTheme,
                    value: _themeModeLabel(mode),
                    onTap: _showThemeSelector,
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
            ValueListenableBuilder<Locale>(
              valueListenable: LocaleNotifier.instance,
              builder: (context, locale, _) {
                return _settingsRow(
                  icon: Icons.language,
                  iconBg: AppColors.success,
                  label: context.l10n.languageSelector,
                  value: LocaleNotifier.localeName(locale),
                  onTap: _showLanguageSelector,
                );
              },
            ),
            const SizedBox(height: 12),
            _settingsRow(
              icon: Icons.notifications,
              iconBg: AppColors.purple,
              label: context.l10n.pushNotifications,
              value: _anyPushReminderEnabled
                  ? context.l10n.pushNotificationsShortOn
                  : context.l10n.pushNotificationsShortOff,
              onTap: () => context.push('/reminders'),
            ),
            const SizedBox(height: 12),
            _settingsRow(
              icon: Icons.menu_book_outlined,
              iconBg: AppColors.primary,
              label: context.l10n.profileMethodology,
              onTap: _showMethodologySheet,
            ),
          ],
        ),
      ),
    );
  }

  void _showMethodologySheet() {
    showMethodologySourcesSheet(context);
  }

  Widget _settingsRow({
    required IconData icon,
    required Color iconBg,
    required String label,
    String? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          _iconCircle(icon, iconBg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 18 / 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (value != null) ...[
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 18 / 14,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                ],
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Version Footer ──────────────────────────────────────────

  Widget _buildVersionFooter() {
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'MealTracker v$appVersion',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 18 / 14,
              color: mutedColor,
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _startOverOnboarding,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: mutedColor,
            ),
            child: Text(
              context.l10n.startOverOnboarding,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 16 / 12,
                color: mutedColor.withValues(alpha: 0.7),
                decoration: TextDecoration.underline,
                decorationColor: mutedColor.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalSummaryCell extends StatelessWidget {
  const _GoalSummaryCell({
    required this.iconAsset,
    required this.value,
    required this.unit,
    required this.primary,
    required this.secondary,
  });

  final String iconAsset;
  final String value;
  final String unit;
  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(iconAsset, width: 28, height: 28),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 22 / 16,
              color: primary,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 16 / 12,
            color: secondary,
          ),
        ),
      ],
    );
  }
}
