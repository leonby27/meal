import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/core/utils/macro_order.dart';

// ── Animation conventions (mirrors `_CalorieRingPainter` /
//   `_overviewIntro` patterns in `ai_meal_result_sheet.dart`) ────────
//
// All data on the analytics screen counts up / sweeps in once on first
// build, and re-tweens between old and new values on subsequent rebuilds
// (period switch, metric switch). We rely on Flutter's
// `TweenAnimationBuilder` semantics — when its `tween.end` changes, it
// continues from the currently-displayed value rather than restarting at
// `begin`, giving free state-change animation in addition to the intro.
//
// Curves and durations are picked from the existing codebase (>90% of
// animations use `easeOutCubic`; data intros land in the 600–800 ms band).
const Duration _kIntroDur = Duration(milliseconds: 750);
const Duration _kDataDur = Duration(milliseconds: 600);
const Duration _kSwitchDur = Duration(milliseconds: 220);
const Curve _kCurve = Curves.easeOutCubic;

enum _Period { week, twoWeeks, month, threeMonths, sixMonths, year }

extension _PeriodX on _Period {
  int get days => switch (this) {
    _Period.week => 7,
    _Period.twoWeeks => 14,
    _Period.month => 30,
    _Period.threeMonths => 90,
    _Period.sixMonths => 180,
    _Period.year => 365,
  };

  String label(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      _Period.week => l10n.analyticsPeriod1W,
      _Period.twoWeeks => l10n.analyticsPeriod2W,
      _Period.month => l10n.analyticsPeriod1M,
      _Period.threeMonths => l10n.analyticsPeriod3M,
      _Period.sixMonths => l10n.analyticsPeriod6M,
      _Period.year => l10n.analyticsPeriod1Y,
    };
  }
}

enum _ChartMetric { calories, protein, fat, carbs }

/// One column in the trends bar chart. For short periods (1W/2W/1M) a
/// bucket is a single day; for longer periods we aggregate days into
/// weeks (3M/6M) or calendar months (1Y) so the chart actually fits and
/// the bars stay readable. The bucket also carries its own x-axis
/// label — only some buckets show one (e.g. month boundaries on 3M/6M).
class _TrendBucket {
  final double value;
  final String label;
  const _TrendBucket({required this.value, required this.label});
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late AppDatabase _db;
  bool _ready = false;

  // Bumped after every data load. Used as a `KeyedSubtree` key on the
  // animated content so that switching periods re-mounts the data
  // sections — every TweenAnimationBuilder inside replays its intro
  // from 0 to the new value, which gives a clear "the data refreshed"
  // moment without showing a loader. Incrementing only AFTER data is
  // loaded means the new mount immediately targets the new values
  // (instead of momentarily targeting the previous period's data while
  // the async fetch is still in flight).
  int _refreshTick = 0;

  _Period _period = _Period.week;
  // Period the currently-loaded `_data` is for. Stays one tap behind
  // `_period` until the async load completes — that way the chart's
  // bucketing logic can't ever read NEW _period over OLD _data and
  // briefly render the wrong number of bars (the "micro-flicker" on
  // tab switch).
  _Period _dataPeriod = _Period.week;
  _ChartMetric _trendMetric = _ChartMetric.calories;
  _ChartMetric _highlightMetric = _ChartMetric.calories;

  double _goalCalories = 2000;
  double _goalProtein = 100;
  double _goalFat = 70;
  double _goalCarbs = 250;
  bool _showProtein = true;
  bool _showFat = true;
  bool _showCarbs = true;

