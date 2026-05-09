import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
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

/// Coarse profile of a dish derived from its macro distribution and
/// calorie density. Drives both the lead sentence in the health
/// description and the trait modifier (so we don't repeat ourselves).
enum _HealthProfile {
  veggie,
  highProtein,
  leanProtein,
  carbHeavy,
  fatHeavy,
  sweet,
  ultraProcessed,
  balanced,
}

/// Pure-data record for an AI "extra ingredient" suggestion. These ride
/// alongside the confirmed ingredients in the recognise response and are
/// rendered as tappable chips in a separate block under the ingredient
/// list. Tapping a chip moves the suggestion into the live `_ingredients`
/// list (keeping the AI's grams/calories/macros) and removes the chip.
class _SuggestionItem {
  final String name;
  final double grams;
  final double protein;
  final double fat;
  final double carbs;
  final double calories;

  const _SuggestionItem({
    required this.name,
    required this.grams,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.calories,
  });
}

class _IngredientEntry {
  final TextEditingController nameCtl;
  final TextEditingController caloriesCtl;
  double grams;
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
    required this.caloriesCtl,
    required this.grams,
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
    caloriesCtl.dispose();
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

  /// Set in the "duplicate" flow (tap an existing diary card). The bottom
  /// action still creates a new log, but the inline "Save macros" button
  /// writes the edits back to this source record so the user's tweaks
  /// survive closing the modal.
  final String? sourceLogId;
  final String? imagePath;
  final Future<Map<String, dynamic>>? pendingResult;

