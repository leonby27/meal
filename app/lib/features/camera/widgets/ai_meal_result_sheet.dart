import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/api/api_client.dart';
import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/services/auth_service.dart';
import 'package:meal_tracker/core/services/locale_service.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/l10n/app_localizations.dart';

class _IngredientEntry {
  final TextEditingController nameCtl;
  final TextEditingController gramsCtl;
  double proteinPer100g;
  double fatPer100g;
  double carbsPer100g;
  double caloriesPer100g;
  double protein;
  double fat;
  double carbs;
  double calories;
  int count;
  double gramsPerUnit;

  _IngredientEntry({
    required this.nameCtl,
    required this.gramsCtl,
    required this.proteinPer100g,
    required this.fatPer100g,
    required this.carbsPer100g,
    required this.caloriesPer100g,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.calories,
    this.count = 0,
    this.gramsPerUnit = 0,
  });

  bool get hasCounter => count > 0;

  void dispose() {
    nameCtl.dispose();
    gramsCtl.dispose();
  }
}

/// Colors for [AiMealResultSheet] — follows app light/dark tokens (not hardcoded dark only).
class _AiSheetColors {
  _AiSheetColors._(this.isDark);

  factory _AiSheetColors.of(BuildContext context) {
    return _AiSheetColors._(
      Theme.of(context).brightness == Brightness.dark,
    );
  }

  final bool isDark;

  Color get sheetBg =>
      isDark ? AppColors.darkBack2 : AppColors.lightBack2;
  Color get cardBg =>
      isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
  Color get surfaceBg =>
      isDark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get borderColor =>
      isDark ? AppColors.lineDT100 : AppColors.lineLight100;
  Color get secondaryText =>
      isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;
  Color get onSurface =>
      isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
  Color get barTrack =>
      isDark ? const Color(0xFF2A2E38) : const Color(0xFFE8EBEF);
  Color get stepperBg =>
      isDark ? AppColors.darkSurface2 : AppColors.lightDisabledBg;

  /// Figma `Base/Back` — slightly tinted neutral background used for inset
  /// rows like the activity strip. One step darker than the parent card.
  Color get back =>
      isDark ? AppColors.darkScaffold : AppColors.lightScaffold;

  /// Figma `Base/On Back 2` — small chip/icon surface that sits on top of
  /// `back`. One step lighter than [back] so it visually pops.
  Color get onBack2 =>
      isDark ? AppColors.darkSurface : AppColors.lightOnBack;

  /// Figma `Base/Surface` — neutral surface token used for inset chips
  /// (e.g. the Edit button). Light mirrors the Figma value, dark uses an
  /// elevated surface so the chip contrasts with the parent card.
  Color get baseSurface =>
      isDark ? AppColors.darkSurface : AppColors.lightScaffold;
}

class AiMealResultSheet extends StatefulWidget {
  final String mealType;
  final String? dateStr;
  final Map<String, dynamic>? result;
  final Uint8List? imageBytes;
  final String? existingLogId;
  final String? imagePath;
  final Future<Map<String, dynamic>>? pendingResult;

  const AiMealResultSheet({
    super.key,
    required this.mealType,
    this.dateStr,
    this.result,
    this.imageBytes,
    this.existingLogId,
    this.imagePath,
    this.pendingResult,
  });

