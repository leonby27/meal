import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:meal_tracker/core/build_info.dart';
import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/services/auth_service.dart';
import 'package:meal_tracker/core/services/theme_service.dart';

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

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Локальные данные сохранятся на устройстве.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Выйти')),
        ],
      ),
    );
    if (confirm != true) return;
    await AuthService().signOut();
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

    final auth = AuthService();

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildUserCard(auth),
          const SizedBox(height: 16),
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Тема оформления',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: ThemeNotifier.instance,
                    builder: (context, mode, _) {
                      return SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.smartphone),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode),
                          ),
                        ],
                        selected: {mode},
                        onSelectionChanged: (selected) {
                          ThemeNotifier.instance.setThemeMode(selected.first);
                        },
                      );
                    },
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
                  leading: const Icon(Icons.restaurant),
                  title: const Text('Мои продукты'),
                  subtitle: const Text('Добавить или редактировать'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/my-products'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('О приложении'),
                  subtitle: Text('MealTracker v$appVersion (build $buildNumber, $buildDate)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signInFromGuest() async {
    final success = await AuthService().signInWithGoogle();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вы вошли в аккаунт')),
      );
      setState(() {});
    }
  }


  Widget _buildUserCard(AuthService auth) {
    final hasAccount = auth.userEmail != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: auth.userPhotoUrl != null
                      ? NetworkImage(auth.userPhotoUrl!)
                      : null,
                  child: auth.userPhotoUrl == null
                      ? const Icon(Icons.person, size: 28)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.userName ?? 'Пользователь',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hasAccount)
                        Text(
                          auth.userEmail!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (!hasAccount)
                        Text(
                          'Гостевой режим',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasAccount)
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Выйти',
                    onPressed: _signOut,
                  ),
              ],
            ),
            if (!hasAccount) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _signInFromGuest,
                  icon: const Icon(Icons.login),
                  label: const Text('Войти через Google'),
                ),
              ),
            ],
          ],
        ),
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
