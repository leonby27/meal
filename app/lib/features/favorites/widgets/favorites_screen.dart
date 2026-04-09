import 'package:cached_network_image/cached_network_image.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:meal_tracker/core/database/app_database.dart';
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
  }

  Future<void> _addToMeal(Product product) async {
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

    await _db.addFoodLog(FoodLogsCompanion.insert(
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
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} добавлен')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_dbReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body: _favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Нет избранных продуктов',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Добавляйте продукты в избранное при поиске',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final product = _favorites[index];
                return ListTile(
                  onTap: () => _addToMeal(product),
                  leading: product.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: product.imageUrl!,
                            width: 48, height: 48, fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(
                              width: 48, height: 48,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.restaurant, color: Colors.grey),
                            ),
                          ),
                        )
                      : CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          child: const Icon(Icons.restaurant, color: Colors.grey),
                        ),
                  title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${product.caloriesPer100g?.toInt() ?? "-"} ккал/100г  •  '
                    'Б${product.proteinPer100g?.toStringAsFixed(1) ?? "-"} '
                    'Ж${product.fatPer100g?.toStringAsFixed(1) ?? "-"} '
                    'У${product.carbsPer100g?.toStringAsFixed(1) ?? "-"}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () async {
                      await _db.toggleFavorite(product.productId);
                      await _loadFavorites();
                      setState(() {});
                    },
                  ),
                );
              },
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

  static const _meals = [
    (key: 'breakfast', label: 'Завтрак', icon: Icons.wb_sunny_outlined),
    (key: 'lunch', label: 'Обед', icon: Icons.wb_cloudy_outlined),
    (key: 'dinner', label: 'Ужин', icon: Icons.nights_stay_outlined),
    (key: 'snack', label: 'Перекус', icon: Icons.cookie_outlined),
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
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24, 16, 24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              p.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (p.caloriesPer100g != null) ...[
              const SizedBox(height: 4),
              Text(
                'На 100 г: ${p.caloriesPer100g!.toInt()} ккал  '
                'Б${p.proteinPer100g?.toStringAsFixed(1) ?? "-"} '
                'Ж${p.fatPer100g?.toStringAsFixed(1) ?? "-"} '
                'У${p.carbsPer100g?.toStringAsFixed(1) ?? "-"}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Приём пищи',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _meals.map((m) {
                return ChoiceChip(
                  avatar: Icon(m.icon, size: 18),
                  label: Text(m.label),
                  selected: _mealType == m.key,
                  onSelected: (_) => setState(() => _mealType = m.key),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _gramsCtl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Граммы',
                suffixText: 'г',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final grams = double.tryParse(_gramsCtl.text);
                  if (grams == null || grams <= 0) return;
                  Navigator.pop(context, (_mealType, grams));
                },
                child: const Text('Добавить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
