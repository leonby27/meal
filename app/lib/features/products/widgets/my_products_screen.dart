import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:meal_tracker/core/database/app_database.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AppDatabase _db;
  bool _dbReady = false;
  List<Product> _userProducts = [];
  List<Recipe> _recipes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initDb();
  }

  Future<void> _initDb() async {
    _db = await AppDatabase.getInstance();
    await _reload();
    if (mounted) setState(() => _dbReady = true);
  }

  Future<void> _reload() async {
    _userProducts = await _db.getUserProducts();
    _recipes = await _db.getAllRecipes();
  }

  @override
  Widget build(BuildContext context) {
    if (!_dbReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои продукты'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Продукты', icon: Icon(Icons.restaurant)),
            Tab(text: 'Рецепты', icon: Icon(Icons.menu_book)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsList(),
          _buildRecipesList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final route = _tabController.index == 0 ? '/add-product' : '/add-recipe';
          final result = await context.push(route);
          if (result == true) {
            await _reload();
            setState(() {});
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Продукт' : 'Рецепт'),
      ),
    );
  }

  Widget _buildProductsList() {
    if (_userProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Нет своих продуктов',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Создайте продукт с указанием БЖУ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _userProducts.length,
      itemBuilder: (context, index) {
        final p = _userProducts[index];
        return Dismissible(
          key: ValueKey(p.productId),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) => _confirmDelete('продукт "${p.name}"'),
          onDismissed: (_) async {
            await _db.deleteUserProduct(p.productId);
            await _reload();
            setState(() {});
          },
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: const Icon(Icons.restaurant),
            ),
            title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${p.caloriesPer100g?.toInt() ?? "-"} ккал/100г  •  '
              'Б${p.proteinPer100g?.toStringAsFixed(1) ?? "-"} '
              'Ж${p.fatPer100g?.toStringAsFixed(1) ?? "-"} '
              'У${p.carbsPer100g?.toStringAsFixed(1) ?? "-"}',
            ),
            trailing: p.brand != null
                ? Chip(label: Text(p.brand!, style: Theme.of(context).textTheme.bodySmall))
                : null,
          ),
        );
      },
    );
  }

  Widget _buildRecipesList() {
    if (_recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Нет рецептов',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Создайте блюдо из нескольких продуктов',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _recipes.length,
      itemBuilder: (context, index) {
        final r = _recipes[index];
        final perServing = r.servings > 0
            ? r.totalWeightGrams / r.servings
            : r.totalWeightGrams;
        return Dismissible(
          key: ValueKey(r.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) => _confirmDelete('рецепт "${r.name}"'),
          onDismissed: (_) async {
            await _db.deleteRecipe(r.id);
            await _reload();
            setState(() {});
          },
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: const Icon(Icons.menu_book),
            ),
            title: Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${r.caloriesPer100g.toInt()} ккал/100г  •  '
              '${r.totalWeightGrams.toInt()} г  •  '
              '${r.servings} порц. (${perServing.toInt()} г)',
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDelete(String what) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить?'),
        content: Text('Удалить $what?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
