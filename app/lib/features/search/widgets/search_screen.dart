import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/api/api_client.dart';
import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/services/auth_service.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/camera/widgets/ai_meal_result_sheet.dart';

class SearchScreen extends StatefulWidget {
  final String mealType;
  final String? dateStr;
  final String? initialQuery;

  const SearchScreen({super.key, required this.mealType, this.dateStr, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  late AppDatabase _db;
  bool _dbReady = false;
  List<Product> _results = [];
  List<Map<String, dynamic>> _serverResults = [];
  bool _serverSearching = false;
  Timer? _serverDebounce;
  List<FoodLog> _recent = [];
  List<Product> _favorites = [];
  bool _searching = false;
  bool _recognizing = false;
  int _preSearchTab = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }
    _initDb();
  }

  Future<void> _initDb() async {
    _db = await AppDatabase.getInstance();
    _recent = await _db.getRecentProducts(limit: 15);
    _favorites = await _db.getFavoriteProducts();
    if (mounted) {
      setState(() => _dbReady = true);
      if (_searchController.text.length >= 2) {
        _search(_searchController.text);
      }
    }
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() {
        _results = [];
        _serverResults = [];
        _searching = false;
        _serverSearching = false;
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
      _serverDebounce?.cancel();
      _serverDebounce = Timer(const Duration(milliseconds: 400), () {
        _searchServer(query);
      });
    }
  }

  Future<void> _searchServer(String query) async {
    if (!mounted || query.length < 2) return;
    setState(() {
      _serverSearching = true;
      _serverResults = [];
    });
    try {
      final api = ApiClient();
      await api.ensureAuthenticated();
      final response = await api.get('/api/products', params: {
        'search': query,
        'page_size': '30',
      });
      if (!mounted) return;
      final products = (response['products'] as List?) ?? [];
      final localNames = _results.map((p) => p.name.toLowerCase()).toSet();
      final filtered = products
          .cast<Map<String, dynamic>>()
          .where((p) => !localNames.contains((p['name'] as String?)?.toLowerCase()))
          .toList();
      setState(() {
        _serverResults = filtered;
        _serverSearching = false;
      });
    } catch (e) {
      debugPrint('Server search failed: $e');
      if (mounted) setState(() => _serverSearching = false);
    }
  }

  Future<void> _recognizeWithAI() async {
    final auth = AuthService();
    if (!auth.isPremium && auth.freeTrialExhausted) {
      if (mounted) context.go('/paywall');
      return;
    }
    final text = _searchController.text.trim();
    if (text.isEmpty) return;

    setState(() => _recognizing = true);

    await AiMealResultSheet.showWithTextLoading(
      context,
      mealType: widget.mealType,
      dateStr: widget.dateStr,
      text: text,
    );

    if (mounted) {
      setState(() => _recognizing = false);
      context.pop();
    }
  }

