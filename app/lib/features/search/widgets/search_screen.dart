import 'package:cached_network_image/cached_network_image.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:meal_tracker/core/database/app_database.dart';

class SearchScreen extends StatefulWidget {
  final String mealType;
  final String? dateStr;

  const SearchScreen({super.key, required this.mealType, this.dateStr});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  late AppDatabase _db;
  bool _dbReady = false;
  List<Product> _results = [];
  List<FoodLog> _recent = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    _db = await AppDatabase.getInstance();
    _recent = await _db.getRecentProducts(limit: 15);
    if (mounted) setState(() => _dbReady = true);
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    final results = await _db.searchProducts(query);
    if (mounted) {
      setState(() {
        _results = results;
        _searching = false;
      });
    }
  }

  Future<void> _addProduct(Product product) async {
    final grams = await _showGramsDialog(product);
    if (grams == null || grams <= 0) return;

    final factor = grams / 100.0;
    final date = widget.dateStr != null
        ? DateFormat('yyyy-MM-dd').parse(widget.dateStr!)
        : DateTime.now();

    await _db.addFoodLog(FoodLogsCompanion.insert(
      id: const Uuid().v4(),
      productId: drift.Value(product.productId),
      productName: product.name,
      mealType: widget.mealType,
      mealDate: DateTime(date.year, date.month, date.day, 12),
      grams: grams,
      protein: drift.Value((product.proteinPer100g ?? 0) * factor),
      fat: drift.Value((product.fatPer100g ?? 0) * factor),
      carbs: drift.Value((product.carbsPer100g ?? 0) * factor),
      calories: drift.Value((product.caloriesPer100g ?? 0) * factor),
      imageUrl: drift.Value(product.imageUrl),
    ));

    if (mounted) context.pop();
  }

  Future<double?> _showGramsDialog(Product product) {
    final controller = TextEditingController(
      text: product.weightGrams?.toInt().toString() ?? '100',
    );

    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (product.caloriesPer100g != null)
              Text(
                'На 100 г: ${product.caloriesPer100g!.toInt()} ккал  '
                'Б${product.proteinPer100g?.toStringAsFixed(1) ?? "-"} '
                'Ж${product.fatPer100g?.toStringAsFixed(1) ?? "-"} '
                'У${product.carbsPer100g?.toStringAsFixed(1) ?? "-"}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Граммы',
                suffixText: 'г',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final grams = double.tryParse(controller.text);
              Navigator.pop(context, grams);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_dbReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final showRecent = _searchController.text.length < 2 && _recent.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Поиск продуктов...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: _search,
        ),
      ),
      body: _searching
          ? const Center(child: CircularProgressIndicator())
          : showRecent
              ? _buildRecentList()
              : _buildSearchResults(),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () async {
          final result = await context.push('/add-product');
          if (result == true) _search(_searchController.text);
        },
        tooltip: 'Создать продукт',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRecentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Недавние',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recent.length,
            itemBuilder: (context, index) {
              final log = _recent[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.history)),
                title: Text(log.productName, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${log.calories.toInt()} ккал  •  ${log.grams.toInt()} г'),
                onTap: () async {
                  if (log.productId != null) {
                    final products = await _db.searchProducts(log.productName, limit: 1);
                    if (products.isNotEmpty) {
                      _addProduct(products.first);
                    }
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_results.isEmpty && _searchController.text.length >= 2) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Ничего не найдено', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final product = _results[index];
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
                      width: 48, height: 48,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
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
            '${product.brand ?? ""}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: Icon(
              product.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: product.isFavorite ? Colors.red : null,
            ),
            onPressed: () async {
              await _db.toggleFavorite(product.productId);
              _search(_searchController.text);
            },
          ),
          onTap: () => _addProduct(product),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
