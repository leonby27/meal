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
import 'package:meal_tracker/core/utils/macro_order.dart';
import 'package:meal_tracker/l10n/app_localizations.dart';

/// Reads the user's onboarding goal ('lose' / 'maintain' / 'gain') from
/// the local settings table. Returns null on a fresh install / unknown
/// value so the backend falls back to balanced-eating defaults.
Future<String?> _loadUserGoal() async {
  try {
    final db = await AppDatabase.getInstance();
    final raw = await db.getSetting('user_goal');
    if (raw == null) return null;
    final code = raw.trim().toLowerCase();
    if (code == 'lose' || code == 'maintain' || code == 'gain') {
      return code;
    }
    return null;
  } catch (_) {
    return null;
  }
}

/// Resolves an AI tag code from the closed list (see backend
/// `_TAG_CODES`) to the user-facing label. Returns null when the code
/// is unknown — the caller drops it.
String? _tagLabel(AppLocalizations l10n, String code) {
  switch (code) {
    // Protein
    case 'HIGH_PROTEIN': return l10n.tagHighProtein;
    case 'CONTAINS_PROTEIN': return l10n.tagContainsProtein;
    case 'LOW_PROTEIN': return l10n.tagLowProtein;
    case 'COMPLETE_PROTEIN': return l10n.tagCompleteProtein;
    // Fats
    case 'HEALTHY_FATS': return l10n.tagHealthyFats;
    case 'RICH_IN_OMEGA3': return l10n.tagRichInOmega3;
    case 'HIGH_FAT': return l10n.tagHighFat;
    case 'HIGH_SAT_FAT': return l10n.tagHighSatFat;
    case 'HIGH_TRANS_FAT': return l10n.tagHighTransFat;
    case 'LOW_FAT': return l10n.tagLowFat;
    // Carbs / fiber / sugar
    case 'HIGH_FIBER': return l10n.tagHighFiber;
    case 'CONTAINS_FIBER': return l10n.tagContainsFiber;
    case 'LOW_FIBER': return l10n.tagLowFiber;
    case 'COMPLEX_CARBS': return l10n.tagComplexCarbs;
    case 'REFINED_CARBS': return l10n.tagRefinedCarbs;
    case 'LOW_SUGAR': return l10n.tagLowSugar;
    case 'HIGH_SUGAR': return l10n.tagHighSugar;
    case 'LOW_CARB': return l10n.tagLowCarb;
    // Calories / density / energy
    case 'HIGH_CALORIES': return l10n.tagHighCalories;
    case 'LOW_CALORIES': return l10n.tagLowCalories;
    case 'HIGH_ENERGY': return l10n.tagHighEnergy;
    case 'HELPS_QUOTA': return l10n.tagHelpsQuota;
    case 'NUTRIENT_DENSE': return l10n.tagNutrientDense;
    case 'EMPTY_CALORIES': return l10n.tagEmptyCalories;
    case 'HEAVY_MEAL': return l10n.tagHeavyMeal;
    case 'LIGHT_MEAL': return l10n.tagLightMeal;
    // Salt / cholesterol
    case 'HIGH_SALT': return l10n.tagHighSalt;
    case 'LOW_SALT': return l10n.tagLowSalt;
    case 'HIGH_CHOLESTEROL': return l10n.tagHighCholesterol;
    // Context
    case 'GOOD_POST_WORKOUT': return l10n.tagGoodPostWorkout;
    case 'GOOD_PRE_WORKOUT': return l10n.tagGoodPreWorkout;
    case 'BREAKFAST_FRIENDLY': return l10n.tagBreakfastFriendly;
    // Body systems
    case 'HEART_FRIENDLY': return l10n.tagHeartFriendly;
    case 'GUT_FRIENDLY': return l10n.tagGutFriendly;
    case 'BRAIN_FOOD': return l10n.tagBrainFood;
    case 'IMMUNE_BOOST': return l10n.tagImmuneBoost;
    case 'BONE_HEALTH': return l10n.tagBoneHealth;
    // Micronutrients
    case 'RICH_IN_VITAMINS': return l10n.tagRichInVitamins;
    case 'RICH_IN_IRON': return l10n.tagRichInIron;
    case 'RICH_IN_CALCIUM': return l10n.tagRichInCalcium;
    case 'RICH_IN_POTASSIUM': return l10n.tagRichInPotassium;
    case 'HIGH_ANTIOXIDANTS': return l10n.tagHighAntioxidants;
    // Quality / composition
    case 'BALANCED_MACROS': return l10n.tagBalancedMacros;
    case 'WHOLE_FOODS': return l10n.tagWholeFoods;
    case 'ULTRA_PROCESSED': return l10n.tagUltraProcessed;
    case 'PLANT_BASED': return l10n.tagPlantBased;
    case 'HYDRATING': return l10n.tagHydrating;
  }
  return null;
}

/// "For your goal: X" caption. Picks one of three localized strings —
/// the goal code itself is small and stable, so we avoid an ICU plural
/// hack with a placeholder. Defaults to `lose` to match onboarding's
/// default goal.
String _goalLabel(AppLocalizations l10n, String? goal) {
  switch (goal) {
    case 'gain': return l10n.forYourGoalGain;
    case 'maintain': return l10n.forYourGoalMaintain;
    case 'lose':
    default: return l10n.forYourGoalLose;
  }
}

/// Activity-equivalent burn estimates for the "How to burn calories?"
/// section. Derived from the standard MET formula
///   kcal/min = MET × weight_kg × 3.5 / 200
/// — the same one the WHO and ACSM physical-activity guidelines use —
/// with conservative MET values for the typical recreational pace of
/// each activity. We round generously so the numbers stay readable;
/// these are "ballpark how-long-would-it-take" hints, not training-
/// log precision.
class _BurnEquivalent {
  final int walkSteps;
  final double walkHours;
  final double runKm;
  final double runMinutes;
  final double gymMinutes;
  final double cyclingKm;
  final double cyclingHours;
  final double restHours;

  const _BurnEquivalent({
    required this.walkSteps,
    required this.walkHours,
    required this.runKm,
    required this.runMinutes,
    required this.gymMinutes,
    required this.cyclingKm,
    required this.cyclingHours,
    required this.restHours,
  });

  factory _BurnEquivalent.forCalories(double kcal, double weightKg) {
    double kcalPerMin(double met) => met * weightKg * 3.5 / 200;
    final walkMin = kcal / kcalPerMin(3.5);     // walking ~5 km/h
    final runMin = kcal / kcalPerMin(9.0);      // running ~10 km/h
    final gymMin = kcal / kcalPerMin(5.0);      // mixed strength
    final cyclingMin = kcal / kcalPerMin(6.0);  // cycling ~15 km/h
    final restMin = kcal / kcalPerMin(1.0);     // very light rest
    return _BurnEquivalent(
      walkSteps: (walkMin * 100).round(),       // ~100 steps/min
      walkHours: walkMin / 60,
      runKm: runMin * (10 / 60),                // 10 km/h
      runMinutes: runMin,
      gymMinutes: gymMin,
      cyclingKm: cyclingMin * (15 / 60),        // 15 km/h
      cyclingHours: cyclingMin / 60,
      restHours: restMin / 60,
    );
  }
}

