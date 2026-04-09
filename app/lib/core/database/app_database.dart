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
  RealColumn get weightGrams => real().nullable().named('weight_grams')();
  RealColumn get proteinPer100g => real().nullable().named('protein_per_100g')();
  RealColumn get fatPer100g => real().nullable().named('fat_per_100g')();
  RealColumn get carbsPer100g => real().nullable().named('carbs_per_100g')();
  RealColumn get caloriesPer100g => real().nullable().named('calories_per_100g')();
  TextColumn get imageUrl => text().nullable().named('image_url')();
  TextColumn get brand => text().nullable()();
  TextColumn get country => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get composition => text().nullable()();
  RealColumn get price => real().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false)).named('is_favorite')();
  BoolColumn get isUserCreated => boolean().withDefault(const Constant(false)).named('is_user_created')();

  @override
  Set<Column> get primaryKey => {productId};
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
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).named('created_at')();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).named('updated_at')();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class UserSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Products, FoodLogs, UserSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal(super.e);

  static AppDatabase? _instance;

  static Future<AppDatabase> getInstance() async {
    if (_instance != null) return _instance!;
    _instance = AppDatabase._internal(await _openConnection());
    return _instance!;
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _importPrebuiltProducts();
    },
  );

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
      await into(products).insert(
        ProductsCompanion.insert(
          productId: Value(row['product_id'] as int),
          name: row['name'] as String,
          weightGrams: Value(toDouble(row['weight_grams'])),
          proteinPer100g: Value(toDouble(row['protein_per_100g'])),
          fatPer100g: Value(toDouble(row['fat_per_100g'])),
          carbsPer100g: Value(toDouble(row['carbs_per_100g'])),
          caloriesPer100g: Value(toDouble(row['calories_per_100g'])),
          imageUrl: Value(row['image_url'] as String?),
          brand: Value(row['brand'] as String?),
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
  Future<List<Product>> searchProducts(String query, {int limit = 50}) {
    return (select(products)
      ..where((p) => p.name.like('%$query%'))
      ..limit(limit))
        .get();
  }

  Future<List<Product>> getFavoriteProducts() {
    return (select(products)..where((p) => p.isFavorite.equals(true))).get();
  }

  Future<void> toggleFavorite(int productId) async {
    final product = await (select(products)..where((p) => p.productId.equals(productId))).getSingle();
    await (update(products)..where((p) => p.productId.equals(productId)))
        .write(ProductsCompanion(isFavorite: Value(!product.isFavorite)));
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

  // Settings
  Future<String?> getSetting(String key) async {
    final result = await (select(userSettings)..where((s) => s.key.equals(key))).getSingleOrNull();
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
