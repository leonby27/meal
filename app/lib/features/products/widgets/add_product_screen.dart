import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:meal_tracker/core/database/app_database.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  final _carbsController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _weightController = TextEditingController(text: '100');
  final _brandController = TextEditingController();
  bool _saving = false;

  void _onMacroChanged() {
    final p = double.tryParse(_proteinController.text) ?? 0;
    final f = double.tryParse(_fatController.text) ?? 0;
    final c = double.tryParse(_carbsController.text) ?? 0;
    final autoCalories = (p * 4 + f * 9 + c * 4).round();

    if (_caloriesController.text.isEmpty ||
        double.tryParse(_caloriesController.text) == 0) {
      _caloriesController.text = autoCalories.toString();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final db = await AppDatabase.getInstance();

    await db.addUserProduct(ProductsCompanion.insert(
      name: _nameController.text.trim(),
      proteinPer100g: drift.Value(double.tryParse(_proteinController.text)),
      fatPer100g: drift.Value(double.tryParse(_fatController.text)),
      carbsPer100g: drift.Value(double.tryParse(_carbsController.text)),
      caloriesPer100g: drift.Value(double.tryParse(_caloriesController.text)),
      weightGrams: drift.Value(double.tryParse(_weightController.text)),
      brand: drift.Value(_brandController.text.isNotEmpty ? _brandController.text.trim() : null),
      category: const drift.Value('Мои продукты'),
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Продукт добавлен')),
      );
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новый продукт')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Основное', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Название *',
                        prefixIcon: Icon(Icons.restaurant),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Введите название' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _brandController,
                      decoration: const InputDecoration(
                        labelText: 'Бренд (необязательно)',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Вес порции (г)',
                        prefixIcon: Icon(Icons.scale),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('БЖУ на 100 г', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _proteinController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Белки'),
                            onChanged: (_) => _onMacroChanged(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _fatController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Жиры'),
                            onChanged: (_) => _onMacroChanged(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _carbsController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Углев.'),
                            onChanged: (_) => _onMacroChanged(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _caloriesController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Калории (ккал)',
                        prefixIcon: Icon(Icons.local_fire_department),
                        helperText: 'Рассчитается автоматически из БЖУ',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add),
              label: const Text('Сохранить продукт'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    _caloriesController.dispose();
    _weightController.dispose();
    _brandController.dispose();
    super.dispose();
  }
}
