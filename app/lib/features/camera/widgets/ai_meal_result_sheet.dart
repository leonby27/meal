import 'dart:async';
import 'dart:io';

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
    final result = <String, dynamic>{
      'name': log.productName,
      'total_grams': log.grams,
      'total': {
        'protein': log.protein,
        'fat': log.fat,
        'carbs': log.carbs,
        'calories': log.calories,
      },
      'ingredients': <Map<String, dynamic>>[],
    };

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xCC000000),
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
    final result = <String, dynamic>{
      'name': log.productName,
      'total_grams': log.grams,
      'total': {
        'protein': log.protein,
        'fat': log.fat,
        'carbs': log.carbs,
        'calories': log.calories,
      },
      'ingredients': <Map<String, dynamic>>[],
    };

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xCC000000),
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

  @override
  State<AiMealResultSheet> createState() => _AiMealResultSheetState();
}

class _AiMealResultSheetState extends State<AiMealResultSheet>
    with SingleTickerProviderStateMixin {
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

  bool _isLoading = false;
  String? _loadingError;
  Timer? _textTimer;
  int _textIndex = 0;
  late final AnimationController _spinController;
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

    if (widget.pendingResult != null) {
      _isLoading = true;
      _startLoadingTexts();
      _spinController.repeat();
      _awaitResult();
    } else if (widget.result != null) {
      _initResultControllers(widget.result!);
    }

    _resolveImagePath();
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
      final count = match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
      final cleanName = match != null
          ? rawName.replaceFirst(match.group(0)!, '').trim()
          : rawName;
      final gramsPerUnit = count > 0 ? grams / count : 0.0;

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

    if (_isEditing) {
      final companion = FoodLogsCompanion(
        productName: drift.Value(productName),
        grams: drift.Value(_val(_totalGramsCtl)),
        protein: drift.Value(_val(_proteinCtl)),
        fat: drift.Value(_val(_fatCtl)),
        carbs: drift.Value(_val(_carbsCtl)),
        calories: drift.Value(_val(_caloriesCtl)),
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
      ));

      final auth = AuthService();
      if (!auth.isPremium) {
        await auth.incrementFreeEntry();
      }
    }

    if (mounted) context.pop(true);
  }

  // ── Macro bar ratio ──────────────────────────────────────────
  double get _totalMacros => _val(_proteinCtl) + _val(_fatCtl) + _val(_carbsCtl);

  double _macroRatio(double macroValue) {
    final total = _totalMacros;
    if (total <= 0) return 0;
    return (macroValue / total).clamp(0.0, 1.0);
  }

  static const _warningBg = Color(0x26FF6686);
  static const _warningIcon = Color(0xFFFF6686);

  static const _proteinGradient = LinearGradient(
    colors: [Color(0xFFF0681B), Color(0xFFD91D1D)],
  );
  static const _fatGradient = LinearGradient(
    colors: [Color(0xFFFFBB00), Color(0xFFD0FF00)],
  );
  static const _carbsGradient = LinearGradient(
    colors: [Color(0xFF1787D1), Color(0xFF17D1C7)],
  );

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
                      if (hasImage) ...[
                        _buildImageCard(c),
                        const SizedBox(height: 24),
                      ],
                      if (_isLoading)
                        _buildLoadingBody(c)
                      else if (_loadingError != null)
                        _buildErrorBody(c)
                      else ...[
                        _buildNameSection(c),
                        const SizedBox(height: 24),
                        _buildParametersSection(c),
                        if (_ingredients.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildIngredientsSection(c),
                        ],
                        const SizedBox(height: 16),
                      ],
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
    final title = _isLoading
        ? context.l10n.aiRecognizingDish
        : _isEditing
            ? context.l10n.edit
            : context.l10n.addDish;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: c.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 24 / 18,
            ),
          ),
          if (!_isLoading)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.surfaceBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: c.onSurface, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNameSection(_AiSheetColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.dishNameLabel,
          style: TextStyle(
            color: c.secondaryText,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 18 / 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: c.cardBg,
            border: Border.all(color: c.borderColor),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: _nameCtl,
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
          ),
        ),
      ],
    );
  }

  Widget _buildParametersSection(_AiSheetColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.dishParameters,
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
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildParamRow(
                c,
                iconAsset: 'assets/icons/cal.svg',
                label: context.l10n.caloriesKcalLabel,
                controller: _caloriesCtl,
                onChanged: (_) => _recalcFromCalories(),
              ),
              const SizedBox(height: 12),
              _buildParamRow(
                c,
                iconAsset: 'assets/icons/belok.svg',
                label: context.l10n.proteinGramsLabel,
                controller: _proteinCtl,
                barGradient: _proteinGradient,
                barRatio: _macroRatio(_val(_proteinCtl)),
                onChanged: (_) => _recalcFromMacros(),
              ),
              const SizedBox(height: 12),
              _buildParamRow(
                c,
                iconAsset: 'assets/icons/fat.svg',
                label: context.l10n.fatGramsLabel,
                controller: _fatCtl,
                barGradient: _fatGradient,
                barRatio: _macroRatio(_val(_fatCtl)),
                onChanged: (_) => _recalcFromMacros(),
              ),
              const SizedBox(height: 12),
              _buildParamRow(
                c,
                iconAsset: 'assets/icons/uglevod.svg',
                label: context.l10n.carbsGramsLabel,
                controller: _carbsCtl,
                barGradient: _carbsGradient,
                barRatio: _macroRatio(_val(_carbsCtl)),
                onChanged: (_) => _recalcFromMacros(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParamRow(
    _AiSheetColors c, {
    required String iconAsset,
    required String label,
    required TextEditingController controller,
    LinearGradient? barGradient,
    double? barRatio,
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
        if (barGradient != null && barRatio != null) ...[
          _buildMacroBar(c, barGradient, barRatio),
          const SizedBox(width: 8),
        ],
        _buildValueField(c, controller, onChanged),
      ],
    );
  }

  Widget _buildMacroBar(
    _AiSheetColors c,
    LinearGradient gradient,
    double ratio,
  ) {
    return SizedBox(
      width: 52,
      height: 12,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            Container(color: c.barTrack),
            FractionallySizedBox(
              widthFactor: ratio,
              child: Container(
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ),
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
              Text(_isEditing ? context.l10n.saveChanges : context.l10n.saveEntry),
            ],
          ),
        ),
      ),
    );
  }
}