/// Bucket for Complete-macro rows. The visual treatment (background tint
/// and trailing icon) is purely a function of this status, so the
/// per-field threshold helpers below all return one of these three.
enum _MacroStatus { worse, average, good }

/// Per-field threshold helpers for the Complete-macro section. All inputs
/// are for the WHOLE portion (matching the model contract). Thresholds
/// are loose category boundaries; precise FDA/WHO cutoffs are not the
/// point — surfacing an at-a-glance verdict is.
_MacroStatus _statusForSugar(double g) {
  // Tuned for TOTAL sugar (natural + added). Used only when the model
  // didn't return the split — fallback path for older responses.
  if (g >= 22.5) return _MacroStatus.worse;
  if (g >= 5) return _MacroStatus.average;
  return _MacroStatus.good;
}

_MacroStatus _statusForAddedSugar(double g) {
  // WHO recommends < 25 g of added sugar per day. Per-meal:
  //   ≥ 15 g  → already ~60 % of the daily ceiling, worse
  //   5–14 g  → significant but acceptable in a balanced day, average
  //   < 5 g   → good
  // These cut-offs are intentionally stricter than _statusForSugar:
  // 22 g of strawberry sugar in a fresh smoothie is fine; 22 g of
  // added syrup in a coffee drink is not.
  if (g >= 15) return _MacroStatus.worse;
  if (g >= 5) return _MacroStatus.average;
  return _MacroStatus.good;
}

_MacroStatus _statusForFiber(double g) {
  // A leafy-veg salad (~250 g of mixed greens, radish, cucumber, herbs)
  // realistically carries 5–7 g of fiber, which should clearly read as
  // "good" — not "average". 5 g is also ~20 % of the WHO daily target
  // for a single meal, a reasonable threshold for the upper bucket.
  if (g >= 5) return _MacroStatus.good;
  if (g >= 2.5) return _MacroStatus.average;
  return _MacroStatus.worse;
}

_MacroStatus _statusForSatFat(double g) {
  if (g >= 10) return _MacroStatus.worse;
  if (g >= 5) return _MacroStatus.average;
  return _MacroStatus.good;
}

_MacroStatus _statusForCholesterol(double mg) {
  // 1 egg ~185 mg; a dish with two eggs lands at ~370 mg. The "worse"
  // threshold sits at 350 mg so 1-2 eggs in a salad falls into average,
  // and the bar climbs to worse only when the dish is genuinely heavy on
  // organ meat, multiple eggs, or hard-cheese-loaded toppings.
  if (mg >= 350) return _MacroStatus.worse;
  if (mg >= 100) return _MacroStatus.average;
  return _MacroStatus.good;
}

_MacroStatus _statusForSodium(double mg) {
  // WHO daily ceiling = 2000 mg of sodium (≈ 5 g of salt). Per single
  // meal: >800 mg already eats ~40 % of the daily allowance — that's
  // worse. 400–799 mg is average, below that good.
  if (mg >= 800) return _MacroStatus.worse;
  if (mg >= 400) return _MacroStatus.average;
  return _MacroStatus.good;
}

_MacroStatus _statusForTransFat(double g) {
  if (g >= 1) return _MacroStatus.worse;
  if (g > 0) return _MacroStatus.average;
  return _MacroStatus.good;
}

_MacroStatus _statusForGlycemicLoad(double load) {
  if (load >= 20) return _MacroStatus.worse;
  if (load >= 11) return _MacroStatus.average;
  return _MacroStatus.good;
}

_MacroStatus _statusForCaloricDensity(double kcalPerG) {
  // Reference: leafy veg ≈ 0.2, lean meat ≈ 1.3, pasta dishes ≈ 1.5,
  // burger ≈ 2.4, pizza slice ≈ 2.8, fries ≈ 3.1, chocolate ≈ 5.5.
  // Old worse ≥ 4 was too lenient — burgers and pizzas slipped into
  // "average" despite being the canonical calorie-dense junk food.
  if (kcalPerG >= 3.5) return _MacroStatus.worse;
  if (kcalPerG >= 2) return _MacroStatus.average;
  return _MacroStatus.good;
}

_MacroStatus _statusForProcessing(int novaLevel) {
  switch (novaLevel) {
    case 4: return _MacroStatus.worse;
    case 3: return _MacroStatus.average;
    default: return _MacroStatus.good;
  }
}

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

/// Detailed micro-nutrient breakdown rendered by the "Complete macro"
/// section. All fields are nullable because the model may legitimately
/// not have a value for a given dish (e.g. cholesterol on a vegan meal).
class _CompleteMacro {
  final double? sugarG;
  /// Refined / added sugars only (white sugar, honey added during
  /// cooking, syrups in packaged foods). NEVER counts natural sugars
  /// from whole fruit, plain milk, or plain yogurt — so a fresh-fruit
  /// smoothie with 25 g `sugarG` reads ~0 g `addedSugarG` and the
  /// status row stays green.
  final double? addedSugarG;
  final double? fiberG;
  final double? saturatedFatG;
  final double? cholesterolMg;
  final double? transFatG;
  final double? sodiumMg;
  final double? glycemicLoad;
  final double? caloricDensity;
  final int? processingLevel;

  const _CompleteMacro({
    this.sugarG,
    this.addedSugarG,
    this.fiberG,
    this.saturatedFatG,
    this.cholesterolMg,
    this.transFatG,
    this.sodiumMg,
    this.glycemicLoad,
    this.caloricDensity,
    this.processingLevel,
  });

  bool get isEmpty =>
      sugarG == null &&
      addedSugarG == null &&
      fiberG == null &&
      saturatedFatG == null &&
      cholesterolMg == null &&
      transFatG == null &&
      sodiumMg == null &&
      glycemicLoad == null &&
      caloricDensity == null &&
      processingLevel == null;
}

/// AI's goal-aware verdict on the dish. Each code is a member of the
/// closed list defined in backend/app/services/timeweb_ai.py and is
/// resolved to a localized chip via [_TagInfo].
class _GoalFit {
  final List<String> positive;
  final List<String> negative;

  const _GoalFit({this.positive = const [], this.negative = const []});

  bool get isEmpty => positive.isEmpty && negative.isEmpty;
}

