import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late AppDatabase _db;
  bool _dbReady = false;
  List<_HistoryDay> _days = [];

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    _db = await AppDatabase.getInstance();
    await _load();
    if (mounted) setState(() => _dbReady = true);
  }

  Future<void> _load() async {
    final dates = await _db.getLoggedDates(limit: 90);
    final days = <_HistoryDay>[];

    for (final date in dates) {
      final logs = await _db.getFoodLogsForDate(date);
      if (logs.isEmpty) continue;
      days.add(_HistoryDay(
        date: date,
        logs: logs,
        totalCalories: logs.fold(0.0, (s, l) => s + l.calories),
        totalProtein: logs.fold(0.0, (s, l) => s + l.protein),
        totalFat: logs.fold(0.0, (s, l) => s + l.fat),
        totalCarbs: logs.fold(0.0, (s, l) => s + l.carbs),
      ));
    }

    _days = days;
  }

  @override
  Widget build(BuildContext context) {
    if (!_dbReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.historyTitle)),
      body: _days.isEmpty
          ? Center(
              child: Text(context.l10n.noRecords, style: const TextStyle(color: Colors.grey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _days.length,
              itemBuilder: (context, index) => _buildDaySection(_days[index]),
            ),
    );
  }

  Widget _buildDaySection(_HistoryDay day) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(day.date.year, day.date.month, day.date.day);

    String dateLabel;
    if (d == today) {
      dateLabel = context.l10n.today;
    } else if (d == today.subtract(const Duration(days: 1))) {
      dateLabel = context.l10n.yesterday;
    } else {
      dateLabel = DateFormat('EEEE, d MMMM', Localizations.localeOf(context).languageCode).format(day.date);
      dateLabel = dateLabel[0].toUpperCase() + dateLabel.substring(1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 20 / 15,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Text(
                context.l10n.kcalValue(day.totalCalories.toInt().toString()),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ...day.logs.map((log) => _buildLogTile(log)),
      ],
    );
  }

  Widget _buildLogTile(FoodLog log) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cal = log.calories.toInt();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: _buildLogImage(log, isDark),
      title: Text(
        log.productName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${log.grams.toInt()} ${context.l10n.gramsUnit}  •  $cal ${context.l10n.kcalUnit}  •  '
        '${context.l10n.proteinShort}${log.protein.toStringAsFixed(1)} '
        '${context.l10n.fatShort}${log.fat.toStringAsFixed(1)} '
        '${context.l10n.carbsShort}${log.carbs.toStringAsFixed(1)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildLogImage(FoodLog log, bool isDark) {
    final url = log.imageUrl;

    if (url != null && url.isNotEmpty) {
      if (url.startsWith('/')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(url),
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholderIcon(isDark),
          ),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          placeholder: (_, __) => const SizedBox(
            width: 48,
            height: 48,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (_, __, ___) => _placeholderIcon(isDark),
        ),
      );
    }

    return _placeholderIcon(isDark);
  }

  Widget _placeholderIcon(bool isDark) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.restaurant, color: Colors.grey),
    );
  }
}

class _HistoryDay {
  final DateTime date;
  final List<FoodLog> logs;
  final double totalCalories;
  final double totalProtein;
  final double totalFat;
  final double totalCarbs;

  _HistoryDay({
    required this.date,
    required this.logs,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalFat,
    required this.totalCarbs,
  });
}
