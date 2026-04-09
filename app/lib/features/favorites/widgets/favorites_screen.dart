import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:meal_tracker/core/database/app_database.dart';

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