  static Future<void> show(
    BuildContext context, {
    required String mealType,
    String? dateStr,
    required Map<String, dynamic> result,
    Uint8List? imageBytes,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xCC000000),
      isDismissible: false,
      enableDrag: false,
      builder: (_) => AiMealResultSheet(
        mealType: mealType,
        dateStr: dateStr,
        result: result,
        imageBytes: imageBytes,
      ),
    );
  }

  /// Kicks off AI recognition and opens the result sheet IMMEDIATELY.
  ///
  /// IMPORTANT: all network work (auth + upload) MUST happen inside the
  /// future passed as [pendingResult], never awaited before opening the
  /// sheet. Otherwise, a slow/failed auth call leaves the user staring at
  /// nothing and any thrown exception is swallowed by the postFrame callback
  /// that invoked us — the exact "tap photo, nothing happens" bug we keep
  /// hitting after every refactor. Do NOT add `await` calls before
  /// [showModalBottomSheet] here.
  static Future<void> showWithLoading(
    BuildContext context, {
    required String mealType,
    String? dateStr,
    required Uint8List imageBytes,
  }) {
    final future = _runRecognition(() async {
      final api = ApiClient();
      final locale = LocaleNotifier.instance.value.languageCode;
      return api.uploadImage(
        '/api/recognize',
        imageBytes,
        locale: locale,
      );
    });

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xCC000000),
      isDismissible: false,
      enableDrag: false,
      builder: (_) => AiMealResultSheet(
        mealType: mealType,
        dateStr: dateStr,
        imageBytes: imageBytes,
        pendingResult: future,
      ),
    );
  }

  static Future<void> showWithTextLoading(
    BuildContext context, {
    required String mealType,
    String? dateStr,
    required String text,
  }) {
    final future = _runRecognition(() async {
      final api = ApiClient();
      await api.ensureAuthenticated();
      final locale = LocaleNotifier.instance.value.languageCode;
      return api.recognizeText(text, locale: locale);
    });

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xCC000000),
      isDismissible: false,
      enableDrag: false,
      builder: (_) => AiMealResultSheet(
        mealType: mealType,
        dateStr: dateStr,
        pendingResult: future,
      ),
    );
  }

  static Future<void> showWithTextAndImageLoading(
    BuildContext context, {
    required String mealType,
    String? dateStr,
    required String text,
    required Uint8List imageBytes,
  }) {
    final future = _runRecognition(() async {
      final api = ApiClient();
      final locale = LocaleNotifier.instance.value.languageCode;
      return api.uploadImage(
        '/api/recognize',
        imageBytes,
        locale: locale,
        text: text,
      );
    });

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xCC000000),
      isDismissible: false,
      enableDrag: false,
      builder: (_) => AiMealResultSheet(
        mealType: mealType,
        dateStr: dateStr,
        imageBytes: imageBytes,
        pendingResult: future,
      ),
    );
  }

  /// Wraps a recognition call in a Future that logs failures. Uses
  /// `Future.sync` so that even synchronous throws inside [body] become a
  /// rejected Future instead of breaking the call site before the sheet
  /// is shown.
  static Future<Map<String, dynamic>> _runRecognition(
    Future<Map<String, dynamic>> Function() body,
  ) {
    return Future.sync(body).catchError((Object e, StackTrace st) {
      debugPrint('AI recognition failed: $e\n$st');
      throw e;
    });
  }

  /// After popping a root sheet, Flutter may restore primary focus to the diary
  /// bottom [TextField]. Schedule unfocus for the frame after the pop completes.
  static void _unfocusUnderlyingAfterSheetPop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  static Future<void> showForLog(
    BuildContext context, {
    required FoodLog log,
    required String dateStr,
  }) async {
    final ingredients = _ingredientsFromLog(log);
    final result = <String, dynamic>{
      'name': _nameForLog(context, log, ingredients),
      'total_grams': log.grams,
      'total': {
        'protein': log.protein,
        'fat': log.fat,
        'carbs': log.carbs,
        'calories': log.calories,
      },
      'ingredients': ingredients,
    };

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xCC000000),
      isDismissible: true,
      enableDrag: true,
      builder: (_) => AiMealResultSheet(
        mealType: log.mealType,
        dateStr: dateStr,
        result: result,
        existingLogId: log.id,
        imagePath: log.imageUrl,
      ),
    );
    _unfocusUnderlyingAfterSheetPop();
  }

  static Future<bool> showForDuplicate(
    BuildContext context, {
    required FoodLog log,
    required String dateStr,
  }) async {
    final ingredients = _ingredientsFromLog(log);
    final result = <String, dynamic>{
      'name': _nameForLog(context, log, ingredients),
      'total_grams': log.grams,
      'total': {
        'protein': log.protein,
        'fat': log.fat,
        'carbs': log.carbs,
        'calories': log.calories,
      },
      'ingredients': ingredients,
    };

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xCC000000),
      isDismissible: true,
      enableDrag: true,
      builder: (_) => AiMealResultSheet(
        mealType: log.mealType,
        dateStr: dateStr,
        result: result,
        imagePath: log.imageUrl,
      ),
    );
    _unfocusUnderlyingAfterSheetPop();
    return saved ?? false;
  }

  static List<Map<String, dynamic>> _ingredientsFromLog(FoodLog log) {
    final raw = log.ingredientsJson;
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, dynamic>>[];
      return decoded
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry('$key', value)))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static String _nameForLog(
    BuildContext context,
    FoodLog log,
    List<Map<String, dynamic>> ingredients,
  ) {
    if (ingredients.length > 1) return log.productName;
    return '${log.productName}, ${context.l10n.gramsValue(log.grams.round())}';
  }

  @override
  State<AiMealResultSheet> createState() => _AiMealResultSheetState();
}