  Future<void> _addFromLog(FoodLog log) async {
    final auth = AuthService();
    if (!auth.isPremium && auth.freeTrialExhausted) {
      if (mounted) context.go('/paywall');
      return;
    }

    final defaultGrams = log.grams > 0 ? log.grams : 100.0;
    final calPer100 = log.grams > 0 ? log.calories / log.grams * 100 : log.calories;
    final pPer100 = log.grams > 0 ? log.protein / log.grams * 100 : log.protein;
    final fPer100 = log.grams > 0 ? log.fat / log.grams * 100 : log.fat;
    final cPer100 = log.grams > 0 ? log.carbs / log.grams * 100 : log.carbs;

    final controller = TextEditingController(text: defaultGrams.toInt().toString());
    final grams = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(log.productName, maxLines: 2, overflow: TextOverflow.ellipsis),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.per100gInfo(
                calPer100.toInt(),
                pPer100.toStringAsFixed(1),
                fPer100.toStringAsFixed(1),
                cPer100.toStringAsFixed(1),
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.l10n.gramsDialogLabel,
                suffixText: context.l10n.gramsUnit,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final g = double.tryParse(controller.text);
              Navigator.pop(context, g);
            },
            child: Text(context.l10n.add),
          ),
        ],
      ),
    );
    if (grams == null || grams <= 0) return;

    final factor = grams / 100.0;
    final date = widget.dateStr != null
        ? DateFormat('yyyy-MM-dd').parse(widget.dateStr!)
        : DateTime.now();

    await _db.addFoodLog(FoodLogsCompanion.insert(
      id: const Uuid().v4(),
      productId: drift.Value(log.productId),
      productName: log.productName,
      mealType: widget.mealType,
      mealDate: DateTime(date.year, date.month, date.day, 12),
      grams: grams,
      protein: drift.Value(pPer100 * factor),
      fat: drift.Value(fPer100 * factor),
      carbs: drift.Value(cPer100 * factor),
      calories: drift.Value(calPer100 * factor),
      imageUrl: drift.Value(log.imageUrl),
    ));

    if (mounted) context.pop();

    if (!auth.isPremium) {
      await auth.incrementFreeEntry();
    }
  }

  Future<void> _addProduct(Product product) async {
    final auth = AuthService();
    if (!auth.isPremium && auth.freeTrialExhausted) {
      if (mounted) context.go('/paywall');
      return;
    }

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

    if (!auth.isPremium) {
      await auth.incrementFreeEntry();
    }
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
                context.l10n.per100gInfo(
                  product.caloriesPer100g!.toInt(),
                  product.proteinPer100g?.toStringAsFixed(1) ?? '-',
                  product.fatPer100g?.toStringAsFixed(1) ?? '-',
                  product.carbsPer100g?.toStringAsFixed(1) ?? '-',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.l10n.gramsDialogLabel,
                suffixText: context.l10n.gramsUnit,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final grams = double.tryParse(controller.text);
              Navigator.pop(context, grams);
            },
            child: Text(context.l10n.add),
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

    final showPreSearch = _searchController.text.length < 2;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final scaffoldBg = isDark ? AppColors.darkBack2 : AppColors.lightBack2;
    final lineBorder =
        isDark ? AppColors.lineDT200 : AppColors.lineLight200;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(context.l10n.searchTitle),
        backgroundColor: appBarBg,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: context.l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor:
                    isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: lineBorder, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: lineBorder, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: lineBorder, width: 1),
                ),
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: _searching
                ? const Center(child: CircularProgressIndicator())
                : showPreSearch
                    ? _buildRecentList()
                    : _buildSearchResults(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () async {
          final result = await context.push('/add-product');
          if (result == true) _search(_searchController.text);
        },
        tooltip: context.l10n.createProduct,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPreSearchTabs() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkUnderBack : AppColors.lightUnderBack;

    final tabs = [
      (value: 0, label: context.l10n.historyTab),
      (value: 1, label: context.l10n.favoritesTab),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _preSearchTab == tab.value;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _preSearchTab = tab.value),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? cs.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: isSelected
                        ? [BoxShadow(
                            color: const Color(0x1A050C26),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 24 / 15,
                      color: isSelected ? cs.onSurface : cs.onSurfaceVariant,
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

  Widget _buildRecentList() {
    return Column(
      children: [
        const SizedBox(height: 12),
        _buildPreSearchTabs(),
        const SizedBox(height: 8),
        Expanded(
          child: _preSearchTab == 0
              ? _buildHistoryTab()
              : _buildFavoritesTab(),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    if (_recent.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noRecentRecords,
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return ListView.builder(
      itemCount: _recent.length,
      itemBuilder: (context, index) {
        final log = _recent[index];
        final calPer100 = log.grams > 0
            ? (log.calories / log.grams * 100).toInt()
            : log.calories.toInt();

        return ListTile(
          leading: _buildLogLeading(log),
          title: Text(log.productName, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            context.l10n.kcalPer100g(calPer100.toString()),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () async {
            if (log.productId != null) {
              final product = await _db.getProductById(log.productId!);
              if (product != null) {
                _addProduct(product);
                return;
              }
            }
            _addFromLog(log);
          },
        );
      },
    );
  }

  Widget _buildLogLeading(FoodLog log) {
    final url = log.imageUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('/')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(File(url), width: 48, height: 48, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _searchPlaceholder()),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 48, height: 48, fit: BoxFit.cover,
          placeholder: (_, __) => const SizedBox(
            width: 48, height: 48,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (_, __, ___) => _searchPlaceholder(),
        ),
      );
    }
    return _searchPlaceholder();
  }

  Widget _buildProductLeading(Product product) {
    if (product.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: product.imageUrl!,
          width: 48, height: 48, fit: BoxFit.cover,
          placeholder: (_, __) => const SizedBox(
            width: 48, height: 48,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (_, __, ___) => _searchPlaceholder(),
        ),
      );
    }
    return _searchPlaceholder();
  }

  Widget _searchPlaceholder() {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.restaurant, color: Colors.grey),
    );
  }

  Widget _buildFavoritesTab() {
    if (_favorites.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noFavoriteProducts,
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return ListView.builder(
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final product = _favorites[index];

        return ListTile(
          leading: _buildProductLeading(product),
          title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${context.l10n.kcalPer100g('${product.caloriesPer100g?.toInt() ?? "-"}')}  •  '
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
              _favorites = await _db.getFavoriteProducts();
              if (mounted) setState(() {});
            },
          ),
          onTap: () => _addFavoriteToMeal(product),
        );
      },
    );
  }

  Future<void> _addFavoriteToMeal(Product product) async {
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
      builder: (ctx) => _AddFavToMealSheet(product: product, mealType: widget.mealType),
    );
    if (result == null) return;

    final (mealType, grams) = result;
    final factor = grams / 100.0;
    final date = widget.dateStr != null
        ? DateFormat('yyyy-MM-dd').parse(widget.dateStr!)
        : DateTime.now();

    await _db.addFoodLog(FoodLogsCompanion.insert(
      id: const Uuid().v4(),
      productId: drift.Value(product.productId),
      productName: product.name,
      mealType: mealType,
      mealDate: DateTime(date.year, date.month, date.day, 12),
      grams: grams,
      protein: drift.Value((product.proteinPer100g ?? 0) * factor),
      fat: drift.Value((product.fatPer100g ?? 0) * factor),
      carbs: drift.Value((product.carbsPer100g ?? 0) * factor),
      calories: drift.Value((product.caloriesPer100g ?? 0) * factor),
      imageUrl: drift.Value(product.imageUrl),
    ));

    if (mounted) context.pop();

    if (!auth.isPremium) {
      await auth.incrementFreeEntry();
    }
  }

  Future<void> _addServerProduct(Map<String, dynamic> json) async {
    final product = await _db.cacheServerProduct(json);
    await _addProduct(product);
  }

  Widget _buildServerProductLeading(Map<String, dynamic> json) {
    final url = json['image_url'] as String?;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 48, height: 48, fit: BoxFit.cover,
          placeholder: (_, __) => const SizedBox(
            width: 48, height: 48,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (_, __, ___) => _searchPlaceholder(),
        ),
      );
    }
    return _searchPlaceholder();
  }

  Widget _buildSearchResults() {
    final totalEmpty = _results.isEmpty && _serverResults.isEmpty && !_serverSearching;

    if (totalEmpty && _searchController.text.length >= 2) {
      return Center(
        child: _recognizing
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(context.l10n.recognizingViaAi, style: const TextStyle(color: Colors.grey)),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.l10n.nothingFound, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _recognizeWithAI,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(context.l10n.recognizeViaAi),
                  ),
                ],
              ),
      );
    }

    final localCount = _results.length;
    final serverCount = _serverResults.length;
    final totalCount = localCount + serverCount + (_serverSearching ? 1 : 0);

    return ListView.builder(
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (index < localCount) {
          final product = _results[index];
          return ListTile(
            leading: _buildProductLeading(product),
            title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${context.l10n.kcalPer100g('${product.caloriesPer100g?.toInt() ?? "-"}')}  •  '
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
        }

        final serverIndex = index - localCount;
        if (serverIndex < serverCount) {
          final json = _serverResults[serverIndex];
          final name = json['name'] as String? ?? '';
          final cal = (json['calories_per_100g'] as num?)?.toInt();
          final brand = json['brand'] as String? ?? '';
          return ListTile(
            leading: _buildServerProductLeading(json),
            title: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${context.l10n.kcalPer100g('${cal ?? "-"}')}  •  $brand',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _addServerProduct(json),
          );
        }

        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }

  @override
  void dispose() {
    _serverDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}

class _AddFavToMealSheet extends StatefulWidget {
  final Product product;
  final String mealType;
  const _AddFavToMealSheet({required this.product, required this.mealType});

  @override
  State<_AddFavToMealSheet> createState() => _AddFavToMealSheetState();
}

class _AddFavToMealSheetState extends State<_AddFavToMealSheet> {
  late String _mealType;
  late final TextEditingController _gramsCtl;

  static const _meals = [
    (key: 'breakfast', icon: Icons.wb_sunny_outlined),
    (key: 'lunch', icon: Icons.wb_cloudy_outlined),
    (key: 'dinner', icon: Icons.nights_stay_outlined),
    (key: 'snack', icon: Icons.cookie_outlined),
  ];

  String _mealLabel(String key) {
    switch (key) {
      case 'breakfast': return context.l10n.mealBreakfast;
      case 'lunch': return context.l10n.mealLunch;
      case 'dinner': return context.l10n.mealDinner;
      case 'snack': return context.l10n.mealSnack;
      default: return key;
    }
  }

  @override
  void initState() {
    super.initState();
    _mealType = widget.mealType;
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
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              p.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            if (p.caloriesPer100g != null) ...[
              const SizedBox(height: 4),
              Text(
                '${context.l10n.kcalValueInt(cal)} / ${context.l10n.gramsValue(grams)}',
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _mealType,
              decoration: InputDecoration(
                labelText: context.l10n.mealTypeLabel,
                prefixIcon: const Icon(Icons.restaurant),
              ),
              items: _meals.map((m) {
                return DropdownMenuItem(
                  value: m.key,
                  child: Row(
                    children: [
                      Icon(m.icon, size: 20),
                      const SizedBox(width: 8),
                      Text(_mealLabel(m.key)),
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
              onChanged: (_) => setState(() {}),
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
}