  List<_DaySummary> _data = [];
  List<_DaySummary> _previousPeriodData = [];
  int _streak = 0;
  // Per-day "did the user log anything?" map for the streak card's
  // swipeable history. Keyed by midnight DateTime. Loaded alongside
  // the streak so we don't double-query the same days.
  Map<DateTime, bool> _streakDayLogged = const {};
  static const int _streakHistoryDays = 84; // 12 weeks
  late DateTime _today;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _initDb();
  }

  Future<void> _initDb() async {
    _db = await AppDatabase.getInstance();
    await _loadGoals();
    await _loadData();
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _loadGoals() async {
    _goalCalories =
        double.tryParse(await _db.getSetting('calorie_goal') ?? '') ?? 2000;
    _goalProtein =
        double.tryParse(await _db.getSetting('protein_goal') ?? '') ?? 100;
    _goalFat = double.tryParse(await _db.getSetting('fat_goal') ?? '') ?? 70;
    _goalCarbs =
        double.tryParse(await _db.getSetting('carbs_goal') ?? '') ?? 250;
    final showP = await _db.getSetting('show_protein');
    final showF = await _db.getSetting('show_fat');
    final showC = await _db.getSetting('show_carbs');
    _showProtein = showP != 'false';
    _showFat = showF != 'false';
    _showCarbs = showC != 'false';
  }

  Future<void> _loadData() async {
    final p = _period;
    final days = p.days;
    final now = DateTime.now();
    final data = <_DaySummary>[];
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final logs = await _db.getFoodLogsForDate(date);
      data.add(_DaySummary.fromLogs(date, logs));
    }
    _data = data;

    final previous = <_DaySummary>[];
    for (int i = days * 2 - 1; i >= days; i--) {
      final date = now.subtract(Duration(days: i));
      final logs = await _db.getFoodLogsForDate(date);
      previous.add(_DaySummary.fromLogs(date, logs));
    }
    _previousPeriodData = previous;

    await _loadStreakAndHistory();
    // Commit the period the data was loaded for. The chart's
    // bucketing reads `_dataPeriod`, never `_period` — so it can never
    // run the new period's logic on the previous period's `_data`.
    _dataPeriod = p;
  }

  /// Single backwards pass: counts the current streak AND records a
  /// `dayLogged` entry for every day in the last 12 weeks so the
  /// streak card can let the user swipe through past weeks of dots
  /// without re-querying the DB on each swipe.
  Future<void> _loadStreakAndHistory() async {
    final logged = <DateTime, bool>{};
    int streak = 0;
    bool counting = true;
    final start = DateTime.now();
    for (int i = 0; i < _streakHistoryDays; i++) {
      final date = start.subtract(Duration(days: i));
      final logs = await _db.getFoodLogsForDate(date);
      final has = logs.any((l) => l.calories > 0);
      logged[DateTime(date.year, date.month, date.day)] = has;
      if (counting) {
        if (has) {
          streak++;
        } else if (!(i == 0 && streak == 0)) {
          // Today empty → grace period; otherwise the streak ends.
          counting = false;
        }
      }
    }
    _streak = streak;
    _streakDayLogged = logged;
  }

  void _setPeriod(_Period p) async {
    if (p == _period) return;
    // Discrete-state haptic — same family iOS uses for picker wheels.
    HapticFeedback.selectionClick();
    // Update the period tab UI immediately so the tap feels responsive.
    setState(() => _period = p);
    await _loadData();
    if (!mounted) return;
    // Bump the refresh tick after the data lands — this re-keys the
    // animated subtree below, so the data sections re-mount and replay
    // their intro animations against the freshly-loaded values.
    setState(() => _refreshTick++);
  }

  String _fmtNum(double v) {
    final i = v.toInt();
    if (i >= 1000) {
      final s = i.toString();
      final b = StringBuffer();
      for (var k = 0; k < s.length; k++) {
        if (k > 0 && (s.length - k) % 3 == 0) b.write('\u{00A0}');
        b.write(s[k]);
      }
      return b.toString();
    }
    return i.toString();
  }

  String _fmtNumberWithComma(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (var k = 0; k < s.length; k++) {
      if (k > 0 && (s.length - k) % 3 == 0) b.write(',');
      b.write(s[k]);
    }
    return b.toString();
  }

  // ── Metric helpers ─────────────────────────────────────────
  double _metricValue(_DaySummary d, _ChartMetric m) => switch (m) {
    _ChartMetric.calories => d.calories,
    _ChartMetric.protein => d.protein,
    _ChartMetric.fat => d.fat,
    _ChartMetric.carbs => d.carbs,
  };

  double _metricGoal(_ChartMetric m) => switch (m) {
    _ChartMetric.calories => _goalCalories,
    _ChartMetric.protein => _goalProtein,
    _ChartMetric.fat => _goalFat,
    _ChartMetric.carbs => _goalCarbs,
  };

  String _metricLabel(_ChartMetric m) => switch (m) {
    _ChartMetric.calories => context.l10n.caloriesLabel,
    _ChartMetric.protein => context.l10n.proteinLabel,
    _ChartMetric.fat => context.l10n.fatLabel,
    _ChartMetric.carbs => context.l10n.carbsLabel,
  };

  String _metricTabLabel(_ChartMetric m) {
    final l10n = context.l10n;
    return switch (m) {
      _ChartMetric.calories => l10n.analyticsMetricCal,
      _ChartMetric.protein => l10n.analyticsMetricProtein,
      _ChartMetric.fat => l10n.analyticsMetricFat,
      _ChartMetric.carbs => l10n.analyticsMetricCarbs,
    };
  }


  /// Bar fill color for a given metric — mirrors `_DonutPainter` /
  /// `_CalorieRingPainter` so the trend bars and highlight bars share
  /// the same visual language as the macro donut. Calories stay green;
  /// fat yellow is darkened in light theme for legibility.
  Color _metricBarColor(_ChartMetric m) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (m) {
      _ChartMetric.calories => AppColors.green,
      _ChartMetric.protein => const Color(0xFFE4431C),
      _ChartMetric.fat => isDark
          ? const Color(0xFFEFD400)
          : const Color(0xFFC8A800),
      _ChartMetric.carbs => const Color(0xFF17ACCC),
    };
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppColors.darkBack2 : AppColors.lightBack2;
    final appBarBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(l10n.analyticsTitle),
        backgroundColor: appBarBg,
        surfaceTintColor: Colors.transparent,
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          // SingleChildScrollView + Column (instead of ListView) so the
          // animated children (donut, bars, count-ups) stay mounted while
          // the user scrolls. ListView recycles children that leave the
          // viewport — re-mounting them would replay the intro animation
          // every time the user scrolled back up, which felt janky.
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PeriodTabs(
                    current: _period,
                    onChanged: _setPeriod,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  // Period tabs sit OUTSIDE the keyed subtree — they
                  // own their own selection animation and shouldn't
                  // remount on data refresh. Everything below remounts
                  // each time `_refreshTick` bumps so intro animations
                  // replay against fresh data.
                  KeyedSubtree(
                    key: ValueKey(_refreshTick),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionTitle(text: l10n.summarySection),
                        const SizedBox(height: 12),
                        _buildSummaryRow(isDark),
                        // Macros progress card hidden for now —
                        // under review.
                        // const SizedBox(height: 12),
                        // _buildMacrosCard(isDark),
                        const SizedBox(height: 24),
                        _buildTrends(isDark),
                        const SizedBox(height: 24),
                        _buildHighlights(isDark),
                        const SizedBox(height: 24),
                        _buildByDays(isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Summary row (streak + average donut) ────────────────────

  Widget _buildSummaryRow(bool isDark) {
    final cal = _data.fold(0.0, (s, d) => s + d.calories);
    final nonEmptyDays = _data.where((d) => d.calories > 0).length;
    final divisor = nonEmptyDays == 0 ? 1 : nonEmptyDays;
    final avgCal = cal / divisor;

    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _StreakCard(
              streak: _streak,
              today: _today,
              dayLogged: _streakDayLogged,
              maxWeeks: _streakHistoryDays ~/ 7,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _AverageDonutCard(
              calories: avgCal,
              goal: _goalCalories,
            ),
          ),
        ],
      ),
    );
  }

  // ── Macros card (3 progress bars) ───────────────────────────
  // Currently hidden in `build()`; kept around so we can flip it back on
  // quickly without restoring it from git.

  // ignore: unused_element
  Widget _buildMacrosCard(bool isDark) {
    final cardBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final trackColor = isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    final secondary = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final primary = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final l10n = context.l10n;

    final nonEmptyDays = _data.where((d) => d.calories > 0).length;
    final divisor = nonEmptyDays == 0 ? 1 : nonEmptyDays;
    final avgProt = _data.fold(0.0, (s, d) => s + d.protein) / divisor;
    final avgFat = _data.fold(0.0, (s, d) => s + d.fat) / divisor;
    final avgCarbs = _data.fold(0.0, (s, d) => s + d.carbs) / divisor;

    final rows = <Widget>[];
    for (final m in MacroOrder.of(context)) {
      final include = switch (m) {
        Macro.protein => _showProtein,
        Macro.fat => _showFat,
        Macro.carbs => _showCarbs,
      };
      if (!include) continue;
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 20));
      rows.add(
        _MacroProgressRow(
          iconAsset: switch (m) {
            Macro.protein => 'assets/icons/belok.svg',
            Macro.fat => 'assets/icons/fat.svg',
            Macro.carbs => 'assets/icons/uglevod.svg',
          },
          current: switch (m) {
            Macro.protein => avgProt,
            Macro.fat => avgFat,
            Macro.carbs => avgCarbs,
          },
          goal: switch (m) {
            Macro.protein => _goalProtein,
            Macro.fat => _goalFat,
            Macro.carbs => _goalCarbs,
          },
          currentLabel: switch (m) {
            Macro.protein => '${avgProt.toInt()} ${l10n.proteinShort}',
            Macro.fat => '${avgFat.toInt()} ${l10n.fatShort}',
            Macro.carbs => '${avgCarbs.toInt()} ${l10n.carbsShort}',
          },
          goalLabel: switch (m) {
            Macro.protein => l10n.proteinGoalLabel(_goalProtein.toInt()),
            Macro.fat => l10n.fatGoalLabel(_goalFat.toInt()),
            Macro.carbs => l10n.carbsGoalLabel(_goalCarbs.toInt()),
          },
          gradient: switch (m) {
            Macro.protein => const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFD91D1D), Color(0xFFF0681B)],
              ),
            Macro.fat => const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFFFBB00), Color(0xFFD0FF00)],
              ),
            Macro.carbs => const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF17D1C7), Color(0xFF1787D1)],
              ),
          },
          trackColor: trackColor,
          labelColor: secondary,
          valueLabelColor: primary,
          cardColor: cardBg,
        ),
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    final lineColor = isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: lineColor),
        boxShadow: AppColors.baseDrop,
      ),
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }

  // ── Trends bucketing ───────────────────────────────────────
  //
  // Maps the raw daily data into bars for the trend chart. For longer
  // periods we aggregate (weekly for 3M/6M, monthly for 1Y) — daily bars
  // for those would each be < 1 px wide and visually collapse.

  List<_TrendBucket> _buildTrendBuckets(_ChartMetric metric) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final days = _data;
    if (days.isEmpty) return const [];

    // Two helpers keep the per-period blocks consistent.
    String dayLetter(DateTime d) =>
        DateFormat('E', localeCode).format(d).substring(0, 1).toUpperCase();
    // 3-letter weekday abbreviation, e.g. "Sun" / "Mon" / "Вс" / "Пн".
    String dayShort(DateTime d) {
      final raw = DateFormat('E', localeCode).format(d);
      return raw.length > 3 ? raw.substring(0, 3) : raw;
    }
    String monthAbbr(DateTime d) =>
        DateFormat('MMM', localeCode).format(d);

    // Use `_dataPeriod` (committed only after the async load lands)
    // rather than `_period` (the tab UI state) — otherwise during a
    // ~100 ms tap-to-load window we'd dispatch on the new period's
    // logic with the previous period's `_data`, briefly producing
    // wrong-shaped buckets and the visible "micro-flicker" on switch.
    switch (_dataPeriod) {
      // ── 1W: 7 bars, 3-letter weekday abbreviations — slot is wide
      //       enough (~40 px) for "Sun" / "Mon" / "Вс" / "Пн".
      case _Period.week:
        return [
          for (final d in days)
            _TrendBucket(
              value: _metricValue(d, metric),
              label: dayShort(d.date),
            ),
        ];

      // ── 2W: 14 bars, single-letter weekday — 3-letter would
      //       overlap on ~20 px slots.
      case _Period.twoWeeks:
        return [
          for (final d in days)
            _TrendBucket(
              value: _metricValue(d, metric),
              label: dayLetter(d.date),
            ),
        ];

      // ── 30 daily bars: weekly tick marks using the day-of-month
      //    number (e.g. "9 16 23 30 7"). The wrap from 30 → small
      //    number signals a month boundary without a separate label.
      case _Period.month:
        final last = days.length - 1;
        return [
          for (var i = 0; i < days.length; i++)
            _TrendBucket(
              value: _metricValue(days[i], metric),
              // Anchor the spacing on the latest bar so the rightmost
              // label sits exactly under "today" rather than drifting.
              label: (last - i) % 7 == 0
                  ? days[i].date.day.toString()
                  : '',
            ),
        ];

      // ── Weekly buckets (7-day chunks anchored on the latest day).
      //    Bucket value is the average daily metric across the chunk.
      //    Label rules:
      //      • first bucket → its own month abbreviation, so the chart
      //        starts with an anchor;
      //      • any later bucket that *contains the 1st of a new
      //        calendar month* → that month's abbreviation. Anchoring
      //        on the actual day of the month boundary (not on the
      //        chunk's start day) keeps the label spacing even —
      //        previously labels drifted depending on where chunks
      //        happened to fall.
      case _Period.threeMonths:
      case _Period.sixMonths:
        final buckets = <_TrendBucket>[];
        String? lastShown;
        for (var start = 0; start < days.length; start += 7) {
          final end = math.min(start + 7, days.length);
          final chunk = days.sublist(start, end);
          final avg =
              chunk.fold(0.0, (s, d) => s + _metricValue(d, metric)) /
                  chunk.length;

          String? label;
          // Find the day in this chunk that's the 1st of its month.
          DateTime? boundary;
          for (final d in chunk) {
            if (d.date.day == 1) {
              boundary = d.date;
              break;
            }
          }
          if (boundary != null) {
            label = monthAbbr(boundary);
          } else if (buckets.isEmpty) {
            label = monthAbbr(chunk.first.date);
          }
          if (label != null && label == lastShown) label = null;
          if (label != null) lastShown = label;

          buckets.add(_TrendBucket(
            value: avg,
            label: label ?? '',
          ));
        }
        return buckets;

      // ── 1Y: 12 monthly buckets. Label every OTHER month so the
      //       3-letter abbreviations don't crowd each other. Bucket
      //       value is the average daily metric for the month.
      case _Period.year:
        final byMonth = <String, List<_DaySummary>>{};
        for (final d in days) {
          final key =
              '${d.date.year}-${d.date.month.toString().padLeft(2, '0')}';
          byMonth.putIfAbsent(key, () => []).add(d);
        }
        final keys = byMonth.keys.toList()..sort();
        // Anchor the every-other-month pattern on the LAST bucket so
        // the rightmost (most recent) month always shows its label.
        final lastIdx = keys.length - 1;
        return [
          for (var i = 0; i < keys.length; i++)
            (() {
              final monthDays = byMonth[keys[i]]!;
              final avg = monthDays.fold(
                      0.0, (s, d) => s + _metricValue(d, metric)) /
                  monthDays.length;
              final showLabel = (lastIdx - i) % 2 == 0;
              return _TrendBucket(
                value: avg,
                label: showLabel ? monthAbbr(monthDays.first.date) : '',
              );
            })(),
        ];
    }
  }

  // ── Trends section (bar chart) ──────────────────────────────

  Widget _buildTrends(bool isDark) {
    final cardBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final lineColor = isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    final primary = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final l10n = context.l10n;

    final buckets = _buildTrendBuckets(_trendMetric);
    final goal = _metricGoal(_trendMetric);
    // Average % is over RAW daily values so the headline stays
    // comparable across periods (a weekly bucket's average doesn't
    // double-count vs. a daily bar's value).
    final dailyValues =
        _data.map((d) => _metricValue(d, _trendMetric)).toList();
    final nonEmpty = dailyValues.where((v) => v > 0).length;
    final avg = nonEmpty == 0
        ? 0.0
        : dailyValues.fold(0.0, (s, v) => s + v) / nonEmpty;
    final avgPercent = goal > 0
        ? (avg / goal * 100).clamp(0, 999).toInt()
        : 0;

    final localeCode = Localizations.localeOf(context).languageCode;
    final dateFormat = DateFormat('d MMM', localeCode);
    final firstDate = _data.isNotEmpty
        ? _data.first.date
        : DateTime.now().subtract(Duration(days: _period.days - 1));
    final lastDate = _data.isNotEmpty ? _data.last.date : DateTime.now();
    final dateRange =
        '${dateFormat.format(firstDate)} - ${dateFormat.format(lastDate)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeaderWithTabs(
          title: l10n.trendsSection,
          metric: _trendMetric,
          onChanged: (m) {
            if (m == _trendMetric) return;
            HapticFeedback.selectionClick();
            setState(() => _trendMetric = m);
          },
          tabLabelBuilder: _metricTabLabel,
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: lineColor),
            boxShadow: AppColors.baseDrop,
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dateRange,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 18 / 14,
                        color: isDark
                            ? AppColors.darkOnSurfaceVariant
                            : AppColors.lightOnSurfaceVariant,
                      ),
                    ),
                  ),
                  // Pill flips from green to red-orange once the period
                  // average crosses the 100 % goal mark — same warning
                  // language used by the trend chart's red overshoot top.
                  Builder(builder: (context) {
                    final overGoal = avgPercent > 100;
                    final pillColor =
                        overGoal ? AppColors.error : AppColors.green;
                    return AnimatedContainer(
                      duration: _kSwitchDur,
                      curve: _kCurve,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: pillColor.withAlpha(40),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: avgPercent.toDouble()),
                        duration: _kIntroDur,
                        curve: _kCurve,
                        builder: (_, value, _) =>
                            AnimatedDefaultTextStyle(
                          duration: _kSwitchDur,
                          curve: _kCurve,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 14 / 12,
                            color: pillColor,
                          ),
                          child: Text(l10n.percentAverage(value.round())),
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: _TrendsBarChart(
                  buckets: buckets,
                  goal: goal,
                  period: _period,
                  isDark: isDark,
                  barColor: primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Highlights section ──────────────────────────────────────

  Widget _buildHighlights(bool isDark) {
    final cardBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final lineColor = isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    final l10n = context.l10n;
    final secondary = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final primary = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;

    final currentNonEmpty = _data.where((d) => d.calories > 0).length;
    final previousNonEmpty = _previousPeriodData
        .where((d) => d.calories > 0)
        .length;

    final curDiv = currentNonEmpty == 0 ? 1 : currentNonEmpty;
    final prevDiv = previousNonEmpty == 0 ? 1 : previousNonEmpty;

    final curAvg =
        _data.fold(0.0, (s, d) => s + _metricValue(d, _highlightMetric)) /
        curDiv;
    final prevAvg =
        _previousPeriodData.fold(
          0.0,
          (s, d) => s + _metricValue(d, _highlightMetric),
        ) /
        prevDiv;

    final diff = curAvg - prevAvg;
    final hasPrevious = previousNonEmpty > 0 && prevAvg > 0;
    final percentChange = hasPrevious ? (diff / prevAvg * 100).round() : 0;
    final isHigher = hasPrevious && diff > 0;
    final isLower = hasPrevious && diff < 0;

    final metricLabelLower = _metricLabel(_highlightMetric).toLowerCase();

    final description = !hasPrevious
        ? l10n.analyticsHighlightSimilar(metricLabelLower)
        : isHigher
        ? l10n.analyticsHighlightHigher(metricLabelLower)
        : isLower
        ? l10n.analyticsHighlightLower(metricLabelLower)
        : l10n.analyticsHighlightSimilar(metricLabelLower);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeaderWithTabs(
          title: l10n.highlightsSection,
          metric: _highlightMetric,
          onChanged: (m) {
            if (m == _highlightMetric) return;
            HapticFeedback.selectionClick();
            setState(() => _highlightMetric = m);
          },
          tabLabelBuilder: _metricTabLabel,
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: lineColor),
            boxShadow: AppColors.baseDrop,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + metric name. Cross-fade when the highlight metric
              // changes so the orange "Calories"/"Protein"/etc. label swaps
              // smoothly instead of snapping.
              AnimatedSwitcher(
                duration: _kSwitchDur,
                switchInCurve: _kCurve,
                switchOutCurve: Curves.easeInCubic,
                child: Text(
                  _metricLabel(_highlightMetric),
                  key: ValueKey(_highlightMetric),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 18 / 14,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Description text — cross-fade between trend phrasings
              // (higher / lower / similar).
              AnimatedSwitcher(
                duration: _kSwitchDur,
                switchInCurve: _kCurve,
                switchOutCurve: Curves.easeInCubic,
                child: Text(
                  description,
                  key: ValueKey(description),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 18 / 14,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Two stacked bars compare the current period to the
              // previous one (or to the goal when there's no previous
              // period). The larger of the two values gets the full bar
              // width, the smaller is proportionally shorter. Current is
              // always green; reference is gray.
              ..._buildHighlightBars(
                curAvg: curAvg,
                prevAvg: prevAvg,
                hasPrevious: hasPrevious,
                isHigher: isHigher,
                percentChange: percentChange,
                diffAbs: diff.abs(),
                primary: primary,
                secondary: secondary,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildHighlightBars({
    required double curAvg,
    required double prevAvg,
    required bool hasPrevious,
    required bool isHigher,
    required int percentChange,
    required double diffAbs,
    required Color primary,
    required Color secondary,
    required bool isDark,
  }) {
    final goal = _metricGoal(_highlightMetric);

    final grayColor = isDark
        ? AppColors.darkSecondaryExtraLight
        : AppColors.lightSecondaryExtraLight;
    // Current bar takes the metric's macro color (mirrors the donut):
    // green for calories, red-orange for protein, yellow for fat, teal
    // for carbs. The +/- direction is communicated by the description
    // text + sign in the pill, so the bar color stays "ours" regardless
    // of whether the user is above or below last week.
    final fillColor = primary;

    if (!hasPrevious) {
      // No previous period to compare against → render the current value
      // as a green fill stacked on top of a half-transparent gray track
      // that represents the user's goal, like a classic progress bar.
      final goalSafe = goal <= 0 ? 1.0 : goal;
      final fillFrac = (curAvg / goalSafe).clamp(0.0, 1.0);
      return [
        _buildHighlightRow(
          value: curAvg,
          widthFraction: fillFrac,
          barColor: fillColor,
          pillText: null,
          primary: primary,
          secondary: secondary,
          showValueText: true,
          trackColor: grayColor.withValues(alpha: 0.5),
        ),
      ];
    }

    // Has a previous period → match the original mockup: two stacked rows
    // (current on top, previous below). The larger value owns the full
    // bar width; the smaller is proportionally shorter.
    final ref = math.max(curAvg, prevAvg);
    final refSafe = ref <= 0 ? 1.0 : ref;
    final currentFrac = (curAvg / refSafe).clamp(0.0, 1.0);
    final prevFrac = (prevAvg / refSafe).clamp(0.0, 1.0);

    final currentPillText = '${percentChange >= 0 ? '+' : ''}$percentChange%';

    return [
      _buildHighlightRow(
        value: curAvg,
        widthFraction: currentFrac,
        barColor: fillColor,
        pillText: currentPillText,
        primary: primary,
        secondary: secondary,
        showValueText: true,
      ),
      const SizedBox(height: 16),
      _buildHighlightRow(
        value: prevAvg,
        widthFraction: prevFrac,
        barColor: grayColor,
        // Diff pill on the previous-period bar removed per design —
        // the +/-% pill on the current bar already conveys the delta.
        pillText: null,
        primary: primary,
        secondary: secondary,
        showValueText: true,
      ),
    ];
  }

  // Currently unused; kept for the "diff pill" callsite that was
  // removed per design feedback. Restore alongside it if the pill
  // comes back.
  // ignore: unused_element
  String _metricShort(_ChartMetric m) => switch (m) {
    _ChartMetric.calories => 'cal',
    _ChartMetric.protein => context.l10n.proteinShort,
    _ChartMetric.fat => context.l10n.fatShort,
    _ChartMetric.carbs => context.l10n.carbsShort,
  };

  Widget _buildHighlightRow({
    required double value,
    required double widthFraction,
    required Color barColor,
    required String? pillText,
    required Color primary,
    required Color secondary,
    required bool showValueText,
    Color? trackColor,
  }) {
    final l10n = context.l10n;
    final metric = _highlightMetric;

    String formatValue(double v) {
      return metric == _ChartMetric.calories
          ? _fmtNum(v)
          : v.toInt().toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showValueText) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: _kIntroDur,
                curve: _kCurve,
                builder: (_, v, _) => Text(
                  formatValue(v),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 32 / 24,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l10n.averageADay,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 18 / 14,
                    color: secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        _HighlightBar(
          widthFraction: widthFraction,
          color: barColor,
          text: pillText,
          trackColor: trackColor,
        ),
      ],
    );
  }

  // ── By days section ─────────────────────────────────────────

  Widget _buildByDays(bool isDark) {
    final cardBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final lineColor = isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    final secondary = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final primary = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final divider = isDark ? AppColors.lineDT100 : AppColors.lineLight200;
    final l10n = context.l10n;

    final recent = _data.reversed.take(_period.days).toList();
    final localeCode = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(text: l10n.byDays),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: lineColor),
            boxShadow: AppColors.baseDrop,
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: List.generate(recent.length, (i) {
              final day = recent[i];
              final percent = _goalCalories > 0
                  ? (day.calories / _goalCalories * 100).round()
                  : 0;
              final isOver = percent > 100;
              final isEmpty = day.calories == 0;

              final dayOfWeek = DateFormat('E', localeCode).format(day.date);
              final capitalized =
                  dayOfWeek[0].toUpperCase() + dayOfWeek.substring(1);
              final dayMonth = DateFormat('MMM dd', localeCode).format(day.date);
              final dateLabel = '$capitalized, $dayMonth';

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateLabel,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  height: 20 / 15,
                                  color: primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.totalGrams(day.totalGrams.toInt()),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  height: 14 / 12,
                                  color: secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  // Short calorie unit (Cal / Ккал / etc.).
                                  // NB: never derive this with substring on
                                  // `caloriesLabel` — for ru the result is
                                  // "Кал", which has an unfortunate other
                                  // meaning. Always use the localized short.
                                  isEmpty
                                      ? '—'
                                      : '${_fmtNumberWithComma(day.calories.toInt())} ${l10n.analyticsMetricCal}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    height: 20 / 15,
                                    color: isEmpty ? secondary : primary,
                                  ),
                                ),
                                if (!isEmpty) ...[
                                  Text(
                                    ' · ',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      height: 20 / 15,
                                      color: primary,
                                    ),
                                  ),
                                  Text(
                                    '$percent%',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      height: 20 / 15,
                                      color: isOver
                                          ? AppColors.error
                                          : primary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                for (final m in MacroOrder.of(context))
                                  switch (m) {
                                    Macro.protein =>
                                      '${l10n.proteinShort}${day.protein.toInt()}',
                                    Macro.fat =>
                                      '${l10n.fatShort}${day.fat.toInt()}',
                                    Macro.carbs =>
                                      '${l10n.carbsShort}${day.carbs.toInt()}',
                                  },
                              ].join(' '),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                height: 14 / 12,
                                color: secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (i < recent.length - 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Container(height: 1, color: divider),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ── Section title ────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 24 / 18,
        color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
      ),
    );
  }
}

// ── Section header with metric tabs ──────────────────────────────

class _SectionHeaderWithTabs extends StatelessWidget {
  final String title;
  final _ChartMetric metric;
  final ValueChanged<_ChartMetric> onChanged;
  final String Function(_ChartMetric) tabLabelBuilder;
  final bool isDark;

  const _SectionHeaderWithTabs({
    required this.title,
    required this.metric,
    required this.onChanged,
    required this.tabLabelBuilder,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SectionTitle(text: title)),
        _MetricTabs(
          current: metric,
          onChanged: onChanged,
          labelBuilder: tabLabelBuilder,
          isDark: isDark,
        ),
      ],
    );
  }
}

// ── Period tabs (1W…1Y) ──────────────────────────────────────────

class _PeriodTabs extends StatelessWidget {
  final _Period current;
  final ValueChanged<_Period> onChanged;
  final bool isDark;

  const _PeriodTabs({
    required this.current,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return _SegmentedSwitch<_Period>(
      values: _Period.values,
      current: current,
      onChanged: onChanged,
      labelBuilder: (p) => p.label(context),
      isDark: isDark,
      height: 30,
      fontSize: 14,
      lineHeight: 20 / 14,
      indicatorRadius: 8,
    );
  }
}

// ── Metric tabs (Cal/Prot/Fats/Crbs) ─────────────────────────────

class _MetricTabs extends StatelessWidget {
  final _ChartMetric current;
  final ValueChanged<_ChartMetric> onChanged;
  final String Function(_ChartMetric) labelBuilder;
  final bool isDark;

  const _MetricTabs({
    required this.current,
    required this.onChanged,
    required this.labelBuilder,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: _SegmentedSwitch<_ChartMetric>(
        values: _ChartMetric.values,
        current: current,
        onChanged: onChanged,
        labelBuilder: labelBuilder,
        isDark: isDark,
        height: 26,
        fontSize: 13,
        lineHeight: 16 / 13,
        indicatorRadius: 7,
        cellPadding: const EdgeInsets.symmetric(horizontal: 6),
      ),
    );
  }
}

// Single sliding-indicator segmented control. One pill smoothly tweens
// between cells instead of cross-fading every cell on every tap.
class _SegmentedSwitch<T> extends StatelessWidget {
  final List<T> values;
  final T current;
  final ValueChanged<T> onChanged;
  final String Function(T) labelBuilder;
  final bool isDark;
  final double height;
  final double fontSize;
  final double lineHeight;
  final double indicatorRadius;
  final EdgeInsetsGeometry cellPadding;

  const _SegmentedSwitch({
    required this.values,
    required this.current,
    required this.onChanged,
    required this.labelBuilder,
    required this.isDark,
    required this.height,
    required this.fontSize,
    required this.lineHeight,
    required this.indicatorRadius,
    this.cellPadding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isDark ? AppColors.darkSurface : AppColors.lightScaffold;
    final selectedBg =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final selectedText =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final unselectedText = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    final n = values.length;
    final idx = values.indexOf(current).clamp(0, n - 1);
    final alignX = n <= 1 ? 0.0 : (idx * 2 / (n - 1)) - 1;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            AnimatedAlign(
              alignment: Alignment(alignX, 0),
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: FractionallySizedBox(
                widthFactor: 1 / n,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: selectedBg,
                    borderRadius: BorderRadius.circular(indicatorRadius),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A050C26),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: values.map((v) {
                final selected = v == current;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(v),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: cellPadding,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w500,
                            height: lineHeight,
                            color: selected ? selectedText : unselectedText,
                          ),
                          child: Text(
                            labelBuilder(v),
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── First-day-of-week table ──────────────────────────────────────
//
// Device-locale-driven mapping. Mirrors CLDR's `firstDay` data:
//   • Saturday  — most of the Middle East / North Africa (AE, EG, SA …)
//   • Sunday    — North & Latin America, Israel, Japan, Korea, parts of
//                 South / South-East Asia, Southern Africa
//   • Monday    — everything else (ISO 8601 default: Europe, AU/NZ,
//                 most of Africa, China, Russia, Vietnam …)
//
// Returns 0 = Sunday, 1 = Monday, …, 6 = Saturday — same convention
// as `MaterialLocalizations.firstDayOfWeekIndex`.
int _firstDayOfWeekForRegion(String? countryCode) {
  final c = countryCode?.toUpperCase();
  if (c == null) return 1;
  const saturday = {
    'AE', 'BH', 'DJ', 'DZ', 'EG', 'IQ', 'JO', 'KW', 'LY',
    'MA', 'OM', 'QA', 'SA', 'SD', 'SY', 'YE',
  };
  const sunday = {
    'AR', 'BD', 'BO', 'BR', 'CA', 'CL', 'CO', 'CR', 'DO', 'EC',
    'GT', 'HK', 'HN', 'IL', 'IN', 'JM', 'JP', 'KE', 'KR', 'MO',
    'MX', 'NI', 'PA', 'PE', 'PH', 'PK', 'PR', 'PY', 'SG', 'SV',
    'TH', 'TW', 'US', 'UY', 'VE', 'ZA', 'ZW',
  };
  if (saturday.contains(c)) return 6;
  if (sunday.contains(c)) return 0;
  return 1; // Monday (ISO 8601 — default for Europe, RU, AU, CN, …).
}

// ── Streak card ──────────────────────────────────────────────────
//
// Matches Figma node 6495:32486 (174.5×166 frame):
//  • Flame group: 63×48 at (54, 12)         — assets/icons/flame.svg
//  • "27" text:   center, top=53.55, font 28/36 bold, color #FBAE2E
//  • "Day Streak" label: center, top=88.55, Inter Medium 15/20, #FBAE2E
//  • Day letters: row width 154 at top=116.55, Inter SemiBold 12/14
//                 color Text/Icons Secondary (#686f87 dark / #83899f light)
//  • Check dots:  row width 154 at top=134.55, 7×20 dots, gap 2px
//                 filled = orange #FBAE2E circle + white check
//                 empty  = Text/Icons Secondary Light (#4d546b dark) outline

class _StreakCard extends StatefulWidget {
  final int streak;
  final DateTime today;
  final Map<DateTime, bool> dayLogged;
  final int maxWeeks;

  const _StreakCard({
    required this.streak,
    required this.today,
    required this.dayLogged,
    required this.maxWeeks,
  });

  @override
  State<_StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<_StreakCard> {
  late PageController _pages;
  // Actual number of pages: clamps to the oldest week within the
  // history window that has at least one logged day. If the user has
  // only logged today there's just one page; the PageView still bounces
  // when swiped (BouncingScrollPhysics) so the gesture is acknowledged.
  // Defaults are non-`late` so hot reload — which doesn't replay
  // `initState` — can't blow up with `LateInitializationError`.
  int _pageCount = 1;
  int _firstDayOfWeek = 1;
  DateTime _currentWeekStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    _recompute();
    _pages = PageController(initialPage: _pageCount - 1);
  }

  @override
  void didUpdateWidget(covariant _StreakCard old) {
    super.didUpdateWidget(old);
    if (old.dayLogged != widget.dayLogged ||
        old.maxWeeks != widget.maxWeeks ||
        !_isSameDay(old.today, widget.today)) {
      _recompute();
      _pages.dispose();
      _pages = PageController(initialPage: _pageCount - 1);
    }
  }

  /// Recomputes `_pageCount`, `_firstDayOfWeek`, `_currentWeekStart`
  /// from the latest props. Pages = (oldest-week-with-data, current).
  void _recompute() {
    final deviceLocale =
        WidgetsBinding.instance.platformDispatcher.locale;
    _firstDayOfWeek =
        _firstDayOfWeekForRegion(deviceLocale.countryCode);
    final today = widget.today;
    final todayDow = today.weekday % 7;
    final daysSinceStart = (todayDow - _firstDayOfWeek + 7) % 7;
    _currentWeekStart =
        today.subtract(Duration(days: daysSinceStart));

    int oldestWeekBack = 0;
    for (int wb = 1; wb < widget.maxWeeks; wb++) {
      final ws = _currentWeekStart.subtract(Duration(days: wb * 7));
      var hasLog = false;
      for (int j = 0; j < 7; j++) {
        final d = ws.add(Duration(days: j));
        final key = DateTime(d.year, d.month, d.day);
        if (widget.dayLogged[key] == true) {
          hasLog = true;
          break;
        }
      }
      if (hasLog) oldestWeekBack = wb;
    }
    _pageCount = oldestWeekBack + 1;
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// Week-start date for the page at [index] (0 = oldest, maxWeeks-1 = current).
  DateTime _weekStartFor(int index) {
    final weeksBack = _pageCount - 1 - index;
    return _currentWeekStart.subtract(Duration(days: weeksBack * 7));
  }

  @override
  Widget build(BuildContext context) {
    // Always rerun on build — `_recompute` is idempotent (depends only
    // on widget props) and cheap (≤ 12 × 7 map lookups). Doing it here
    // means hot reload, which doesn't replay `initState`, can't leave
    // stale defaults like `_currentWeekStart = DateTime.now()` on the
    // existing state.
    _recompute();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final lineColor = isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    final letterColor = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    final localeCode = Localizations.localeOf(context).languageCode;

    return Container(
      height: 182,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: lineColor),
        boxShadow: AppColors.baseDrop,
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final cardW = constraints.maxWidth;
          // See `_StreakCard` block in earlier commit for sizing math.
          const figmaRowW = 154.0;
          const minSideMargin = 12.0;
          final maxRowW =
              (cardW - 2 * minSideMargin).clamp(0.0, figmaRowW);
          final daysRowW = maxRowW;
          final scale = figmaRowW > 0 ? daysRowW / figmaRowW : 1.0;
          final dotSize = (20.0 * scale).clamp(12.0, 20.0);
          final letterFont = (12.0 * scale).clamp(9.0, 12.0);
          final letterLineH = (14.0 * scale).clamp(11.0, 14.0);

          return Stack(
            children: [
              // Flame group (63×48 at top=12, centered horizontally)
              Positioned(
                top: 12,
                left: (cardW - 63) / 2,
                width: 63,
                height: 48,
                child: SvgPicture.asset(
                  'assets/icons/flame.svg',
                  width: 63,
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
              // Number + "Day Streak" label
              Positioned(
                top: 53.55,
                left: 0,
                right: 0,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: widget.streak.toDouble()),
                  duration: _kIntroDur,
                  curve: _kCurve,
                  builder: (_, value, _) {
                    final n = value.round();
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          n.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 36 / 28,
                            color: isDark
                                ? AppColors.darkOnSurface
                                : AppColors.lightOnSurface,
                          ),
                        ),
                        Text(
                          context.l10n.dayStreak(n),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 20 / 15,
                            color: isDark
                                ? AppColors.darkOnSurface
                                : AppColors.lightOnSurface,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Swipeable letters + dots — one page per week of
              // history. We cap pages at the oldest week that has any
              // logged day, so the user can't swipe back into a stretch
              // of empty weeks. `BouncingScrollPhysics` gives an
              // elastic snap-back at both edges (and even on a
              // single-page card), so a swipe that has nowhere to go
              // still answers with "we tried".
              Positioned(
                top: 116.55,
                left: 0,
                right: 0,
                height: 38,
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _pageCount,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  itemBuilder: (context, index) {
                    final weekStart = _weekStartFor(index);
                    return _StreakWeekRow(
                      weekStart: weekStart,
                      today: widget.today,
                      dayLogged: widget.dayLogged,
                      rowWidth: daysRowW,
                      dotSize: dotSize,
                      letterFont: letterFont,
                      letterLineH: letterLineH,
                      letterColor: letterColor,
                      localeCode: localeCode,
                      isDark: isDark,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One week's row of day-of-week letters + filled/empty dots,
/// rendered inside the streak card's PageView. Stateless — the card
/// state owns the controller and the per-day "logged?" map.
class _StreakWeekRow extends StatelessWidget {
  final DateTime weekStart;
  final DateTime today;
  final Map<DateTime, bool> dayLogged;
  final double rowWidth;
  final double dotSize;
  final double letterFont;
  final double letterLineH;
  final Color letterColor;
  final String localeCode;
  final bool isDark;

  const _StreakWeekRow({
    required this.weekStart,
    required this.today,
    required this.dayLogged,
    required this.rowWidth,
    required this.dotSize,
    required this.letterFont,
    required this.letterLineH,
    required this.letterColor,
    required this.localeCode,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final letters = <String>[];
    final filled = <bool>[];
    for (int i = 0; i < 7; i++) {
      final d = weekStart.add(Duration(days: i));
      letters.add(
        DateFormat('E', localeCode).format(d).substring(0, 1).toUpperCase(),
      );
      final key = DateTime(d.year, d.month, d.day);
      final isFuture = d.isAfter(today) &&
          !(d.year == today.year &&
              d.month == today.month &&
              d.day == today.day);
      filled.add(!isFuture && (dayLogged[key] ?? false));
    }

    return Center(
      child: SizedBox(
        width: rowWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: letterLineH,
              child: Row(
                children: List.generate(7, (i) {
                  return Expanded(
                    child: Text(
                      letters[i],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontSize: letterFont,
                        fontWeight: FontWeight.w600,
                        height: letterLineH / letterFont,
                        color: letterColor,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: dotSize,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  return _StreakDot(
                    filled: filled[i],
                    isDark: isDark,
                    size: dotSize,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakDot extends StatelessWidget {
  final bool filled;
  final bool isDark;
  final double size;
  const _StreakDot({
    required this.filled,
    required this.isDark,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    // The bundled SVGs are baked for the dark theme (#FBAE2E filled,
    // #4D546B empty). On the light card surface the empty dots read too
    // heavy and the orange goes a touch washed-out, so we re-tint via
    // ColorFilter.srcIn — which only repaints the visible (non-transparent)
    // pixels, leaving the cut-out check inside the filled dot showing
    // through to the card background as before.
    final Color tint = filled
        ? (isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface)
        : (isDark
            ? AppColors.darkSecondaryExtraLight
            : AppColors.lightSecondaryExtraLight);
    return SvgPicture.asset(
      filled
          ? 'assets/icons/streak_dot_done.svg'
          : 'assets/icons/streak_dot_empty.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
    );
  }
}

// ── Average donut card ───────────────────────────────────────────

class _AverageDonutCard extends StatelessWidget {
  final double calories;
  final double goal;

  const _AverageDonutCard({
    required this.calories,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final lineColor = isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    final primary = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final secondary = isDark
        ? AppColors.darkSecondaryDark
        : AppColors.lightSecondaryDark;
    final trackColor = isDark ? AppColors.lineDT100 : AppColors.lineLight100;

    final double progress =
        goal > 0 ? (calories / goal).clamp(0.0, 1.0).toDouble() : 0.0;

    return Container(
      height: 182,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: lineColor),
        boxShadow: AppColors.baseDrop,
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                width: 110,
                height: 110,
                child: _AnimatedDonut(
                  progress: progress,
                  calories: calories,
                  trackColor: trackColor,
                  fillColor: primary,
                  primary: primary,
                  secondary: secondary,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              context.l10n.averageLabel,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 20 / 15,
                color: primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps the donut painter + its centre label and lerps every value
/// (arc fractions and the calorie counter) towards their new targets
/// on each rebuild — same convention as `_overviewIntro` in the meal
/// result sheet.
class _AnimatedDonut extends StatefulWidget {
  final double progress;
  final double calories;
  final Color trackColor;
  final Color fillColor;
  final Color primary;
  final Color secondary;

  const _AnimatedDonut({
    required this.progress,
    required this.calories,
    required this.trackColor,
    required this.fillColor,
    required this.primary,
    required this.secondary,
  });

  @override
  State<_AnimatedDonut> createState() => _AnimatedDonutState();
}

class _AnimatedDonutState extends State<_AnimatedDonut>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late Animation<double> _curve;

  // Snapshot of the values the donut is currently displaying. We tween
  // from this snapshot to the latest widget values so period/metric
  // changes interpolate smoothly instead of snapping.
  double _fromProgress = 0;
  double _fromCalories = 0;

  double _toProgress = 0;
  double _toCalories = 0;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: _kIntroDur);
    _curve = CurvedAnimation(parent: _ctl, curve: _kCurve);
    _toProgress = widget.progress;
    _toCalories = widget.calories;
    _ctl.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedDonut old) {
    super.didUpdateWidget(old);
    final changed = old.progress != widget.progress ||
        old.calories != widget.calories;
    if (!changed) return;

    final t = _curve.value;
    _fromProgress = _lerp(_fromProgress, _toProgress, t);
    _fromCalories = _lerp(_fromCalories, _toCalories, t);

    _toProgress = widget.progress;
    _toCalories = widget.calories;

    _ctl.duration = _kDataDur;
    _ctl.forward(from: 0);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, _) {
        final t = _curve.value;
        final progress = _lerp(_fromProgress, _toProgress, t);
        final cal = _lerp(_fromCalories, _toCalories, t);
        return CustomPaint(
          painter: _DonutPainter(
            progress: progress,
            trackColor: widget.trackColor,
            fillColor: widget.fillColor,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  cal.round().toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 24 / 20,
                    color: widget.primary,
                  ),
                ),
                Text(
                  context.l10n.analyticsMetricCal,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 18 / 14,
                    color: widget.secondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color fillColor;

  static const _strokeWidth = 12.0;

  _DonutPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width, size.height) / 2 - _strokeWidth / 2;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);

    if (progress <= 0) return;

    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, fill);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.fillColor != fillColor;
}

// ── Macro progress row ───────────────────────────────────────────

class _MacroProgressRow extends StatelessWidget {
  final String iconAsset;
  final double current;
  final double goal;
  final String currentLabel;
  final String goalLabel;
  final LinearGradient gradient;
  final Color trackColor;
  final Color labelColor;
  final Color valueLabelColor;
  final Color cardColor;

  const _MacroProgressRow({
    required this.iconAsset,
    required this.current,
    required this.goal,
    required this.currentLabel,
    required this.goalLabel,
    required this.gradient,
    required this.trackColor,
    required this.labelColor,
    required this.valueLabelColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: SvgPicture.asset(iconAsset, width: 24, height: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MacroBar(
            current: current,
            goal: goal,
            gradient: gradient,
            currentLabel: currentLabel,
            goalLabel: goalLabel,
            trackColor: trackColor,
            labelColor: labelColor,
            valueLabelColor: valueLabelColor,
            cardColor: cardColor,
          ),
        ),
      ],
    );
  }
}

class _MacroBar extends StatelessWidget {
  final double current;
  final double goal;
  final LinearGradient gradient;
  final String currentLabel;
  final String goalLabel;
  final Color trackColor;
  final Color labelColor;
  final Color valueLabelColor;
  final Color cardColor;

  static const double _barHeight = 8;
  static const double _barTop = 4;
  static const double _markerHeight = 16;
  static const double _markerTop = 0;
  static const double _labelTop = 20;
  static const double _barRadius = 4;

  const _MacroBar({
    required this.current,
    required this.goal,
    required this.gradient,
    required this.currentLabel,
    required this.goalLabel,
    required this.trackColor,
    required this.labelColor,
    required this.valueLabelColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    final progressTarget =
        goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      height: 38,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final totalWidth = constraints.maxWidth;
          // Animate fill width and marker position together — re-tweens
          // from the currently-displayed progress to the new value when
          // the period switches.
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progressTarget),
            duration: _kIntroDur,
            curve: _kCurve,
            builder: (context, progress, _) {
              final fillWidth = totalWidth * progress;
              final markerX = totalWidth * progress;
              return _buildBar(
                totalWidth: totalWidth,
                fillWidth: fillWidth,
                markerX: markerX,
                progress: progress,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBar({
    required double totalWidth,
    required double fillWidth,
    required double markerX,
    required double progress,
  }) {
    return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: _barTop,
                child: Container(
                  height: _barHeight,
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: BorderRadius.circular(_barRadius),
                  ),
                ),
              ),
              if (progress > 0)
                Positioned(
                  left: 0,
                  top: _barTop,
                  child: Container(
                    width: fillWidth,
                    height: _barHeight,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(_barRadius),
                        bottomLeft: const Radius.circular(_barRadius),
                        topRight: progress >= 1.0
                            ? const Radius.circular(_barRadius)
                            : Radius.zero,
                        bottomRight: progress >= 1.0
                            ? const Radius.circular(_barRadius)
                            : Radius.zero,
                      ),
                    ),
                  ),
                ),
              if (progress > 0 && progress < 1.0)
                Positioned(
                  left: markerX - 0.75,
                  top: _markerTop,
                  child: Container(
                    width: 1.5,
                    height: _markerHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                top: _labelTop,
                child: Text(
                  '0',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 18 / 14,
                    color: labelColor,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: _labelTop,
                child: Text(
                  goalLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 18 / 14,
                    color: labelColor,
                  ),
                ),
              ),
        _PositionedValueLabel(
          markerX: markerX,
          totalWidth: totalWidth,
          label: currentLabel,
          color: valueLabelColor,
          bg: cardColor,
          top: _labelTop,
        ),
      ],
    );
  }
}

class _PositionedValueLabel extends StatelessWidget {
  final double markerX;
  final double totalWidth;
  final String label;
  final Color color;
  final Color bg;
  final double top;

  const _PositionedValueLabel({
    required this.markerX,
    required this.totalWidth,
    required this.label,
    required this.color,
    required this.bg,
    required this.top,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 18 / 14,
      color: color,
    );
    final tp = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final width = tp.width + 8;
    var left = markerX - width / 2;
    if (left < 0) left = 0;
    if (left + width > totalWidth) left = totalWidth - width;
    return Positioned(
      left: left,
      top: top,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        color: bg,
        child: Text(label, style: style),
      ),
    );
  }
}

// ── Highlight comparison bar ─────────────────────────────────────
//
// Pill-shaped horizontal bar used in the Highlights card. Width is a
// fraction of the parent's max width — the larger of the two compared
// values takes 1.0, the smaller takes its proportional share. A floor
// (`_minTextFraction`) keeps narrow bars wide enough to show their
// label. Width animates on metric/period switch via TweenAnimationBuilder.

class _HighlightBar extends StatelessWidget {
  final double widthFraction;
  final Color color;
  final String? text;

  /// When non-null, a full-width track is rendered behind the bar. Used
  /// for the "no previous period" case where the colored bar fills part
  /// of the goal track (classic progress-bar style).
  final Color? trackColor;

  // Bars narrower than this can't fit "−23%" / "5 cal" comfortably, so
  // we floor the fraction to keep the label readable. ≈ 60px on a
  // ~330px-wide card.
  static const double _minTextFraction = 0.18;
  static const double _height = 24;
  static const double _radius = 6;

  const _HighlightBar({
    required this.widthFraction,
    required this.color,
    required this.text,
    this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final maxW = constraints.maxWidth;
        final fraction = (text == null
                ? widthFraction
                : math.max(widthFraction, _minTextFraction))
            .clamp(0.0, 1.0);
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: fraction),
          duration: _kIntroDur,
          curve: _kCurve,
          builder: (_, f, _) {
            final fill = Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: _kSwitchDur,
                curve: _kCurve,
                width: maxW * f,
                height: _height,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(_radius),
                ),
                alignment: Alignment.centerLeft,
                child: text == null
                    ? null
                    : AnimatedSwitcher(
                        duration: _kSwitchDur,
                        switchInCurve: _kCurve,
                        switchOutCurve: Curves.easeInCubic,
                        child: Text(
                          text!,
                          key: ValueKey(text),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 14 / 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
            );

            if (trackColor == null) return fill;

            // Stack the colored fill on top of a full-width track, so the
            // green progress reads as filling up against the goal.
            return SizedBox(
              height: _height,
              width: double.infinity,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: trackColor,
                      borderRadius: BorderRadius.circular(_radius),
                    ),
                  ),
                  fill,
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Trends bar chart ─────────────────────────────────────────────

class _TrendsBarChart extends StatelessWidget {
  final List<_TrendBucket> buckets;
  final double goal;
  final _Period period;
  final bool isDark;
  final Color barColor;

  const _TrendsBarChart({
    required this.buckets,
    required this.goal,
    required this.period,
    required this.isDark,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final gridColor = isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    final secondary = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    final maxRaw = buckets.isEmpty
        ? 0.0
        : buckets
            .map((b) => b.value)
            .reduce((a, b) => a > b ? a : b);
    final goalAxis = goal > 0 ? goal : maxRaw;
    final chartMax = math.max(maxRaw, goalAxis) * 1.15;
    final safeMax = chartMax <= 0 ? 1.0 : chartMax;

    // Roughly 20 % of slot width as inter-bar gap, clamped so 7-bar
    // weeks breathe and 90-bar weekly views still fit. Without this,
    // periods with many bars used to render with negative-width slots
    // and the chart visually collapsed.
    final hasAnyLabel = buckets.any((b) => b.label.isNotEmpty);

    return LayoutBuilder(
      builder: (ctx, constraints) {
        const labelHeight = 14.0;
        // Breathing room between the bottom of each bar and the row
        // of x-axis labels — without it the labels visually clamp
        // against the bars on dense charts.
        const labelGap = 2.0;
        final yAxisWidth = 32.0;
        final chartHeight =
            constraints.maxHeight - labelHeight - labelGap;
        final chartWidth = constraints.maxWidth - yAxisWidth;
        final slotWidth = buckets.isEmpty ? 0.0 : chartWidth / buckets.length;
        final hPad = (slotWidth * 0.18).clamp(0.5, 8.0);

        return Stack(
          children: [
            // Horizontal grid lines
            Positioned(
              left: 0,
              right: yAxisWidth,
              top: 0,
              height: chartHeight,
              child: CustomPaint(
                painter: _GridPainter(
                  color: gridColor,
                  divisions: 4,
                ),
              ),
            ),
            // Goal dotted line
            if (goal > 0)
              Positioned(
                left: 0,
                right: yAxisWidth,
                top: chartHeight - (goal / safeMax * chartHeight),
                child: CustomPaint(
                  size: Size(chartWidth, 1),
                  painter: _DottedLinePainter(color: AppColors.error),
                ),
              ),
            // Bars
            Positioned(
              left: 0,
              right: yAxisWidth,
              top: 0,
              height: chartHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(buckets.length, (i) {
                  final v = buckets[i].value;
                  final overGoal = goal > 0 && v > goal;
                  final greenTarget = overGoal
                      ? goal / safeMax * chartHeight
                      : v / safeMax * chartHeight;
                  final redTarget = overGoal
                      ? (v - goal) / safeMax * chartHeight
                      : 0.0;
                  // Stagger only on shorter periods — for 90-bar charts a
                  // 5 %/bar offset would push the last bar's animation
                  // window past the duration entirely.
                  final stagger = buckets.length <= 14
                      ? (i * 0.05).clamp(0.0, 0.5)
                      : 0.0;
                  // Bars at 0 still want a visible tick so the chart
                  // doesn't show gaps for empty days.
                  const minVisibleBar = 2.0;
                  final radius = buckets.length <= 14 ? 4.0 : 2.0;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: greenTarget),
                        duration: _kIntroDur,
                        curve: Interval(stagger, 1, curve: _kCurve),
                        builder: (context, greenH, _) =>
                            TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: redTarget),
                          duration: _kIntroDur,
                          curve: Interval(stagger, 1, curve: _kCurve),
                          builder: (context, redH, _) {
                            final hasValue = v > 0;
                            final clampedGreen = hasValue
                                ? math
                                    .max(greenH, minVisibleBar)
                                    .clamp(0.0, chartHeight)
                                : greenH.clamp(0.0, chartHeight);
                            final clampedRed =
                                redH.clamp(0.0, chartHeight);
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (overGoal && clampedRed > 0.5)
                                  Container(
                                    height: clampedRed,
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(radius),
                                        topRight: Radius.circular(radius),
                                      ),
                                    ),
                                  ),
                                Container(
                                  height: clampedGreen,
                                  decoration: BoxDecoration(
                                    color: barColor,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(
                                          overGoal ? 0 : radius),
                                      topRight: Radius.circular(
                                          overGoal ? 0 : radius),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // Bucket labels — dynamic per-period content baked into
            // each bucket (day letter / date number / month abbrev).
            // Each label is positioned absolutely at its bucket's
            // x-center via Stack + FractionalTranslation, so a 3-letter
            // "Nov" label can render its full width even when the
            // bucket's slot is only 11 px wide on dense charts (which
            // would otherwise visually clip it inside an Expanded).
            if (hasAnyLabel)
              Positioned(
                left: 0,
                right: yAxisWidth,
                bottom: 0,
                height: labelHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i < buckets.length; i++)
                      if (buckets[i].label.isNotEmpty)
                        Positioned(
                          left: i * slotWidth + slotWidth / 2,
                          top: 0,
                          child: FractionalTranslation(
                            translation: const Offset(-0.5, 0),
                            child: Text(
                              buckets[i].label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                height: 12 / 10,
                                color: secondary,
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            // Y-axis labels (right side)
            Positioned(
              right: 0,
              top: 0,
              width: yAxisWidth,
              height: chartHeight,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: _YAxisLabels(
                  max: safeMax,
                  color: secondary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _YAxisLabels extends StatelessWidget {
  final double max;
  final Color color;
  const _YAxisLabels({required this.max, required this.color});

  String _format(double v) {
    if (v == 0) return '0';
    final i = v.toInt();
    if (i >= 1000) {
      final s = i.toString();
      final b = StringBuffer();
      for (var k = 0; k < s.length; k++) {
        if (k > 0 && (s.length - k) % 3 == 0) b.write('\u{00A0}');
        b.write(s[k]);
      }
      return b.toString();
    }
    return i.toString();
  }

  @override
  Widget build(BuildContext context) {
    final upper = max / 1.15;
    final mid = upper / 2;
    final style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      height: 12 / 10,
      color: color,
    );
    return Stack(
      children: [
        Positioned(top: 0, left: 0, child: Text(_format(upper), style: style)),
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          child: Center(child: Text(_format(mid), style: style)),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: Text('0', style: style),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  final int divisions;

  _GridPainter({required this.color, required this.divisions});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (int i = 0; i <= divisions; i++) {
      final y = size.height * (i / divisions);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.color != color;
}

class _DottedLinePainter extends CustomPainter {
  final Color color;
  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(180)
      ..strokeWidth = 1;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter old) => old.color != color;
}

// ── Data model ───────────────────────────────────────────────────

class _DaySummary {
  final DateTime date;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double totalGrams;

  _DaySummary({
    required this.date,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.totalGrams,
  });

  factory _DaySummary.fromLogs(DateTime date, List<FoodLog> logs) {
    return _DaySummary(
      date: date,
      calories: logs.fold(0.0, (s, l) => s + l.calories),
      protein: logs.fold(0.0, (s, l) => s + l.protein),
      fat: logs.fold(0.0, (s, l) => s + l.fat),
      carbs: logs.fold(0.0, (s, l) => s + l.carbs),
      totalGrams: logs.fold(0.0, (s, l) => s + l.grams),
    );
  }
}