class _IngredientEntry {
  final TextEditingController nameCtl;
  final TextEditingController caloriesCtl;
  final FocusNode nameFocus;
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
    FocusNode? nameFocus,
  }) : nameFocus = nameFocus ?? FocusNode();

  bool get hasCounter => count > 0;

  void dispose() {
    nameCtl.dispose();
    caloriesCtl.dispose();
    nameFocus.dispose();
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
      final goal = await _loadUserGoal();
      return api.uploadImage(
        '/api/recognize',
        imageBytes,
        locale: locale,
        goal: goal,
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
      final goal = await _loadUserGoal();
      return api.recognizeText(text, locale: locale, goal: goal);
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
      final goal = await _loadUserGoal();
      return api.uploadImage(
        '/api/recognize',
        imageBytes,
        locale: locale,
        text: text,
        goal: goal,
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
      if (log.mealQuote != null && log.mealQuote!.isNotEmpty)
        'meal_quote': log.mealQuote,
      if (log.completeMacroJson != null)
        'complete_macro': _decodeMacroJson(log.completeMacroJson!),
      if (log.goalFitJson != null)
        'goal_fit': _decodeGoalFitJson(log.goalFitJson!),
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
      if (log.mealQuote != null && log.mealQuote!.isNotEmpty)
        'meal_quote': log.mealQuote,
      if (log.completeMacroJson != null)
        'complete_macro': _decodeMacroJson(log.completeMacroJson!),
      if (log.goalFitJson != null)
        'goal_fit': _decodeGoalFitJson(log.goalFitJson!),
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

  /// Decodes the persisted `complete_macro` JSON blob back into the same
  /// map shape the AI returned originally so [_initResultControllers]
  /// rehydrates it through its existing parsing path. Returns an empty
  /// map (not null) on malformed JSON — keeps the section quietly
  /// absent rather than crashing the sheet.
  static Map<String, dynamic> _decodeMacroJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry('$k', v));
      }
    } catch (_) {}
    return const <String, dynamic>{};
  }

  /// Same idea as [_decodeMacroJson] for `goal_fit`.
  static Map<String, dynamic> _decodeGoalFitJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry('$k', v));
      }
    } catch (_) {}
    return const <String, dynamic>{};
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

  /// Optional light-irony caption rendered as a bubble overlay on the dish
  /// photo. Hidden when the AI returned nothing or an empty string.
  String? _mealQuote;

  /// Detailed macro/quality breakdown for the "Complete macro" section.
  _CompleteMacro _completeMacro = const _CompleteMacro();

  /// AI-picked tag codes for the "For your goal" chips section. Resolved to
  /// localized labels and ✓/⚠ icons via [_resolveTag].
  _GoalFit _goalFit = const _GoalFit();

  /// User's onboarding goal — drives the "For your goal: X" caption and is
  /// forwarded to AI on every recognise call so chips stay goal-aware.
  /// 'lose' / 'maintain' / 'gain'. Null until [_loadUserGoal] resolves.
  String? _userGoal;
  // Index of the ingredient whose name is currently in inline-edit
  // mode. -1 = none. Each `_IngredientEntry` carries its own
  // `FocusNode`, so we just toggle `readOnly` on a single always-
  // rendered TextField — no widget swap, no layout jump.
  int _editingIngredientNameIndex = -1;
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

  /// User weight in kg, loaded from settings. Used by the
  /// "How to burn calories" section to scale MET-based estimates.
  /// Defaults to 70 kg if not set — close enough to the global average
  /// that pre-onboarding users still see sensible numbers.
  double _userWeightKg = 70;

  bool _isLoading = false;
  String? _loadingError;

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
      _stage1Ctl.forward();
      _awaitResult();
    } else if (widget.result != null) {
      _initResultControllers(widget.result!);
    }

    _resolveImagePath();
    _loadDailyCalorieGoal();
    _loadUserGoalFromSettings();
    _loadUserWeightFromSettings();
  }

  Future<void> _loadUserGoalFromSettings() async {
    final goal = await _loadUserGoal();
    if (!mounted) return;
    if (goal == null) return;
    setState(() => _userGoal = goal);
  }

  Future<void> _loadUserWeightFromSettings() async {
    try {
      final db = await AppDatabase.getInstance();
      final raw = await db.getSetting('user_weight');
      final parsed = double.tryParse(raw ?? '');
      if (parsed == null || parsed <= 0) return;
      if (!mounted) return;
      setState(() => _userWeightKg = parsed);
    } catch (_) {
      // Defaults to 70 kg — left untouched on failure.
    }
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

    final quote = (result['meal_quote'] as String?)?.trim();
    _mealQuote = (quote != null && quote.isNotEmpty) ? quote : null;

    final macro = result['complete_macro'] as Map<String, dynamic>? ?? const {};
    _completeMacro = _CompleteMacro(
      sugarG: (macro['sugar_g'] as num?)?.toDouble(),
      addedSugarG: (macro['added_sugar_g'] as num?)?.toDouble(),
      fiberG: (macro['fiber_g'] as num?)?.toDouble(),
      saturatedFatG: (macro['saturated_fat_g'] as num?)?.toDouble(),
      cholesterolMg: (macro['cholesterol_mg'] as num?)?.toDouble(),
      transFatG: (macro['trans_fat_g'] as num?)?.toDouble(),
      sodiumMg: (macro['sodium_mg'] as num?)?.toDouble(),
      glycemicLoad: (macro['glycemic_load'] as num?)?.toDouble(),
      caloricDensity: (macro['caloric_density'] as num?)?.toDouble(),
      processingLevel: (macro['processing_level'] as num?)?.toInt(),
    );

    final fit = result['goal_fit'] as Map<String, dynamic>? ?? const {};
    _goalFit = _GoalFit(
      positive: ((fit['positive'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      negative: ((fit['negative'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
    );

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

  /// Serializes the current `_completeMacro` for persistence. Mirrors the
  /// JSON shape the AI returns so the same `_initResultControllers` path
  /// can rehydrate it on reopen without a special case. Returns null when
  /// no field was populated — keeps the column nullable and avoids
  /// writing empty `{}` rows.
  String? _completeMacroJson() {
    if (_completeMacro.isEmpty) return null;
    final m = _completeMacro;
    return jsonEncode(<String, dynamic>{
      if (m.sugarG != null) 'sugar_g': m.sugarG,
      if (m.addedSugarG != null) 'added_sugar_g': m.addedSugarG,
      if (m.fiberG != null) 'fiber_g': m.fiberG,
      if (m.saturatedFatG != null) 'saturated_fat_g': m.saturatedFatG,
      if (m.cholesterolMg != null) 'cholesterol_mg': m.cholesterolMg,
      if (m.transFatG != null) 'trans_fat_g': m.transFatG,
      if (m.sodiumMg != null) 'sodium_mg': m.sodiumMg,
      if (m.glycemicLoad != null) 'glycemic_load': m.glycemicLoad,
      if (m.caloricDensity != null) 'caloric_density': m.caloricDensity,
      if (m.processingLevel != null) 'processing_level': m.processingLevel,
    });
  }

  /// Serializes `_goalFit` to the same `{positive: [...], negative: [...]}`
  /// shape the AI returns, so the rehydrate path is uniform.
  String? _goalFitJson() {
    if (_goalFit.isEmpty) return null;
    return jsonEncode(<String, dynamic>{
      'positive': _goalFit.positive,
      'negative': _goalFit.negative,
    });
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
    HapticFeedback.selectionClick();
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
    setState(() => _editingIngredientNameIndex = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ingredients[index].nameFocus.requestFocus();
    });
  }

  void _commitIngredientName() {
    final i = _editingIngredientNameIndex;
    if (i < 0 || i >= _ingredients.length) {
      setState(() => _editingIngredientNameIndex = -1);
      return;
    }
    // Trim trailing whitespace the user may have left in the controller.
    final ing = _ingredients[i];
    final trimmed = ing.nameCtl.text.trim();
    if (trimmed != ing.nameCtl.text) ing.nameCtl.text = trimmed;
    setState(() => _editingIngredientNameIndex = -1);
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
    // selectionClick is the iOS HIG haptic for "moving through a series of
    // discrete options" — picker wheels, sliders that snap, +/- steppers.
    // Crisp on iOS, soft tick on Android, doesn't fatigue on rapid taps.
    HapticFeedback.selectionClick();

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
    HapticFeedback.selectionClick();
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
      if (!auth.isPremium) {
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
        mealQuote: drift.Value(_mealQuote),
        completeMacroJson: drift.Value(_completeMacroJson()),
        goalFitJson: drift.Value(_goalFitJson()),
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
        mealQuote: drift.Value(_mealQuote),
        completeMacroJson: drift.Value(_completeMacroJson()),
        goalFitJson: drift.Value(_goalFitJson()),
      ));

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
        mealQuote: drift.Value(_mealQuote),
        completeMacroJson: drift.Value(_completeMacroJson()),
        goalFitJson: drift.Value(_goalFitJson()),
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
      final goal = await _loadUserGoal();
      result = await api.recognizeText(prompt, locale: locale, goal: goal);
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
                      // Photo + body in a Stack. Per Figma the body sits
                      // 28 px BELOW the photo (no overlap) — keeps the
                      // dish quote bubble clean and gives the analytics
                      // card its own breathing room. Cards are inset 8 px
                      // on each side relative to the photo.
                      Stack(
                        children: [
                          if (hasImage) _buildImageCard(c),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              8,
                              hasImage ? 221 + 28 : 0,
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
          // Health rating sits as its OWN 20-radius card under the
          // analytics card (Figma `Frame 60` gap = 8 px). Only shown in
          // overview mode — when the user flips into the macro editor
          // it doesn't make sense to keep showing the rating.
          if (!_paramsEditMode) ...[
            const SizedBox(height: 8),
            _buildHealthCard(
              c,
              score: _computeHealthScore(),
              scoreRatio: (_computeHealthScore() / 10).clamp(0.0, 1.0),
              description: _healthDescription(_computeHealthScore()),
            ),
          ],
          if (!_goalFit.isEmpty) ...[
            const SizedBox(height: 16),
            _buildGoalFitSection(c),
          ],
          if (!_paramsEditMode && _val(_caloriesCtl) > 0) ...[
            const SizedBox(height: 16),
            _buildBurnCaloriesSection(c),
          ],
          if (!_completeMacro.isEmpty) ...[
            const SizedBox(height: 16),
            _buildCompleteMacroSection(c),
          ],
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
    // the progress bars at exactly 36px from the screen edges. The extra
    // top padding replaces the breathing room the cabbage mascot used to
    // occupy.
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 56, 28, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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

    final quote = _mealQuote;
    // At 24 px radius the combination of `Border.all` + `Clip.antiAlias`
    // gives jagged corners on iOS — the border anti-aliases against
    // ARGB pixels and the clip then chews into them. Splitting the
    // border (outer Container) from the clip (inner ClipRRect) lets
    // each pass do clean anti-aliasing.
    final photo = Container(
      height: 221,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isOpaquePhoto ? null : Colors.white,
        border: Border.all(color: c.borderColor),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        // Inset the inner clip by the 1 px border so the image's outer
        // pixels never paint over (or under) the border ring.
        borderRadius: BorderRadius.circular(23),
        child: imageWidget,
      ),
    );

    if (quote == null) return photo;

    // The bubble overhangs the bottom edge of the photo by 8 px (per
    // design), so it has to live OUTSIDE the photo's clipBehavior. We
    // wrap photo + bubble in an outer Stack with `clipBehavior: none`
    // and pin the bubble to the bottom. With Positioned(left/right/bottom)
    // and no `top`, the bubble's height is determined entirely by its
    // child — so it visually GROWS UPWARD when the quote wraps to more
    // lines, while its bottom edge stays nailed at -8.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        photo,
        Positioned(
          left: 20,
          right: 20,
          bottom: -12,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 256),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightInverse,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.lightBack2,
                    width: 4,
                  ),
                ),
                child: Text(
                  quote,
                  // 4 lines fits a typical ≤100-char quote at the
                  // Figma width of 256 px (Inter Bold 15/20 averages
                  // ~25 chars per line including spaces). Anything
                  // longer than that is on the AI — the prompt caps
                  // it at 100 chars, so we keep ellipsis as a guard
                  // rather than removing maxLines entirely.
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 20 / 15,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(20),
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
    // [score / scoreRatio / description] are passed in but the new Figma
    // layout renders the health card OUTSIDE the analytics shell — we
    // ignore them here. Keeping them in the signature so the parent
    // build can stay unchanged.
    required int score,
    required double scoreRatio,
    required String description,
  }) {
    final order = MacroOrder.of(context);
    final grams = _val(_totalGramsCtl);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Calorie ring + macro rows (Figma: ring 106×105 left, three
        // 32 px gradient rows stacked on the right with 6 px gap).
        // Note: ring SEGMENTS use the final shares unchanged — only the
        // calorie number inside the ring counts up. The ring redrawing
        // its arcs on every ±10 g tap is jarring; the macro distribution
        // doesn't really change for small weight tweaks, so we let the
        // numbers do the talking.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCalorieRing(
              c,
              calories * progress,
              pShare,
              fShare,
              cShare,
            ),
            const SizedBox(width: 23),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < order.length; i++) ...[
                    if (i > 0) const SizedBox(height: 6),
                    _buildMacroRow(c, order[i], _macroGrams(order[i]) * progress),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Weight (left) + daily-calorie % (right).
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _animNum(
                grams,
                (v) => _buildLabelledValue(
                  c,
                  value: l10n.gramsValue(v.round()),
                  label: l10n.dishWeightLabel,
                  alignment: CrossAxisAlignment.start,
                ),
              ),
            ),
            if (dailyPercent != null)
              Expanded(
                child: _animNum(
                  dailyPercent * progress,
                  (v) => _buildLabelledValue(
                    c,
                    value: '${v.round()}%',
                    label: l10n.ofYourDailyCalories,
                    alignment: CrossAxisAlignment.end,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Stepper (left) + Edit chip (right).
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildWeightStepper(c),
            const Spacer(),
            _buildEditChip(c, l10n),
          ],
        ),
        const SizedBox(height: 9),
        _buildRefineFieldCompact(c),
      ],
    );
  }

  // ── Helpers used by the new Figma overview layout ────────────────────

  /// Wraps any numeric value in a TweenAnimationBuilder so that
  /// successive rebuilds tween FROM the previously rendered number TO
  /// the new one — instead of snapping. Reused by the calorie ring,
  /// macro rows, weight, %, burn-calorie values and the health score.
  /// The intro count-up still works because [progress] in the parent
  /// scales the input from 0 → full on first show; this helper just
  /// follows whichever value flows in.
  ///
  /// [duration] is short by default (260 ms) — long enough to feel
  /// like a transition, short enough that ±10 g spam doesn't queue up.
  Widget _animNum(
    double value,
    Widget Function(double current) builder, {
    Duration duration = const Duration(milliseconds: 260),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: value, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, current, _) => builder(current),
    );
  }

  /// Returns the macro's current per-portion grams from the editable
  /// controllers (so stepper-driven recalculation is reflected live).
  double _macroGrams(Macro m) {
    switch (m) {
      case Macro.protein: return _val(_proteinCtl);
      case Macro.fat: return _val(_fatCtl);
      case Macro.carbs: return _val(_carbsCtl);
    }
  }

  /// Figma `Frame 235999..236003` — 32 px full-width row, radius 8, a
  /// macro-specific horizontal gradient (right→left as in Figma), 20 px
  /// circle for the SVG ingredient icon, Medium 13 label left, Bold 13
  /// gram count right with 8 px inset from the row's edge.
  Widget _buildMacroRow(_AiSheetColors c, Macro macro, double grams) {
    final l10n = context.l10n;
    final (gradient, iconAsset, label) = switch (macro) {
      Macro.protein => (
          const LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [Color(0x26F0681B), Color(0x26D91D1D)],
          ),
          'assets/onboarding/emoji/cut-of-meat.svg',
          l10n.proteinLabel,
        ),
      Macro.fat => (
          const LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [Color(0x26FFBB00), Color(0x26D0FF00)],
          ),
          'assets/onboarding/emoji/avocado.svg',
          l10n.fatLabel,
        ),
      Macro.carbs => (
          const LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [Color(0x261787D1), Color(0x2617D1C7)],
          ),
          'assets/onboarding/emoji/bread.svg',
          l10n.carbsLabel,
        ),
    };

    return Container(
      height: 32,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.only(left: 4, right: 8),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Center(
              child: SvgPicture.asset(iconAsset, width: 17, height: 17),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 16 / 13,
              ),
            ),
          ),
          _animNum(
            grams,
            (v) => Text(
              l10n.gramsValue(v.round()),
              style: TextStyle(
                color: c.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 16 / 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Big-number-over-secondary-label pair used twice in the analytics
  /// card: weight on the left, % of daily calories on the right. Figma
  /// styles: 18 px Bold value, 13 px Regular secondary label at 50 %
  /// opacity over primary text.
  Widget _buildLabelledValue(
    _AiSheetColors c, {
    required String value,
    required String label,
    required CrossAxisAlignment alignment,
  }) {
    final textAlign = alignment == CrossAxisAlignment.end
        ? TextAlign.right
        : TextAlign.left;
    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          textAlign: textAlign,
          style: TextStyle(
            color: c.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 24 / 18,
          ),
        ),
        Text(
          label,
          textAlign: textAlign,
          style: TextStyle(
            color: c.onSurface.withValues(alpha: 0.5),
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 16 / 13,
          ),
        ),
      ],
    );
  }

  /// −/+ stepper that adjusts the dish's total weight by 10 g and
  /// scales every macro accordingly so the displayed totals stay
  /// consistent. Two 40×40 buttons with a 4 px gap on a 84 px footprint.
  Widget _buildWeightStepper(_AiSheetColors c) {
    return SizedBox(
      width: 84,
      height: 40,
      child: Row(
        children: [
          _weightStepperButton(c, icon: Icons.remove_rounded, onTap: () => _adjustWeight(-10)),
          const SizedBox(width: 4),
          _weightStepperButton(c, icon: Icons.add_rounded, onTap: () => _adjustWeight(10)),
        ],
      ),
    );
  }

  Widget _weightStepperButton(
    _AiSheetColors c, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: c.back,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 24, color: c.onSurface),
        ),
      ),
    );
  }

  void _adjustWeight(int deltaG) {
    final current = _val(_totalGramsCtl);
    final next = (current + deltaG).clamp(0.0, 9999.0);
    if (next == current) return;
    final ratio = current > 0 ? next / current : 1.0;
    setState(() {
      _totalGramsCtl.text = _fmt(next);
      _proteinCtl.text = _fmt(_val(_proteinCtl) * ratio);
      _fatCtl.text = _fmt(_val(_fatCtl) * ratio);
      _carbsCtl.text = _fmt(_val(_carbsCtl) * ratio);
      _caloriesCtl.text = _fmt(_val(_caloriesCtl) * ratio);
      for (final ing in _ingredients) {
        ing.grams = ing.grams * ratio;
        ing.protein = ing.protein * ratio;
        ing.fat = ing.fat * ratio;
        ing.carbs = ing.carbs * ratio;
        ing.calories = ing.calories * ratio;
        ing.caloriesCtl.text = _fmt(ing.calories);
      }
    });
    // Don't replay the intro count-up here — counting from 0 makes
    // ±10 g feel like a full reload. The actual displayed values are
    // wrapped in TweenAnimationBuilder by [_animNum], so each setState
    // animates from the PREVIOUS rendered value to the new target
    // automatically. The intro controller stays at 1.0 from its first
    // run; only the per-value tween reacts to this delta.
  }

  /// Surface-toned chip that flips the card into edit mode. Figma:
  /// 139×40, radius 12, icon 20 + label 14 px Medium with 8 px gap.
  Widget _buildEditChip(_AiSheetColors c, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => setState(() => _paramsEditMode = true),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: c.back,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/edit.svg',
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(c.onSurface, BlendMode.srcIn),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.edit,
              style: TextStyle(
                color: c.onSurface,
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

  /// Compact refine field per Figma: 48 px tall outlined input with a
  /// 36 px round send button pinned to the right. Tapping the field
  /// focuses the text input; tapping the send button submits when
  /// there's text, otherwise no-op.
  Widget _buildRefineFieldCompact(_AiSheetColors c) {
    final hint = c.isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    // While refining, drop the whole row to ~60 % opacity and freeze
    // the text field — visual signal that the AI is working on the
    // dish, plus prevents the user from stacking a second request on
    // top of the in-flight one.
    final busy = _refining;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: busy ? 0.6 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: busy ? null : () => _refineFocus.requestFocus(),
        child: Container(
          height: 48,
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
          decoration: BoxDecoration(
            color: c.cardBg,
            border: Border.all(
              color: c.isDark ? AppColors.lineDT200 : AppColors.lineLight200,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _refineCtl,
                  builder: (context, value, _) {
                    return TextField(
                      controller: _refineCtl,
                      focusNode: _refineFocus,
                      enabled: !busy,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (_refineCtl.text.trim().isNotEmpty) {
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
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 11),
                        // Outer Container already draws the 1 px border;
                        // killing every TextField border state stops the
                        // theme's default underline from layering on top.
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
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
                    );
                  },
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _refineCtl,
                builder: (context, value, _) {
                  final hasText = value.text.trim().isNotEmpty;
                  // When in-flight we keep the button blue so the inline
                  // spinner reads as "active" rather than "disabled grey".
                  final bg = (hasText || busy)
                      ? AppColors.primary
                      : (c.isDark
                          ? AppColors.darkSecondaryExtraLight
                          : AppColors.lightSecondaryExtraLight);
                  return GestureDetector(
                    onTap: hasText && !busy ? _onRefineDish : null,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: bg,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      // Cross-fade between the send arrow and the
                      // spinner so the busy → idle transition isn't a
                      // hard glyph swap.
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 160),
                        child: busy
                            ? const SizedBox(
                                key: ValueKey('spinner'),
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : SvgPicture.asset(
                                'assets/icons/send.svg',
                                key: const ValueKey('arrow'),
                                width: 18,
                                height: 18,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
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
              order: MacroOrder.of(context),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _animNum(
                calories,
                (v) => Text(
                  _formatCalories(v),
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
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

  // Kept for the upcoming "How to burn calories" section; the old
  // overview now uses macro rows instead.
  // ignore: unused_element
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

  /// Standalone health-rating card sat below the analytics card (Figma
  /// `Frame 236000`). Same outer radius (20) and white background as the
  /// analytics card; heart icon left, title + 6 px progress bar + comment
  /// stacked on the right.
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
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 20 / 15,
                      ),
                    ),
                    Text(
                      l10n.healthRatingValue(displayScore),
                      style: TextStyle(
                        color: c.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 20 / 15,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 20 / 15,
                  ),
                ),
              ],
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

  // ignore: unused_element
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

  /// Section header used by the "For your goal" and "Complete macro"
  /// blocks. Matches Figma `Text Small 14px/Medium`, secondary color,
  /// with an 8 px gap to the card body below.
  Widget _buildSectionHeader(_AiSheetColors c, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: c.secondaryText,
          fontSize: 14,
          height: 18 / 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// "For your goal: X" — wrap of positive/negative AI-picked tags. The
  /// AI already split codes into [_GoalFit.positive] / `.negative`; we
  /// just resolve labels and pick the chip variant accordingly.
  Widget _buildGoalFitSection(_AiSheetColors c) {
    final l10n = context.l10n;
    final chips = <Widget>[];
    for (final code in _goalFit.positive) {
      final label = _tagLabel(l10n, code);
      if (label != null) chips.add(_buildGoalFitChip(label, positive: true));
    }
    for (final code in _goalFit.negative) {
      final label = _tagLabel(l10n, code);
      if (label != null) chips.add(_buildGoalFitChip(label, positive: false));
    }
    if (chips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(c, _goalLabel(l10n, _userGoal)),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: chips,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalFitChip(String label, {required bool positive}) {
    // Figma: positive = success @ 15% over surface, negative = orange
    // @ 10% over surface. The negative tint is intentionally orange-not-
    // red here — red is reserved for "Worse than average" rows in
    // [_buildMacroGroup], so that the user has a clear visual hierarchy
    // between "this is suboptimal for your goal" (orange) and "this is
    // a meaningful nutrition red flag" (red).
    final bgColor = positive
        ? AppColors.success.withValues(alpha: 0.15)
        : AppColors.orange.withValues(alpha: 0.10);
    final iconBg = positive ? AppColors.success : AppColors.orange;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(
              positive ? Icons.check : Icons.priority_high,
              size: 12,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.lightOnSurface,
              fontSize: 14,
              height: 18 / 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// "How to burn calories?" — five activity rows (Walking / Running /
  /// Gym workout / Cycling / Body at rest) with km / steps / hours
  /// derived from the dish's total calories and the user's weight.
  /// Hidden when total calories are zero (e.g. a glass of water).
  Widget _buildBurnCaloriesSection(_AiSheetColors c) {
    final l10n = context.l10n;
    final kcal = _val(_caloriesCtl);
    if (kcal <= 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(c, l10n.burnSectionTitle),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          // The whole burn-by-activity card rebuilds against a tweened
          // kcal so a ±10 g tap slides every row's number from the old
          // value to the new one in lock-step (instead of snapping).
          child: _animNum(
            kcal,
            (currentKcal) {
              final burn = _BurnEquivalent.forCalories(
                currentKcal,
                _userWeightKg,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBurnRow(
                    c,
                    icon: Icons.directions_walk_rounded,
                    label: l10n.burnWalking,
                    primary: l10n.burnApproxSteps(
                      _formatStepsCount(burn.walkSteps),
                    ),
                    secondary: l10n.approxHours(
                      burn.walkHours.round().clamp(1, 99),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildBurnRow(
                    c,
                    icon: Icons.directions_run_rounded,
                    label: l10n.burnRunning,
                    primary: l10n.burnApproxKm(burn.runKm.toStringAsFixed(0)),
                    secondary: _formatBurnDuration(burn.runMinutes),
                  ),
                  const SizedBox(height: 6),
                  _buildBurnRow(
                    c,
                    icon: Icons.fitness_center_rounded,
                    label: l10n.burnGym,
                    primary: _formatBurnDuration(burn.gymMinutes),
                  ),
                  const SizedBox(height: 6),
                  _buildBurnRow(
                    c,
                    icon: Icons.directions_bike_rounded,
                    label: l10n.burnCycling,
                    primary:
                        l10n.burnApproxKm(burn.cyclingKm.toStringAsFixed(0)),
                    secondary: l10n.approxHours(
                      burn.cyclingHours.round().clamp(1, 99),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildBurnRow(
                    c,
                    icon: Icons.bed_rounded,
                    label: l10n.burnResting,
                    primary:
                        l10n.approxHours(burn.restHours.round().clamp(1, 99)),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// Single burn row — icon + label on the left, value(s) on the right.
  /// When [secondary] is provided we join with a localised "or" so users
  /// see two equivalent ways of burning the same calories.
  Widget _buildBurnRow(
    _AiSheetColors c, {
    required IconData icon,
    required String label,
    required String primary,
    String? secondary,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: c.back,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: c.onSurface),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
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
          _buildBurnValueText(c, primary, secondary),
        ],
      ),
    );
  }

  Widget _buildBurnValueText(
    _AiSheetColors c,
    String primary,
    String? secondary,
  ) {
    final primaryStyle = TextStyle(
      color: c.onSurface,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 18 / 14,
    );
    if (secondary == null) {
      return Text(primary, style: primaryStyle);
    }
    final secondaryStyle = TextStyle(
      color: c.secondaryText,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 18 / 14,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: primary, style: primaryStyle),
          TextSpan(text: '  ${context.l10n.burnOr}  ', style: secondaryStyle),
          TextSpan(text: secondary, style: primaryStyle),
        ],
      ),
    );
  }

  /// Formats step counts the way native tracker apps do: 8 723 → "8 700",
  /// 12 345 → "12 000", to avoid spurious precision and keep the row
  /// stable when the user adjusts the dish weight by ±10 g via the stepper.
  String _formatStepsCount(int steps) {
    if (steps < 1000) return steps.toString();
    final rounded = (steps / 100).round() * 100;
    final s = rounded.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  /// Human-readable "~ 1 h 15 min" / "~ 45 min" / "~ 2 h" depending on
  /// the total minutes. Reuses approxHours / approxMinutes for the pure
  /// cases and the new burnApproxHoursMinutes for the mixed one.
  String _formatBurnDuration(double minutes) {
    final m = minutes.round();
    if (m <= 0) return context.l10n.approxMinutes(1);
    if (m < 60) return context.l10n.approxMinutes(m);
    final h = m ~/ 60;
    final rem = m % 60;
    if (rem == 0) return context.l10n.approxHours(h);
    return context.l10n.burnApproxHoursMinutes(h, rem);
  }

  /// "Complete macro" — grouped breakdown of dish nutrition into three
  /// blocks coloured by [_MacroStatus]: red for "worse", amber for
  /// "average", green for "good". Empty fields are skipped entirely.
  Widget _buildCompleteMacroSection(_AiSheetColors c) {
    if (_completeMacro.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;

    // Collect every row with a value and bucket it by status. Order
    // inside a bucket mirrors the Figma frame order so the eye lands on
    // the same nutrient when comparing dishes.
    final rows = <(_MacroStatus, String)>[];
    void add(_MacroStatus status, String label) => rows.add((status, label));

    // Prefer added_sugar_g when the model split it out: natural sugars
    // from fruit/milk shouldn't penalise the row (a fresh smoothie
    // shouldn't read red for 25 g of mostly-banana sugar). Use the
    // matching stricter threshold for added sugar; fall back to the
    // total-sugar threshold when only `sugar_g` is available so older
    // responses still render.
    if (_completeMacro.addedSugarG != null) {
      add(
        _statusForAddedSugar(_completeMacro.addedSugarG!),
        l10n.macroSugar,
      );
    } else if (_completeMacro.sugarG != null) {
      add(_statusForSugar(_completeMacro.sugarG!), l10n.macroSugar);
    }
    if (_completeMacro.fiberG != null) {
      add(_statusForFiber(_completeMacro.fiberG!), l10n.macroFiber);
    }
    if (_completeMacro.saturatedFatG != null) {
      add(_statusForSatFat(_completeMacro.saturatedFatG!), l10n.macroSaturatedFat);
    }
    if (_completeMacro.cholesterolMg != null) {
      add(
        _statusForCholesterol(_completeMacro.cholesterolMg!),
        l10n.macroCholesterol,
      );
    }
    if (_completeMacro.sodiumMg != null) {
      add(_statusForSodium(_completeMacro.sodiumMg!), l10n.macroSalt);
    }
    if (_completeMacro.transFatG != null) {
      add(_statusForTransFat(_completeMacro.transFatG!), l10n.macroTransFat);
    }
    if (_completeMacro.glycemicLoad != null) {
      add(
        _statusForGlycemicLoad(_completeMacro.glycemicLoad!),
        l10n.macroGlycemicLoad,
      );
    }
    if (_completeMacro.caloricDensity != null) {
      add(
        _statusForCaloricDensity(_completeMacro.caloricDensity!),
        l10n.macroCaloricDensity,
      );
    }
    if (_completeMacro.processingLevel != null) {
      add(
        _statusForProcessing(_completeMacro.processingLevel!),
        l10n.macroProcessing,
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    final worse = [for (final r in rows) if (r.$1 == _MacroStatus.worse) r.$2];
    final average = [
      for (final r in rows) if (r.$1 == _MacroStatus.average) r.$2,
    ];
    final good = [for (final r in rows) if (r.$1 == _MacroStatus.good) r.$2];

    final groups = <Widget>[];
    if (worse.isNotEmpty) {
      groups.add(_buildMacroGroup(c, worse, _MacroStatus.worse));
    }
    if (average.isNotEmpty) {
      if (groups.isNotEmpty) groups.add(const SizedBox(height: 4));
      groups.add(_buildMacroGroup(c, average, _MacroStatus.average));
    }
    if (good.isNotEmpty) {
      if (groups.isNotEmpty) groups.add(const SizedBox(height: 4));
      groups.add(_buildMacroGroup(c, good, _MacroStatus.good));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(c, l10n.completeMacroSection),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: groups,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroGroup(
    _AiSheetColors c,
    List<String> labels,
    _MacroStatus status,
  ) {
    final l10n = context.l10n;
    final (bg, statusText, isPositive) = switch (status) {
      _MacroStatus.worse =>
        (AppColors.error.withValues(alpha: 0.09), l10n.macroStatusWorse, false),
      _MacroStatus.average => (
          AppColors.orange.withValues(alpha: 0.10),
          l10n.macroStatusAverage,
          false,
        ),
      _MacroStatus.good => (
          AppColors.success.withValues(alpha: 0.12),
          l10n.macroStatusGood,
          true,
        ),
    };
    final accent = switch (status) {
      _MacroStatus.worse => AppColors.error,
      _MacroStatus.average => AppColors.orange,
      _MacroStatus.good => AppColors.success,
    };

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        color: AppColors.lightOnSurface,
                        fontSize: 14,
                        height: 18 / 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: accent,
                      fontSize: 13,
                      height: 14 / 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPositive ? Icons.check : Icons.priority_high,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
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
        for (final m in MacroOrder.of(context)) ...[
          const SizedBox(height: 12),
          _buildParamRow(
            c,
            iconAsset: switch (m) {
              Macro.protein => 'assets/icons/belok.svg',
              Macro.fat => 'assets/icons/fat.svg',
              Macro.carbs => 'assets/icons/uglevod.svg',
            },
            label: switch (m) {
              Macro.protein => l10n.proteinGramsLabel,
              Macro.fat => l10n.fatGramsLabel,
              Macro.carbs => l10n.carbsGramsLabel,
            },
            controller: switch (m) {
              Macro.protein => _proteinCtl,
              Macro.fat => _fatCtl,
              Macro.carbs => _carbsCtl,
            },
            onChanged: (_) => _recalcFromMacros(),
          ),
        ],
        // Refine field belongs to the overview surface (the user has
        // the dish in front of them and asks the AI to nudge it).
        // The edit mode is the manual editor — pure number tweaking —
        // so the "Refine the dish…" input would just sit in the way of
        // the Update button. Keep edit-mode focused on the macros.
        const SizedBox(height: 12),
        _buildSaveMacrosButton(c),
      ],
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
          // ValueKey on the entry's identity — Column matches by key
          // when the list mutates, so existing cards stay mounted (no
          // animation replay) while a freshly added entry mounts and
          // plays its `_MountFadeSlide` once.
          KeyedSubtree(
            key: ObjectKey(_ingredients[i]),
            child: _MountFadeSlide(
              child: _buildIngredientCard(c, i),
            ),
          ),
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
              _PressFeedback(
                onTap: () => _removeIngredient(index),
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
                  numericValue: isCounter ? ing.count : ing.grams,
                  onMinus: () => _onIngredientGramsStepped(index, -1),
                  onPlus: () => _onIngredientGramsStepped(index, 1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildIngredientField(
                  c: c,
                  label: l10n.caloriesLabel,
                  numericValue: ing.calories,
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
  /// `numericValue` drives a smooth tween between consecutive integer
  /// values so the digit roll is visible (no hard snap on tap).
  Widget _buildIngredientField({
    required _AiSheetColors c,
    required String label,
    required num numericValue,
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
                child: _AnimatedNumber(
                  value: numericValue,
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
    return _PressFeedback(
      onTap: onTap,
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: c.back,
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

  /// Ingredient card header. Always a `TextField` — when not editing
  /// it's `readOnly`, so the layout, baseline, font metrics and decoration
  /// all stay byte-identical between the static and editing states.
  /// Tapping flips it into edit mode (focus + keyboard); commit on
  /// submit / unfocus. Replacing the previous Text↔TextField swap fixed
  /// a one-frame "the text grows" wobble caused by the two widgets
  /// computing their text-box height differently.
  Widget _buildIngredientNameField(
    _AiSheetColors c,
    int index,
    _IngredientEntry ing,
  ) {
    final l10n = context.l10n;
    final editing = _editingIngredientNameIndex == index;
    final placeholderColor = c.onSurface.withAlpha(120);
    final isEmpty = ing.nameCtl.text.trim().isEmpty;

    const nameStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 22 / 16,
    );
    const nameStrut = StrutStyle(
      fontSize: 16,
      height: 22 / 16,
      forceStrutHeight: true,
    );

    return TextField(
      controller: ing.nameCtl,
      focusNode: ing.nameFocus,
      readOnly: !editing,
      enableInteractiveSelection: editing,
      showCursor: editing,
      textInputAction: TextInputAction.done,
      style: nameStyle.copyWith(
        color: isEmpty ? placeholderColor : c.onSurface,
      ),
      strutStyle: nameStrut,
      cursorColor: AppColors.primary,
      cursorWidth: 1.5,
      decoration: InputDecoration(
        isCollapsed: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        filled: false,
        hintText: l10n.untitledIngredientName,
        hintStyle: nameStyle.copyWith(color: placeholderColor),
      ),
      onTap: editing ? null : () => _beginEditIngredientName(index),
      onChanged: (_) {
        // Hint visibility flips when the controller text becomes empty;
        // refresh so the placeholder color follows.
        setState(() {});
      },
      onSubmitted: (_) => _commitIngredientName(),
      onTapOutside: (_) {
        if (_editingIngredientNameIndex == index) _commitIngredientName();
      },
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
    required this.order,
  });

  final double proteinShare;
  final double fatShare;
  final double carbsShare;
  final Color trackColor;
  /// Locale-driven macro clockwise order, starting at 12 o'clock.
  final List<Macro> order;

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
    // regardless of arc length. The clockwise order follows the active
    // locale's macro convention (БЖУ for ru, Carbs-first elsewhere).
    final raw = <_RingSegment>[];
    for (final m in order) {
      final share = switch (m) {
        Macro.protein => proteinShare,
        Macro.fat => fatShare,
        Macro.carbs => carbsShare,
      };
      if (share <= 0) continue;
      final color = switch (m) {
        Macro.protein => const Color(0xFFE4431C),
        Macro.fat => const Color(0xFFEFD400),
        Macro.carbs => const Color(0xFF17ACCC),
      };
      raw.add(_RingSegment(share, [color]));
    }
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
    if (old.proteinShare != proteinShare ||
        old.fatShare != fatShare ||
        old.carbsShare != carbsShare ||
        old.trackColor != trackColor ||
        old.order.length != order.length) {
      return true;
    }
    for (int i = 0; i < order.length; i++) {
      if (old.order[i] != order[i]) return true;
    }
    return false;
  }
}

class _RingSegment {
  const _RingSegment(this.share, this.colors);
  final double share;
  final List<Color> colors;
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
    return _PressFeedback(
      onTap: onTap,
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
                color: c.back,
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

/// Tactile press feedback. Scales the wrapped child down to 92 % while
/// the user is holding their finger on it, springs back when released.
/// Short and shallow on purpose — same `easeOutCubic` curve the rest
/// of the app uses, ~90 ms duration, just enough to confirm the tap
/// without a "bouncy" feel.
class _PressFeedback extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _PressFeedback({
    required this.child,
    required this.onTap,
  });

  static const _pressedScale = 0.92;
  static const _behavior = HitTestBehavior.opaque;

  @override
  State<_PressFeedback> createState() => _PressFeedbackState();
}

class _PressFeedbackState extends State<_PressFeedback> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: disabled ? null : (_) => _setPressed(true),
      onTapUp: disabled ? null : (_) => _setPressed(false),
      onTapCancel: disabled ? null : () => _setPressed(false),
      behavior: _PressFeedback._behavior,
      child: AnimatedScale(
        scale: _pressed ? _PressFeedback._pressedScale : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Smoothly tweens between integer values. Used for the grams /
/// calories displays in ingredient cards so a 100 → 110 stepper tap
/// looks like a quick count-up rather than a hard snap. Idempotent on
/// initial mount (begin == end == value), so the existing list of
/// recognised ingredients renders at its true value with no count-up
/// flash.
class _AnimatedNumber extends StatelessWidget {
  final num value;
  final TextStyle? style;

  const _AnimatedNumber({
    required this.value,
    this.style,
  });

  static const _duration = Duration(milliseconds: 160);

  @override
  Widget build(BuildContext context) {
    final v = value.toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: v, end: v),
      duration: _duration,
      curve: Curves.easeOutCubic,
      builder: (_, current, _) => Text(
        current.round().toString(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}

/// One-shot fade + slide-up on first mount. Used to give newly added
/// ingredient cards (via "Add suggestion" / "Smth else") a soft entry
/// instead of popping in. Existing cards never see this animation —
/// once `tween.end` settles at 1.0 on the first frame after mount,
/// rebuilds keep it there.
class _MountFadeSlide extends StatelessWidget {
  final Widget child;

  const _MountFadeSlide({required this.child});

  static const _duration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: _duration,
      curve: Curves.easeOutCubic,
      builder: (_, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 8),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
