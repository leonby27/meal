import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

part 'app_database.g.dart';

class Products extends Table {
  IntColumn get productId => integer().named('product_id')();
  TextColumn get name => text()();
  TextColumn get searchName =>
      text().withDefault(const Constant('')).named('search_name')();
  RealColumn get weightGrams => real().nullable().named('weight_grams')();
  RealColumn get proteinPer100g =>
      real().nullable().named('protein_per_100g')();
  RealColumn get fatPer100g => real().nullable().named('fat_per_100g')();
  RealColumn get carbsPer100g => real().nullable().named('carbs_per_100g')();
  RealColumn get caloriesPer100g =>
      real().nullable().named('calories_per_100g')();
  TextColumn get imageUrl => text().nullable().named('image_url')();
  TextColumn get brand => text().nullable()();
  TextColumn get country => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get composition => text().nullable()();
  RealColumn get price => real().nullable()();
  TextColumn get barcode => text().nullable()();
  TextColumn get source => text().nullable()();
  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false)).named('is_favorite')();
  BoolColumn get isUserCreated =>
      boolean().withDefault(const Constant(false)).named('is_user_created')();

  @override
  Set<Column> get primaryKey => {productId};
}

String buildSearchName(String name, [String? brand]) {
  final parts = <String>[name];
  if (brand != null && brand.isNotEmpty) parts.add(brand);
  return parts.join(' ').toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

class FoodLogs extends Table {
  TextColumn get id => text()();
  IntColumn get productId => integer().nullable().named('product_id')();
  TextColumn get productName => text().named('product_name')();
  TextColumn get mealType => text().named('meal_type')();
  DateTimeColumn get mealDate => dateTime().named('meal_date')();
  RealColumn get grams => real()();
  RealColumn get protein => real().withDefault(const Constant(0))();
  RealColumn get fat => real().withDefault(const Constant(0))();
  RealColumn get carbs => real().withDefault(const Constant(0))();
  RealColumn get calories => real().withDefault(const Constant(0))();
  TextColumn get imageUrl => text().nullable().named('image_url')();
  TextColumn get ingredientsJson =>
      text().nullable().named('ingredients_json')();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime).named('updated_at')();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Recipes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get totalWeightGrams =>
      real().withDefault(const Constant(0)).named('total_weight_grams')();
  IntColumn get servings => integer().withDefault(const Constant(1))();
  RealColumn get proteinPer100g =>
      real().withDefault(const Constant(0)).named('protein_per_100g')();
  RealColumn get fatPer100g =>
      real().withDefault(const Constant(0)).named('fat_per_100g')();
  RealColumn get carbsPer100g =>
      real().withDefault(const Constant(0)).named('carbs_per_100g')();
  RealColumn get caloriesPer100g =>
      real().withDefault(const Constant(0)).named('calories_per_100g')();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('created_at')();
}

class RecipeIngredients extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get recipeId => integer().named('recipe_id')();
  IntColumn get productId => integer().named('product_id')();
  RealColumn get grams => real()();
}

class UserSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [Products, FoodLogs, Recipes, RecipeIngredients, UserSettings],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal(super.e);

  static AppDatabase? _instance;

  static Future<AppDatabase> getInstance() async {
    if (_instance != null) return _instance!;
    _instance = AppDatabase._internal(await _openConnection());
    return _instance!;
  }

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _importPrebuiltProducts();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(products, products.searchName);
        await _rebuildSearchIndex();
      }
      if (from < 3) {
        await m.addColumn(products, products.barcode);
        await m.addColumn(products, products.source);
      }
      if (from < 4) {
        await m.addColumn(foodLogs, foodLogs.ingredientsJson);
      }
    },
  );

  Future<void> _rebuildSearchIndex() async {
    final all = await select(products).get();
    for (final p in all) {
      await (update(
        products,
      )..where((t) => t.productId.equals(p.productId))).write(
        ProductsCompanion(searchName: Value(buildSearchName(p.name, p.brand))),
      );
    }
  }

  Future<void> _importPrebuiltProducts() async {
    final dbDir = await getApplicationDocumentsDirectory();
    final prebuiltPath = p.join(dbDir.path, 'prebuilt_products.db');

    final data = await rootBundle.load('assets/database/products.db');
    final bytes = data.buffer.asUint8List();
    await File(prebuiltPath).writeAsBytes(bytes);

    final prebuiltDb = sqlite.sqlite3.open(prebuiltPath);
    final result = prebuiltDb.select(
      'SELECT product_id, name, weight_grams, protein_per_100g, fat_per_100g, '
      'carbs_per_100g, calories_per_100g, image_url, brand, country, category, '
      'composition, price FROM products',
    );

    double? toDouble(Object? v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString());
    }

    for (final row in result) {
      final name = row['name'] as String;
      final brand = row['brand'] as String?;
      await into(products).insert(
        ProductsCompanion.insert(
          productId: Value(row['product_id'] as int),
          name: name,
          searchName: Value(buildSearchName(name, brand)),
          weightGrams: Value(toDouble(row['weight_grams'])),
          proteinPer100g: Value(toDouble(row['protein_per_100g'])),
          fatPer100g: Value(toDouble(row['fat_per_100g'])),
          carbsPer100g: Value(toDouble(row['carbs_per_100g'])),
          caloriesPer100g: Value(toDouble(row['calories_per_100g'])),
          imageUrl: Value(row['image_url'] as String?),
          brand: Value(brand),
          country: Value(row['country'] as String?),
          category: Value(row['category'] as String?),
          composition: Value(row['composition'] as String?),
          price: Value(toDouble(row['price'])),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }

    prebuiltDb.close();
    File(prebuiltPath).deleteSync();
  }

  // Product queries
  Future<List<Product>> searchProducts(String query, {int limit = 50}) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];

    final words = q.split(RegExp(r'\s+')).where((w) => w.length >= 2).toList();
    if (words.isEmpty) return [];

    // Variables must match the order of ? in SQL text.
    // CASE WHEN appears before WHERE, so relevance vars go first.
    final vars = <Variable>[
      Variable.withString('$q%'), // CASE WHEN search_name LIKE ? THEN 3
      Variable.withString('%$q%'), // WHEN search_name LIKE ? THEN 2
    ];

    final whereClauses = <String>[];
    for (final word in words) {
      whereClauses.add('search_name LIKE ?');
      vars.add(Variable.withString('%$word%'));
    }
    final whereStr = whereClauses.join(' AND ');

    final sql =
        '''
      SELECT *, 
        CASE 
          WHEN search_name LIKE ? THEN 3
          WHEN search_name LIKE ? THEN 2
          ELSE 1
        END AS relevance
      FROM products
      WHERE $whereStr
      ORDER BY relevance DESC, LENGTH(name) ASC
      LIMIT $limit
    ''';

    final results = await customSelect(sql, variables: vars).get();
    return results
        .map(
          (row) => Product(
            productId: row.read<int>('product_id'),
            name: row.read<String>('name'),
            searchName: row.read<String>('search_name'),
            weightGrams: row.readNullable<double>('weight_grams'),
            proteinPer100g: row.readNullable<double>('protein_per_100g'),
            fatPer100g: row.readNullable<double>('fat_per_100g'),
            carbsPer100g: row.readNullable<double>('carbs_per_100g'),
            caloriesPer100g: row.readNullable<double>('calories_per_100g'),
            imageUrl: row.readNullable<String>('image_url'),
            brand: row.readNullable<String>('brand'),
            country: row.readNullable<String>('country'),
            category: row.readNullable<String>('category'),
            composition: row.readNullable<String>('composition'),
            price: row.readNullable<double>('price'),
            barcode: row.readNullable<String>('barcode'),
            source: row.readNullable<String>('source'),
            isFavorite: row.read<bool>('is_favorite'),
            isUserCreated: row.read<bool>('is_user_created'),
          ),
        )
        .toList();
  }

  Future<List<Product>> getFavoriteProducts() {
    return (select(products)..where((p) => p.isFavorite.equals(true))).get();
  }

  Future<void> toggleFavorite(int productId) async {
    final product = await (select(
      products,
    )..where((p) => p.productId.equals(productId))).getSingle();
    await (update(products)..where((p) => p.productId.equals(productId))).write(
      ProductsCompanion(isFavorite: Value(!product.isFavorite)),
    );
  }

  Future<Product> cacheServerProduct(Map<String, dynamic> json) async {
    final id = json['id'] as int? ?? 0;
    final name = json['name'] as String;
    final brand = json['brand'] as String?;
    final productId = id > 0 ? id : await getNextUserProductId();

    final companion = ProductsCompanion.insert(
      productId: Value(productId),
      name: name,
      searchName: Value(buildSearchName(name, brand)),
      weightGrams: Value((json['weight_grams'] as num?)?.toDouble()),
      proteinPer100g: Value((json['protein_per_100g'] as num?)?.toDouble()),
      fatPer100g: Value((json['fat_per_100g'] as num?)?.toDouble()),
      carbsPer100g: Value((json['carbs_per_100g'] as num?)?.toDouble()),
      caloriesPer100g: Value((json['calories_per_100g'] as num?)?.toDouble()),
      imageUrl: Value(json['image_url'] as String?),
      brand: Value(brand),
      country: Value(json['country'] as String?),
      category: Value(json['category'] as String?),
      barcode: Value(json['barcode'] as String?),
      source: Value(json['source'] as String?),
    );

    await into(products).insert(companion, mode: InsertMode.insertOrReplace);
    return (await (select(
      products,
    )..where((p) => p.productId.equals(productId))).getSingle());
  }

  // Food log queries
  Future<List<FoodLog>> getFoodLogsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(foodLogs)
          ..where((l) => l.mealDate.isBetweenValues(start, end))
          ..orderBy([(l) => OrderingTerm.asc(l.createdAt)]))
        .get();
  }

  Future<void> addFoodLog(FoodLogsCompanion entry) {
    return into(foodLogs).insert(entry);
  }

  Future<void> deleteFoodLog(String id) {
    return (delete(foodLogs)..where((l) => l.id.equals(id))).go();
  }

  Future<void> updateFoodLog(String id, FoodLogsCompanion companion) {
    return (update(foodLogs)..where((l) => l.id.equals(id))).write(companion);
  }

  Stream<List<FoodLog>> watchFoodLogsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(foodLogs)
          ..where((l) => l.mealDate.isBetweenValues(start, end))
          ..orderBy([(l) => OrderingTerm.asc(l.createdAt)]))
        .watch();
  }

  Future<List<FoodLog>> getRecentProducts({int limit = 20}) {
    return (select(foodLogs)
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])
          ..limit(limit))
        .get();
  }

  // User products
  Future<int> getNextUserProductId() async {
    final result = await customSelect(
      'SELECT COALESCE(MAX(product_id), 99999) + 1 AS next_id FROM products WHERE product_id >= 100000',
    ).getSingle();
    return result.read<int>('next_id');
  }

  Future<int> addUserProduct(ProductsCompanion product) async {
    final nextId = await getNextUserProductId();
    final name = product.name.value;
    final brand = product.brand.present ? product.brand.value : null;
    await into(products).insert(
      product.copyWith(
        productId: Value(nextId),
        isUserCreated: const Value(true),
        searchName: Value(buildSearchName(name, brand)),
      ),
    );
    return nextId;
  }

  Future<void> updateProduct(int productId, ProductsCompanion companion) {
    return (update(
      products,
    )..where((p) => p.productId.equals(productId))).write(companion);
  }

  Future<List<Product>> getUserProducts() {
    return (select(products)
          ..where((p) => p.isUserCreated.equals(true))
          ..orderBy([(p) => OrderingTerm.desc(p.productId)]))
        .get();
  }

  Future<void> deleteUserProduct(int productId) {
    return (delete(products)..where(
          (p) => p.productId.equals(productId) & p.isUserCreated.equals(true),
        ))
        .go();
  }

  // Recipes
  Future<int> addRecipe(RecipesCompanion recipe) {
    return into(recipes).insert(recipe);
  }

  Future<List<Recipe>> getAllRecipes() {
    return (select(
      recipes,
    )..orderBy([(r) => OrderingTerm.desc(r.createdAt)])).get();
  }

  Future<Recipe> getRecipe(int id) {
    return (select(recipes)..where((r) => r.id.equals(id))).getSingle();
  }

  Future<void> deleteRecipe(int id) async {
    await (delete(
      recipeIngredients,
    )..where((ri) => ri.recipeId.equals(id))).go();
    await (delete(recipes)..where((r) => r.id.equals(id))).go();
    await (delete(products)..where(
          (p) => p.isUserCreated.equals(true) & p.category.equals('recipe_$id'),
        ))
        .go();
  }

  Future<void> clearUserData() async {
    await transaction(() async {
      await delete(foodLogs).go();
      await delete(recipeIngredients).go();
      await delete(recipes).go();
      await (delete(products)..where((p) => p.isUserCreated.equals(true))).go();
      await (update(products)..where((p) => p.isFavorite.equals(true))).write(
        const ProductsCompanion(isFavorite: Value(false)),
      );
      await delete(userSettings).go();
    });
  }

  Future<void> addRecipeIngredient(RecipeIngredientsCompanion ingredient) {
    return into(recipeIngredients).insert(ingredient);
  }

  Future<List<RecipeIngredient>> getRecipeIngredients(int recipeId) {
    return (select(
      recipeIngredients,
    )..where((ri) => ri.recipeId.equals(recipeId))).get();
  }

  Future<Product?> getProductById(int productId) {
    return (select(
      products,
    )..where((p) => p.productId.equals(productId))).getSingleOrNull();
  }

  // Copy meal logs from one date to another
  Future<int> copyMealLogs({
    required DateTime fromDate,
    required DateTime toDate,
    String? mealType,
  }) async {
    final logs = await getFoodLogsForDate(fromDate);
    final filtered = mealType != null
        ? logs.where((l) => l.mealType == mealType).toList()
        : logs;

    int count = 0;
    for (final log in filtered) {
      final newDate = DateTime(toDate.year, toDate.month, toDate.day, 12);
      await addFoodLog(
        FoodLogsCompanion.insert(
          id: '${DateTime.now().microsecondsSinceEpoch}_$count',
          productId: Value(log.productId),
          productName: log.productName,
          mealType: log.mealType,
          mealDate: newDate,
          grams: log.grams,
          protein: Value(log.protein),
          fat: Value(log.fat),
          carbs: Value(log.carbs),
          calories: Value(log.calories),
          imageUrl: Value(log.imageUrl),
        ),
      );
      count++;
    }
    return count;
  }

  // History — all logged days
  Future<List<DateTime>> getLoggedDates({int limit = 60}) async {
    final result = await customSelect(
      'SELECT DISTINCT DATE(meal_date, \'unixepoch\', \'localtime\') as d FROM food_logs ORDER BY d DESC LIMIT ?',
      variables: [Variable.withInt(limit)],
    ).get();
    return result.map((r) {
      final dateStr = r.read<String>('d');
      return DateTime.parse(dateStr);
    }).toList();
  }

  // Settings
  Future<String?> getSetting(String key) async {
    final result = await (select(
      userSettings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return result?.value;
  }

  Future<void> setSetting(String key, String value) {
    return into(userSettings).insertOnConflictUpdate(
      UserSettingsCompanion.insert(key: key, value: value),
    );
  }
}

Future<QueryExecutor> _openConnection() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'meal_tracker.db'));
  return NativeDatabase.createInBackground(file);
}
