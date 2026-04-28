import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:meal_tracker/app/theme.dart';
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

    if (source == ImageSource.camera) {
      return _showPhotoDetailsAndRecognize(
        context,
        mealType: mealType,
        dateStr: dateStr,
        imageBytes: bytes,
      );
    }

    return _recognizeImage(
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

  static Future<void> _recognizeImage(
    BuildContext context, {
    required String mealType,
    String? dateStr,
    required Uint8List imageBytes,
    String? details,
  }) {
    final text = details?.trim() ?? '';
    if (text.isNotEmpty) {
      return AiMealResultSheet.showWithTextAndImageLoading(
        context,
        mealType: mealType,
        dateStr: dateStr,
        text: text,
        imageBytes: imageBytes,
      );
    }

    return AiMealResultSheet.showWithLoading(
      context,
      mealType: mealType,
      dateStr: dateStr,
      imageBytes: imageBytes,
    );
  }

  static Future<void> _showPhotoDetailsAndRecognize(
    BuildContext context, {
    required String mealType,
    String? dateStr,
    required Uint8List imageBytes,
  }) async {
    final details = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xCC000000),
      builder: (_) => _PhotoDetailsSheet(imageBytes: imageBytes),
    );
    if (details == null || !context.mounted) return;

    return _recognizeImage(
      context,
      mealType: mealType,
      dateStr: dateStr,
      imageBytes: imageBytes,
      details: details,
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
    if (source == ImageSource.camera) {
      await _recognizeCameraPhoto(bytes);
      return;
    }

    setState(() => _imageBytes = bytes);
    _recognize(bytes);
  }

  Future<void> _recognizeCameraPhoto(Uint8List bytes) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final currentNavigator = Navigator.of(context);
    final presenterContext = rootNavigator.context;

    if (currentNavigator.canPop()) {
      currentNavigator.pop();
      await Future<void>.delayed(Duration.zero);
    }

    if (!presenterContext.mounted) return;

    await CameraScreen._showPhotoDetailsAndRecognize(
      presenterContext,
      mealType: widget.mealType,
      dateStr: widget.dateStr,
      imageBytes: bytes,
    );
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
            onTap: () {
              HapticFeedback.selectionClick();
              _pickImage(ImageSource.camera);
            },
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

class _PhotoDetailsSheet extends StatefulWidget {
  final Uint8List imageBytes;

  const _PhotoDetailsSheet({required this.imageBytes});

  @override
  State<_PhotoDetailsSheet> createState() => _PhotoDetailsSheetState();
}

class _PhotoDetailsSheetState extends State<_PhotoDetailsSheet> {
  final _detailsCtl = TextEditingController();
  bool _buttonPressed = false;

  @override
  void dispose() {
    _detailsCtl.dispose();
    super.dispose();
  }

  void _setButtonPressed(bool pressed) {
    if (_buttonPressed == pressed) return;
    setState(() => _buttonPressed = pressed);
  }

  void _submit() {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(_detailsCtl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.darkBack2 : AppColors.lightBack2;
    final cardBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final borderColor = isDark ? AppColors.lineDT200 : AppColors.lineLight200;
    final textColor = isDark
        ? AppColors.darkOnSurface
        : AppColors.lightOnSurface;
    final hintColor = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.95),
      child: Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: keyboardHeight > 0 ? keyboardHeight : bottomPadding,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 42,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.addDish,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            height: 24 / 18,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cardBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, color: textColor, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 221,
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.memory(widget.imageBytes, fit: BoxFit.cover),
                ),
                const SizedBox(height: 18),
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: TextField(
                    controller: _detailsCtl,
                    maxLines: 1,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 18 / 14,
                    ),
                    decoration: InputDecoration(
                      hintText: context.l10n.photoDetailsHint,
                      hintStyle: TextStyle(
                        color: hintColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 18 / 14,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTapDown: (_) => _setButtonPressed(true),
                  onTapUp: (_) => _setButtonPressed(false),
                  onTapCancel: () => _setButtonPressed(false),
                  onTap: _submit,
                  child: AnimatedScale(
                    scale: _buttonPressed ? 0.94 : 1,
                    duration: const Duration(milliseconds: 110),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF317BFF), Color(0xFF7631FF)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/ai_generated_photo.svg',
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              context.l10n.recognizeDish,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                height: 22 / 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