class _AiMealResultSheetState extends State<AiMealResultSheet>
    with TickerProviderStateMixin {
  final _nameCtl = TextEditingController();
  final _totalGramsCtl = TextEditingController();
  final _proteinCtl = TextEditingController();
  final _fatCtl = TextEditingController();
  final _carbsCtl = TextEditingController();
  final _caloriesCtl = TextEditingController();

  List<_IngredientEntry> _ingredients = [];
  bool _updatingControllers = false;
  bool _saving = false;
  File? _resolvedImageFile;
  String? _networkImageUrl;

  /// View vs. edit mode for the macros/calories card. View mode shows the
  /// new Figma overview design (read-only); edit mode swaps in the existing
  /// parameter inputs so the user can fine-tune values.
  bool _paramsEditMode = false;

  /// Daily calorie target loaded from settings. Used for the "X% of your
  /// daily calories" indicator. 0 means goal not loaded yet — hide percent.
  double _dailyCalorieGoal = 0;

  bool _isLoading = false;
  String? _loadingError;
  Timer? _textTimer;
  int _textIndex = 0;
  late final AnimationController _spinController;

  /// Drives the count-up reveal of the overview card values (calorie ring,
  /// activity rows, macros, health rating, daily %). Plays once after the
  /// sheet opens; subsequent edits don't replay it.
  late final AnimationController _overviewIntroCtl;
  late final Animation<double> _overviewIntro;
  bool _overviewIntroStarted = false;
  late List<String> _loadingTexts;
  bool _loadingTextsInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadingTexts = [];

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _overviewIntroCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _overviewIntro = CurvedAnimation(
      parent: _overviewIntroCtl,
      curve: Curves.easeOutCubic,
    );

    if (widget.pendingResult != null) {
      _isLoading = true;
      _startLoadingTexts();
      _spinController.repeat();
      _awaitResult();
    } else if (widget.result != null) {
      _initResultControllers(widget.result!);
    }

    _resolveImagePath();
    _loadDailyCalorieGoal();
  }

  Future<void> _loadDailyCalorieGoal() async {
    final db = await AppDatabase.getInstance();
    final raw = await db.getSetting('calorie_goal');
    if (!mounted) return;
    final value = double.tryParse(raw ?? '');
    if (value != null && value > 0) {
      setState(() => _dailyCalorieGoal = value);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadingTextsInitialized) {
      _loadingTextsInitialized = true;
      _loadingTexts = widget.imageBytes != null
          ? [
              context.l10n.aiAnalyzingPhoto,
              context.l10n.aiRecognizingIngredients,
              context.l10n.aiCountingCalories,
              context.l10n.aiDeterminingMacros,
              context.l10n.aiAlmostDone,
            ]
          : [
              context.l10n.aiAnalyzingData,
              context.l10n.aiRecognizingIngredients,
              context.l10n.aiCountingCalories,
              context.l10n.aiDeterminingMacros,
              context.l10n.aiAlmostDone,
            ];
    }
  }

  void _startLoadingTexts() {
    _textTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      if (!mounted) return;
      setState(() {
        _textIndex = (_textIndex + 1) % _loadingTexts.length;
      });
    });
  }

  Future<void> _awaitResult() async {
    try {
      final result = await widget.pendingResult!;
      if (!mounted) return;
      _textTimer?.cancel();
      _spinController.stop();
      setState(() {
        _isLoading = false;
        _initResultControllers(result);
      });
    } on NetworkException catch (e) {
      debugPrint('AI recognition network error: ${e.message}');
      if (!mounted) return;
      _textTimer?.cancel();
      _spinController.stop();
      setState(() {
        _isLoading = false;
        _loadingError = e.message;
      });
    } catch (e, st) {
      debugPrint('AI recognition error: $e\n$st');
      if (!mounted) return;
      _textTimer?.cancel();
      _spinController.stop();
      setState(() {
        _isLoading = false;
        _loadingError = context.l10n.aiRecognitionFailed;
      });
    }
  }

  void _resolveImagePath() {
    final path = widget.imagePath;
    if (path == null || path.isEmpty) return;

    if (path.startsWith('http://') || path.startsWith('https://')) {
      _networkImageUrl = path;
    } else {
      final file = File(path);
      if (file.existsSync()) {
        _resolvedImageFile = file;
      }
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _overviewIntroCtl.dispose();
    _textTimer?.cancel();
    _nameCtl.dispose();
    _totalGramsCtl.dispose();
    _proteinCtl.dispose();
    _fatCtl.dispose();
    _carbsCtl.dispose();
    _caloriesCtl.dispose();
    for (final ing in _ingredients) {
      ing.dispose();
    }
    super.dispose();
  }

  void _initResultControllers(Map<String, dynamic> result) {
    final total = result['total'] as Map<String, dynamic>? ?? {};
    final totalGrams = (result['total_grams'] as num?)?.toDouble() ?? 100;
    final ingredients =
        (result['ingredients'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    _nameCtl.text = result['name'] as String? ?? context.l10n.defaultDishName;
    _totalGramsCtl.text = _fmt(totalGrams);
    _proteinCtl.text = _fmt((total['protein'] as num?)?.toDouble() ?? 0);
    _fatCtl.text = _fmt((total['fat'] as num?)?.toDouble() ?? 0);
    _carbsCtl.text = _fmt((total['carbs'] as num?)?.toDouble() ?? 0);
    _caloriesCtl.text = _fmt((total['calories'] as num?)?.toDouble() ?? 0);

    for (final ing in _ingredients) {
      ing.dispose();
    }

    final countRegex = RegExp(
      r'\((\d+)\s*(?:шт\.?|pcs?\.?|pieces?)\)',
      caseSensitive: false,
    );

    _ingredients = ingredients.map((i) {
      final grams = (i['grams'] as num?)?.toDouble() ?? 0;
      final protein = (i['protein'] as num?)?.toDouble() ?? 0;
      final fat = (i['fat'] as num?)?.toDouble() ?? 0;
      final carbs = (i['carbs'] as num?)?.toDouble() ?? 0;
      final calories = (i['calories'] as num?)?.toDouble() ?? 0;

      final rawName = i['name'] as String? ?? '';
      final match = countRegex.firstMatch(rawName);
      final explicitCount = (i['count'] as num?)?.toInt() ?? 0;
      final count = explicitCount > 0
          ? explicitCount
          : match != null
              ? int.tryParse(match.group(1)!) ?? 0
              : 0;
      final cleanName = match != null
          ? rawName.replaceFirst(match.group(0)!, '').trim()
          : rawName;
      final gramsPerUnit =
          (i['grams_per_unit'] as num?)?.toDouble() ??
          (count > 0 ? grams / count : 0.0);

      return _IngredientEntry(
        nameCtl: TextEditingController(text: cleanName),
        gramsCtl: TextEditingController(text: _fmt(grams)),
        proteinPer100g: grams > 0 ? protein / grams * 100 : 0,
        fatPer100g: grams > 0 ? fat / grams * 100 : 0,
        carbsPer100g: grams > 0 ? carbs / grams * 100 : 0,
        caloriesPer100g: grams > 0 ? calories / grams * 100 : 0,
        protein: protein,
        fat: fat,
        carbs: carbs,
        calories: calories,
        count: count,
        gramsPerUnit: gramsPerUnit,
      );
    }).toList();
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  double _val(TextEditingController c) => double.tryParse(c.text) ?? 0;

  String? _ingredientsJson() {
    if (_ingredients.isEmpty) return null;
    return jsonEncode(
      _ingredients.map((ing) {
        final grams = _val(ing.gramsCtl);
        return <String, dynamic>{
          'name': ing.nameCtl.text.trim(),
          'grams': grams,
          'protein': ing.protein,
          'fat': ing.fat,
          'carbs': ing.carbs,
          'calories': ing.calories,
          if (ing.hasCounter) 'count': ing.count,
          if (ing.hasCounter) 'grams_per_unit': ing.gramsPerUnit,
        };
      }).toList(),
    );
  }

  void _recalcFromMacros() {
    if (_updatingControllers) return;
    _updatingControllers = true;

    final p = _val(_proteinCtl);
    final f = _val(_fatCtl);
    final c = _val(_carbsCtl);
    _caloriesCtl.text = _fmt(p * 4 + f * 9 + c * 4);

    _updatingControllers = false;
    setState(() {});
  }

  void _recalcFromCalories() {
    if (_updatingControllers) return;
    _updatingControllers = true;

    final currentCal = _val(_caloriesCtl);
    final oldCal =
        _val(_proteinCtl) * 4 + _val(_fatCtl) * 9 + _val(_carbsCtl) * 4;
    if (oldCal > 0) {
      final factor = currentCal / oldCal;
      _proteinCtl.text = _fmt(_val(_proteinCtl) * factor);
      _fatCtl.text = _fmt(_val(_fatCtl) * factor);
      _carbsCtl.text = _fmt(_val(_carbsCtl) * factor);
    }

    _updatingControllers = false;
    setState(() {});
  }

  void _onIngredientGramsChanged(int index) {
    if (_updatingControllers) return;
    _updatingControllers = true;

    final ing = _ingredients[index];
    final g = _val(ing.gramsCtl);
    final f = g / 100;
    ing.protein = ing.proteinPer100g * f;
    ing.fat = ing.fatPer100g * f;
    ing.carbs = ing.carbsPer100g * f;
    ing.calories = ing.caloriesPer100g * f;

    _recalcTotalsFromIngredients();

    _updatingControllers = false;
    setState(() {});
  }

  void _onIngredientCountChanged(int index, int delta) {
    final ing = _ingredients[index];
    final newCount = (ing.count + delta).clamp(1, 99);
    if (newCount == ing.count) return;

    ing.count = newCount;
    final newGrams = ing.gramsPerUnit * newCount;
    ing.gramsCtl.text = _fmt(newGrams);
    _onIngredientGramsChanged(index);
  }

  void _recalcTotalsFromIngredients() {
    double totalGrams = 0, totalP = 0, totalF = 0, totalC = 0, totalCal = 0;
    for (final i in _ingredients) {
      totalGrams += _val(i.gramsCtl);
      totalP += i.protein;
      totalF += i.fat;
      totalC += i.carbs;
      totalCal += i.calories;
    }
    _totalGramsCtl.text = _fmt(totalGrams);
    _proteinCtl.text = _fmt(totalP);
    _fatCtl.text = _fmt(totalF);
    _carbsCtl.text = _fmt(totalC);
    _caloriesCtl.text = _fmt(totalCal);
  }

  void _removeIngredient(int index) {
    _updatingControllers = true;
    _ingredients[index].dispose();
    _ingredients.removeAt(index);

    if (_ingredients.isNotEmpty) {
      _recalcTotalsFromIngredients();
    }

    _updatingControllers = false;
    setState(() {});
  }

  Future<String?> _saveImageLocally(Uint8List bytes, String logId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${dir.path}/meal_photos');
      if (!photosDir.existsSync()) {
        photosDir.createSync(recursive: true);
      }
      final file = File('${photosDir.path}/$logId.jpg');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('Failed to save photo locally: $e');
      return null;
    }
  }

  /// When duplicating a log or adding from an existing image path (no new bytes).
  Future<String?> _imageUrlForNewLog(String logId) async {
    if (widget.imageBytes != null) {
      return _saveImageLocally(widget.imageBytes!, logId);
    }
    final path = widget.imagePath;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return _copyLocalMealPhotoToLog(path, logId);
  }

  Future<String?> _copyLocalMealPhotoToLog(String sourcePath, String logId) async {
    try {
      final src = File(sourcePath);
      if (!src.existsSync()) return null;
      final dir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${dir.path}/meal_photos');
      if (!photosDir.existsSync()) {
        photosDir.createSync(recursive: true);
      }
      final dest = File('${photosDir.path}/$logId.jpg');
      await src.copy(dest.path);
      return dest.path;
    } catch (e) {
      debugPrint('Failed to copy meal photo: $e');
      return null;
    }
  }

  bool get _isEditing => widget.existingLogId != null;

  Future<void> _saveResult() async {
    if (_saving) return;
    final l10n = context.l10n;

    if (!_isEditing) {
      final auth = AuthService();
      if (!auth.isPremium && auth.freeTrialExhausted) {
        if (mounted) {
          Navigator.of(context).pop();
          GoRouter.of(context).go('/paywall');
        }
        return;
      }
    }

    setState(() => _saving = true);

    final db = await AppDatabase.getInstance();
    final date = widget.dateStr != null
        ? DateFormat('yyyy-MM-dd').parse(widget.dateStr!)
        : DateTime.now();

    final productName = _nameCtl.text.trim().isEmpty
        ? l10n.unknownDish
        : _nameCtl.text.trim();
    final ingredientsJson = _ingredientsJson();

    if (_isEditing) {
      final companion = FoodLogsCompanion(
        productName: drift.Value(productName),
        grams: drift.Value(_val(_totalGramsCtl)),
        protein: drift.Value(_val(_proteinCtl)),
        fat: drift.Value(_val(_fatCtl)),
        carbs: drift.Value(_val(_carbsCtl)),
        calories: drift.Value(_val(_caloriesCtl)),
        ingredientsJson: drift.Value(ingredientsJson),
        updatedAt: drift.Value(DateTime.now()),
        synced: const drift.Value(false),
      );
      await db.updateFoodLog(widget.existingLogId!, companion);
    } else {
      final logId = const Uuid().v4();
      final imageUrl = await _imageUrlForNewLog(logId);

      await db.addFoodLog(FoodLogsCompanion.insert(
        id: logId,
        productName: productName,
        mealType: widget.mealType,
        mealDate: DateTime(date.year, date.month, date.day, 12),
        grams: _val(_totalGramsCtl),
        protein: drift.Value(_val(_proteinCtl)),
        fat: drift.Value(_val(_fatCtl)),
        carbs: drift.Value(_val(_carbsCtl)),
        calories: drift.Value(_val(_caloriesCtl)),
        imageUrl: drift.Value(imageUrl),
        ingredientsJson: drift.Value(ingredientsJson),
      ));

      final auth = AuthService();
      if (!auth.isPremium) {
        await auth.incrementFreeEntry();
      }
    }

    if (mounted) context.pop(true);
  }

  static const _warningBg = Color(0x26FF6686);
  static const _warningIcon = Color(0xFFFF6686);

  @override
  Widget build(BuildContext context) {
    final c = _AiSheetColors.of(context);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final hasImage = widget.imageBytes != null || _resolvedImageFile != null || _networkImageUrl != null;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.95),
      child: Container(
        decoration: BoxDecoration(
          color: c.sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(c),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: keyboardHeight > 0 ? keyboardHeight : 0,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasImage) _buildImageCard(c),
                      // Body content overlaps the photo by 24px so the stats
                      // card visually anchors the dish image. Cards inset 8px
                      // on each side relative to the photo (Figma layout).
                      Transform.translate(
                        offset: Offset(0, hasImage ? -24 : 0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isLoading)
                                _buildLoadingBody(c)
                              else if (_loadingError != null)
                                _buildErrorBody(c)
                              else ...[
                                _buildAnalyticsCardShell(
                                  c,
                                  AnimatedSize(
                                    duration:
                                        const Duration(milliseconds: 260),
                                    curve: Curves.easeOutCubic,
                                    alignment: Alignment.topCenter,
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      transitionBuilder:
                                          (child, animation) =>
                                              FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                      layoutBuilder: (current, previous) =>
                                          Stack(
                                        alignment: Alignment.topCenter,
                                        children: [
                                          ...previous,
                                          ?current,
                                        ],
                                      ),
                                      child: KeyedSubtree(
                                        key: ValueKey(_paramsEditMode),
                                        child: _paramsEditMode
                                            ? _buildParametersSection(c)
                                            : _buildOverviewCard(c),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_ingredients.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  _buildIngredientsSection(c),
                                ],
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!_isLoading && _loadingError == null)
              _buildBottomBar(c, keyboardHeight > 0 ? 0 : bottomPadding),
            if (_isLoading || _loadingError != null)
              SizedBox(height: bottomPadding + 8),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBody(_AiSheetColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.primary),
                    backgroundColor: AppColors.primary.withAlpha(40),
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _loadingTexts[_textIndex],
                    key: ValueKey(_textIndex),
                    style: TextStyle(
                      color: c.secondaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 20 / 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBody(_AiSheetColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: _warningBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: _warningIcon,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _loadingError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 20 / 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: c.surfaceBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  context.l10n.close,
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(_AiSheetColors c) {
    final isFreshPhoto = widget.imageBytes != null;

    Widget imageWidget;
    if (isFreshPhoto) {
      imageWidget = Image.memory(widget.imageBytes!, fit: BoxFit.cover);
    } else if (_resolvedImageFile != null) {
      imageWidget = Image.file(_resolvedImageFile!, fit: BoxFit.contain);
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: _networkImageUrl!,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Center(
          child: Icon(Icons.broken_image_outlined, color: c.secondaryText, size: 40),
        ),
      );
    }

    return Container(
      height: 221,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isFreshPhoto ? null : c.surfaceBg,
        border: Border.all(color: c.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageWidget,
    );
  }

  Widget _buildHeader(_AiSheetColors c) {
    final String title;
    if (_isLoading) {
      title = context.l10n.aiRecognizingDish;
    } else if (_loadingError != null) {
      title = _isEditing ? context.l10n.edit : context.l10n.addDish;
    } else {
      final name = _nameCtl.text.trim();
      title = name.isEmpty ? context.l10n.defaultDishName : name;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 24 / 18,
              ),
            ),
          ),
          if (!_isLoading) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.cardBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: c.onSurface, size: 20),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── New design: read-only overview card ──────────────────────────────
  Widget _buildOverviewCard(_AiSheetColors c) {
    final l10n = context.l10n;
    final calories = _val(_caloriesCtl);
    final protein = _val(_proteinCtl);
    final fat = _val(_fatCtl);
    final carbs = _val(_carbsCtl);

    final pCal = protein * 4;
    final fCal = fat * 9;
    final cCal = carbs * 4;
    final macroCalSum = pCal + fCal + cCal;
    final pShare = macroCalSum > 0 ? pCal / macroCalSum : 0.0;
    final fShare = macroCalSum > 0 ? fCal / macroCalSum : 0.0;
    final cShare = macroCalSum > 0 ? cCal / macroCalSum : 0.0;

    final dailyPercent = _dailyCalorieGoal > 0
        ? (calories / _dailyCalorieGoal * 100).round().clamp(0, 999)
        : null;

    final score = _computeHealthScore();
    final scoreRatio = (score / 10).clamp(0.0, 1.0);
    final description = _healthDescription(score);

    // Kick the count-up animation off the first time the overview is shown.
    if (!_overviewIntroStarted) {
      _overviewIntroStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _overviewIntroCtl.forward();
      });
    }

    return AnimatedBuilder(
      animation: _overviewIntro,
      builder: (context, _) {
        final t = _overviewIntro.value;
        return _buildOverviewCardContent(
          c: c,
          l10n: l10n,
          progress: t,
          calories: calories,
          protein: protein,
          fat: fat,
          carbs: carbs,
          pShare: pShare,
          fShare: fShare,
          cShare: cShare,
          dailyPercent: dailyPercent,
          score: score,
          scoreRatio: scoreRatio,
          description: description,
        );
      },
    );
  }

  /// Outer card chrome shared between the read-only overview and the macros
  /// editor. Keeping it mounted across mode toggles avoids a layout flash —
  /// only the inner column swaps and the height animates smoothly.
  Widget _buildAnalyticsCardShell(_AiSheetColors c, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: c.isDark ? AppColors.darkBack2 : AppColors.lightBack2,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _buildOverviewCardContent({
    required _AiSheetColors c,
    required AppLocalizations l10n,
    required double progress,
    required double calories,
    required double protein,
    required double fat,
    required double carbs,
    required double pShare,
    required double fShare,
    required double cShare,
    required int? dailyPercent,
    required int score,
    required double scoreRatio,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // Calorie ring + activity rows
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildCalorieRing(
                c,
                calories * progress,
                pShare * progress,
                fShare * progress,
                cShare * progress,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActivityRow(
                      c,
                      icon: Icons.directions_walk_rounded,
                      label: l10n.activityWalking,
                      value: _formatActivityHours(calories * progress / 250),
                    ),
                    const SizedBox(height: 4),
                    _buildActivityRow(
                      c,
                      icon: Icons.directions_bike_rounded,
                      label: l10n.activityBicycle,
                      value: _formatActivityHours(calories * progress / 600),
                    ),
                    const SizedBox(height: 4),
                    _buildActivityRow(
                      c,
                      svgAsset: 'assets/icons/sleep.svg',
                      svgWidth: 16,
                      svgHeight: 10,
                      label: l10n.activityResting,
                      value: _formatActivityHours(calories * progress / 70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Macro pills
          Row(
            children: [
              Expanded(
                child: _buildMacroPill(
                  c,
                  iconAsset: 'assets/icons/belok.svg',
                  letter: l10n.proteinShort,
                  grams: protein * progress,
                  gradient: const LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [Color(0x26F0681B), Color(0x26D91D1D)],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroPill(
                  c,
                  iconAsset: 'assets/icons/fat.svg',
                  letter: l10n.fatShort,
                  grams: fat * progress,
                  gradient: const LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [Color(0x26FFBB00), Color(0x26D0FF00)],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroPill(
                  c,
                  iconAsset: 'assets/icons/uglevod.svg',
                  letter: l10n.carbsShort,
                  grams: carbs * progress,
                  gradient: const LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [Color(0x261787D1), Color(0x2617D1C7)],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildHealthCard(
            c,
            score: score,
            scoreRatio: scoreRatio,
            description: description,
            progress: progress,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => setState(() => _paramsEditMode = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: c.baseSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: c.isDark
                            ? AppColors.darkSecondaryDark
                            : AppColors.lightSecondaryDark,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.edit,
                        style: TextStyle(
                          color: c.isDark
                              ? AppColors.darkPrimaryLight
                              : AppColors.lightPrimaryLight,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 18 / 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (dailyPercent != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(dailyPercent * progress).round()}%',
                      style: TextStyle(
                        color: c.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.ofYourDailyCalories,
                      style: TextStyle(
                        color: c.onSurface.withAlpha(128),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
    );
  }

  Widget _buildCalorieRing(
    _AiSheetColors c,
    double calories,
    double pShare,
    double fShare,
    double cShare,
  ) {
    return SizedBox(
      width: 106,
      height: 105,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(94, 94),
            painter: _CalorieRingPainter(
              proteinShare: pShare,
              fatShare: fShare,
              carbsShare: cShare,
              trackColor: c.barTrack,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatCalories(calories),
                style: TextStyle(
                  color: c.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              Text(
                context.l10n.kcalUnit,
                style: TextStyle(
                  color: c.secondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRow(
    _AiSheetColors c, {
    IconData? icon,
    String? svgAsset,
    double svgWidth = 16,
    double svgHeight = 16,
    required String label,
    required String value,
  }) {
    assert(icon != null || svgAsset != null);
    return Container(
      decoration: BoxDecoration(
        color: c.back,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 24,
            decoration: BoxDecoration(
              color: c.onBack2,
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x081B364A),
                  offset: Offset(0, 5),
                  blurRadius: 20,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: svgAsset != null
                ? SvgPicture.asset(
                    svgAsset,
                    width: svgWidth,
                    height: svgHeight,
                    colorFilter: ColorFilter.mode(
                      c.onSurface,
                      BlendMode.srcIn,
                    ),
                  )
                : Icon(icon, size: 16, color: c.onSurface),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.isDark
                    ? AppColors.darkPrimaryLight
                    : AppColors.lightPrimaryLight,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 16 / 13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: c.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 16 / 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPill(
    _AiSheetColors c, {
    required String iconAsset,
    required String letter,
    required double grams,
    required LinearGradient gradient,
  }) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            child: SvgPicture.asset(iconAsset, width: 18, height: 18),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              letter.toUpperCase(),
              style: TextStyle(
                color: c.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 16 / 13,
              ),
            ),
          ),
          Text(
            context.l10n.gramsValue(grams.round()),
            style: TextStyle(
              color: c.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 16 / 13,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildHealthCard(
    _AiSheetColors c, {
    required int score,
    required double scoreRatio,
    required String description,
    double progress = 1,
  }) {
    final l10n = context.l10n;
    final displayScore = (score * progress).round();
    final displayRatio = scoreRatio * progress;

    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        border: Border.all(color: c.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: SvgPicture.asset('assets/icons/heart_rating.svg'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.healthRatingLabel,
                        style: TextStyle(
                          color: c.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 16 / 13,
                        ),
                      ),
                      Text(
                        l10n.healthRatingValue(displayScore),
                        style: TextStyle(
                          color: c.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 16 / 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: c.isDark
                          ? AppColors.lineDT200
                          : AppColors.lineLight200,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor:
                            displayRatio <= 0 ? 0.001 : displayRatio,
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _healthBarGradient(score),
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    description,
                    style: TextStyle(
                      color: c.isDark
                          ? AppColors.darkPrimaryLight
                          : AppColors.lightPrimaryLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 16 / 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Heuristic 1–10 health score. Backend may override via
  /// `result['health_rating']`.
  ///
  /// We start at a neutral 5 and adjust based on two signals:
  ///
  ///   1. **Calorie density** (kcal per gram) — the strongest proxy for
  ///      whole vs. processed foods. Vegetables and broths sit well below
  ///      1 kcal/g; oils and sweets above 4. Big swings here.
  ///   2. **Macro balance** — penalise fat-dominant meals, reward
  ///      protein-dominant ones.
  ///
  /// Tested against: spinach (~10), grilled chicken (~8), burger (~4),
  /// chocolate bar (~2).
  int _computeHealthScore() {
    final raw = (widget.result?['health_rating'] as num?)?.toInt();
    if (raw != null) return raw.clamp(0, 10);

    final p = _val(_proteinCtl);
    final f = _val(_fatCtl);
    final cal = _val(_caloriesCtl);
    final grams = _val(_totalGramsCtl);
    if (cal <= 0 || grams <= 0) return 7;

    final calDensity = cal / grams;
    final fatCalShare = (f * 9) / cal;
    final proteinCalShare = (p * 4) / cal;

    var score = 5.0;

    // Calorie density (kcal/g): the strongest single predictor of whether
    // a food is whole/water-rich vs. processed/oily.
    if (calDensity < 0.6) {
      score += 4; // vegetables, broths, leafy greens
    } else if (calDensity < 1.2) {
      score += 3; // fruit, low-fat dairy, beans
    } else if (calDensity < 2.0) {
      score += 1; // lean meats, whole grains
    } else if (calDensity < 3.0) {
      score += 0; // mixed dishes
    } else if (calDensity < 4.0) {
      score -= 1; // dense/processed
    } else {
      score -= 2; // oils, sweets, snacks
    }

    // Fat-dominant meals.
    if (fatCalShare > 0.55) {
      score -= 2;
    } else if (fatCalShare > 0.40) {
      score -= 1;
    }

    // Protein-rich meals.
    if (proteinCalShare > 0.40) {
      score += 2;
    } else if (proteinCalShare > 0.25) {
      score += 1;
    }

    return score.round().clamp(1, 10);
  }

  /// Health bar gradient picked by score band:
  ///   1–3 → red ("poor"), 4–6 → amber ("fair"), 7–10 → green ("good").
  /// Each band uses a 2-stop gradient so the fill keeps the same depth/feel
  /// regardless of score, only the hue shifts.
  List<Color> _healthBarGradient(int score) {
    if (score <= 3) {
      return const [Color(0xFFEE2750), Color(0xFFFF6686)];
    }
    if (score <= 6) {
      return const [Color(0xFFF0681B), Color(0xFFFFBB00)];
    }
    return const [Color(0xFF3DA43B), Color(0xFF8FCB3B)];
  }

  String _healthDescription(int score) {
    final raw = widget.result?['health_comment'] as String?;
    if (raw != null && raw.trim().isNotEmpty) return raw.trim();
    final l10n = context.l10n;
    if (score >= 9) return l10n.healthDescGreat;
    if (score >= 7) return l10n.healthDescGood;
    if (score >= 4) return l10n.healthDescFair;
    return l10n.healthDescPoor;
  }

  String _formatCalories(double v) {
    if (v <= 0) return '0';
    return v.round().toString();
  }

  String _formatActivityHours(double hours) {
    if (hours.isNaN || hours <= 0) {
      return context.l10n.approxMinutes(0);
    }
    if (hours < 1) {
      final minutes = (hours * 60).round().clamp(1, 59);
      return context.l10n.approxMinutes(minutes);
    }
    return context.l10n.approxHours(hours.round().clamp(1, 99));
  }

  Widget _buildParametersSection(_AiSheetColors c) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildParamRow(
          c,
          iconAsset: 'assets/icons/cal.svg',
          label: l10n.caloriesKcalLabel,
          controller: _caloriesCtl,
          onChanged: (_) => _recalcFromCalories(),
        ),
        const SizedBox(height: 12),
        _buildParamRow(
          c,
          iconAsset: 'assets/icons/belok.svg',
          label: l10n.proteinGramsLabel,
          controller: _proteinCtl,
          onChanged: (_) => _recalcFromMacros(),
        ),
        const SizedBox(height: 12),
        _buildParamRow(
          c,
          iconAsset: 'assets/icons/fat.svg',
          label: l10n.fatGramsLabel,
          controller: _fatCtl,
          onChanged: (_) => _recalcFromMacros(),
        ),
        const SizedBox(height: 12),
        _buildParamRow(
          c,
          iconAsset: 'assets/icons/uglevod.svg',
          label: l10n.carbsGramsLabel,
          controller: _carbsCtl,
          onChanged: (_) => _recalcFromMacros(),
        ),
        const SizedBox(height: 12),
        _buildSaveMacrosButton(c),
      ],
    );
  }

  /// Outlined success button at the bottom of the macros editor — commits the
  /// edits and returns to the read-only overview card.
  Widget _buildSaveMacrosButton(_AiSheetColors c) {
    return GestureDetector(
      onTap: () => setState(() => _paramsEditMode = false),
      child: Container(
        height: 44,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.green.withAlpha(102),
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.green,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              context.l10n.saveMacros,
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 18 / 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParamRow(
    _AiSheetColors c, {
    required String iconAsset,
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: Center(
            child: SvgPicture.asset(iconAsset, width: 24, height: 24),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: c.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 18 / 14,
            ),
          ),
        ),
        _buildValueField(c, controller, onChanged),
      ],
    );
  }

  Widget _buildValueField(
    _AiSheetColors c,
    TextEditingController controller,
    ValueChanged<String> onChanged,
  ) {
    return Container(
      width: 70,
      decoration: BoxDecoration(
        border: Border.all(color: c.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
        ],
        style: TextStyle(
          color: c.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 18 / 14,
        ),
        textAlign: TextAlign.left,
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
          filled: false,
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildIngredientsSection(_AiSheetColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.ingredientsLabel,
          style: TextStyle(
            color: c.secondaryText,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 18 / 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: c.isDark ? AppColors.darkBack2 : AppColors.lightBack2,
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: List.generate(_ingredients.length, (i) {
              return Padding(
                padding: EdgeInsets.only(top: i > 0 ? 12 : 0),
                child: _buildIngredientRow(c, i),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientRow(_AiSheetColors c, int index) {
    final ing = _ingredients[index];
    return Row(
      children: [
        Expanded(
          child: Text(
            ing.nameCtl.text,
            style: TextStyle(
              color: c.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 18 / 14,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 8),
        if (ing.hasCounter) ...[
          _buildStepper(c, index, ing.count),
          const SizedBox(width: 8),
        ],
        _buildGramsField(c, ing.gramsCtl, index),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _removeIngredient(index),
          child: Container(
            width: 28,
            height: 34,
            decoration: BoxDecoration(
              color: _warningBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.close, color: _warningIcon, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildStepper(_AiSheetColors c, int index, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _onIngredientCountChanged(index, -1),
          child: Container(
            width: 28,
            height: 34,
            decoration: BoxDecoration(
              color: c.stepperBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: SizedBox(
                width: 12,
                height: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: c.onSurface),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$count',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 18 / 14,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _onIngredientCountChanged(index, 1),
          child: Container(
            width: 28,
            height: 34,
            decoration: BoxDecoration(
              color: c.stepperBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.add, color: c.onSurface, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildGramsField(
    _AiSheetColors c,
    TextEditingController controller,
    int index,
  ) {
    return Container(
      width: 70,
      decoration: BoxDecoration(
        border: Border.all(color: c.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              style: TextStyle(
                color: c.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 18 / 14,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                filled: false,
              ),
              onChanged: (_) => _onIngredientGramsChanged(index),
            ),
          ),
          Text(
            context.l10n.gramsUnitDot,
            style: TextStyle(
              color: c.onSurface.withAlpha(128),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 18 / 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(_AiSheetColors c, double bottomPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPadding + 8),
      decoration: BoxDecoration(
        color: c.sheetBg,
      ),
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: FilledButton(
          onPressed: _val(_totalGramsCtl) > 0 && !_saving ? _saveResult : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withAlpha(100),
            disabledForegroundColor: Colors.white54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 22 / 16,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/fork_knife.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 4),
              Text(_isEditing ? context.l10n.saveChanges : context.l10n.logEntry),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders the segmented calorie ring used in the meal overview card.
///
/// Each macro (protein/fat/carbs) draws a coloured arc whose sweep is
/// proportional to its share of total macro calories. A small radial gap
/// separates segments — matching the Figma reference.
class _CalorieRingPainter extends CustomPainter {
  _CalorieRingPainter({
    required this.proteinShare,
    required this.fatShare,
    required this.carbsShare,
    required this.trackColor,
  });

  final double proteinShare;
  final double fatShare;
  final double carbsShare;
  final Color trackColor;

  static const double _strokeWidth = 9;
  static const double _gapPx = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - _strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    // Convert a fixed pixel gap into the angle subtended on the ring.
    final gap = radius > 0 ? _gapPx / radius : 0.0;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    // Solid colors per macro — using a sweep gradient on a long segment
    // makes the gradient stretch so far that the segment reads as two
    // separate colors. A single saturated tone keeps each macro recognisable
    // regardless of arc length. Order clockwise from top: protein → fat → carbs.
    final raw = <_RingSegment>[
      if (proteinShare > 0)
        _RingSegment(proteinShare, const [Color(0xFFE4431C)]),
      if (fatShare > 0)
        _RingSegment(fatShare, const [Color(0xFFEFD400)]),
      if (carbsShare > 0)
        _RingSegment(carbsShare, const [Color(0xFF17ACCC)]),
    ];
    if (raw.isEmpty) return;

    // Drop slivers smaller than the gap — drawing them produces an isolated
    // stub flanked by two gaps that reads as a "hole" in the ring. Their
    // share is absorbed into the previous segment so total sweep is preserved.
    final segments = <_RingSegment>[];
    final minShare = (gap * 1.5) / (2 * math.pi);
    for (final s in raw) {
      if (s.share < minShare && segments.isNotEmpty) {
        final last = segments.removeLast();
        segments.add(_RingSegment(last.share + s.share, last.colors));
      } else {
        segments.add(s);
      }
    }
    if (segments.length >= 2 &&
        segments.first.share < minShare &&
        raw.length > 1) {
      final first = segments.removeAt(0);
      final last = segments.removeLast();
      segments.add(_RingSegment(last.share + first.share, last.colors));
    }

    final useGaps = segments.length > 1;
    var start = -math.pi / 2;
    for (final segment in segments) {
      final share = 2 * math.pi * segment.share;
      final sweep = useGaps ? share - gap : share;
      if (sweep <= 0) {
        start += share;
        continue;
      }
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.butt;
      if (segment.colors.length == 1) {
        paint.color = segment.colors.single;
      } else {
        paint.shader = SweepGradient(
          startAngle: start,
          endAngle: start + sweep,
          colors: segment.colors,
        ).createShader(rect);
      }
      canvas.drawArc(rect, start, sweep, false, paint);
      start += share;
    }
  }

  @override
  bool shouldRepaint(covariant _CalorieRingPainter old) {
    return old.proteinShare != proteinShare ||
        old.fatShare != fatShare ||
        old.carbsShare != carbsShare ||
        old.trackColor != trackColor;
  }
}

class _RingSegment {
  const _RingSegment(this.share, this.colors);
  final double share;
  final List<Color> colors;
}
