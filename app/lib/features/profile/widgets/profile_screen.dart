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
import 'package:meal_tracker/core/services/theme_service.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';

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
  final _calorieController = TextEditingController(text: '');
  final _proteinController = TextEditingController(text: '');
  final _fatController = TextEditingController(text: '');
  final _carbsController = TextEditingController(text: '');

  /// КБЖУ-инпуты не должны получать фокус сами при возврате на экран / смене локали.
  void _scheduleUnfocusGoalInputs() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route?.isCurrent != true) return;
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  @override
  void initState() {
    super.initState();
    LocaleNotifier.instance.addListener(_scheduleUnfocusGoalInputs);
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
    _scheduleUnfocusGoalInputs();
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
    LocaleNotifier.instance.removeListener(_scheduleUnfocusGoalInputs);
    appRouteObserver.unsubscribe(this);
    _saveGoals();
    _calorieController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  Future<void> _initDb() async {
    _db = await AppDatabase.getInstance();
    _calorieController.text =
        await _db.getSetting('calorie_goal') ?? '2000';
    _proteinController.text =
        await _db.getSetting('protein_goal') ?? '';
    _fatController.text = await _db.getSetting('fat_goal') ?? '';
    _carbsController.text =
        await _db.getSetting('carbs_goal') ?? '';
    final anyPushReminders = await _anyPushReminderEnabledFromDb();
    if (mounted) {
      setState(() {
        _dbReady = true;
        _anyPushReminderEnabled = anyPushReminders;
      });
      _scheduleUnfocusGoalInputs();
    }
  }

  Future<void> _saveGoals() async {
    await _db.setSetting('calorie_goal', _calorieController.text);
    await _db.setSetting('protein_goal', _proteinController.text);
    await _db.setSetting('fat_goal', _fatController.text);
    await _db.setSetting('carbs_goal', _carbsController.text);
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

  Future<void> _signInFromGuest() async {
    final success = await AuthService().signInWithGoogle();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.signedInSnackbar)),
      );
      setState(() {});
    }
  }

  Future<void> _signInWithAppleFromGuest() async {
    final success = await AuthService().signInWithApple();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.signedInSnackbar)),
      );
      setState(() {});
    }
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
                trailing: LocaleNotifier.instance.value.languageCode ==
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
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
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
    final lineBorder =
        _isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lineBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x081B364A),
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
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
    final subtitle = auth.userEmail ??
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
                          color:
                              Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 14 / 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
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
              ? [
                  const Color(0xFF1A2340),
                  const Color(0xFF162035),
                ]
              : [
                  const Color(0xFFEEF4FF),
                  const Color(0xFFE0ECFF),
                ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x081B364A),
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
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

  Widget _proBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle,
            size: 16,
            color: AppColors.primary.withAlpha(_isDark ? 200 : 255),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 18 / 14,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
            ),
          ),
        ),
      ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Goals Card ──────────────────────────────────────────────

  Widget _buildGoalsCard() {
    return _card(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        child: Column(
          children: [
            _goalRow(
              'assets/icons/cal.svg',
              context.l10n.goalCaloriesKcal,
              _calorieController,
            ),
            const SizedBox(height: 12),
            _goalRow(
              'assets/icons/belok.svg',
              context.l10n.goalProteinG,
              _proteinController,
            ),
            const SizedBox(height: 12),
            _goalRow(
              'assets/icons/fat.svg',
              context.l10n.goalFatG,
              _fatController,
            ),
            const SizedBox(height: 12),
            _goalRow(
              'assets/icons/uglevod.svg',
              context.l10n.goalCarbsG,
              _carbsController,
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalRow(
    String iconAsset,
    String label,
    TextEditingController controller,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: SvgPicture.asset(iconAsset, width: 28, height: 28),
        ),
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
        Container(
          width: 70,
          decoration: BoxDecoration(
            color: _isDark
                ? AppColors.darkOnBack4
                : AppColors.lightOnBack4,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isDark ? AppColors.lineDT200 : AppColors.lineLight200,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 18 / 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              isDense: true,
              hintText: '0',
              hintStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 18 / 14,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
              ),
            ),
            onChanged: (_) => _saveGoals(),
          ),
        ),
      ],
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
          ],
        ),
      ),
    );
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
