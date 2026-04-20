import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  late AppDatabase _db;
  bool _dbReady = false;
  List<Product> _userProducts = [];

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    _db = await AppDatabase.getInstance();
    await _reload();
    if (mounted) setState(() => _dbReady = true);
  }

  Future<void> _reload() async {
    _userProducts = await _db.getUserProducts();
  }

  @override
  Widget build(BuildContext context) {
    if (!_dbReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.myProducts),
      ),
      body: _buildProductsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push('/add-product');
          if (result == true) {
            await _reload();
            setState(() {});
          }
        },
        icon: const Icon(Icons.add),
        label: Text(context.l10n.productLabel),
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
              context.l10n.noOwnProducts,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.createProductWithMacros,
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
          confirmDismiss: (_) => _confirmDelete('${context.l10n.productLabel.toLowerCase()} "${p.name}"'),
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
              '${context.l10n.kcalPer100g('${p.caloriesPer100g?.toInt() ?? "-"}')}  •  '
              '${context.l10n.proteinShort}${p.proteinPer100g?.toStringAsFixed(1) ?? "-"} '
              '${context.l10n.fatShort}${p.fatPer100g?.toStringAsFixed(1) ?? "-"} '
              '${context.l10n.carbsShort}${p.carbsPer100g?.toStringAsFixed(1) ?? "-"}',
            ),
            trailing: p.brand != null
                ? Chip(label: Text(p.brand!, style: Theme.of(context).textTheme.bodySmall))
                : null,
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDelete(String what) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.deleteConfirm),
        content: Text(ctx.l10n.deleteWhat(what)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(ctx.l10n.delete),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
