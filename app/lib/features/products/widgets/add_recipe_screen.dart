import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';

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
          decoration: InputDecoration(
            labelText: ctx.l10n.gramsDialogLabel,
            suffixText: ctx.l10n.gramsUnit,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(controller.text)),
            child: Text(ctx.l10n.add),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.enterRecipeName)),
      );
      return;
    }
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.addAtLeastOneIngredient)),
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
        SnackBar(content: Text(context.l10n.recipeSaved)),
      );
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.newRecipe),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
            label: Text(context.l10n.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: context.l10n.recipeNameRequired,
                      prefixIcon: const Icon(Icons.menu_book),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _servingsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.l10n.servingsCount,
                      prefixIcon: const Icon(Icons.people),
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
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Row(
                    children: [
                      Text(context.l10n.ingredientsCount(_ingredients.length),
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: _addIngredient,
                        icon: const Icon(Icons.add),
                        label: Text(context.l10n.add),
                      ),
                    ],
                  ),
                ),
                if (_ingredients.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        context.l10n.tapAddToSelect,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
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
                          '${ing.grams.toInt()} ${context.l10n.gramsUnit}  •  '
                          '${context.l10n.proteinShort} ${ing.protein.toStringAsFixed(1)} '
                          '${context.l10n.fatShort} ${ing.fat.toStringAsFixed(1)} '
                          '${context.l10n.carbsShort} ${ing.carbs.toStringAsFixed(1)}  •  '
                          '${context.l10n.kcalValue(ing.calories.toInt().toString())}',
                        ),
                        trailing: SizedBox(
                          width: 70,
                          child: TextField(
                            controller: TextEditingController(text: ing.grams.toInt().toString()),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              suffixText: context.l10n.gramsUnit,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            Text(context.l10n.totalForRecipe, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MacroChip(context.l10n.weightLabel, '${_totalGrams.toInt()} ${context.l10n.gramsUnit}'),
                _MacroChip(context.l10n.caloriesLabel, _totalCalories.toInt().toString()),
                _MacroChip(context.l10n.proteinShort, '${_totalProtein.toStringAsFixed(1)} ${context.l10n.gramsUnit}'),
                _MacroChip(context.l10n.fatShort, '${_totalFat.toStringAsFixed(1)} ${context.l10n.gramsUnit}'),
                _MacroChip(context.l10n.carbsShort, '${_totalCarbs.toStringAsFixed(1)} ${context.l10n.gramsUnit}'),
              ],
            ),
            const Divider(height: 24),
            Text(context.l10n.per100g, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MacroChip(context.l10n.caloriesLabel, _per100gCalories.toInt().toString()),
                _MacroChip(context.l10n.proteinShort, '${_per100gProtein.toStringAsFixed(1)} ${context.l10n.gramsUnit}'),
                _MacroChip(context.l10n.fatShort, '${_per100gFat.toStringAsFixed(1)} ${context.l10n.gramsUnit}'),
                _MacroChip(context.l10n.carbsShort, '${_per100gCarbs.toStringAsFixed(1)} ${context.l10n.gramsUnit}'),
              ],
            ),
            if (_servings > 1) ...[
              const Divider(height: 24),
              Text(context.l10n.perServing(_perServingGrams.toInt()),
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MacroChip(context.l10n.caloriesLabel, (_totalCalories / _servings).toInt().toString()),
                  _MacroChip(context.l10n.proteinShort, '${(_totalProtein / _servings).toStringAsFixed(1)} ${context.l10n.gramsUnit}'),
                  _MacroChip(context.l10n.fatShort, '${(_totalFat / _servings).toStringAsFixed(1)} ${context.l10n.gramsUnit}'),
                  _MacroChip(context.l10n.carbsShort, '${(_totalCarbs / _servings).toStringAsFixed(1)} ${context.l10n.gramsUnit}'),
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
              decoration: InputDecoration(
                hintText: context.l10n.ingredientSearchHint,
                prefixIcon: const Icon(Icons.search),
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
                        _controller.text.length < 2 ? context.l10n.startTypingName : context.l10n.nothingFound,
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
                            '${context.l10n.kcalPer100g('${p.caloriesPer100g?.toInt() ?? "-"}')}  •  '
                            '${context.l10n.proteinShort}${p.proteinPer100g?.toStringAsFixed(1) ?? "-"} '
                            '${context.l10n.fatShort}${p.fatPer100g?.toStringAsFixed(1) ?? "-"} '
                            '${context.l10n.carbsShort}${p.carbsPer100g?.toStringAsFixed(1) ?? "-"}',
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
