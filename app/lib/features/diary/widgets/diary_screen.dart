import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:uuid/uuid.dart';

import 'package:meal_tracker/app/route_observer.dart';
import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/services/auth_service.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/core/utils/meal_type_helper.dart';
import 'package:meal_tracker/features/diary/widgets/daily_summary_card.dart';
import 'package:meal_tracker/features/diary/widgets/meal_section.dart';
import 'package:meal_tracker/features/camera/widgets/ai_meal_result_sheet.dart';
import 'package:meal_tracker/features/camera/widgets/camera_screen.dart';

/// Не даёт [PageView] дневника или недели прокрутиться правее страницы «сегодня»
/// (как clamp, без отката).
class _ClampedForwardPageScrollPhysics extends PageScrollPhysics {
  const _ClampedForwardPageScrollPhysics({required this.maxPage, super.parent});

  final int maxPage;

  @override
  _ClampedForwardPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _ClampedForwardPageScrollPhysics(
      maxPage: maxPage,
      parent: buildParent(ancestor),
    );
  }

  double _maxPixels(ScrollMetrics position) {
    if (position.viewportDimension <= 0) return 0;
    return _pixelsForPage(position, maxPage.toDouble());
  }

  double _pixelsForPage(ScrollMetrics position, double page) {
    if (position is PageMetrics) {
      final vf = position.viewportFraction;
      final initialOffset = math.max(
        0.0,
        position.viewportDimension * (vf - 1) / 2,
      );
      return page * position.viewportDimension * vf + initialOffset;
    }
    return page * position.viewportDimension;
  }

  double _getPage(ScrollMetrics position) {
    if (position is PageMetrics) {
      final p = position.page;
      if (p != null) return p;
    }
    if (position.viewportDimension <= 0.0) {
      return 0.0;
    }
    return position.pixels / position.viewportDimension;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (position.viewportDimension <= 0) {
      return super.applyBoundaryConditions(position, value);
    }
    final maxPx = _maxPixels(position);
    if (value > maxPx) {
      return value - maxPx;
    }
    return super.applyBoundaryConditions(position, value);
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (position.viewportDimension <= 0.0) {
      return super.createBallisticSimulation(position, velocity);
    }
    if (velocity <= 0.0 && position.pixels <= position.minScrollExtent) {
      return super.createBallisticSimulation(position, velocity);
    }
    final maxPx = _maxPixels(position);
    final Tolerance tolerance = toleranceFor(position);
    double page = _getPage(position);
    if (velocity < -tolerance.velocity) {
      page -= 0.5;
    } else if (velocity > tolerance.velocity) {
      page += 0.5;
    }
    var target = _pixelsForPage(position, page.roundToDouble());
    target = math.min(target, maxPx);
    if (target != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }
    return null;
  }
}

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> with RouteAware {
  static const double _weekStripHeight = 64.0;
  static const double _inputBarReservedHeight = 62.0;
  static const String _recordsSortOrderSetting = 'diary_records_sort_order';

  DateTime _selectedDate = DateTime.now();
  late AppDatabase _db;
  bool _dbReady = false;

  Map<int, double> _weekCalories = {};
  double _goalCalories = 2000;

  static const int _weekPageCenter = 5000;
  late final PageController _weekPageCtl;
  late final DateTime _weekAnchor;

  static const int _dayPageCenter = 50000;
  late final PageController _dayPageCtl;
  late final DateTime _dayAnchor;
  bool _syncingPages = false;
  bool _weekStripExpanded = false;

  final _inputCtl = TextEditingController();
  final _inputFocus = FocusNode();

  bool _searchMode = false;
  List<Product> _searchResults = [];
  List<FoodLog> _recentProducts = [];
  List<FoodLog> _recommendedProducts = [];
  List<Product> _favoriteProducts = [];
  bool _isSearching = false;
  bool _isRecognizing = false;
  bool _hasSearchText = false;
  bool _addMenuOpen = false;
  Uint8List? _attachedImageBytes;
  int _preSearchTab = 0;
  FoodLogCardVariant _foodLogCardVariant = FoodLogCardVariant.expanded;
  bool _recordsNewestFirst = false;
  int _recordsAnimationSeed = 0;
  bool _headerScrolledUnder = false;
  bool _inputActionPressed = false;
  bool _sortActionPressed = false;
  bool _viewMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _weekAnchor = _weekStart(DateTime.now());
    _weekPageCtl = PageController(initialPage: _weekPageCenter);
    final now = DateTime.now();
    _dayAnchor = DateTime(now.year, now.month, now.day);
    _dayPageCtl = PageController(initialPage: _dayPageCenter);
    _initDb();
    _inputCtl.addListener(_onSearchTextChanged);
    _inputFocus.addListener(_onSearchFocusChanged);
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
  void didPushNext() {
    _inputFocus.unfocus();
  }

  @override
  void didPopNext() {
    _scheduleUnfocusInputBar();
  }

  void _onSearchTextChanged() {
    final has = _inputCtl.text.trim().isNotEmpty;
    if (has != _hasSearchText) setState(() => _hasSearchText = has);
  }

  void _onSearchFocusChanged() {
    if (!_inputFocus.hasFocus && _inputCtl.text.trim().isEmpty && _searchMode) {
      _deactivateSearch();
    }
  }

  bool _handleDayScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final scrolledUnder = notification.metrics.pixels > 0.5;
    if (scrolledUnder != _headerScrolledUnder) {
      setState(() => _headerScrolledUnder = scrolledUnder);
    }
    return false;
  }

  void _setInputActionPressed(bool pressed) {
    if (_inputActionPressed == pressed) return;
    setState(() => _inputActionPressed = pressed);
  }

  void _setSortActionPressed(bool pressed) {
    if (_sortActionPressed == pressed) return;
    setState(() => _sortActionPressed = pressed);
  }

  void _setViewMenuOpen(bool open) {
    if (_viewMenuOpen == open) return;
    setState(() => _viewMenuOpen = open);
  }

  /// Нижнее поле ввода не должно самопроизвольно получать фокус при возврате с другого экрана.
  void _scheduleUnfocusInputBar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route?.isCurrent != true) return;
      _inputFocus.unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  void _activateSearch() {
    if (_searchMode) return;
    setState(() => _searchMode = true);
    _loadRecentProducts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inputFocus.requestFocus();
    });
    final text = _inputCtl.text.trim();
    if (text.length >= 2) {
      _onSearchChanged(text);
    }
  }

  Future<void> _toggleAddMenu() async {
    if (_addMenuOpen) {
      setState(() => _addMenuOpen = false);
      return;
    }
    _inputFocus.unfocus();
    setState(() => _addMenuOpen = true);
    await _loadRecommendedProducts(limit: 3);
  }

  void _closeAddMenu() {
    if (!_addMenuOpen) return;
    setState(() => _addMenuOpen = false);
  }

  String get _todayDateStr => DateFormat('yyyy-MM-dd').format(DateTime.now());

  void _deactivateSearch({bool syncCalendarToToday = true}) {
    _inputFocus.unfocus();
    _inputCtl.clear();
    setState(() {
      _searchMode = false;
      _searchResults = [];
      _isSearching = false;
      _isRecognizing = false;
      _hasSearchText = false;
      _attachedImageBytes = null;
    });
    if (!syncCalendarToToday) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sel = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    if (sel == today) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _selectDate(today);
    });
  }

  Future<void> _loadRecentProducts({int limit = 15}) async {
    final recent = await _db.getRecentProducts(limit: limit);
    final favorites = await _db.getFavoriteProducts();
    if (mounted) {
      setState(() {
        _recentProducts = recent;
        _favoriteProducts = favorites;
      });
    }
  }

  Future<void> _loadRecommendedProducts({int limit = 3}) async {
    final recommended = await _db.getRecommendedProducts(
      currentMealType: defaultMealType(),
      limit: limit,
    );
    if (mounted) {
      setState(() => _recommendedProducts = recommended);
    }
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    final results = await _db.searchProducts(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  bool _checkFreeLimit() {
    final auth = AuthService();
    if (!auth.isPremium && auth.freeTrialExhausted) {
      context.go('/paywall');
      return true;
    }
    return false;
  }

  Future<void> _recognizeWithAI(String dateStr) async {
    if (_checkFreeLimit()) return;
    final text = _inputCtl.text.trim();
    final image = _attachedImageBytes;
    if (text.isEmpty && image == null) return;

    setState(() => _isRecognizing = true);
    _inputFocus.unfocus();

    final savedText = text;
    final savedImage = image;

    if (_searchMode) {
      _deactivateSearch(syncCalendarToToday: false);
    } else {
      _inputCtl.clear();
      setState(() {
        _isRecognizing = false;
        _hasSearchText = false;
        _attachedImageBytes = null;
      });
    }

    if (savedImage != null && savedText.isNotEmpty) {
      await AiMealResultSheet.showWithTextAndImageLoading(
        context,
        mealType: defaultMealType(),
        dateStr: dateStr,
        text: savedText,
        imageBytes: savedImage,
      );
    } else if (savedImage != null) {
      await AiMealResultSheet.showWithLoading(
        context,
        mealType: defaultMealType(),
        dateStr: dateStr,
        imageBytes: savedImage,
      );
    } else {
      await AiMealResultSheet.showWithTextLoading(
        context,
        mealType: defaultMealType(),
        dateStr: dateStr,
        text: savedText,
      );
    }

    if (mounted) {
      setState(() => _isRecognizing = false);
    }
  }

  Future<void> _addFromLog(FoodLog log, String dateStr) async {
    final auth = AuthService();
    if (!auth.isPremium && auth.freeTrialExhausted) {
      if (mounted) context.go('/paywall');
      return;
    }

    final defaultGrams = log.grams > 0 ? log.grams : 100.0;
    final calPer100 = log.grams > 0
        ? log.calories / log.grams * 100
        : log.calories;
    final pPer100 = log.grams > 0 ? log.protein / log.grams * 100 : log.protein;
    final fPer100 = log.grams > 0 ? log.fat / log.grams * 100 : log.fat;
    final cPer100 = log.grams > 0 ? log.carbs / log.grams * 100 : log.carbs;

    final controller = TextEditingController(
      text: defaultGrams.toInt().toString(),
    );
    final grams = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          log.productName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ctx.l10n.per100gInfo(
                calPer100.toInt(),
                pPer100.toStringAsFixed(1),
                fPer100.toStringAsFixed(1),
                cPer100.toStringAsFixed(1),
              ),
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: ctx.l10n.gramsDialogLabel,
                suffixText: ctx.l10n.gramsUnit,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final g = double.tryParse(controller.text);
              Navigator.pop(ctx, g);
            },
            child: Text(ctx.l10n.add),
          ),
        ],
      ),
    );
    if (grams == null || grams <= 0) return;

    final factor = grams / 100.0;
    final date = DateFormat('yyyy-MM-dd').parse(dateStr);

    await _db.addFoodLog(
      FoodLogsCompanion.insert(
        id: const Uuid().v4(),
        productId: drift.Value(log.productId),
        productName: log.productName,
        mealType: defaultMealType(),
        mealDate: DateTime(date.year, date.month, date.day, 12),
        grams: grams,
        protein: drift.Value(pPer100 * factor),
        fat: drift.Value(fPer100 * factor),
        carbs: drift.Value(cPer100 * factor),
        calories: drift.Value(calPer100 * factor),
        imageUrl: drift.Value(log.imageUrl),
      ),
    );

    if (mounted) {
      _deactivateSearch(syncCalendarToToday: dateStr == _todayDateStr);
    }

    if (!auth.isPremium) {
      await auth.incrementFreeEntry();
    }
  }

  Future<void> _addRecentLogFromMenu(FoodLog log, String dateStr) async {
    _closeAddMenu();
    if (log.productId != null) {
      final product = await _db.getProductById(log.productId!);
      if (product != null && mounted) {
        await _addProductFromSearch(product, dateStr);
        return;
      }
    }
    if (mounted) await _addFromLog(log, dateStr);
  }

  Future<void> _attachPhotoFromMenu() async {
    _closeAddMenu();
    if (_checkFreeLimit()) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (mounted) {
      setState(() => _attachedImageBytes = bytes);
    }
  }

  Future<void> _addProductFromSearch(Product product, String dateStr) async {
    final auth = AuthService();
    if (!auth.isPremium && auth.freeTrialExhausted) {
      if (mounted) context.go('/paywall');
      return;
    }

    final grams = await _showGramsDialog(product);
    if (grams == null || grams <= 0) return;

    final factor = grams / 100.0;
    final date = DateFormat('yyyy-MM-dd').parse(dateStr);

    await _db.addFoodLog(
      FoodLogsCompanion.insert(
        id: const Uuid().v4(),
        productId: drift.Value(product.productId),
        productName: product.name,
        mealType: defaultMealType(),
        mealDate: DateTime(date.year, date.month, date.day, 12),
        grams: grams,
        protein: drift.Value((product.proteinPer100g ?? 0) * factor),
        fat: drift.Value((product.fatPer100g ?? 0) * factor),
        carbs: drift.Value((product.carbsPer100g ?? 0) * factor),
        calories: drift.Value((product.caloriesPer100g ?? 0) * factor),
        imageUrl: drift.Value(product.imageUrl),
      ),
    );

    if (mounted) {
      _deactivateSearch(syncCalendarToToday: dateStr == _todayDateStr);
    }

    if (!auth.isPremium) {
      await auth.incrementFreeEntry();
    }
  }

  Future<double?> _showGramsDialog(Product product) {
    final controller = TextEditingController(
      text: product.weightGrams?.toInt().toString() ?? '100',
    );

    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (product.caloriesPer100g != null)
              Text(
                ctx.l10n.per100gInfo(
                  product.caloriesPer100g!.toInt(),
                  product.proteinPer100g?.toStringAsFixed(1) ?? '-',
                  product.fatPer100g?.toStringAsFixed(1) ?? '-',
                  product.carbsPer100g?.toStringAsFixed(1) ?? '-',
                ),
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: ctx.l10n.gramsDialogLabel,
                suffixText: ctx.l10n.gramsUnit,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final grams = double.tryParse(controller.text);
              Navigator.pop(ctx, grams);
            },
            child: Text(ctx.l10n.add),
          ),
        ],
      ),
    );
  }

  Future<void> _initDb() async {
    _db = await AppDatabase.getInstance();
    await Future.wait([_loadGoal(), _loadRecordsSortOrder()]);
    if (mounted) setState(() => _dbReady = true);
    unawaited(_loadWeekCalories());
  }

  Future<void> _loadRecordsSortOrder() async {
    final value = await _db.getSetting(_recordsSortOrderSetting);
    _recordsNewestFirst = value == 'newest';
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _weekPageCtl.dispose();
    _dayPageCtl.dispose();
    _inputCtl.removeListener(_onSearchTextChanged);
    _inputCtl.dispose();
    _inputFocus.removeListener(_onSearchFocusChanged);
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _loadGoal() async {
    final cal = await _db.getSetting('calorie_goal');
    _goalCalories = double.tryParse(cal ?? '') ?? 2000;
  }

  Future<void> _loadWeekCalories() async {
    final weekStart = _weekStart(_selectedDate);
    final result = <int, double>{};
    for (var i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final logs = await _db.getFoodLogsForDate(day);
      result[i] = logs.fold(0.0, (sum, l) => sum + l.calories);
    }
    if (mounted) setState(() => _weekCalories = result);
  }

  void _syncWeekCalories(List<FoodLog> logs) {
    final dayIndex = _selectedDate
        .difference(_weekStart(_selectedDate))
        .inDays
        .clamp(0, 6);
    final cal = logs.fold(0.0, (sum, l) => sum + l.calories);
    if (_weekCalories[dayIndex] != cal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _weekCalories[dayIndex] = cal);
      });
    }
  }

  Future<void> _toggleRecordsSortOrder() async {
    final next = !_recordsNewestFirst;
    setState(() {
      _recordsNewestFirst = next;
      _recordsAnimationSeed++;
    });
    await _db.setSetting(_recordsSortOrderSetting, next ? 'newest' : 'oldest');
  }

  List<FoodLog> _sortLogsForDisplay(Iterable<FoodLog> logs) {
    final sorted = logs.toList();
    sorted.sort((a, b) {
      final byCreated = _recordsNewestFirst
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt);
      if (byCreated != 0) return byCreated;
      return _recordsNewestFirst
          ? b.mealDate.compareTo(a.mealDate)
          : a.mealDate.compareTo(b.mealDate);
    });
    return sorted;
  }

  DateTime _weekStart(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  DateTime _weekStartForPage(int page) {
    final offset = page - _weekPageCenter;
    return _weekAnchor.add(Duration(days: offset * 7));
  }

  int _pageForDate(DateTime date) {
    final ws = _weekStart(date);
    final diff = ws.difference(_weekAnchor).inDays;
    return _weekPageCenter + (diff ~/ 7);
  }

  DateTime _dateForDayPage(int page) {
    final offset = page - _dayPageCenter;
    return _dayAnchor.add(Duration(days: offset));
  }

  int _dayPageForDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return _dayPageCenter + d.difference(_dayAnchor).inDays;
  }

  void _onDayPageChanged(int page) {
    if (_syncingPages) return;
    final date = _dateForDayPage(page);
    final d = DateTime(date.year, date.month, date.day);
    final sel = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    if (d == sel) return;

    _syncingPages = true;
    setState(() {
      _selectedDate = date;
      _headerScrolledUnder = false;
    });

    final newWeekPage = _pageForDate(date);
    if (_weekPageCtl.hasClients) {
      final currentWeekPage = _weekPageCtl.page?.round() ?? _weekPageCenter;
      if (currentWeekPage != newWeekPage) {
        _weekPageCtl.jumpToPage(newWeekPage);
      }
    }

    _loadWeekCalories();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncingPages = false;
    });
  }

  void _selectDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    if (target.isAfter(today)) return;
    setState(() {
      _selectedDate = date;
    });

    if (_dayPageCtl.hasClients) {
      final dayPage = _dayPageForDate(date);
      if (_dayPageCtl.page?.round() != dayPage) {
        _dayPageCtl.jumpToPage(dayPage);
      }
    }

    _loadWeekCalories();
  }

  ({String date, String weekday}) _formatHeaderDateParts() {
    final d = _selectedDate;
    final locale = Localizations.localeOf(context).languageCode;
    final dayName = DateFormat('E', locale).format(d).replaceAll('.', '');
    final month = DateFormat('MMM', locale).format(d).replaceAll('.', '');
    return (date: '${d.day} $month', weekday: dayName);
  }

  Future<void> _openDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: Localizations.localeOf(context),
    );
    if (picked != null) {
      _selectDate(picked);
    }
  }

  void _showAddMealSheet(String dateStr) {
    if (_checkFreeLimit()) return;
    String selectedMealType = defaultMealType();

    final mealTypes = [
      (
        key: 'breakfast',
        label: context.l10n.mealBreakfast,
        icon: Icons.wb_sunny_outlined,
      ),
      (
        key: 'lunch',
        label: context.l10n.mealLunch,
        icon: Icons.wb_cloudy_outlined,
      ),
      (
        key: 'dinner',
        label: context.l10n.mealDinner,
        icon: Icons.nights_stay_outlined,
      ),
      (
        key: 'snack',
        label: context.l10n.mealSnack,
        icon: Icons.cookie_outlined,
      ),
    ];

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      ctx.l10n.addMealTitle,
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMealType,
                      decoration: InputDecoration(
                        labelText: ctx.l10n.mealTypeLabel,
                        prefixIcon: const Icon(Icons.restaurant),
                      ),
                      items: mealTypes.map((m) {
                        return DropdownMenuItem(
                          value: m.key,
                          child: Row(
                            children: [
                              Icon(m.icon, size: 20),
                              const SizedBox(width: 8),
                              Text(m.label),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null)
                          setSheetState(() => selectedMealType = v);
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _CompactActionTile(
                            icon: Icons.search,
                            label: ctx.l10n.searchInDb,
                            onTap: () {
                              Navigator.pop(ctx);
                              context.push(
                                '/search?meal_type=$selectedMealType&date=$dateStr',
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _CompactActionTile(
                            icon: Icons.photo_library_outlined,
                            label: ctx.l10n.fromGallery,
                            onTap: () {
                              Navigator.pop(ctx);
                              CameraScreen.pickAndShow(
                                context,
                                mealType: selectedMealType,
                                dateStr: dateStr,
                                source: ImageSource.gallery,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          CameraScreen.pickAndShow(
                            context,
                            mealType: selectedMealType,
                            dateStr: dateStr,
                            source: ImageSource.camera,
                          );
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: Text(ctx.l10n.recognizeByPhoto),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_dbReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final back2 = isDark ? AppColors.darkBack2 : AppColors.lightBack2;
    final onBack4 = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final systemOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: _addMenuOpen ? AppColors.overlayDark : Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: _addMenuOpen ? AppColors.overlayDark : back2,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle,
      child: Scaffold(
        backgroundColor: back2,
        body: FocusScope(
          autofocus: false,
          child: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: _handleDayScrollNotification,
                        child: _buildDayPageView(context, isDark, onBack4),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: safeBottom + _inputBarReservedHeight + 72,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          back2.withValues(alpha: 0),
                          back2.withValues(alpha: isDark ? 0.74 : 0.62),
                          back2.withValues(alpha: isDark ? 0.98 : 0.96),
                        ],
                        stops: const [0, 0.62, 1],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_addMenuOpen,
                  child: AnimatedOpacity(
                    opacity: _addMenuOpen ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: GestureDetector(
                      onTap: _closeAddMenu,
                      behavior: HitTestBehavior.opaque,
                      child: Container(color: AppColors.overlayDark),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: safeBottom + _inputBarReservedHeight + 8,
                child: IgnorePointer(
                  ignoring: !_addMenuOpen,
                  child: AnimatedOpacity(
                    opacity: _addMenuOpen ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: AnimatedSlide(
                      offset: _addMenuOpen
                          ? Offset.zero
                          : const Offset(0, 0.05),
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: AnimatedScale(
                        scale: _addMenuOpen ? 1 : 0.98,
                        alignment: Alignment.bottomCenter,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: _buildAddEntryMenu(context, dateStr, isDark),
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: _buildInputBar(context, dateStr, isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateParts = _formatHeaderDateParts();
    final borderColor = _headerScrolledUnder
        ? (isDark ? AppColors.lineDT100 : AppColors.lineLight100)
        : Colors.transparent;
    final auth = AuthService();
    final initial = (auth.userName?.isNotEmpty == true)
        ? auth.userName![0].toUpperCase()
        : (auth.userEmail?.isNotEmpty == true)
        ? auth.userEmail![0].toUpperCase()
        : 'M';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(
                            () => _weekStripExpanded = !_weekStripExpanded,
                          );
                        },
                        onLongPress: () => _openDatePicker(context),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(text: dateParts.date),
                                    const TextSpan(text: ', '),
                                    TextSpan(
                                      text: dateParts.weekday,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  height: 32 / 24,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            AnimatedRotation(
                              turns: _weekStripExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeInOut,
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/stats'),
                          child: Icon(
                            Icons.bar_chart_rounded,
                            size: 24,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 24),
                        GestureDetector(
                          onTap: () => context.push('/favorites'),
                          child: Icon(
                            Icons.favorite,
                            size: 24,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 24),
                        GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                height: 24 / 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_weekStripExpanded) ...[
              _buildWeekStrip(context, isDark),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBody(BuildContext context, String dateStr, bool isDark) {
    final cs = Theme.of(context).colorScheme;
    final showPreSearch = _inputCtl.text.length < 2;

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isRecognizing) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              context.l10n.recognizingViaAi,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (showPreSearch) {
      return Column(
        children: [
          const SizedBox(height: 12),
          _buildPreSearchTabs(cs, isDark),
          const SizedBox(height: 8),
          Expanded(
            child: _preSearchTab == 0
                ? _buildHistoryTab(cs, dateStr)
                : _buildFavoritesTab(cs, dateStr),
          ),
        ],
      );
    }

    if (_searchResults.isEmpty && _inputCtl.text.length >= 2) {
      return Center(
        child: Text(
          context.l10n.notFoundInDb,
          textAlign: TextAlign.center,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return ListTile(
          leading: product.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 48,
                      height: 48,
                      color: isDark
                          ? AppColors.darkSurface2
                          : Colors.grey.shade200,
                      child: const Icon(Icons.restaurant, color: Colors.grey),
                    ),
                  ),
                )
              : CircleAvatar(
                  backgroundColor: isDark
                      ? AppColors.darkSurface2
                      : Colors.grey.shade200,
                  child: const Icon(Icons.restaurant, color: Colors.grey),
                ),
          title: Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${context.l10n.kcalPer100g((product.caloriesPer100g?.toInt() ?? 0).toString())}  •  '
            '${product.brand ?? ""}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _addProductFromSearch(product, dateStr),
        );
      },
    );
  }

  Widget _buildPreSearchTabs(ColorScheme cs, bool isDark) {
    final bgColor = isDark ? AppColors.darkUnderBack : AppColors.lightUnderBack;

    final tabs = [
      (value: 0, label: context.l10n.historyTab),
      (value: 1, label: context.l10n.favoritesTab),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _preSearchTab == tab.value;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _preSearchTab = tab.value),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? cs.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0x1A050C26),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 24 / 15,
                      color: isSelected ? cs.onSurface : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryTab(ColorScheme cs, String dateStr) {
    if (_recentProducts.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noRecentRecords,
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      itemCount: _recentProducts.length,
      itemBuilder: (context, index) {
        final log = _recentProducts[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < _recentProducts.length - 1 ? 8 : 0,
          ),
          child: GestureDetector(
            onTap: () async {
              if (log.productId != null) {
                final product = await _db.getProductById(log.productId!);
                if (product != null && mounted) {
                  _addProductFromSearch(product, dateStr);
                  return;
                }
              }
              if (mounted) _addFromLog(log, dateStr);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(20),
                border: AppTheme.cardEdgeBorder(
                  isDark: Theme.of(context).brightness == Brightness.dark,
                ),
                boxShadow: AppTheme.cardEdgeShadows(
                  isDark: Theme.of(context).brightness == Brightness.dark,
                ),
              ),
              child: Row(
                children: [
                  _buildRecentLogPhoto(log, cs),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 20 / 15,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              context.l10n.gramsValue(log.grams.toInt()),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 18 / 14,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              context.l10n.kcalValueInt(log.calories.toInt()),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 18 / 14,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoritesTab(ColorScheme cs, String dateStr) {
    if (_favoriteProducts.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noFavoriteProducts,
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      itemCount: _favoriteProducts.length,
      itemBuilder: (context, index) {
        final product = _favoriteProducts[index];
        final grams = product.weightGrams?.toInt() ?? 100;
        final factor = grams / 100.0;
        final cal = ((product.caloriesPer100g ?? 0) * factor).toInt();

        return Padding(
          padding: EdgeInsets.only(
            bottom: index < _favoriteProducts.length - 1 ? 8 : 0,
          ),
          child: GestureDetector(
            onTap: () => _addProductFromSearch(product, dateStr),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(20),
                border: AppTheme.cardEdgeBorder(
                  isDark: Theme.of(context).brightness == Brightness.dark,
                ),
                boxShadow: AppTheme.cardEdgeShadows(
                  isDark: Theme.of(context).brightness == Brightness.dark,
                ),
              ),
              child: Row(
                children: [
                  _buildFavProductPhoto(product, cs),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 20 / 15,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              context.l10n.gramsValue(grams),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 18 / 14,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              context.l10n.kcalValueInt(cal),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 18 / 14,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavProductPhoto(Product product, ColorScheme cs) {
    final url = product.imageUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('/')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(url),
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _recentPlaceholder(cs),
          ),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => _recentPlaceholder(cs),
        ),
      );
    }
    return _recentPlaceholder(cs);
  }

  Widget _buildRecentLogPhoto(FoodLog log, ColorScheme cs) {
    final url = log.imageUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('/')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(url),
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _recentPlaceholder(cs),
          ),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => _recentPlaceholder(cs),
        ),
      );
    }
    return _recentPlaceholder(cs);
  }

  Widget _recentPlaceholder(ColorScheme cs) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.restaurant, size: 20, color: cs.onSurfaceVariant),
    );
  }

  Widget _buildDayPageView(BuildContext context, bool isDark, Color onBack4) {
    // Без верхней границы itemCount — иначе при большом initialPage возможен assert
    // в SliverFixedExtentList (рассинхрон scrollOffset и дочерних слотов).
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxDayPage = _dayPageForDate(today);

    return PageView.builder(
      controller: _dayPageCtl,
      physics: _ClampedForwardPageScrollPhysics(maxPage: maxDayPage),
      onPageChanged: _onDayPageChanged,
      itemCount: null,
      itemBuilder: (_, page) {
        final date = _dateForDayPage(page);
        final dateStr = DateFormat('yyyy-MM-dd').format(date);

        return StreamBuilder<List<FoodLog>>(
          stream: _db.watchFoodLogsForDate(date),
          builder: (context, snapshot) {
            final logs = snapshot.data ?? [];
            final d = DateTime(date.year, date.month, date.day);
            final sel = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
            );
            if (d == sel) _syncWeekCalories(logs);
            return LayoutBuilder(
              builder: (context, constraints) {
                return _buildDayContent(
                  context,
                  logs,
                  dateStr,
                  isDark,
                  onBack4,
                  constraints.maxHeight,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFreeEntriesBanner(BuildContext context, AuthService auth) {
    final remaining = auth.freeEntriesRemaining;
    final isUrgent = remaining <= 2;

    final gradientColors = isUrgent
        ? const [Color(0xFFFF5A6E), Color(0xFFFF7A3D)]
        : const [Color(0xFF317BFF), Color(0xFF7631FF)];
    final glowColor = isUrgent
        ? const Color(0xFFFF5A6E)
        : const Color(0xFF5A47FF);
    final ctaTextColor = isUrgent
        ? const Color(0xFFD13848)
        : const Color(0xFF4F2BD9);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => context.push('/paywall'),
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.32),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.freeEntriesRemaining(remaining),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 18 / 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.l10n.getPro,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 16 / 13,
                              color: ctaTextColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: ctaTextColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayContent(
    BuildContext context,
    List<FoodLog> logs,
    String dateStr,
    bool isDark,
    Color back2,
    double viewportHeight,
  ) {
    final cs = Theme.of(context).colorScheme;

    final sortedLogs = _sortLogsForDisplay(logs);
    final date = DateFormat('yyyy-MM-dd').parse(dateStr);
    final auth = AuthService();
    final showBanner =
        !auth.isPremium &&
        auth.freeEntriesUsed >= 6 &&
        !auth.freeTrialExhausted;

    final bottomPadding =
        MediaQuery.paddingOf(context).bottom + _inputBarReservedHeight + 24;

    return ListView(
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: [
        DailySummaryCard(logs: logs, selectedDate: date),
        if (showBanner) _buildFreeEntriesBanner(context, auth),
        if (sortedLogs.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildRecordsHeader(context, cs),
          const SizedBox(height: 8),
          _buildFoodCards(
            context,
            sortedLogs,
            dateStr,
            back2,
            _goalCalories,
            animationSeed: _recordsAnimationSeed,
          ),
        ] else ...[
          Builder(
            builder: (context) {
              const fixedAbove = 220.0;
              final emptyHeight = (viewportHeight - fixedAbove).clamp(
                200.0,
                viewportHeight,
              );
              return SizedBox(
                height: emptyHeight,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Lottie.asset(
                        'assets/animations/empty_plate.json',
                        width: 90,
                        height: 90,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.diaryEmptyDay,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 22 / 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  void _onWeekPageChanged(int page) {
    if (_syncingPages) return;

    _syncingPages = true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final newWeekStart = _weekStartForPage(page);

    final currentWeekday = _selectedDate.weekday - 1;
    var candidate = newWeekStart.add(Duration(days: currentWeekday));
    if (candidate.isAfter(today)) candidate = today;
    if (candidate.isBefore(newWeekStart)) candidate = newWeekStart;

    setState(() {
      _selectedDate = candidate;
    });

    if (_dayPageCtl.hasClients) {
      _dayPageCtl.jumpToPage(_dayPageForDate(candidate));
    }

    _loadWeekCalories();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncingPages = false;
    });
  }

  Widget _buildWeekStrip(BuildContext context, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxWeekPage = _pageForDate(today);

    return SizedBox(
      height: _weekStripHeight,
      child: PageView.builder(
        controller: _weekPageCtl,
        physics: _ClampedForwardPageScrollPhysics(maxPage: maxWeekPage),
        onPageChanged: _onWeekPageChanged,
        // Не ограничиваем число страниц через itemCount — иначе граница
        // + огромный scrollOffset дают падение layout у PageView; граница через physics.
        itemCount: null,
        itemBuilder: (context, page) {
          return _buildWeekPage(context, page, isDark, today);
        },
      ),
    );
  }

  Widget _buildWeekPage(
    BuildContext context,
    int page,
    bool isDark,
    DateTime today,
  ) {
    final weekStart = _weekStartForPage(page);
    final selectedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    final calendarLine = isDark ? AppColors.lineDT300 : AppColors.lineLight300;
    final cs = Theme.of(context).colorScheme;

    final dayLabels = [
      context.l10n.dayMon,
      context.l10n.dayTue,
      context.l10n.dayWed,
      context.l10n.dayThu,
      context.l10n.dayFri,
      context.l10n.daySat,
      context.l10n.daySun,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(7, (i) {
          final date = weekStart.add(Duration(days: i));
          final dayDate = DateTime(date.year, date.month, date.day);
          final isToday = dayDate == today;
          final isSelected = dayDate == selectedDay;
          final isFuture = dayDate.isAfter(today);
          final progress = _goalCalories > 0
              ? ((_weekCalories[i] ?? 0) / _goalCalories).clamp(0.0, 1.0)
              : 0.0;

          final numberColor = cs.onSurface;
          final labelColor = isToday ? cs.onSurface : cs.onSurfaceVariant;
          final showBorder = !isFuture;

          final content = Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dayLabels[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 12 / 10,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 24 / 18,
                    color: numberColor,
                  ),
                ),
              ],
            ),
          );

          final dayOpacity = (isToday || isSelected)
              ? 1.0
              : (isFuture ? 0.5 : 0.35); // past dates — dimmer by ~15%

          return Expanded(
            child: GestureDetector(
              onTap: isFuture ? null : () => _selectDate(date),
              child: Opacity(
                opacity: dayOpacity,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 0 : 2,
                    right: i == 6 ? 0 : 2,
                  ),
                  child: SizedBox(
                    height: 64,
                    child: showBorder
                        ? CustomPaint(
                            painter: _DayCellBorderPainter(
                              trackColor: calendarLine,
                              gradientColors: const [
                                Color(0xFF22D33A),
                                Color(0xFF1EBF92),
                              ],
                              progress: progress,
                              borderRadius: 12,
                              borderWidth: 4,
                            ),
                            child: content,
                          )
                        : content,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFoodCards(
    BuildContext context,
    List<FoodLog> logs,
    String dateStr,
    Color back2,
    double calorieGoal, {
    required int animationSeed,
  }) {
    final shouldAnimate = animationSeed > 0;
    final entryOffset = _recordsNewestFirst ? -10.0 : 10.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(logs.length, (index) {
          final log = logs[index];
          final intervalStart = shouldAnimate
              ? math.min(index, 6) * 0.045
              : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TweenAnimationBuilder<double>(
              key: ValueKey('${log.id}-$animationSeed'),
              tween: Tween<double>(begin: shouldAnimate ? 0 : 1, end: 1),
              duration: const Duration(milliseconds: 320),
              curve: Interval(
                intervalStart.clamp(0.0, 0.72),
                1,
                curve: Curves.easeOutCubic,
              ),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * entryOffset),
                    child: Transform.scale(
                      scale: 0.985 + (0.015 * value),
                      alignment: Alignment.topCenter,
                      child: child,
                    ),
                  ),
                );
              },
              child: MealSection.buildSingleCard(
                context: context,
                log: log,
                mealType: log.mealType,
                dateStr: dateStr,
                duplicateDateStr: _todayDateStr,
                onDuplicateAdded: () => _selectDate(DateTime.now()),
                onDelete: (id) => _db.deleteFoodLog(id),
                back2: back2,
                variant: _foodLogCardVariant,
                calorieGoal: calorieGoal,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRecordsHeader(BuildContext context, ColorScheme cs) {
    final currentViewLabel = _foodLogCardVariant == FoodLogCardVariant.expanded
        ? context.l10n.diaryViewExpanded
        : context.l10n.diaryViewCompact;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryDark = isDark
        ? AppColors.darkSecondaryDark
        : AppColors.lightSecondaryDark;
    final sortBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final menuBg = isDark ? AppColors.darkScaffold : AppColors.lightScaffold;
    final menuItemBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final menuBorder = isDark ? AppColors.lineDT200 : AppColors.lineLight200;
    final sortLabel = _recordsNewestFirst
        ? context.l10n.recordsSortNewestFirst
        : context.l10n.recordsSortOldestFirst;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    context.l10n.diaryRecordsForDay,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 18 / 14,
                      color: secondaryDark,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Tooltip(
                  message: sortLabel,
                  child: GestureDetector(
                    onTapDown: (_) => _setSortActionPressed(true),
                    onTapUp: (_) => _setSortActionPressed(false),
                    onTapCancel: () => _setSortActionPressed(false),
                    onTap: _toggleRecordsSortOrder,
                    behavior: HitTestBehavior.opaque,
                    child: Semantics(
                      button: true,
                      label: sortLabel,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
                        child: AnimatedScale(
                          scale: _sortActionPressed ? 0.86 : 1,
                          duration: const Duration(milliseconds: 110),
                          curve: Curves.easeOutCubic,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOutCubic,
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _sortActionPressed
                                  ? sortBg.withValues(alpha: 0.72)
                                  : sortBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: AnimatedRotation(
                                turns: _recordsNewestFirst ? 0.5 : 0,
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOutBack,
                                child: SvgPicture.asset(
                                  'assets/icons/sort_arrow_up.svg',
                                  width: 18,
                                  height: 18,
                                  colorFilter: ColorFilter.mode(
                                    secondaryDark,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
            ),
            child: PopupMenuButton<FoodLogCardVariant>(
              padding: EdgeInsets.zero,
              position: PopupMenuPosition.under,
              offset: const Offset(0, 8),
              color: menuBg,
              surfaceTintColor: Colors.transparent,
              elevation: 8,
              shadowColor: const Color(0x21000000),
              menuPadding: const EdgeInsets.all(16),
              constraints: const BoxConstraints.tightFor(width: 180),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: menuBorder),
              ),
              onOpened: () => _setViewMenuOpen(true),
              onCanceled: () => _setViewMenuOpen(false),
              itemBuilder: (context) => [
                PopupMenuItem<FoodLogCardVariant>(
                  enabled: false,
                  padding: EdgeInsets.zero,
                  child: StatefulBuilder(
                    builder: (context, setMenuState) {
                      void pick(FoodLogCardVariant v) {
                        if (_foodLogCardVariant == v) return;
                        setState(() {
                          _foodLogCardVariant = v;
                          _recordsAnimationSeed++;
                        });
                        setMenuState(() {});
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildViewModeMenuItem(
                            context,
                            label: context.l10n.diaryViewExpanded,
                            background: menuItemBg,
                            isActive: _foodLogCardVariant ==
                                FoodLogCardVariant.expanded,
                            onTap: () => pick(FoodLogCardVariant.expanded),
                          ),
                          _buildViewModeMenuItem(
                            context,
                            label: context.l10n.diaryViewCompact,
                            background: menuItemBg,
                            isActive: _foodLogCardVariant ==
                                FoodLogCardVariant.compact,
                            onTap: () => pick(FoodLogCardVariant.compact),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              child: AnimatedScale(
                scale: _viewMenuOpen ? 0.97 : 1,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${context.l10n.diaryViewLabel}: ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 18 / 14,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            TextSpan(
                              text: currentViewLabel,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 18 / 14,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AnimatedRotation(
                        turns: _viewMenuOpen ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeMenuItem(
    BuildContext context, {
    required String label,
    required Color background,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 148,
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? background : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 18 / 14,
              color: cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddEntryMenu(BuildContext context, String dateStr, bool isDark) {
    final cs = Theme.of(context).colorScheme;
    final menuBg = isDark ? AppColors.darkScaffold : AppColors.lightScaffold;
    final itemBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final border = isDark ? AppColors.lineDT200 : AppColors.lineLight200;
    final secondary = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final recent = _recommendedProducts.take(3).toList();

    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: menuBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x21000000),
              blurRadius: 165,
              offset: Offset(0, 6),
            ),
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 20.66,
              offset: Offset(0, 0.75),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (recent.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.addMenuRecentEntries,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 18 / 14,
                            color: secondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...recent.map(
                          (log) => Padding(
                            padding: EdgeInsets.only(
                              bottom: log == recent.last ? 0 : 8,
                            ),
                            child: _buildAddMenuRecentTile(
                              context,
                              log,
                              dateStr,
                              itemBg,
                              cs,
                              secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, thickness: 1, color: border),
                  const SizedBox(height: 16),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildAddMenuAction(
                        iconAsset: 'assets/icons/menu_search.svg',
                        label: context.l10n.searchInDb,
                        background: itemBg,
                        textColor: cs.onSurface,
                        onTap: () {
                          _closeAddMenu();
                          if (_checkFreeLimit()) return;
                          final mealType = defaultMealType();
                          context.push(
                            '/search?meal_type=$mealType&date=$dateStr',
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildAddMenuAction(
                        iconAsset: 'assets/icons/menu_barcode.svg',
                        label: context.l10n.scanBarcodeAction,
                        background: itemBg,
                        textColor: cs.onSurface,
                        onTap: () {
                          _closeAddMenu();
                          if (_checkFreeLimit()) return;
                          context.push(
                            '/scanner?meal_type=${defaultMealType()}&date=$dateStr',
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildAddMenuAction(
                        iconAsset: 'assets/icons/menu_heart.svg',
                        label: context.l10n.favoritesTab,
                        background: itemBg,
                        textColor: cs.onSurface,
                        onTap: () {
                          _closeAddMenu();
                          context.push('/favorites');
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildAddMenuAction(
                        iconAsset: 'assets/icons/menu_photo.svg',
                        label: context.l10n.attachPhotoAction,
                        background: itemBg,
                        textColor: cs.onSurface,
                        onTap: _attachPhotoFromMenu,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddMenuRecentTile(
    BuildContext context,
    FoodLog log,
    String dateStr,
    Color background,
    ColorScheme cs,
    Color secondary,
  ) {
    return GestureDetector(
      onTap: () => _addRecentLogFromMenu(log, dateStr),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 72,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            _buildRecentLogPhoto(log, cs),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    log.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 20 / 15,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        context.l10n.kcalValueInt(log.calories.toInt()),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 18 / 14,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        context.l10n.gramsValue(log.grams.toInt()),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 18 / 14,
                          color: secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMenuAction({
    required String iconAsset,
    required String label,
    required Color background,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SvgPicture.asset(iconAsset, width: 24, height: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 18 / 14,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, String dateStr, bool isDark) {
    final onBack = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final plusBg = _addMenuOpen
        ? (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface2)
        : (isDark ? AppColors.darkSurface2 : AppColors.lightScaffold);
    final placeholderColor = isDark
        ? AppColors.darkSecondaryDark
        : AppColors.lightSecondaryDark;
    final iconColor = isDark
        ? AppColors.darkSecondaryDark
        : AppColors.lightSecondaryDark;
    final primaryIconColor = isDark
        ? AppColors.darkOnSurface
        : AppColors.lightOnSurface;
    final textColor = primaryIconColor;
    final lineBorder = isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    final plusColor = _addMenuOpen ? primaryIconColor : iconColor;
    final hasDraft = _hasSearchText || _attachedImageBytes != null;
    final inputShadow = isDark
        ? const [
            BoxShadow(color: Color(0x14000000), blurRadius: 16),
            BoxShadow(color: Color(0x0A000000), blurRadius: 2),
          ]
        : const [
            BoxShadow(color: Color(0x09000000), blurRadius: 16),
            BoxShadow(color: Color(0x05000000), blurRadius: 2),
          ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: onBack,
                borderRadius: BorderRadius.circular(50),
                boxShadow: inputShadow,
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _toggleAddMenu();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: plusBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: lineBorder),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Center(
                            child: AnimatedRotation(
                              turns: _addMenuOpen ? 0.125 : 0,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              child: SvgPicture.asset(
                                'assets/icons/menu_plus.svg',
                                width: 24,
                                height: 24,
                                colorFilter: ColorFilter.mode(
                                  plusColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                          if (_attachedImageBytes != null)
                            Positioned(
                              top: -1,
                              right: -1,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _inputCtl,
                      focusNode: _inputFocus,
                      minLines: 1,
                      maxLines: 1,
                      onTap: _closeAddMenu,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 22 / 16,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: context.l10n.addEntry,
                        hintStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 22 / 16,
                          color: placeholderColor,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(vertical: 5),
                      ),
                      onChanged: null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTapDown: (_) => _setInputActionPressed(true),
            onTapUp: (_) => _setInputActionPressed(false),
            onTapCancel: () => _setInputActionPressed(false),
            onTap: hasDraft
                ? () {
                    HapticFeedback.selectionClick();
                    _closeAddMenu();
                    _recognizeWithAI(dateStr);
                  }
                : () {
                    HapticFeedback.selectionClick();
                    _closeAddMenu();
                    if (_checkFreeLimit()) return;
                    CameraScreen.pickAndShow(
                      context,
                      mealType: defaultMealType(),
                      dateStr: dateStr,
                      source: ImageSource.camera,
                    );
                  },
            child: AnimatedScale(
              scale: _inputActionPressed ? 0.94 : 1,
              duration: const Duration(milliseconds: 110),
              curve: Curves.easeOutCubic,
              child: Container(
                width: 64,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: hasDraft ? AppColors.primary : null,
                  gradient: hasDraft
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF317BFF), Color(0xFF7631FF)],
                        ),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: inputShadow,
                ),
                child: Center(
                  child: _isRecognizing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : SvgPicture.asset(
                          hasDraft
                              ? 'assets/icons/send.svg'
                              : 'assets/icons/ai_generated_photo.svg',
                          width: hasDraft ? 24 : 32,
                          height: hasDraft ? 24 : 32,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCellBorderPainter extends CustomPainter {
  final Color trackColor;
  final List<Color> gradientColors;
  final double progress;
  final double borderRadius;
  final double borderWidth;

  _DayCellBorderPainter({
    required this.trackColor,
    required this.gradientColors,
    required this.progress,
    required this.borderRadius,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final halfBorder = borderWidth / 2;
    final rectW = size.width - borderWidth;
    final rectH = size.height - borderWidth;
    final r = borderRadius - halfBorder;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(halfBorder, halfBorder, rectW, rectH),
      Radius.circular(r),
    );

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawRRect(rrect, trackPaint);

    if (progress <= 0) return;

    final rect = Rect.fromLTWH(halfBorder, halfBorder, rectW, rectH);
    final rad = Radius.circular(r);
    final path = Path()
      ..moveTo(rect.left + rectW / 2, rect.top)
      ..lineTo(rect.right - r, rect.top)
      ..arcToPoint(Offset(rect.right, rect.top + r), radius: rad)
      ..lineTo(rect.right, rect.bottom - r)
      ..arcToPoint(Offset(rect.right - r, rect.bottom), radius: rad)
      ..lineTo(rect.left + r, rect.bottom)
      ..arcToPoint(Offset(rect.left, rect.bottom - r), radius: rad)
      ..lineTo(rect.left, rect.top + r)
      ..arcToPoint(Offset(rect.left + r, rect.top), radius: rad)
      ..lineTo(rect.left + rectW / 2, rect.top);

    final metrics = path.computeMetrics().first;
    final fillLength = metrics.length * progress.clamp(0.0, 1.0);

    final fillPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: gradientColors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(metrics.extractPath(0, fillLength), fillPaint);
  }

  @override
  bool shouldRepaint(_DayCellBorderPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.gradientColors != gradientColors;
}

class _CompactActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CompactActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_ctrl),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
