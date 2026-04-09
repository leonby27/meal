import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';

import 'package:meal_tracker/core/api/api_client.dart';
import 'package:meal_tracker/core/database/app_database.dart';

class _IngredientEntry {
  final TextEditingController nameCtl;
  final TextEditingController gramsCtl;
  double proteinPer100g;
  double fatPer100g;
  double carbsPer100g;
  double caloriesPer100g;
  double protein;
  double fat;
  double carbs;
  double calories;

  _IngredientEntry({
    required this.nameCtl,
    required this.gramsCtl,
    required this.proteinPer100g,
    required this.fatPer100g,
    required this.carbsPer100g,
    required this.caloriesPer100g,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.calories,
  });

  void dispose() {
    nameCtl.dispose();
    gramsCtl.dispose();
  }
}

class CameraScreen extends StatefulWidget {
  final String mealType;
  final String? dateStr;
  final String? autoSource;
  final Uint8List? initialImageBytes;
  final ScrollController? sheetScrollController;

  const CameraScreen({super.key, required this.mealType, this.dateStr, this.autoSource, this.initialImageBytes, this.sheetScrollController});

  static Future<void> showAsSheet(BuildContext context, {required String mealType, String? dateStr, String? autoSource}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => CameraScreen(
          mealType: mealType,
          dateStr: dateStr,
          autoSource: autoSource,
          sheetScrollController: scrollController,
        ),
      ),
    );
  }

  static Future<void> pickAndShow(BuildContext context, {required String mealType, String? dateStr, required ImageSource source}) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, maxWidth: 768, imageQuality: 70);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (!context.mounted) return;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => CameraScreen(
          mealType: mealType,
          dateStr: dateStr,
          initialImageBytes: bytes,
          sheetScrollController: scrollController,
        ),
      ),
    );
  }

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  Uint8List? _imageBytes;
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;
  bool _autoLaunched = false;

  final _nameCtl = TextEditingController();
  final _totalGramsCtl = TextEditingController();
  final _proteinCtl = TextEditingController();
  final _fatCtl = TextEditingController();
  final _carbsCtl = TextEditingController();
  final _caloriesCtl = TextEditingController();

  double _proteinPer100g = 0;
  double _fatPer100g = 0;
  double _carbsPer100g = 0;
  double _caloriesPer100g = 0;

  List<_IngredientEntry> _ingredients = [];
  bool _updatingControllers = false;

  List<AssetEntity> _recentPhotos = [];

  @override
  void initState() {
    super.initState();
    _loadRecentPhotos();
    if (widget.initialImageBytes != null) {
      _imageBytes = widget.initialImageBytes;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _recognize(_imageBytes!);
      });
    } else if (widget.autoSource != null) {
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

  Future<void> _loadRecentPhotos() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) return;

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(sizeConstraint: SizeConstraint(ignoreSize: true)),
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );
    if (albums.isEmpty) return;

    final recent = await albums.first.getAssetListRange(start: 0, end: 30);
    if (mounted) setState(() => _recentPhotos = recent);
  }

  Future<void> _pickFromGalleryAsset(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _result = null;
      _error = null;
    });
    _recognize(bytes);
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _totalGramsCtl.dispose();
    _proteinCtl.dispose();
    _fatCtl.dispose();
    _carbsCtl.dispose();
    _caloriesCtl.dispose();
    for (final ing in _ingredients) {
      ing.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, maxWidth: 768, imageQuality: 70);
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
      await api.ensureAuthenticated();
      final result = await api.uploadImage('/api/recognize', bytes);
      _initResultControllers(result);
      setState(() {
        _result = result;
        _loading = false;
      });
    } on NetworkException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось распознать: $e';
        _loading = false;
      });
    }
  }

  void _initResultControllers(Map<String, dynamic> result) {
    final total = result['total'] as Map<String, dynamic>? ?? {};
    final per100g = result['per_100g'] as Map<String, dynamic>? ?? {};
    final totalGrams = (result['total_grams'] as num?)?.toDouble() ?? 100;
    final ingredients =
        (result['ingredients'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    _nameCtl.text = result['name'] as String? ?? 'Блюдо';
    _totalGramsCtl.text = _fmt(totalGrams);
    _proteinCtl.text = _fmt((total['protein'] as num?)?.toDouble() ?? 0);
    _fatCtl.text = _fmt((total['fat'] as num?)?.toDouble() ?? 0);
    _carbsCtl.text = _fmt((total['carbs'] as num?)?.toDouble() ?? 0);
    _caloriesCtl.text = _fmt((total['calories'] as num?)?.toDouble() ?? 0);

    if (per100g.isNotEmpty) {
      _proteinPer100g = (per100g['protein'] as num?)?.toDouble() ?? 0;
      _fatPer100g = (per100g['fat'] as num?)?.toDouble() ?? 0;
      _carbsPer100g = (per100g['carbs'] as num?)?.toDouble() ?? 0;
      _caloriesPer100g = (per100g['calories'] as num?)?.toDouble() ?? 0;
    } else if (totalGrams > 0) {
      _proteinPer100g =
          ((total['protein'] as num?)?.toDouble() ?? 0) / totalGrams * 100;
      _fatPer100g =
          ((total['fat'] as num?)?.toDouble() ?? 0) / totalGrams * 100;
      _carbsPer100g =
          ((total['carbs'] as num?)?.toDouble() ?? 0) / totalGrams * 100;
      _caloriesPer100g =
          ((total['calories'] as num?)?.toDouble() ?? 0) / totalGrams * 100;
    }

    for (final ing in _ingredients) {
      ing.dispose();
    }

    _ingredients = ingredients.map((i) {
      final grams = (i['grams'] as num?)?.toDouble() ?? 0;
      final protein = (i['protein'] as num?)?.toDouble() ?? 0;
      final fat = (i['fat'] as num?)?.toDouble() ?? 0;
      final carbs = (i['carbs'] as num?)?.toDouble() ?? 0;
      final calories = (i['calories'] as num?)?.toDouble() ?? 0;

      return _IngredientEntry(
        nameCtl: TextEditingController(text: i['name'] as String? ?? ''),
        gramsCtl: TextEditingController(text: _fmt(grams)),
        proteinPer100g: grams > 0 ? protein / grams * 100 : 0,
        fatPer100g: grams > 0 ? fat / grams * 100 : 0,
        carbsPer100g: grams > 0 ? carbs / grams * 100 : 0,
        caloriesPer100g: grams > 0 ? calories / grams * 100 : 0,
        protein: protein,
        fat: fat,
        carbs: carbs,
        calories: calories,
      );
    }).toList();
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  double _val(TextEditingController c) => double.tryParse(c.text) ?? 0;

  void _recalcFrom(TextEditingController source) {
    if (_updatingControllers) return;
    _updatingControllers = true;

    if (source == _totalGramsCtl) {
      final g = _val(_totalGramsCtl);
      final f = g / 100;
      _proteinCtl.text = _fmt(_proteinPer100g * f);
      _fatCtl.text = _fmt(_fatPer100g * f);
      _carbsCtl.text = _fmt(_carbsPer100g * f);
      _caloriesCtl.text = _fmt(_caloriesPer100g * f);
    } else if (source == _proteinCtl ||
        source == _fatCtl ||
        source == _carbsCtl) {
      final p = _val(_proteinCtl);
      final f = _val(_fatCtl);
      final c = _val(_carbsCtl);
      _caloriesCtl.text = _fmt(p * 4 + f * 9 + c * 4);
    } else if (source == _caloriesCtl) {
      final currentCal = _val(_caloriesCtl);
      final oldCal =
          _val(_proteinCtl) * 4 + _val(_fatCtl) * 9 + _val(_carbsCtl) * 4;
      if (oldCal > 0) {
        final factor = currentCal / oldCal;
        _totalGramsCtl.text = _fmt(_val(_totalGramsCtl) * factor);
        _proteinCtl.text = _fmt(_val(_proteinCtl) * factor);
        _fatCtl.text = _fmt(_val(_fatCtl) * factor);
        _carbsCtl.text = _fmt(_val(_carbsCtl) * factor);
      }
    }

    _updatingControllers = false;
    setState(() {});
  }

  void _onIngredientGramsChanged(int index) {
    if (_updatingControllers) return;
    _updatingControllers = true;

    final ing = _ingredients[index];
    final g = _val(ing.gramsCtl);
    final f = g / 100;
    ing.protein = ing.proteinPer100g * f;
    ing.fat = ing.fatPer100g * f;
    ing.carbs = ing.carbsPer100g * f;
    ing.calories = ing.caloriesPer100g * f;

    _recalcTotalsFromIngredients();

    _updatingControllers = false;
    setState(() {});
  }

  void _recalcTotalsFromIngredients() {
    double totalGrams = 0, totalP = 0, totalF = 0, totalC = 0, totalCal = 0;
    for (final i in _ingredients) {
      totalGrams += _val(i.gramsCtl);
      totalP += i.protein;
      totalF += i.fat;
      totalC += i.carbs;
      totalCal += i.calories;
    }
    _totalGramsCtl.text = _fmt(totalGrams);
    _proteinCtl.text = _fmt(totalP);
    _fatCtl.text = _fmt(totalF);
    _carbsCtl.text = _fmt(totalC);
    _caloriesCtl.text = _fmt(totalCal);

    if (totalGrams > 0) {
      _proteinPer100g = totalP / totalGrams * 100;
      _fatPer100g = totalF / totalGrams * 100;
      _carbsPer100g = totalC / totalGrams * 100;
      _caloriesPer100g = totalCal / totalGrams * 100;
    }
  }

  void _removeIngredient(int index) {
    _updatingControllers = true;
    _ingredients[index].dispose();
    _ingredients.removeAt(index);

    if (_ingredients.isNotEmpty) {
      _recalcTotalsFromIngredients();
    }

    _updatingControllers = false;
    setState(() {});
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

    final logId = const Uuid().v4();

    String? localImagePath;
    if (_imageBytes != null) {
      localImagePath = await _saveImageLocally(_imageBytes!, logId);
    }

    await db.addFoodLog(FoodLogsCompanion.insert(
      id: logId,
      productName: _nameCtl.text.trim().isEmpty
          ? 'Неизвестное блюдо'
          : _nameCtl.text.trim(),
      mealType: widget.mealType,
      mealDate: DateTime(date.year, date.month, date.day, 12),
      grams: _val(_totalGramsCtl),
      protein: drift.Value(_val(_proteinCtl)),
      fat: drift.Value(_val(_fatCtl)),
      carbs: drift.Value(_val(_carbsCtl)),
      calories: drift.Value(_val(_caloriesCtl)),
      imageUrl: drift.Value(localImagePath),
    ));

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSheet = widget.sheetScrollController != null;

    final body = ListView(
      controller: widget.sheetScrollController,
      padding: const EdgeInsets.all(16),
      children: [
        if (isSheet) ...[
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Распознать блюдо',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
        ],

        if (_imageBytes != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(_imageBytes!, height: 250, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
        ],

        if (_imageBytes == null)
          _buildGalleryGrid(),

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
            child: OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.refresh),
              label: const Text('Новое фото'),
            ),
          ),
      ],
    );

    if (isSheet) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Распознать блюдо')),
      body: body,
    );
  }

  Widget _buildGalleryGrid() {
    const crossAxisCount = 3;
    const spacing = 4.0;
    final totalItems = 1 + _recentPhotos.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (index == 0) {
          return GestureDetector(
            onTap: () => _pickImage(ImageSource.camera),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, color: Colors.white, size: 32),
                  SizedBox(height: 4),
                  Text('Камера', style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          );
        }

        final asset = _recentPhotos[index - 1];
        return GestureDetector(
          onTap: () => _pickFromGalleryAsset(asset),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FutureBuilder<Uint8List?>(
              future: asset.thumbnailDataWithSize(const ThumbnailSize.square(300)),
              builder: (context, snap) {
                if (snap.data != null) {
                  return Image.memory(snap.data!, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
                }
                return Container(color: Colors.grey.shade200);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildResult() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtl,
              style: Theme.of(context).textTheme.titleLarge,
              decoration: const InputDecoration(
                labelText: 'Название',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Text(
              'На 100 г: ${_caloriesPer100g.toInt()} ккал  '
              'Б${_proteinPer100g.toStringAsFixed(1)} '
              'Ж${_fatPer100g.toStringAsFixed(1)} '
              'У${_carbsPer100g.toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _totalGramsCtl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Граммы',
                suffixText: 'г',
              ),
              onChanged: (_) => _recalcFrom(_totalGramsCtl),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _proteinCtl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Белки'),
                    onChanged: (_) => _recalcFrom(_proteinCtl),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _fatCtl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Жиры'),
                    onChanged: (_) => _recalcFrom(_fatCtl),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _carbsCtl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Углев.'),
                    onChanged: (_) => _recalcFrom(_carbsCtl),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _caloriesCtl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Калории',
                suffixText: 'ккал',
              ),
              onChanged: (_) => _recalcFrom(_caloriesCtl),
            ),
            if (_ingredients.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              Text('Ингредиенты:',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...List.generate(
                  _ingredients.length, (i) => _buildIngredientRow(i)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _val(_totalGramsCtl) > 0 ? _saveResult : null,
                icon: const Icon(Icons.add),
                label: const Text('Добавить в дневник'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientRow(int index) {
    final ing = _ingredients[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: ing.nameCtl,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                child: TextField(
                  controller: ing.gramsCtl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    suffixText: 'г',
                    border: OutlineInputBorder(),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                  onChanged: (_) => _onIngredientGramsChanged(index),
                ),
              ),
              SizedBox(
                width: 32,
                child: IconButton(
                  icon: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
                  onPressed: () => _removeIngredient(index),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Text(
              '${ing.calories.toInt()} ккал  '
              'Б${ing.protein.toStringAsFixed(1)} '
              'Ж${ing.fat.toStringAsFixed(1)} '
              'У${ing.carbs.toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
