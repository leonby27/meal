import 'package:flutter/material.dart';

import 'package:meal_tracker/core/database/app_database.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late AppDatabase _db;
  bool _dbReady = false;
  final _calorieController = TextEditingController(text: '2000');
  final _proteinController = TextEditingController(text: '');
  final _fatController = TextEditingController(text: '');
  final _carbsController = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    _db = await AppDatabase.getInstance();
    _calorieController.text = await _db.getSetting('calorie_goal') ?? '2000';
    _proteinController.text = await _db.getSetting('protein_goal') ?? '';
    _fatController.text = await _db.getSetting('fat_goal') ?? '';
    _carbsController.text = await _db.getSetting('carbs_goal') ?? '';
    if (mounted) setState(() => _dbReady = true);
  }

  Future<void> _save() async {
    await _db.setSetting('calorie_goal', _calorieController.text);
    await _db.setSetting('protein_goal', _proteinController.text);
    await _db.setSetting('fat_goal', _fatController.text);
    await _db.setSetting('carbs_goal', _carbsController.text);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Настройки сохранены')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_dbReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Дневные цели',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _calorieController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Калории (ккал)',
                      prefixIcon: Icon(Icons.local_fire_department),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _proteinController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Белки (г)',
                      prefixIcon: Icon(Icons.fitness_center),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _fatController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Жиры (г)',
                      prefixIcon: Icon(Icons.opacity),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _carbsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Углеводы (г)',
                      prefixIcon: Icon(Icons.grain),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('О приложении'),
                  subtitle: const Text('MealTracker v1.0.0'),
                ),
                ListTile(
                  leading: const Icon(Icons.storage),
                  title: const Text('База продуктов'),
                  subtitle: const Text('5500+ продуктов (edostavka.by)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _calorieController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    super.dispose();
  }
}
