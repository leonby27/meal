import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/camera/widgets/ai_meal_result_sheet.dart';

class CameraScreen extends StatefulWidget {
  final String mealType;
  final String? dateStr;
  final String? autoSource;
  final Uint8List? initialImageBytes;
  final ScrollController? sheetScrollController;

  const CameraScreen({
    super.key,
    required this.mealType,
    this.dateStr,
    this.autoSource,
    this.initialImageBytes,
    this.sheetScrollController,
  });

  static Future<void> showAsSheet(
    BuildContext context, {
    required String mealType,
    String? dateStr,
    String? autoSource,
  }) {
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

  /// Opens the native image picker and goes straight to the AI result
  /// sheet. No intermediate CameraScreen modal — every extra navigator
  /// hop between picker and result sheet has historically been a source
  /// of "tap photo, nothing happens" bugs.
  static Future<void> pickAndShow(
    BuildContext context, {
    required String mealType,
    String? dateStr,
    required ImageSource source,
  }) async {
    final picker = ImagePicker();
    final XFile? image;
    try {
      image = await picker.pickImage(
        source: source,
        maxWidth: 768,
        imageQuality: 70,
      );
    } catch (e, st) {
      debugPrint('ImagePicker failed: $e\n$st');
      return;
    }
    if (image == null) return;

    final Uint8List bytes;
    try {
      bytes = await image.readAsBytes();
    } catch (e, st) {
      debugPrint('Failed to read picked image bytes: $e\n$st');
      return;
    }
    if (!context.mounted) return;

    return AiMealResultSheet.showWithLoading(
      context,
      mealType: mealType,
      dateStr: dateStr,
      imageBytes: bytes,
    );
  }

  static Future<void> showWithResult(
    BuildContext context, {
    required String mealType,
    String? dateStr,
    required Map<String, dynamic> result,
    Uint8List? imageBytes,
  }) {
    return AiMealResultSheet.show(
      context,
      mealType: mealType,
      dateStr: dateStr,
      result: result,
      imageBytes: imageBytes,
    );
  }

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  Uint8List? _imageBytes;
  bool _autoLaunched = false;

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
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
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
    setState(() => _imageBytes = bytes);
    _recognize(bytes);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 768,
      imageQuality: 70,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    setState(() => _imageBytes = bytes);
    _recognize(bytes);
  }

  Future<void> _recognize(Uint8List bytes) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final currentNavigator = Navigator.of(context);
    final presenterContext = rootNavigator.context;

    if (currentNavigator.canPop()) {
      currentNavigator.pop();
      await Future<void>.delayed(Duration.zero);
    }

    if (!presenterContext.mounted) return;

    await AiMealResultSheet.showWithLoading(
      presenterContext,
      mealType: widget.mealType,
      dateStr: widget.dateStr,
      imageBytes: bytes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSheet = widget.sheetScrollController != null;

    final body = ListView(
      controller: widget.sheetScrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        if (isSheet) ...[
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            context.l10n.recognizeDish,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
        ],

        if (_imageBytes != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(_imageBytes!, height: 250, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
        ],

        if (_imageBytes == null) _buildGalleryGrid(),
      ],
    );

    if (isSheet) return body;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.recognizeDish)),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, color: Colors.white, size: 32),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.cameraLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
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
              future: asset.thumbnailDataWithSize(
                const ThumbnailSize.square(300),
              ),
              builder: (context, snap) {
                if (snap.data != null) {
                  return Image.memory(
                    snap.data!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  );
                }
                return Container(color: Colors.grey.shade200);
              },
            ),
          ),
        );
      },
    );
  }
}