  const AiMealResultSheet({
    super.key,
    required this.mealType,
    this.dateStr,
    this.result,
    this.imageBytes,
    this.existingLogId,
    this.sourceLogId,
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
    // Kick off the JPEG decode now so it overlaps the sheet's slide-up
    // animation. Without this, Image.memory inside the loading body
    // decodes on first paint and the photo flashes in a frame after the
    // rest of the modal — a visible blink. We deliberately don't await:
    // the cache hit by the time the user can see the photo card is
    // enough; missing it falls back to the original async-decode behaviour.
    precacheImage(MemoryImage(imageBytes), context);

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
    // See the comment in [showWithLoading] — same pre-decode trick so the
    // photo doesn't flash in late on the loading screen.
    precacheImage(MemoryImage(imageBytes), context);

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
      if (log.healthRating != null) 'health_rating': log.healthRating,
      if (log.healthComment != null) 'health_comment': log.healthComment,
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
      if (log.healthRating != null) 'health_rating': log.healthRating,
      if (log.healthComment != null) 'health_comment': log.healthComment,
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
        sourceLogId: log.id,
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

  /// Free-form text the user can supply alongside the macros editor to
  /// refine the dish ("with double cheese", "small portion", …). When this
  /// has any content the bottom button switches its icon from a check to
  /// a send arrow to telegraph that tapping submits a refinement.
  final _refineCtl = TextEditingController();
  final _refineFocus = FocusNode();

  /// True while the refine API call is in flight. Shown as an inline
  /// spinner inside the action button; once the response lands we hand
  /// off to the full staged loading screen.
  bool _refining = false;

  List<_IngredientEntry> _ingredients = [];
  List<_SuggestionItem> _suggestions = const [];
  // Index of the ingredient whose name is currently in inline-edit
  // mode. -1 = none. Tapping a name swaps the Text for a TextField; the
  // field saves on submit / unfocus.
  int _editingIngredientNameIndex = -1;
  final TextEditingController _editingNameCtl = TextEditingController();
  final FocusNode _editingNameFocus = FocusNode();
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
  late final AnimationController _spinController;

  /// Three-stage progress for the AI loading screen. Each stage runs in
  /// sequence: "analyzing" → "recognizing" → "counting calories". Each fills
  /// naturally at its own pace; we never force-snap them to 1.0 just because
  /// the AI returned early — the bars play out and only then do we hand off
  /// to the result UI. If the AI is slower than the chain, the third bar
  /// holds at full and we wait for the response.
  late final AnimationController _stage1Ctl;
  late final AnimationController _stage2Ctl;
  late final AnimationController _stage3Ctl;
  late final Animation<double> _stage1Anim;
  late final Animation<double> _stage2Anim;
  late final Animation<double> _stage3Anim;

  /// Result/error stashed while we wait for stage 3 to finish. We only
  /// transition to the next screen when both the bars are full AND the AI
  /// call is back.
  Map<String, dynamic>? _pendingResultData;
  String? _pendingErrorMessage;

  /// Drives the count-up reveal of the overview card values (calorie ring,
  /// activity rows, macros, health rating, daily %). Plays once after the
  /// sheet opens; subsequent edits don't replay it.
  late final AnimationController _overviewIntroCtl;
  late final Animation<double> _overviewIntro;
  bool _overviewIntroStarted = false;

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _stage1Ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _stage2Ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    // Stage 3 doesn't have a "natural" end-time — it has to last as long
    // as the AI takes. We split it in two phases inside [_runStage3]: a
    // long approach to 90% (decelerating, so the bar visibly slows near
    // the end) and a quick snap to 100% the moment the result arrives.
    // The controller lower/upper bound stays 0..1; durations are passed
    // per-animateTo so we can swap pace mid-animation.
    _stage3Ctl = AnimationController(vsync: this);
    _stage1Anim =
        CurvedAnimation(parent: _stage1Ctl, curve: Curves.easeOutCubic);
    _stage2Anim =
        CurvedAnimation(parent: _stage2Ctl, curve: Curves.easeOutCubic);
    _stage3Anim = _stage3Ctl.view;
    _stage1Ctl.addStatusListener(_onStage1Status);
    _stage2Ctl.addStatusListener(_onStage2Status);
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
      _spinController.repeat();
      _stage1Ctl.forward();
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

  void _onStage1Status(AnimationStatus s) {
    if (s == AnimationStatus.completed && _isLoading) _stage2Ctl.forward();
  }

  void _onStage2Status(AnimationStatus s) {
    if (s == AnimationStatus.completed && _isLoading) {
      unawaited(_runStage3());
    }
  }

  /// Signals to [_runStage3] that the AI call has resolved (success or
  /// error). Recreated on every loading round so a stale completer can't
  /// fire across runs.
  Completer<void>? _resultReady;

  /// Stage 3 has two phases:
  ///   1. **Approach** — animate to 90% with a decelerating curve. By
  ///      the time we reach the upper end the bar is visibly slowing,
  ///      hinting that something is still being computed.
  ///   2. **Finish** — once the AI returns, snap from wherever we are
  ///      to 100% over a short, easy curve, then hand off to the result
  ///      UI via [_maybeFinishLoading]. If the AI was already ready by
  ///      the time the approach finishes, this happens back-to-back —
  ///      no perceptible hold.
  Future<void> _runStage3() async {
    await _stage3Ctl.animateTo(
      0.9,
      duration: const Duration(milliseconds: 2200),
      curve: Curves.easeOutQuart,
    );
    if (!_isLoading) return;

    if (_pendingResultData == null && _pendingErrorMessage == null) {
      _resultReady ??= Completer<void>();
      await _resultReady!.future;
    }
    if (!_isLoading) return;

    await _stage3Ctl.animateTo(
      1.0,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
    if (!_isLoading) return;
    _maybeFinishLoading();
  }

  /// Called once the AI call has settled (success or error). Wakes
  /// [_runStage3] if it's parked at 90% waiting for us; otherwise the
  /// flag is read on the next stage 3 frame.
  void _signalResultReady() {
    final completer = _resultReady;
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  /// Called once stage 3 has reached 100% AND the AI result is in. Holds
  /// briefly so the third check has time to register, then swaps the
  /// loading body for the result/error body.
  static const Duration _postCompleteHold = Duration(milliseconds: 700);
  bool _finishScheduled = false;

  void _maybeFinishLoading() {
    if (!_isLoading) return;
    if (_stage3Ctl.value < 1.0) return;
    if (_pendingResultData == null && _pendingErrorMessage == null) return;
    if (_finishScheduled) return;
    _finishScheduled = true;

    Future<void>.delayed(_postCompleteHold, () {
      if (!mounted || !_isLoading) return;

      _spinController.stop();
      if (_pendingErrorMessage != null) {
        setState(() {
          _isLoading = false;
          _loadingError = _pendingErrorMessage;
        });
        return;
      }
      setState(() {
        _isLoading = false;
        _initResultControllers(_pendingResultData!);
      });
      // If this loading round was a refinement on an existing log, the new
      // values must reach the diary record without forcing the user to tap
      // anywhere. _scheduleAutosave is a no-op for fresh dishes (no log id).
      _scheduleAutosave();
    });
  }

  Future<void> _awaitResult() async {
    try {
      final result = await widget.pendingResult!;
      if (!mounted) return;
      _pendingResultData = result;
    } on NetworkException catch (e) {
      debugPrint('AI recognition network error: ${e.message}');
      if (!mounted) return;
      _pendingErrorMessage = e.message;
    } catch (e, st) {
      debugPrint('AI recognition error: $e\n$st');
      if (!mounted) return;
      _pendingErrorMessage = context.l10n.aiRecognitionFailed;
    }
    _signalResultReady();
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
    _flushAutosave();
    _spinController.dispose();
    _stage1Ctl.dispose();
    _stage2Ctl.dispose();
    _stage3Ctl.dispose();
    _overviewIntroCtl.dispose();
    _toastTimer?.cancel();
    _toastEntry?.remove();
    _toastVisible.dispose();
    _nameCtl.dispose();
    _totalGramsCtl.dispose();
    _proteinCtl.dispose();
    _fatCtl.dispose();
    _carbsCtl.dispose();
    _caloriesCtl.dispose();
    _refineCtl.dispose();
    _refineFocus.dispose();
    _editingNameCtl.dispose();
    _editingNameFocus.dispose();
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
      final gramsPerUnit = (i['grams_per_unit'] as num?)?.toDouble() ??
          (count > 0 ? grams / count : 0.0);
      return _IngredientEntry(
        nameCtl: TextEditingController(text: cleanName),
        caloriesCtl: TextEditingController(text: _fmt(calories)),
        grams: grams,
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

    final suggestions =
        (result['suggestions'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    _suggestions = [
      for (final s in suggestions)
        if ((s['name'] as String?)?.trim().isNotEmpty ?? false)
          _SuggestionItem(
            name: (s['name'] as String).trim(),
            grams: (s['grams'] as num?)?.toDouble() ?? 30,
            protein: (s['protein'] as num?)?.toDouble() ?? 0,
            fat: (s['fat'] as num?)?.toDouble() ?? 0,
            carbs: (s['carbs'] as num?)?.toDouble() ?? 0,
            calories: (s['calories'] as num?)?.toDouble() ?? 0,
          ),
    ];

    _captureMacroRatio();
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  double _val(TextEditingController c) => double.tryParse(c.text) ?? 0;

  String? _ingredientsJson() {
    if (_ingredients.isEmpty) return null;
    return jsonEncode(
      _ingredients.map((ing) {
        return <String, dynamic>{
          'name': ing.nameCtl.text.trim(),
          'grams': ing.grams,
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

  /// Cached macro split (each macro's share of total calories) from the last
  /// time the dish had non-zero macros. Lets us redistribute calories back
  /// onto P/F/C if the user clears them and re-enters a value — otherwise
  /// macros would stay stuck at zero with no way to recover the ratio.
  ({double p, double f, double c})? _lastMacroCalShares;

  void _captureMacroRatio() {
    final p = _val(_proteinCtl);
    final f = _val(_fatCtl);
    final cb = _val(_carbsCtl);
    final total = p * 4 + f * 9 + cb * 4;
    if (total > 0) {
      _lastMacroCalShares = (
        p: (p * 4) / total,
        f: (f * 9) / total,
        c: (cb * 4) / total,
      );
    }
  }

  void _recalcFromMacros() {
    if (_updatingControllers) return;
    _updatingControllers = true;

    final p = _val(_proteinCtl);
    final f = _val(_fatCtl);
    final c = _val(_carbsCtl);
    _caloriesCtl.text = _fmt(p * 4 + f * 9 + c * 4);
    _captureMacroRatio();

    _updatingControllers = false;
    setState(() {});
    _scheduleAutosave();
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
      _captureMacroRatio();
    } else if (currentCal > 0 && _lastMacroCalShares != null) {
      // Macros got zeroed out (likely from clearing calories first).
      // Redistribute the new calorie value using the last known ratio.
      final r = _lastMacroCalShares!;
      _proteinCtl.text = _fmt(currentCal * r.p / 4);
      _fatCtl.text = _fmt(currentCal * r.f / 9);
      _carbsCtl.text = _fmt(currentCal * r.c / 4);
    }

    _updatingControllers = false;
    setState(() {});
    _scheduleAutosave();
  }

  /// Stepper bumped the unit count (e.g. 2 → 3 eggs). Rescales grams from
  /// the captured per-unit weight, then reapplies the per-100g macros so
  /// calories/protein/fat/carbs all track the new portion. Per-100g ratios
  /// are unchanged — only the absolute portion size is.
  void _onIngredientCountChanged(int index, int delta) {
    final ing = _ingredients[index];
    final newCount = (ing.count + delta).clamp(1, 99);
    if (newCount == ing.count) return;
    if (_updatingControllers) return;
    _updatingControllers = true;

    ing.count = newCount;
    ing.grams = ing.gramsPerUnit * newCount;
    final factor = ing.grams / 100;
    ing.protein = ing.proteinPer100g * factor;
    ing.fat = ing.fatPer100g * factor;
    ing.carbs = ing.carbsPer100g * factor;
    ing.calories = ing.caloriesPer100g * factor;
    ing.caloriesCtl.text = _fmt(ing.calories);

    _recalcTotalsFromIngredients();
    _captureMacroRatio();

    _updatingControllers = false;
    setState(() {});
    _scheduleAutosave();
  }

  // ── Suggestions → ingredients ─────────────────────────────────

  /// Append an AI-suggested extra ingredient to the live ingredient
  /// list, preserving the AI's grams/calories/macros, and remove the
  /// chip so it can't be added twice.
  void _addSuggestion(int index) {
    if (index < 0 || index >= _suggestions.length) return;
    final s = _suggestions[index];
    final entry = _IngredientEntry(
      nameCtl: TextEditingController(text: s.name),
      caloriesCtl: TextEditingController(text: _fmt(s.calories)),
      grams: s.grams,
      proteinPer100g: s.grams > 0 ? s.protein / s.grams * 100 : 0,
      fatPer100g: s.grams > 0 ? s.fat / s.grams * 100 : 0,
      carbsPer100g: s.grams > 0 ? s.carbs / s.grams * 100 : 0,
      caloriesPer100g: s.grams > 0 ? s.calories / s.grams * 100 : 0,
      protein: s.protein,
      fat: s.fat,
      carbs: s.carbs,
      calories: s.calories,
    );
    setState(() {
      _ingredients.add(entry);
      _suggestions = [
        for (var i = 0; i < _suggestions.length; i++)
          if (i != index) _suggestions[i],
      ];
    });
    _recalcTotalsFromIngredients();
    _captureMacroRatio();
    _scheduleAutosave();
  }

  /// Append a blank "Untitled" ingredient (10 g, 0 kcal). Tapping the
  /// name in the new card opens the inline editor so the user can name
  /// it without leaving the sheet.
  void _addCustomIngredient() {
    final entry = _IngredientEntry(
      nameCtl: TextEditingController(),
      caloriesCtl: TextEditingController(text: '0'),
      grams: 10,
      proteinPer100g: 0,
      fatPer100g: 0,
      carbsPer100g: 0,
      caloriesPer100g: 0,
      protein: 0,
      fat: 0,
      carbs: 0,
      calories: 0,
    );
    setState(() => _ingredients.add(entry));
    _scheduleAutosave();
  }

  // ── Inline name editor ────────────────────────────────────────

  void _beginEditIngredientName(int index) {
    if (index < 0 || index >= _ingredients.length) return;
    setState(() {
      _editingIngredientNameIndex = index;
      _editingNameCtl.text = _ingredients[index].nameCtl.text;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _editingNameFocus.requestFocus();
    });
  }

  void _commitIngredientName() {
    final i = _editingIngredientNameIndex;
    if (i < 0 || i >= _ingredients.length) {
      setState(() => _editingIngredientNameIndex = -1);
      return;
    }
    final newName = _editingNameCtl.text.trim();
    setState(() {
      _ingredients[i].nameCtl.text = newName;
      _editingIngredientNameIndex = -1;
    });
    _scheduleAutosave();
  }

  /// Step the GRAMS for ingredient [index] by `delta * 10` (the design
  /// uses a fixed 10-point step). Recomputes calories + macros from the
  /// per-100g composition — i.e. the per-100g rates are the source of
  /// truth here, the absolute values track grams. For unit-counted
  /// ingredients (eggs etc.) we delegate to the count stepper instead so
  /// the user always operates in the natural unit for that item.
  void _onIngredientGramsStepped(int index, int delta) {
    final ing = _ingredients[index];
    if (ing.hasCounter) {
      _onIngredientCountChanged(index, delta);
      return;
    }
    if (_updatingControllers) return;
    // Floor at 10 g — going to zero (or negative) doesn't make sense for
    // an ingredient that's still in the list.
    final newGrams = (ing.grams + delta * 10).clamp(10.0, double.infinity);
    if (newGrams == ing.grams) return;

    _updatingControllers = true;
    ing.grams = newGrams;
    final factor = ing.grams / 100;
    ing.protein = ing.proteinPer100g * factor;
    ing.fat = ing.fatPer100g * factor;
    ing.carbs = ing.carbsPer100g * factor;
    ing.calories = ing.caloriesPer100g * factor;
    ing.caloriesCtl.text = _fmt(ing.calories);

    _recalcTotalsFromIngredients();
    _captureMacroRatio();
    _updatingControllers = false;
    setState(() {});
    _scheduleAutosave();
  }

  /// Step the CALORIES for ingredient [index] by `delta * 10`. Per the
  /// design, changing calories does NOT change grams — it just rescales
  /// the macros to fit the new energy figure (same logic
  /// `_onIngredientCaloriesChanged` already applies when the user types
  /// into the calories field).
  void _onIngredientCaloriesStepped(int index, int delta) {
    if (_updatingControllers) return;
    final ing = _ingredients[index];
    final newCal = (ing.calories + delta * 10).clamp(0.0, double.infinity);
    if (newCal == ing.calories) return;
    ing.caloriesCtl.text = _fmt(newCal);
    _onIngredientCaloriesChanged(index);
  }

  /// User edited the calorie field for ingredient [index]. We treat the new
  /// calorie figure as the source of truth and scale this ingredient's
  /// macros proportionally so the per-100g composition stays consistent
  /// with the new energy figure. Then we recompute the dish-level totals
  /// (top analytics card reflects the change immediately).
  void _onIngredientCaloriesChanged(int index) {
    if (_updatingControllers) return;
    _updatingControllers = true;

    final ing = _ingredients[index];
    final newCal = _val(ing.caloriesCtl);
    final oldCal = ing.calories;

    if (oldCal > 0 && newCal >= 0) {
      final factor = newCal / oldCal;
      ing.calories = newCal;
      ing.protein = ing.protein * factor;
      ing.fat = ing.fat * factor;
      ing.carbs = ing.carbs * factor;
      // Per-100g rates follow the same scaling, so future edits remain
      // consistent if this ingredient is rescaled again.
      ing.proteinPer100g = ing.proteinPer100g * factor;
      ing.fatPer100g = ing.fatPer100g * factor;
      ing.carbsPer100g = ing.carbsPer100g * factor;
      ing.caloriesPer100g = ing.caloriesPer100g * factor;
    } else if (oldCal == 0 && newCal > 0 && ing.grams > 0) {
      // Came in at zero calories — distribute the new value as pure carbs
      // so the totals at least reflect something. User can fix macros via
      // the top-level edit if they care about the exact split.
      ing.calories = newCal;
      ing.carbs = newCal / 4;
      ing.caloriesPer100g = newCal / ing.grams * 100;
      ing.carbsPer100g = ing.carbs / ing.grams * 100;
    } else {
      ing.calories = newCal;
    }

    _recalcTotalsFromIngredients();
    _captureMacroRatio();

    _updatingControllers = false;
    setState(() {});
    _scheduleAutosave();
  }

  void _recalcTotalsFromIngredients() {
    double totalGrams = 0, totalP = 0, totalF = 0, totalC = 0, totalCal = 0;
    for (final i in _ingredients) {
      totalGrams += i.grams;
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
    _scheduleAutosave();
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
        healthRating: drift.Value(_persistedHealthRating),
        healthComment: drift.Value(_persistedHealthComment),
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
        healthRating: drift.Value(_persistedHealthRating),
        healthComment: drift.Value(_persistedHealthComment),
      ));

      final auth = AuthService();
      if (!auth.isPremium) {
        await auth.incrementFreeEntry();
      }
    }

    if (mounted) context.pop(true);
  }

  // ── Silent autosave ────────────────────────────────────────────────
  // Ingredient edits and removals persist immediately so closing the
  // modal (X button, swipe-down, tapping outside) never loses changes.
  // We debounce ~400ms to coalesce typing bursts.

  Timer? _autosaveTimer;

  void _scheduleAutosave() {
    final logId = widget.existingLogId ?? widget.sourceLogId;
    if (logId == null) return; // brand-new dish, no record yet
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(
      const Duration(milliseconds: 400),
      () => _persistCurrentState(logId),
    );
  }

  /// Flushes any pending debounced write — call before closing the modal.
  void _flushAutosave() {
    if (_autosaveTimer?.isActive != true) return;
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
    final logId = widget.existingLogId ?? widget.sourceLogId;
    if (logId == null) return;
    _persistCurrentState(logId);
  }

  Future<void> _persistCurrentState(String logId) async {
    try {
      final db = await AppDatabase.getInstance();
      final companion = FoodLogsCompanion(
        grams: drift.Value(_val(_totalGramsCtl)),
        protein: drift.Value(_val(_proteinCtl)),
        fat: drift.Value(_val(_fatCtl)),
        carbs: drift.Value(_val(_carbsCtl)),
        calories: drift.Value(_val(_caloriesCtl)),
        ingredientsJson: drift.Value(_ingredientsJson()),
        healthRating: drift.Value(_persistedHealthRating),
        healthComment: drift.Value(_persistedHealthComment),
        updatedAt: drift.Value(DateTime.now()),
        synced: const drift.Value(false),
      );
      await db.updateFoodLog(logId, companion);
    } catch (e, st) {
      debugPrint('Autosave failed: $e\n$st');
    }
  }

  /// Re-runs AI recognition with the current dish details + the user's
  /// refinement text appended, so the model adjusts the existing dish
  /// instead of starting from scratch. The macros editor stays on screen
  /// with an inline button spinner; when the response lands we drop the
  /// edit pane and the user is back on the overview with the new numbers
  /// — no full staged-loading detour.
  Future<void> _onRefineDish() async {
    final refinement = _refineCtl.text.trim();
    if (refinement.isEmpty) {
      _onSaveMacros();
      return;
    }
    final prompt = _composeRefinementPrompt(refinement);
    final fallbackError = context.l10n.aiRecognitionFailed;

    _refineFocus.unfocus();
    setState(() => _refining = true);

    Map<String, dynamic>? result;
    String? error;
    try {
      final api = ApiClient();
      final locale = LocaleNotifier.instance.value.languageCode;
      result = await api.recognizeText(prompt, locale: locale);
    } on NetworkException catch (e) {
      debugPrint('Refine network error: ${e.message}');
      error = e.message;
    } catch (e, st) {
      debugPrint('Refine error: $e\n$st');
      error = fallbackError;
    }

    if (!mounted) return;

    if (error != null || result == null) {
      setState(() => _refining = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error ?? fallbackError),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    _refineCtl.clear();
    // Replay the overview intro animation once so the freshly refined
    // numbers count up rather than just snapping in.
    _overviewIntroStarted = false;
    _overviewIntroCtl.value = 0;
    setState(() {
      _refining = false;
      _paramsEditMode = false;
      _initResultControllers(result!);
    });
    _scheduleAutosave();
  }

  /// Builds the text we send to `/api/recognize-text`. We hand the model
  /// the dish as it currently stands (name, totals, ingredients) and tack
  /// on the user's clarification, so the response is a delta over the
  /// existing entry rather than a fresh recognition.
  String _composeRefinementPrompt(String refinement) {
    final buffer = StringBuffer();
    final name = _nameCtl.text.trim();
    if (name.isNotEmpty) buffer.write(name);

    final cal = _val(_caloriesCtl);
    final p = _val(_proteinCtl);
    final f = _val(_fatCtl);
    final cb = _val(_carbsCtl);
    if (cal > 0) {
      if (buffer.isNotEmpty) buffer.write(' — ');
      buffer.write(
        '${cal.round()} kcal, '
        'P${p.round()}/F${f.round()}/C${cb.round()}',
      );
    }

    if (_ingredients.isNotEmpty) {
      final parts = _ingredients
          .map((i) {
            final n = i.nameCtl.text.trim();
            if (n.isEmpty) return null;
            return '$n ${i.grams.round()}g';
          })
          .whereType<String>()
          .join(', ');
      if (parts.isNotEmpty) {
        if (buffer.isNotEmpty) buffer.write(' (');
        buffer.write(parts);
        if (buffer.toString().contains('(')) buffer.write(')');
      }
    }

    if (buffer.isEmpty) return refinement;
    buffer.write('. Refinement: ');
    buffer.write(refinement);
    return buffer.toString();
  }

  /// Commits the macros edits made in the inline editor.
  ///
  /// We persist to whichever log id we have on hand — `existingLogId` for the
  /// edit flow, `sourceLogId` for the duplicate flow. Both ultimately point
  /// at a real diary record, so the user's tweaks survive closing the modal
  /// regardless of how they opened it.
  ///
  /// For brand-new dishes (camera/search) there's no record yet, so we just
  /// keep the values in the controllers — they get persisted when the user
  /// taps the bottom action button.
  Future<void> _onSaveMacros() async {
    final logId = widget.existingLogId ?? widget.sourceLogId;
    if (logId != null) {
      try {
        final db = await AppDatabase.getInstance();
        final companion = FoodLogsCompanion(
          grams: drift.Value(_val(_totalGramsCtl)),
          protein: drift.Value(_val(_proteinCtl)),
          fat: drift.Value(_val(_fatCtl)),
          carbs: drift.Value(_val(_carbsCtl)),
          calories: drift.Value(_val(_caloriesCtl)),
          ingredientsJson: drift.Value(_ingredientsJson()),
          healthRating: drift.Value(_persistedHealthRating),
          healthComment: drift.Value(_persistedHealthComment),
          updatedAt: drift.Value(DateTime.now()),
          synced: const drift.Value(false),
        );
        await db.updateFoodLog(logId, companion);
      } catch (e, st) {
        debugPrint('Failed to persist macros: $e\n$st');
      }
    }

    if (!mounted) return;
    setState(() => _paramsEditMode = false);
    _showInModalToast(context.l10n.macrosSavedToast);
  }

  // ── In-modal toast ─────────────────────────────────────────────────
  // Uses the modal's own Overlay so the message appears above the bottom
  // action button instead of being clipped by the sheet (a SnackBar from
  // ScaffoldMessenger ends up hidden under the sheet on iOS).

  OverlayEntry? _toastEntry;
  Timer? _toastTimer;
  late final ValueNotifier<bool> _toastVisible = ValueNotifier(false);

  void _showInModalToast(String message) {
    _toastTimer?.cancel();
    _toastEntry?.remove();

    final overlay = Overlay.maybeOf(context, rootOverlay: false);
    if (overlay == null) return;

    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    _toastVisible.value = false;
    _toastEntry = OverlayEntry(
      builder: (_) => _AiSheetToast(
        message: message,
        bottomOffset: bottomInset + 80,
        visible: _toastVisible,
      ),
    );
    overlay.insert(_toastEntry!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _toastVisible.value = true;
    });
    _toastTimer = Timer(const Duration(milliseconds: 1800), _hideToast);
  }

  void _hideToast() {
    _toastVisible.value = false;
    Future.delayed(const Duration(milliseconds: 220), () {
      _toastEntry?.remove();
      _toastEntry = null;
    });
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

    // The sheet is rendered behind any visible system keyboard, so without
    // this AnimatedPadding the bottom rows of the ingredient editor (calorie
    // input + delete chip) sit underneath the keyboard. Padding the entire
    // sheet by viewInsets.bottom shifts it up to stay above the keyboard;
    // Scrollable.ensureVisible inside SingleChildScrollView then scrolls
    // the focused field into the visible area.
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: ConstrainedBox(
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
                child: Padding(
                  // 8px outer inset → photo edges sit 8px from the screen.
                  // Body cards inside the Stack add another 8px of inset
                  // (= 16px total from the screen) per spec.
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo + body in a Stack so the body card overlaps
                      // the photo by 24px without leaving phantom whitespace
                      // at the bottom. Cards are inset 8px on each side
                      // relative to the photo (Figma layout).
                      Stack(
                        children: [
                          if (hasImage) _buildImageCard(c),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              8,
                              hasImage ? 221 - 24 : 0,
                              8,
                              0,
                            ),
                            // Cross-fade between loading, error and result
                            // bodies so the swap feels like one continuous
                            // surface settling rather than a jump cut. The
                            // surrounding AnimatedSize lerps the height
                            // change so the modal doesn't snap when the
                            // result body's content is taller.
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 320),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                                layoutBuilder: (current, previous) => Stack(
                                  alignment: Alignment.topCenter,
                                  children: [
                                    ...previous,
                                    ?current,
                                  ],
                                ),
                                child: _buildBodyForCurrentState(c),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom bar fades in only when we have a result to act on; the
            // loading + error states don't need an action button. Wrapping
            // in AnimatedSize keeps the modal height transition continuous
            // with the body cross-fade above.
            AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: (!_isLoading && _loadingError == null)
                    ? KeyedSubtree(
                        key: const ValueKey('bottom-action'),
                        child: _buildBottomBar(
                          c,
                          keyboardHeight > 0 ? 0 : bottomPadding,
                        ),
                      )
                    : KeyedSubtree(
                        key: const ValueKey('bottom-spacer'),
                        child: SizedBox(height: bottomPadding + 8),
                      ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// Returns the body widget for the current sheet state — loading mascot,
  /// error block, or the result/edit cards. Each branch is wrapped in a
  /// `KeyedSubtree` with a stable string key so the surrounding
  /// `AnimatedSwitcher` recognises a state change and cross-fades between
  /// the old and new tree instead of snap-replacing it.
  Widget _buildBodyForCurrentState(_AiSheetColors c) {
    if (_isLoading) {
      return KeyedSubtree(
        key: const ValueKey('loading'),
        child: _buildLoadingBody(c),
      );
    }
    if (_loadingError != null) {
      return KeyedSubtree(
        key: const ValueKey('error'),
        child: _buildErrorBody(c),
      );
    }
    return KeyedSubtree(
      key: const ValueKey('result'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAnalyticsCardShell(
            c,
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                layoutBuilder: (current, previous) => Stack(
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
          // Suggestions block: always rendered when the user could add
          // something — i.e. either the AI suggested specific extras or
          // we still want to expose the "Smth else" custom-input chip.
          // Only hidden entirely if there's no ingredient list at all
          // (recognise hasn't completed / failed).
          if (_ingredients.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSuggestionsBlock(c),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildLoadingBody(_AiSheetColors c) {
    final l10n = context.l10n;
    final labelColor = c.isDark
        ? AppColors.darkPrimaryLight
        : AppColors.lightPrimaryLight;
    final doneColor =
        c.isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final trackColor = c.isDark
        ? AppColors.lineDT200
        : AppColors.lineLight200;

    // Outer scroll padding contributes 8px on each side, so 28px here lands
    // the progress bars at exactly 36px from the screen edges.
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _MeditatingMascot(float: _spinController)),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: Listenable.merge([
              _stage1Anim,
              _stage2Anim,
              _stage3Anim,
            ]),
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _LoadingProgressRow(
                    label: l10n.aiAnalyzingData,
                    progress: _stage1Anim.value,
                    labelColor: labelColor,
                    doneColor: doneColor,
                    trackColor: trackColor,
                  ),
                  const SizedBox(height: 16),
                  _LoadingProgressRow(
                    label: l10n.aiRecognizingIngredients,
                    progress: _stage2Anim.value,
                    labelColor: labelColor,
                    doneColor: doneColor,
                    trackColor: trackColor,
                  ),
                  const SizedBox(height: 16),
                  _LoadingProgressRow(
                    label: l10n.aiCountingCalories,
                    progress: _stage3Anim.value,
                    labelColor: labelColor,
                    doneColor: doneColor,
                    trackColor: trackColor,
                  ),
                ],
              );
            },
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
    final isOpaquePhoto =
        widget.imageBytes != null || _resolvedImageFile != null;

    Widget imageWidget;
    if (widget.imageBytes != null) {
      imageWidget = Image.memory(widget.imageBytes!, fit: BoxFit.cover);
    } else if (_resolvedImageFile != null) {
      imageWidget = Image.file(_resolvedImageFile!, fit: BoxFit.cover);
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: _networkImageUrl!,
        fit: BoxFit.cover,
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
        // Real photos (camera / saved meal file) are opaque — no canvas
        // needed, and a white one would bleed through the antialiased
        // rounded clip as a 1-px halo. Network images may be product
        // cut-outs with transparency, so they keep the flat-white canvas.
        color: isOpaquePhoto ? null : Colors.white,
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
  /// Returns whichever map currently holds the recognition result. For
  /// flows that pass it via the constructor we read [PaywallScreen.result];
  /// for the async loading flow the data lands in [_pendingResultData] only
  /// after the API returns. Reading just `widget.result` would silently
  /// miss \`health_rating\` / \`health_comment\` for every photo / text
  /// recognition that goes through the loading path.
  Map<String, dynamic>? get _resultData =>
      widget.result ?? _pendingResultData;

  /// AI-supplied health score (1-10) carried via the result map. Persisted
  /// to the food log so reopening a saved meal shows the same number we
  /// computed when the dish was first recognised, instead of falling back
  /// to the local heuristic and confusing the user with a different value.
  int? get _persistedHealthRating =>
      (_resultData?['health_rating'] as num?)?.toInt();

  /// AI-supplied health comment paired with [_persistedHealthRating].
  /// Stored alongside it so the same explanation reappears on reopen.
  String? get _persistedHealthComment {
    final raw = _resultData?['health_comment'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  int _computeHealthScore() {
    final raw = (_resultData?['health_rating'] as num?)?.toInt();
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

  /// Composes a description from three signals so each food gets copy
  /// that actually fits it:
  ///
  ///   1. **Lead** — describes the food *kind* (veggie, lean protein,
  ///      sweet, etc.) so spinach and chicken don't sound the same even
  ///      when they share a score.
  ///   2. **Trait** — adds one notable nutritional fact only if it isn't
  ///      already implied by the lead (e.g. "notably protein-rich" on a
  ///      veggie that happens to be high-protein, but not on a lean
  ///      protein dish where the lead already says it).
  ///   3. **Advice** — score-band guidance ("great fit for most days" /
  ///      "best occasional") so the recommendation matches the rating.
  ///
  /// Order matters in the lead block: most specific signals first.
  String _healthDescription(int score) {
    final raw = _resultData?['health_comment'] as String?;
    if (raw != null && raw.trim().isNotEmpty) return raw.trim();
    final l10n = context.l10n;

    final p = _val(_proteinCtl);
    final f = _val(_fatCtl);
    final cb = _val(_carbsCtl);
    final cal = _val(_caloriesCtl);
    final grams = _val(_totalGramsCtl);
    if (cal <= 0 || grams <= 0) {
      return '${l10n.healthDescBalanced} ${_healthAdvice(l10n, score)}';
    }

    final calDensity = cal / grams;
    final fatShare = (f * 9) / cal;
    final proteinShare = (p * 4) / cal;
    final carbShare = (cb * 4) / cal;

    final profile = _healthProfile(
      calDensity: calDensity,
      fatShare: fatShare,
      proteinShare: proteinShare,
      carbShare: carbShare,
    );
    final lead = _healthLead(l10n, profile, score);
    final trait = _healthTrait(
      l10n,
      profile: profile,
      calDensity: calDensity,
      fatShare: fatShare,
      proteinShare: proteinShare,
      carbShare: carbShare,
    );
    final advice = _healthAdvice(l10n, score);

    return [lead, ?trait, advice].join(' ');
  }

  _HealthProfile _healthProfile({
    required double calDensity,
    required double fatShare,
    required double proteinShare,
    required double carbShare,
  }) {
    if (calDensity < 0.7) return _HealthProfile.veggie;
    if (calDensity > 3.5 && carbShare > 0.55 && proteinShare < 0.10) {
      return _HealthProfile.sweet;
    }
    if (fatShare > 0.50 || (calDensity > 4.0 && fatShare > 0.40)) {
      return _HealthProfile.fatHeavy;
    }
    if (proteinShare > 0.50) return _HealthProfile.highProtein;
    if (proteinShare > 0.30 && fatShare < 0.35) {
      return _HealthProfile.leanProtein;
    }
    if (carbShare > 0.55 && proteinShare < 0.15) {
      return _HealthProfile.carbHeavy;
    }
    if (calDensity > 3.5 && proteinShare < 0.20) {
      return _HealthProfile.ultraProcessed;
    }
    return _HealthProfile.balanced;
  }

  String _healthLead(AppLocalizations l10n, _HealthProfile profile, int score) {
    switch (profile) {
      case _HealthProfile.veggie:
        return l10n.healthDescVeggie;
      case _HealthProfile.highProtein:
        return l10n.healthDescHighProtein;
      case _HealthProfile.leanProtein:
        return l10n.healthDescLeanProtein;
      case _HealthProfile.carbHeavy:
        return l10n.healthDescCarbHeavy;
      case _HealthProfile.fatHeavy:
        return l10n.healthDescFatHeavy;
      case _HealthProfile.sweet:
        return l10n.healthDescSweet;
      case _HealthProfile.ultraProcessed:
        return l10n.healthDescUltraProcessed;
      case _HealthProfile.balanced:
        if (score >= 9) return l10n.healthDescGreat;
        if (score >= 7) return l10n.healthDescBalanced;
        if (score >= 4) return l10n.healthDescFair;
        return l10n.healthDescPoor;
    }
  }

  /// Picks the most informative trait that the lead hasn't already covered.
  /// Returns null when nothing notable would add value.
  String? _healthTrait(
    AppLocalizations l10n, {
    required _HealthProfile profile,
    required double calDensity,
    required double fatShare,
    required double proteinShare,
    required double carbShare,
  }) {
    bool leadCovers(_HealthProfile p) => profile == p;

    // Notable protein on a non-protein lead (e.g. high-protein veggie).
    if (proteinShare > 0.30 &&
        !leadCovers(_HealthProfile.highProtein) &&
        !leadCovers(_HealthProfile.leanProtein)) {
      return l10n.healthTraitHighProtein;
    }

    // Calorie-light on something that isn't already a veggie.
    if (calDensity < 1.0 && !leadCovers(_HealthProfile.veggie)) {
      return l10n.healthTraitLowCalDensity;
    }

    // Fat-heaviness when not already the lead.
    if (fatShare > 0.45 &&
        !leadCovers(_HealthProfile.fatHeavy) &&
        !leadCovers(_HealthProfile.sweet)) {
      return l10n.healthTraitHighFat;
    }

    // Carb-dominant when not already the lead.
    if (carbShare > 0.55 &&
        !leadCovers(_HealthProfile.carbHeavy) &&
        !leadCovers(_HealthProfile.sweet)) {
      return l10n.healthTraitHighCarb;
    }

    // Truly balanced macros (no macro > 50% of cals).
    if (proteinShare < 0.50 &&
        fatShare < 0.45 &&
        carbShare < 0.55 &&
        proteinShare > 0.15 &&
        leadCovers(_HealthProfile.balanced)) {
      return l10n.healthTraitBalancedMacros;
    }

    return null;
  }

  String _healthAdvice(AppLocalizations l10n, int score) {
    if (score >= 9) return l10n.healthAdviceGreat;
    if (score >= 7) return l10n.healthAdviceGood;
    if (score >= 4) return l10n.healthAdviceFair;
    return l10n.healthAdvicePoor;
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
        _buildRefineField(c),
        const SizedBox(height: 12),
        _buildSaveMacrosButton(c),
      ],
    );
  }

  Widget _buildRefineField(_AiSheetColors c) {
    final hint =
        c.isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;
    // GestureDetector covers the full 44×W bordered area so any tap (even
    // on the empty hint side) focuses the field — without it taps only
    // landed on the actual text glyphs.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _refineFocus.requestFocus(),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: c.isDark ? AppColors.lineDT200 : AppColors.lineLight200,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        // Center wrapper + isCollapsed/zero contentPadding gives TextField
        // its intrinsic line-height; the Container then perfectly centers
        // it. Cross-platform — Android wasn't honouring textAlignVertical
        // with non-zero contentPadding and shifted the glyphs downward.
        child: Center(
          child: TextField(
            controller: _refineCtl,
            focusNode: _refineFocus,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (_refineCtl.text.trim().isEmpty) {
                _onSaveMacros();
              } else {
                _onRefineDish();
              }
            },
            style: TextStyle(
              color: c.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 18 / 14,
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              // Theme-level dark TextField fillColor leaks through unless we
              // pin the field as unfilled — that produces the inner grey block.
              filled: false,
              fillColor: Colors.transparent,
              hintText: context.l10n.refineDishHint,
              hintStyle: TextStyle(
                color: hint,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 18 / 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Outlined action button under the macros editor. Three states:
  ///
  ///   - empty refine → green check + "Обновить блюдо" (commits local edits).
  ///   - refine has text → blue send + "Уточнить блюдо" (submits to AI).
  ///   - while the refine call is in flight → blue outline with an inline
  ///     spinner. After the response arrives we hand off to the full
  ///     staged loading screen.
  ///
  /// Listens directly to the controller so the colour/icon swap doesn't
  /// rely on parent setState bubbling through animated switchers above.
  Widget _buildSaveMacrosButton(_AiSheetColors c) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _refineCtl,
      builder: (context, value, _) {
        final hasRefine = value.text.trim().isNotEmpty;
        final accent =
            (hasRefine || _refining) ? AppColors.primary : AppColors.green;
        final label =
            hasRefine ? context.l10n.refineDish : context.l10n.updateDish;
        return GestureDetector(
          onTap: _refining
              ? null
              : (hasRefine ? _onRefineDish : _onSaveMacros),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 44,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withAlpha(102)),
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _refining
                  ? SizedBox(
                      key: const ValueKey('refining'),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(accent),
                      ),
                    )
                  : Row(
                      key: ValueKey('idle-$hasRefine'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasRefine)
                          SvgPicture.asset(
                            'assets/icons/send.svg',
                            width: 20,
                            height: 20,
                            colorFilter:
                                ColorFilter.mode(accent, BlendMode.srcIn),
                          )
                        else
                          Icon(Icons.check_circle, color: accent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: TextStyle(
                            color: accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 18 / 14,
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

  // ── Ingredient cards (Figma node 6575:12632) ─────────────────
  //
  // Each ingredient is its own white card with a name + delete pill at
  // the top, and two side-by-side bordered fields below — left is
  // grams (or unit count for items like eggs), right is calories. Each
  // field has a value on the left and -/+ steppers on the right that
  // step by 10 in either direction. Changing grams scales calories
  // proportionally; changing calories leaves grams alone (matches the
  // user spec). Cards are stacked with an 8 px gap.

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
        for (var i = 0; i < _ingredients.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _buildIngredientCard(c, i),
        ],
      ],
    );
  }

  Widget _buildIngredientCard(_AiSheetColors c, int index) {
    final ing = _ingredients[index];
    final l10n = context.l10n;
    final isCounter = ing.hasCounter;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: name + delete pill (red minus inside #EE275017 chip)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _buildIngredientNameField(c, index, ing)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _removeIngredient(index),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 36,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _warningBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 12,
                    height: 1.6,
                    decoration: BoxDecoration(
                      color: _warningIcon,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildIngredientField(
                  c: c,
                  label: isCounter
                      ? l10n.quantityLabel
                      : l10n.gramsDialogLabel,
                  value: isCounter
                      ? ing.count.toString()
                      : ing.grams.round().toString(),
                  onMinus: () => _onIngredientGramsStepped(index, -1),
                  onPlus: () => _onIngredientGramsStepped(index, 1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildIngredientField(
                  c: c,
                  label: l10n.caloriesLabel,
                  value: ing.calories.round().toString(),
                  onMinus: () => _onIngredientCaloriesStepped(index, -1),
                  onPlus: () => _onIngredientCaloriesStepped(index, 1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bordered "label + value + minus/plus" field used by both grams and
  /// calories sides of an ingredient card. The value is read-only here —
  /// editing happens through the steppers (each step = ±10 per spec).
  Widget _buildIngredientField({
    required _AiSheetColors c,
    required String label,
    required String value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: 0.5,
          child: Text(
            label,
            style: TextStyle(
              color: c.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 18 / 14,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: c.borderColor),
            borderRadius: BorderRadius.circular(11),
          ),
          padding: const EdgeInsets.fromLTRB(10, 0, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 18 / 14,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 72,
                child: Row(
                  children: [
                    Expanded(child: _stepperButton(c, false, onMinus)),
                    const SizedBox(width: 4),
                    Expanded(child: _stepperButton(c, true, onPlus)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Square 34×34 ±-button used inside `_buildIngredientField`. Plus
  /// shows a Material `add` glyph; minus is drawn manually so the bar
  /// thickness matches the Figma minus icon (the Material `remove`
  /// glyph reads slightly thinner at this size).
  Widget _stepperButton(_AiSheetColors c, bool isPlus, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: c.baseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: isPlus
            ? Icon(Icons.add, color: c.onSurface, size: 16)
            : Container(
                width: 12,
                height: 1.6,
                decoration: BoxDecoration(
                  color: c.onSurface,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
      ),
    );
  }

  /// Ingredient card header — either a tap-to-edit Text (the name as
  /// stored, or a localized "Untitled" placeholder when empty) or an
  /// inline TextField when this row is the one currently being edited.
  /// Tapping outside or pressing return on the keyboard commits.
  Widget _buildIngredientNameField(
    _AiSheetColors c,
    int index,
    _IngredientEntry ing,
  ) {
    final l10n = context.l10n;
    final editing = _editingIngredientNameIndex == index;
    final placeholderColor = c.onSurface.withAlpha(120);

    // The Text and TextField below are styled to be pixel-equivalent —
    // same font, weight, line-height, no decoration, no padding — so
    // tapping the name swaps the widgets without shifting the row.
    const nameStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 22 / 16,
    );
    // Locking the strut to the text style stops Flutter from auto-
    // computing extra leading on either widget, which is the usual
    // source of the "TextField is one pixel taller than Text" jump.
    const nameStrut = StrutStyle(
      fontSize: 16,
      height: 22 / 16,
      forceStrutHeight: true,
    );

    if (editing) {
      return SizedBox(
        height: 22,
        child: TextField(
          controller: _editingNameCtl,
          focusNode: _editingNameFocus,
          autofocus: true,
          textInputAction: TextInputAction.done,
          style: nameStyle.copyWith(color: c.onSurface),
          strutStyle: nameStrut,
          cursorColor: AppColors.primary,
          cursorWidth: 1.5,
          decoration: InputDecoration(
            isCollapsed: true,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            hintText: l10n.untitledIngredientName,
            hintStyle: nameStyle.copyWith(color: placeholderColor),
          ),
          onSubmitted: (_) => _commitIngredientName(),
          onTapOutside: (_) {
            if (_editingIngredientNameIndex == index) _commitIngredientName();
          },
        ),
      );
    }

    final raw = ing.nameCtl.text.trim();
    final isEmpty = raw.isEmpty;
    return GestureDetector(
      onTap: () => _beginEditIngredientName(index),
      behavior: HitTestBehavior.opaque,
      child: Text(
        isEmpty ? l10n.untitledIngredientName : raw,
        style: nameStyle.copyWith(
          color: isEmpty ? placeholderColor : c.onSurface,
        ),
        strutStyle: nameStrut,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  // ── Add-suggestions block (Figma node 6575:13007) ─────────────
  //
  // Wrap row of chips: each is a 34 px-tall pill with the suggestion
  // name on the left and a 26×26 plus button on the right. The trailing
  // chip is "Smth else" — tapping it appends a blank "Untitled"
  // ingredient that the user can rename inline. Tapping any other chip
  // moves that suggestion into the live ingredient list and removes the
  // chip from this block.

  Widget _buildSuggestionsBlock(_AiSheetColors c) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.addSuggestionsLabel,
          style: TextStyle(
            color: c.secondaryText,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 18 / 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < _suggestions.length; i++)
              _SuggestionChip(
                c: c,
                label: _suggestions[i].name,
                onTap: () => _addSuggestion(i),
              ),
            _SuggestionChip(
              c: c,
              label: l10n.suggestionSomethingElse,
              onTap: _addCustomIngredient,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar(_AiSheetColors c, double bottomPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding + 8),
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

/// Cabbage mascot that breathes up-and-down while the AI is recognising the
/// dish. A blurred radial ellipse beneath it doubles as a contact shadow —
/// it widens and darkens slightly as the mascot dips, sells the float.
class _MeditatingMascot extends StatelessWidget {
  const _MeditatingMascot({required this.float});

  /// 0..1 looping animation that drives one breath cycle.
  final Animation<double> float;

  static const double _mascotSize = 120;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: _mascotSize,
        height: _mascotSize + 6,
        child: AnimatedBuilder(
          animation: float,
          builder: (context, child) {
            // Sin wave: -1 (top of breath) → 0 → 1 (bottom of breath).
            final phase = math.sin(float.value * 2 * math.pi);
            final lift = -phase * 5 - 1; // gentle bob
            // Subtle scale pulse layered on top of the bob makes the breath
            // read as inhale/exhale rather than a flat hover.
            final scale = 1 + 0.02 * phase;
            return Transform.translate(
              offset: Offset(0, lift),
              child: Transform.scale(scale: scale, child: child),
            );
          },
          child: Center(
            child: Image.asset(
              'assets/mascot/meditate.png',
              width: _mascotSize,
              height: _mascotSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingProgressRow extends StatelessWidget {
  const _LoadingProgressRow({
    required this.label,
    required this.progress,
    required this.labelColor,
    required this.doneColor,
    required this.trackColor,
  });

  final String label;
  final double progress;
  final Color labelColor;
  final Color doneColor;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0);
    final done = clamped >= 0.999;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // AnimatedDefaultTextStyle interpolates colour and weight without
            // remounting the Text widget — no font-baseline pop on completion.
            // We hold weight at a single value so glyph metrics don't shift
            // and produce a horizontal jitter as the bar fills.
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              style: TextStyle(
                color: done ? doneColor : labelColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 16 / 13,
              ),
              child: Text(label),
            ),
            const SizedBox(width: 4),
            // Icon is always laid out (zero-sized when hidden) so the row
            // width stays stable; we just fade + scale the check in.
            AnimatedScale(
              scale: done ? 1.0 : 0.6,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: done ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: SvgPicture.asset(
                  'assets/icons/check.svg',
                  width: 16,
                  height: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(3),
          ),
          clipBehavior: Clip.antiAlias,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: clamped <= 0 ? 0.001 : clamped,
              heightFactor: 1,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.green,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Lightweight toast surfaced inside the modal's own overlay so it sits
/// above the bottom action button instead of being clipped by the sheet.
/// A regular SnackBar from `ScaffoldMessenger` would render under the sheet
/// on iOS and never reach the user.
class _AiSheetToast extends StatelessWidget {
  const _AiSheetToast({
    required this.message,
    required this.bottomOffset,
    required this.visible,
  });

  final String message;
  final double bottomOffset;
  final ValueListenable<bool> visible;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomOffset,
      child: IgnorePointer(
        // Material wrapper provides default text styles + Directionality so
        // the toast text doesn't render with the "missing parent" yellow
        // debug underlines you get on raw Overlay children.
        child: Material(
          type: MaterialType.transparency,
          child: ValueListenableBuilder<bool>(
            valueListenable: visible,
            builder: (context, isVisible, child) {
              return AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                offset: isVisible ? Offset.zero : const Offset(0, 0.35),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: isVisible ? 1 : 0,
                  child: child,
                ),
              );
            },
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xE6111317),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 18 / 14,
                          decoration: TextDecoration.none,
                        ),
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
}

/// Pill chip used in the "Add suggestions" block: name + circular +
/// button. White surface, 1 px hairline border, 34 px tall (so a 17 px
/// border-radius gives a true pill shape). The label uses the Figma
/// `Text or Icons/Primary Light` token (#485066) and stays the same in
/// both light/dark themes — the chip's surface mirrors the dark/light
/// card background.
class _SuggestionChip extends StatelessWidget {
  final _AiSheetColors c;
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.c,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = c.isDark
        ? AppColors.darkPrimaryLight
        : AppColors.lightPrimaryLight;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 34,
        padding: const EdgeInsets.fromLTRB(12, 0, 4, 0),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: c.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 18 / 14,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: c.baseSurface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(Icons.add, size: 16, color: c.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
