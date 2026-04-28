import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/services/auth_service.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/core/utils/meal_type_helper.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late AppDatabase _db;
  bool _dbReady = false;
  List<Product> _favorites = [];
  final Set<int> _pendingRemoval = {};

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    _db = await AppDatabase.getInstance();
    await _loadFavorites();
    if (mounted) setState(() => _dbReady = true);
  }

  Future<void> _loadFavorites() async {
    _favorites = await _db.getFavoriteProducts();
    _pendingRemoval.clear();
  }

  Future<void> _addToMeal(Product product) async {
    final auth = AuthService();
    if (!auth.isPremium && auth.freeTrialExhausted) {
      if (mounted) context.go('/paywall');
      return;
    }

    final result = await showModalBottomSheet<(String, double)?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AddToMealSheet(product: product),
    );
    if (result == null) return;

    final (mealType, grams) = result;
    final factor = grams / 100.0;
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day, 12);

    await _db.addFoodLog(
      FoodLogsCompanion.insert(
        id: const Uuid().v4(),
        productId: drift.Value(product.productId),
        productName: product.name,
        mealType: mealType,
        mealDate: date,
        grams: grams,
        protein: drift.Value((product.proteinPer100g ?? 0) * factor),
        fat: drift.Value((product.fatPer100g ?? 0) * factor),
        carbs: drift.Value((product.carbsPer100g ?? 0) * factor),
        calories: drift.Value((product.caloriesPer100g ?? 0) * factor),
        imageUrl: drift.Value(product.imageUrl),
      ),
    );

    if (!auth.isPremium) {
      await auth.incrementFreeEntry();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.productAddedToMeal(product.name))),
      );
    }
  }

  Future<void> _toggleFavorite(Product product) async {
    final id = product.productId;
    if (_pendingRemoval.contains(id)) {
      await _db.toggleFavorite(id);
      setState(() => _pendingRemoval.remove(id));
    } else {
      await _db.toggleFavorite(id);
      setState(() => _pendingRemoval.add(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_dbReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineBorder = isDark ? AppColors.lineDT100 : AppColors.lineLight100;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.favoritesTitle)),
      body: _favorites.isEmpty
          ? Center(
              child: Text(
                context.l10n.noFavoriteProducts,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade500),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final product = _favorites[index];
                final isRemoved = _pendingRemoval.contains(product.productId);
                final grams = product.weightGrams?.toInt() ?? 100;
                final factor = grams / 100.0;
                final cal = ((product.caloriesPer100g ?? 0) * factor).toInt();

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < _favorites.length - 1 ? 8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () => _addToMeal(product),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: lineBorder, width: 1),
                        boxShadow: AppTheme.cardEdgeShadows(isDark: isDark),
                      ),
                      foregroundDecoration: AppTheme.cardEdgeForeground(
                        isDark: isDark,
                        radius: 20,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                _buildPhoto(product),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => _toggleFavorite(product),
                            behavior: HitTestBehavior.opaque,
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: Center(
                                child: Icon(
                                  isRemoved
                                      ? Icons.favorite_border
                                      : Icons.favorite,
                                  color: isRemoved
                                      ? cs.onSurfaceVariant
                                      : Colors.red,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPhoto(Product product) {
    final url = product.imageUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('/')) {
        final file = File(url);
        if (!file.existsSync()) return _placeholderIcon();
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _placeholderIcon(),
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
          errorWidget: (context, url, error) => _placeholderIcon(),
        ),
      );
    }
    return _placeholderIcon();
  }

  Widget _placeholderIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.restaurant,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _AddToMealSheet extends StatefulWidget {
  final Product product;
  const _AddToMealSheet({required this.product});

  @override
  State<_AddToMealSheet> createState() => _AddToMealSheetState();
}

class _AddToMealSheetState extends State<_AddToMealSheet> {
  String _mealType = defaultMealType();
  late final TextEditingController _gramsCtl;

  List<({String key, String label, IconData icon})> _getMeals(
    BuildContext context,
  ) => [
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
    (key: 'snack', label: context.l10n.mealSnack, icon: Icons.cookie_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _gramsCtl = TextEditingController(
      text: widget.product.weightGrams?.toInt().toString() ?? '100',
    );
  }

  @override
  void dispose() {
    _gramsCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final cs = Theme.of(context).colorScheme;
    final grams = int.tryParse(_gramsCtl.text) ?? p.weightGrams?.toInt() ?? 100;
    final factor = grams / 100.0;
    final cal = ((p.caloriesPer100g ?? 0) * factor).toInt();
    final prot = ((p.proteinPer100g ?? 0) * factor).toInt();
    final fat = ((p.fatPer100g ?? 0) * factor).toInt();
    final carbs = ((p.carbsPer100g ?? 0) * factor).toInt();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSheetPhoto(p),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
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
                          const SizedBox(width: 12),
                          Text(
                            '${context.l10n.proteinShort}$prot ${context.l10n.fatShort}$fat ${context.l10n.carbsShort}$carbs',
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
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _mealType,
              decoration: InputDecoration(
                labelText: context.l10n.mealTypeLabel,
                prefixIcon: const Icon(Icons.restaurant),
              ),
              items: _getMeals(context).map((m) {
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
                if (v != null) setState(() => _mealType = v);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _gramsCtl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.l10n.gramsDialogLabel,
                suffixText: context.l10n.gramsUnit,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                final grams = double.tryParse(_gramsCtl.text);
                if (grams == null || grams <= 0) return;
                Navigator.pop(context, (_mealType, grams));
              },
              icon: const Icon(Icons.restaurant_outlined, size: 20),
              label: Text(
                context.l10n.addEntry,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 22 / 16,
                ),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetPhoto(Product p) {
    final url = p.imageUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('/')) {
        final file = File(url);
        if (!file.existsSync()) return _sheetPlaceholder();
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _sheetPlaceholder(),
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
          errorWidget: (_, _, _) => _sheetPlaceholder(),
        ),
      );
    }
    return _sheetPlaceholder();
  }

  Widget _sheetPlaceholder() {
    final cs = Theme.of(context).colorScheme;
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
}
