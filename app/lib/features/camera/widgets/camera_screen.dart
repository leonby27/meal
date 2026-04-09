import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:meal_tracker/core/api/api_client.dart';
import 'package:meal_tracker/core/database/app_database.dart';

class CameraScreen extends StatefulWidget {
  final String mealType;
  final String? dateStr;
  final String? autoSource;

  const CameraScreen({super.key, required this.mealType, this.dateStr, this.autoSource});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  Uint8List? _imageBytes;
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;
  bool _autoLaunched = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoSource != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_autoLaunched) {
          _autoLaunched = true;
          final source = widget.autoSource == 'gallery'
              ? ImageSource.gallery
              : ImageSource.camera;
          _pickImage(source);
        }
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, maxWidth: 1024, imageQuality: 80);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _result = null;
      _error = null;
    });

    _recognize(bytes);
  }

  Future<void> _recognize(Uint8List bytes) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ApiClient();
      final result = await api.uploadImage('/api/recognize', bytes);
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось распознать: $e';
        _loading = false;
      });
    }
  }

  Future<String?> _saveImageLocally(Uint8List bytes, String logId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${dir.path}/meal_photos');
      if (!photosDir.existsSync()) {
        photosDir.createSync(recursive: true);
      }
      final file = File('${photosDir.path}/$logId.jpg');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('Failed to save photo locally: $e');
      return null;
    }
  }

  Future<void> _saveResult() async {
    if (_result == null) return;

    final db = await AppDatabase.getInstance();
    final date = widget.dateStr != null
        ? DateFormat('yyyy-MM-dd').parse(widget.dateStr!)
        : DateTime.now();

    final total = _result!['total'] as Map<String, dynamic>;
    final totalGrams = (_result!['total_grams'] as num?)?.toDouble() ?? 100;
    final logId = const Uuid().v4();

    String? localImagePath;
    if (_imageBytes != null) {
      localImagePath = await _saveImageLocally(_imageBytes!, logId);
    }

    await db.addFoodLog(FoodLogsCompanion.insert(
      id: logId,
      productName: _result!['name'] as String? ?? 'Неизвестное блюдо',
      mealType: widget.mealType,
      mealDate: DateTime(date.year, date.month, date.day, 12),
      grams: totalGrams,
      protein: drift.Value((total['protein'] as num?)?.toDouble() ?? 0),
      fat: drift.Value((total['fat'] as num?)?.toDouble() ?? 0),
      carbs: drift.Value((total['carbs'] as num?)?.toDouble() ?? 0),
      calories: drift.Value((total['calories'] as num?)?.toDouble() ?? 0),
      imageUrl: drift.Value(localImagePath),
    ));

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Распознать блюдо')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_imageBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(_imageBytes!, height: 250, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
            ],

            if (_imageBytes == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.camera_alt, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text('Сфотографируйте блюдо или выберите из галереи'),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Камера'),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Галерея'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('AI анализирует блюдо...'),
                    ],
                  ),
                ),
              ),

            if (_error != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => _imageBytes != null ? _recognize(_imageBytes!) : null,
                        child: const Text('Попробовать снова'),
                      ),
                    ],
                  ),
                ),
              ),

            if (_result != null) _buildResult(),

            if (_imageBytes != null && !_loading)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Новое фото'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final name = _result!['name'] ?? 'Блюдо';
    final total = _result!['total'] as Map<String, dynamic>? ?? {};
    final ingredients = (_result!['ingredients'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _nutrientChip('Ккал', total['calories']),
                _nutrientChip('Белки', total['protein'], 'г'),
                _nutrientChip('Жиры', total['fat'], 'г'),
                _nutrientChip('Углеводы', total['carbs'], 'г'),
              ],
            ),
            if (ingredients.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              Text('Ингредиенты:', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...ingredients.map((i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${i['name']} — ${(i['grams'] as num?)?.toInt() ?? '?'} г',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saveResult,
                icon: const Icon(Icons.add),
                label: const Text('Добавить в дневник'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nutrientChip(String label, dynamic value, [String suffix = '']) {
    final display = value is num ? value.toStringAsFixed(1) : '-';
    return Column(
      children: [
        Text(
          '$display$suffix',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
