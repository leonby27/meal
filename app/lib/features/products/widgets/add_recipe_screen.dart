import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:meal_tracker/core/database/app_database.dart';

class _Ingredient {
  final Product product;
  double grams;

  _Ingredient({required this.product, this.grams = 100});

  double get protein => (product.proteinPer100g ?? 0) * grams / 100;
  double get fat => (product.fatPer100g ?? 0) * grams / 100;
  double get carbs => (product.carbsPer100g ?? 0) * grams / 100;
  double get calories => (product.caloriesPer100g ?? 0) * grams / 100;
}

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _nameController = TextEditingController();
  final _servingsController = TextEditingController(text: '1');
  final List<_Ingredient> _ingredients = [];
  bool _saving = false;

  double get _totalGrams => _ingredients.fold(0, (s, i) => s + i.grams);
  double get _totalProtein => _ingredients.fold(0, (s, i) => s + i.protein);
  double get _totalFat => _ingredients.fold(0, (s, i) => s + i.fat);
  double get _totalCarbs => _ingredients.fold(0, (s, i) => s + i.carbs);
  double get _totalCalories => _ingredients.fold(0, (s, i) => s + i.calories);
  int get _servings => int.tryParse(_servingsController.text) ?? 1;

  double get _perServingGrams => _servings > 0 ? _totalGrams / _servings : _totalGrams;
  double get _per100gProtein => _totalGrams > 0 ? _totalProtein / _totalGrams * 100 : 0;
  double get _per100gFat => _totalGrams > 0 ? _totalFat / _totalGrams * 100 : 0;
  double get _per100gCarbs => _totalGrams > 0 ? _totalCarbs / _totalGrams * 100 : 0;
  double get _per100gCalories => _totalGrams > 0 ? _totalCalories / _totalGrams * 100 : 0;

  Future<void> _addIngredient() async {
    final product = await _showProductPicker();
    if (product == null) return;

    final grams = await _showGramsInput(product);
    if (grams == null || grams <= 0) return;

    setState(() {
      _ingredients.add(_Ingredient(product: product, grams: grams));
    });
  }

  Future<Product?> _showProductPicker() async {
    return showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _IngredientSearchSheet(),
    );
  }

  Future<double?> _showGramsInput(Product product) {
    final controller = TextEditingController(
      text: product.weightGrams?.toInt().toString() ?? '100',
    );
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Граммы', suffixText: 'г'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(controller.text)),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название рецепта')),
      );
      return;
    }
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы один ингредиент')),
      );
      return;
    }

    setState(() => _saving = true);
    final db = await AppDatabase.getInstance();

    final recipeId = await db.addRecipe(RecipesCompanion.insert(
      name: _nameController.text.trim(),
      totalWeightGrams: drift.Value(_totalGrams),
      servings: drift.Value(_servings),
      proteinPer100g: drift.Value(_per100gProtein),
      fatPer100g: drift.Value(_per100gFat),
      carbsPer100g: drift.Value(_per100gCarbs),
      caloriesPer100g: drift.Value(_per100gCalories),
    ));

    for (final ing in _ingredients) {
      await db.addRecipeIngredient(RecipeIngredientsCompanion.insert(
        recipeId: recipeId,
        productId: ing.product.productId,
        grams: ing.grams,
      ));
    }

    await db.addUserProduct(ProductsCompanion.insert(
      name: _nameController.text.trim(),
      proteinPer100g: drift.Value(_per100gProtein),
      fatPer100g: drift.Value(_per100gFat),
      carbsPer100g: drift.Value(_per100gCarbs),
      caloriesPer100g: drift.Value(_per100gCalories),
      weightGrams: drift.Value(_perServingGrams),
      category: drift.Value('recipe_$recipeId'),
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Рецепт сохранён')),
      );
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новый рецепт'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
            label: const Text('Сохранить'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Название рецепта *',
                      prefixIcon: Icon(Icons.menu_book),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _servingsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Количество порций',
                      prefixIcon: Icon(Icons.people),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_ingredients.isNotEmpty) _buildSummary(),
          const SizedBox(height: 8),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Text('Ингредиенты (${_ingredients.length})',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: _addIngredient,
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить'),
                      ),
                    ],
                  ),
                ),
                if (_ingredients.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Нажмите «Добавить» чтобы\nвыбрать продукты',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...List.generate(_ingredients.length, (i) {
                    final ing = _ingredients[i];
                    return Dismissible(
                      key: ObjectKey(ing),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => setState(() => _ingredients.removeAt(i)),
                      child: ListTile(
                        title: Text(ing.product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${ing.grams.toInt()} г  •  '
                          'Б ${ing.protein.toStringAsFixed(1)} '
                          'Ж ${ing.fat.toStringAsFixed(1)} '
                          'У ${ing.carbs.toStringAsFixed(1)}  •  '
                          '${ing.calories.toInt()} ккал',
                        ),
                        trailing: SizedBox(
                          width: 70,
                          child: TextField(
                            controller: TextEditingController(text: ing.grams.toInt().toString()),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              suffixText: 'г',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            onChanged: (v) {
                              final g = double.tryParse(v);
                              if (g != null && g > 0) {
                                setState(() => ing.grams = g);
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withAlpha(80),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Итого на весь рецепт', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MacroChip('Вес', '${_totalGrams.toInt()} г'),
                _MacroChip('Ккал', _totalCalories.toInt().toString()),
                _MacroChip('Б', '${_totalProtein.toStringAsFixed(1)} г'),
                _MacroChip('Ж', '${_totalFat.toStringAsFixed(1)} г'),
                _MacroChip('У', '${_totalCarbs.toStringAsFixed(1)} г'),
              ],
            ),
            const Divider(height: 24),
            Text('На 100 г:', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MacroChip('Ккал', _per100gCalories.toInt().toString()),
                _MacroChip('Б', '${_per100gProtein.toStringAsFixed(1)} г'),
                _MacroChip('Ж', '${_per100gFat.toStringAsFixed(1)} г'),
                _MacroChip('У', '${_per100gCarbs.toStringAsFixed(1)} г'),
              ],
            ),
            if (_servings > 1) ...[
              const Divider(height: 24),
              Text('На порцию (${_perServingGrams.toInt()} г):',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MacroChip('Ккал', (_totalCalories / _servings).toInt().toString()),
                  _MacroChip('Б', '${(_totalProtein / _servings).toStringAsFixed(1)} г'),
                  _MacroChip('Ж', '${(_totalFat / _servings).toStringAsFixed(1)} г'),
                  _MacroChip('У', '${(_totalCarbs / _servings).toStringAsFixed(1)} г'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _servingsController.dispose();
    super.dispose();
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;

  const _MacroChip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _IngredientSearchSheet extends StatefulWidget {
  const _IngredientSearchSheet();

  @override
  State<_IngredientSearchSheet> createState() => _IngredientSearchSheetState();
}

class _IngredientSearchSheetState extends State<_IngredientSearchSheet> {
  final _controller = TextEditingController();
  List<Product> _results = [];
  bool _loading = false;
  late AppDatabase _db;
  bool _dbReady = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _db = await AppDatabase.getInstance();
    if (mounted) setState(() => _dbReady = true);
  }

  Future<void> _search(String q) async {
    if (q.length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    final results = await _db.searchProducts(q, limit: 30);
    if (mounted) setState(() { _results = results; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Поиск ингредиента...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _search,
            ),
          ),
          if (_loading)
            const LinearProgressIndicator()
          else if (!_dbReady)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        _controller.text.length < 2 ? 'Начните вводить название' : 'Ничего не найдено',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final p = _results[i];
                        return ListTile(
                          title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            '${p.caloriesPer100g?.toInt() ?? "-"} ккал/100г  •  '
                            'Б${p.proteinPer100g?.toStringAsFixed(1) ?? "-"} '
                            'Ж${p.fatPer100g?.toStringAsFixed(1) ?? "-"} '
                            'У${p.carbsPer100g?.toStringAsFixed(1) ?? "-"}',
                          ),
                          onTap: () => Navigator.pop(context, p),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
