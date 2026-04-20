import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';

enum _ChartMetric { calories, protein, fat, carbs }

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late AppDatabase _db;
  bool _dbReady = false;
  List<_DaySummary> _data = [];
  int _periodDays = 7;
  double _goalCalories = 2000;
  double _goalProtein = 100;
  double _goalFat = 70;
  double _goalCarbs = 250;
  bool _showProtein = true;
  bool _showFat = true;
  bool _showCarbs = true;
  _ChartMetric _selectedMetric = _ChartMetric.calories;

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    _db = await AppDatabase.getInstance();
    await _loadGoals();
    await _loadData();
    if (mounted) setState(() => _dbReady = true);
  }

  Future<void> _loadGoals() async {
    _goalCalories =
        double.tryParse(await _db.getSetting('calorie_goal') ?? '') ?? 2000;
    _goalProtein =
        double.tryParse(await _db.getSetting('protein_goal') ?? '') ?? 100;
    _goalFat =
        double.tryParse(await _db.getSetting('fat_goal') ?? '') ?? 70;
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
    final now = DateTime.now();
    final data = <_DaySummary>[];

    for (int i = _periodDays - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final logs = await _db.getFoodLogsForDate(date);
      data.add(_DaySummary(
        date: date,
        calories: logs.fold(0.0, (s, l) => s + l.calories),
        protein: logs.fold(0.0, (s, l) => s + l.protein),
        fat: logs.fold(0.0, (s, l) => s + l.fat),
        carbs: logs.fold(0.0, (s, l) => s + l.carbs),
        totalGrams: logs.fold(0.0, (s, l) => s + l.grams),
      ));
    }

    _data = data;
  }

  void _setPeriod(int days) async {
    _periodDays = days;
    await _loadData();
    setState(() {});
  }

  // ── Helpers ──────────────────────────────────────────────────

  String _formatNumber(double value) {
    final intVal = value.toInt();
    if (intVal >= 1000) {
      final str = intVal.toString();
      final buffer = StringBuffer();
      for (var i = 0; i < str.length; i++) {
        if (i > 0 && (str.length - i) % 3 == 0) buffer.write('\u{00A0}');
        buffer.write(str[i]);
      }
      return buffer.toString();
    }
    return intVal.toString();
  }

  String _formatDayDate(DateTime date) {
    final locale = Localizations.localeOf(context).languageCode;
    final dayOfWeek = DateFormat('E', locale).format(date);
    final capitalized = dayOfWeek[0].toUpperCase() + dayOfWeek.substring(1);
    final dayMonth = DateFormat('d MMM', locale).format(date);
    return '$capitalized, $dayMonth';
  }

  // ── Metric maps ──────────────────────────────────────────────

  static const _metricGradients = <_ChartMetric, LinearGradient>{
    _ChartMetric.calories:
        LinearGradient(colors: [Color(0xFF22D33A), Color(0xFF1EBF92)]),
    _ChartMetric.protein:
        LinearGradient(colors: [Color(0xFFD91D1D), Color(0xFFF0681B)]),
    _ChartMetric.fat:
        LinearGradient(colors: [Color(0xFFD0FF00), Color(0xFFFFBB00)]),
    _ChartMetric.carbs:
        LinearGradient(colors: [Color(0xFF17D1C7), Color(0xFF1787D1)]),
  };

  static const _metricBarGradients = <_ChartMetric, LinearGradient>{
    _ChartMetric.calories: LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [Color(0xFF22D33A), Color(0xFF1EBF92)],
    ),
    _ChartMetric.protein: LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [Color(0xFFD91D1D), Color(0xFFF0681B)],
    ),
    _ChartMetric.fat: LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [Color(0xFFD0FF00), Color(0xFFFFBB00)],
    ),
    _ChartMetric.carbs: LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [Color(0xFF17D1C7), Color(0xFF1787D1)],
    ),
  };

  Map<_ChartMetric, String> _metricLabels(BuildContext context) => {
    _ChartMetric.calories: context.l10n.caloriesLabel,
    _ChartMetric.protein: context.l10n.proteinLabel,
    _ChartMetric.fat: context.l10n.fatLabel,
    _ChartMetric.carbs: context.l10n.carbsLabel,
  };

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_dbReady) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final nonEmptyDays = _data.where((d) => d.calories > 0).toList();
    final daysCount = nonEmptyDays.length;
    final avgCalories = daysCount > 0
        ? nonEmptyDays.fold(0.0, (s, d) => s + d.calories) / daysCount
        : 0.0;
    final avgProtein = daysCount > 0
        ? nonEmptyDays.fold(0.0, (s, d) => s + d.protein) / daysCount
        : 0.0;
    final avgFat = daysCount > 0
        ? nonEmptyDays.fold(0.0, (s, d) => s + d.fat) / daysCount
        : 0.0;
    final avgCarbs = daysCount > 0
        ? nonEmptyDays.fold(0.0, (s, d) => s + d.carbs) / daysCount
        : 0.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final scaffoldBg = isDark ? AppColors.darkBack2 : AppColors.lightBack2;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(context.l10n.statsTitle),
        backgroundColor: appBarBg,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 24),
          _buildSectionLabel(context.l10n.averageLabel),
          const SizedBox(height: 8),
          _buildAverageCard(avgCalories, avgProtein, avgFat, avgCarbs),
          const SizedBox(height: 24),
          _buildChartDropdown(),
          const SizedBox(height: 8),
          _buildSelectedBarChart(),
          const SizedBox(height: 24),
          _buildSectionLabel(context.l10n.byDays),
          const SizedBox(height: 8),
          _buildDaysCard(),
        ],
      ),
    );
  }

  // ── Section label ────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 18 / 14,
        color: color,
      ),
    );
  }

  // ── Period selector ──────────────────────────────────────────

  Widget _buildPeriodSelector() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkUnderBack : AppColors.lightUnderBack;

    final tabs = [
      (value: 7, label: context.l10n.periodWeek),
      (value: 14, label: context.l10n.period2Weeks),
      (value: 30, label: context.l10n.periodMonth),
    ];

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _periodDays == tab.value;
          return Expanded(
            child: GestureDetector(
              onTap: () => _setPeriod(tab.value),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? cs.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0x1A050C26),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
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
                      color:
                          isSelected ? cs.onSurface : cs.onSurfaceVariant,
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

  // ── Average card ─────────────────────────────────────────────

  Widget _buildAverageCard(
      double cal, double prot, double fat, double carbs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final lineBorder = isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    final trackColor = isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    final secondaryText =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;
    final primaryText =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;

    final rows = <Widget>[];

    rows.add(_buildIconProgressRow(
      icon: '🔥',
      current: cal,
      goal: _goalCalories,
      gradient: _metricGradients[_ChartMetric.calories]!,
      currentLabel: context.l10n.kcalValue(_formatNumber(cal)),
      goalLabel: context.l10n.kcalValue(_formatNumber(_goalCalories)),
      trackColor: trackColor,
      cardBg: cardBg,
      primaryText: primaryText,
      secondaryText: secondaryText,
    ));

    if (_showProtein) {
      rows.add(const SizedBox(height: 20));
      rows.add(_buildIconProgressRow(
        icon: '🥩',
        current: prot,
        goal: _goalProtein,
        gradient: _metricGradients[_ChartMetric.protein]!,
        currentLabel: '${prot.toInt()} ${context.l10n.proteinShort}',
        goalLabel: context.l10n.proteinGoalLabel(_goalProtein.toInt()),
        trackColor: trackColor,
        cardBg: cardBg,
        primaryText: primaryText,
        secondaryText: secondaryText,
      ));
    }

    if (_showFat) {
      rows.add(const SizedBox(height: 20));
      rows.add(_buildIconProgressRow(
        icon: '🥑',
        current: fat,
        goal: _goalFat,
        gradient: _metricGradients[_ChartMetric.fat]!,
        currentLabel: '${fat.toInt()} ${context.l10n.fatShort}',
        goalLabel: context.l10n.fatGoalLabel(_goalFat.toInt()),
        trackColor: trackColor,
        cardBg: cardBg,
        primaryText: primaryText,
        secondaryText: secondaryText,
      ));
    }

    if (_showCarbs) {
      rows.add(const SizedBox(height: 20));
      rows.add(_buildIconProgressRow(
        icon: '🍞',
        current: carbs,
        goal: _goalCarbs,
        gradient: _metricGradients[_ChartMetric.carbs]!,
        currentLabel: '${carbs.toInt()} ${context.l10n.carbsShort}',
        goalLabel: context.l10n.carbsGoalLabel(_goalCarbs.toInt()),
        trackColor: trackColor,
        cardBg: cardBg,
        primaryText: primaryText,
        secondaryText: secondaryText,
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lineBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: rows,
      ),
    );
  }

  Widget _buildIconProgressRow({
    required String icon,
    required double current,
    required double goal,
    required LinearGradient gradient,
    required String currentLabel,
    required String goalLabel,
    required Color trackColor,
    required Color cardBg,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: Center(
            child: Text(icon, style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatsProgressBar(
            current: current,
            goal: goal,
            gradient: gradient,
            currentLabel: currentLabel,
            goalLabel: goalLabel,
            trackColor: trackColor,
            labelColor: secondaryText,
            valueLabelColor: primaryText,
            cardColor: cardBg,
          ),
        ),
      ],
    );
  }

  // ── Chart dropdown ───────────────────────────────────────────

  Widget _buildChartDropdown() {
    return PopupMenuButton<_ChartMetric>(
      onSelected: (metric) => setState(() => _selectedMetric = metric),
      offset: const Offset(0, 4),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      position: PopupMenuPosition.under,
      tooltip: '',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _metricLabels(context)[_selectedMetric]!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 18 / 14,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.keyboard_arrow_down_rounded,
              size: 20, color: AppColors.primary),
        ],
      ),
      itemBuilder: (context) => _ChartMetric.values
          .map((m) => PopupMenuItem(
                value: m,
                child: Text(
                  _metricLabels(context)[m]!,
                  style: TextStyle(
                    fontWeight: m == _selectedMetric
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ))
          .toList(),
    );
  }

  // ── Bar chart ────────────────────────────────────────────────

  Widget _buildSelectedBarChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final lineBorder = isDark ? AppColors.lineDT100 : AppColors.lineLight100;

    List<double> values;
    double goal;

    switch (_selectedMetric) {
      case _ChartMetric.calories:
        values = _data.map((d) => d.calories).toList();
        goal = _goalCalories;
      case _ChartMetric.protein:
        values = _data.map((d) => d.protein).toList();
        goal = _goalProtein;
      case _ChartMetric.fat:
        values = _data.map((d) => d.fat).toList();
        goal = _goalFat;
      case _ChartMetric.carbs:
        values = _data.map((d) => d.carbs).toList();
        goal = _goalCarbs;
    }

    final gradient = _metricBarGradients[_selectedMetric]!;
    final maxVal = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);
    final chartMax = goal > maxVal ? goal * 1.1 : maxVal * 1.1;
    final showDayLabels = _periodDays <= 14;
    final showValueLabels = _periodDays <= 7;

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lineBorder, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barAreaHeight = constraints.maxHeight;
          final barMax =
              (barAreaHeight - 30).clamp(10.0, barAreaHeight);
          return Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(values.length, (i) {
                  final v = values[i];
                  final h =
                      (v / chartMax * barMax).clamp(2.0, barMax);
                  final isToday = i == values.length - 1;
                  final overGoal = v > goal;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: _periodDays <= 14 ? 3 : 1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (showValueLabels && v > 0)
                            Text(
                              v.toInt().toString(),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontSize: 9,
                                    color:
                                        overGoal ? AppColors.orange : null,
                                  ),
                            ),
                          const SizedBox(height: 2),
                          Container(
                            height: h,
                            decoration: BoxDecoration(
                              gradient: gradient,
                              borderRadius: BorderRadius.circular(
                                  _periodDays <= 14 ? 4 : 2),
                            ),
                            foregroundDecoration: !isToday
                                ? BoxDecoration(
                                    color: cardBg.withAlpha(120),
                                    borderRadius: BorderRadius.circular(
                                        _periodDays <= 14 ? 4 : 2),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 4),
                          if (showDayLabels)
                            Text(
                              DateFormat('E', Localizations.localeOf(context).languageCode)
                                  .format(_data[i].date)
                                  .substring(0, 2),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontSize: 9,
                                    fontWeight:
                                        isToday ? FontWeight.bold : null,
                                  ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              if (goal > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom:
                      (goal / chartMax * barMax).clamp(0, barMax),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.error.withAlpha(120),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        goal.toInt().toString(),
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.error.withAlpha(180),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── Days card ────────────────────────────────────────────────

  Widget _buildDaysCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final lineBorder = isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    final primaryText =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final secondaryText =
        isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;

    final recent = _data.reversed.take(7).toList();

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lineBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0x081B364A),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(recent.length, (i) {
          final day = recent[i];
          final percent = _goalCalories > 0
              ? (day.calories / _goalCalories * 100).toInt()
              : 0;
          final isEmpty = day.calories == 0;
          final calColor = isEmpty ? secondaryText : primaryText;

          return Padding(
            padding:
                EdgeInsets.only(bottom: i < recent.length - 1 ? 16 : 0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDayDate(day.date),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 20 / 15,
                        color: primaryText,
                      ),
                    ),
                    Text(
                      '${context.l10n.kcalValueInt(day.calories.toInt())} · $percent%',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 20 / 15,
                        color: calColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.totalGrams(day.totalGrams.toInt()),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 14 / 12,
                        color: secondaryText,
                      ),
                    ),
                    Text(
                      '${context.l10n.proteinShort}${day.protein.toInt()} ${context.l10n.fatShort}${day.fat.toInt()} ${context.l10n.carbsShort}${day.carbs.toInt()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 14 / 12,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Progress bar ─────────────────────────────────────────────────

class _StatsProgressBar extends StatelessWidget {
  final double current;
  final double goal;
  final LinearGradient gradient;
  final String currentLabel;
  final String goalLabel;
  final Color trackColor;
  final Color labelColor;
  final Color valueLabelColor;
  final Color cardColor;

  static const double _barHeight = 12;
  static const double _barTop = 2;
  static const double _markerHeight = 16;
  static const double _labelTop = 20;
  static const double _barRadius = 4;

  const _StatsProgressBar({
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
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      height: 38,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final fillWidth = totalWidth * progress;
          final markerX = totalWidth * progress;

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
                  top: 0,
                  child: Container(
                    width: 1.5,
                    height: _markerHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 2,
                        ),
                      ],
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
              _buildPositionedValueLabel(markerX, totalWidth),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPositionedValueLabel(double markerX, double totalWidth) {
    final textStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 18 / 14,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: currentLabel, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelWidth = textPainter.width + 8;
    final halfLabel = labelWidth / 2;

    double left = markerX - halfLabel;
    if (left < 0) left = 0;
    if (left + labelWidth > totalWidth) left = totalWidth - labelWidth;

    return Positioned(
      left: left,
      top: _labelTop,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        color: cardColor,
        child: Text(
          currentLabel,
          style: textStyle.copyWith(color: valueLabelColor),
        ),
      ),
    );
  }
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
}
