import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uuid/uuid.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/services/auth_service.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/core/utils/meal_type_helper.dart';
import 'package:meal_tracker/features/diary/widgets/daily_summary_card.dart';
import 'package:meal_tracker/features/diary/widgets/meal_section.dart';
import 'package:meal_tracker/features/camera/widgets/ai_meal_result_sheet.dart';
import 'package:meal_tracker/features/camera/widgets/camera_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  DateTime _selectedDate = DateTime.now();
  late AppDatabase _db;
  bool _dbReady = false;

  Map<int, double> _weekCalories = {};
  double _goalCalories = 2000;

  static const int _weekPageCenter = 5000;
  late final PageController _weekPageCtl;
  late final DateTime _weekAnchor;

  static const int _dayPageCenter = 50000;
  late final PageController _dayPageCtl;
  late final DateTime _dayAnchor;
  bool _syncingPages = false;

  final _inputCtl = TextEditingController();
  final _inputFocus = FocusNode();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _voiceLocked = false;
  Offset _voiceDragOrigin = Offset.zero;
  double _voiceSlideX = 0;
  Timer? _voiceTimer;
  String _voiceDuration = '0:00';
  final _micKey = GlobalKey();
  OverlayEntry? _micTooltip;

  bool _searchMode = false;
  List<Product> _searchResults = [];
  List<FoodLog> _recentProducts = [];
  List<Product> _favoriteProducts = [];
  bool _isSearching = false;
  bool _isRecognizing = false;
  bool _hasSearchText = false;
  int _preSearchTab = 0;

  @override
  void initState() {
    super.initState();
    _weekAnchor = _weekStart(DateTime.now());
    _weekPageCtl = PageController(initialPage: _weekPageCenter);
    final now = DateTime.now();
    _dayAnchor = DateTime(now.year, now.month, now.day);
    _dayPageCtl = PageController(initialPage: _dayPageCenter);
    _initDb();
    _initSpeech();
    _inputCtl.addListener(_onSearchTextChanged);
    _inputFocus.addListener(_onSearchFocusChanged);
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint('[STT] status: $status');
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            if (_voiceLocked && !_listenCancelled) {
              _doFinalizeVoice();
            }
          }
        },
        onError: (error) {
          debugPrint('[STT] error: ${error.errorMsg} (permanent: ${error.permanent})');
          if (!mounted) return;
          _stopVoiceTimer();
          setState(() {
            _isListening = false;
            _voiceLocked = false;
            _voiceSlideX = 0;
          });
        },
      );
      debugPrint('[STT] initialized, available: $_speechAvailable');
      if (_speechAvailable) {
        final locales = await _speech.locales();
        debugPrint('[STT] locales: ${locales.map((l) => l.localeId).join(', ')}');
      }
    } catch (e) {
      debugPrint('[STT] init exception: $e');
      _speechAvailable = false;
    }
  }

  void _onSearchTextChanged() {
    final has = _inputCtl.text.trim().isNotEmpty;
    if (has != _hasSearchText) setState(() => _hasSearchText = has);
  }

  void _onSearchFocusChanged() {
    if (!_inputFocus.hasFocus && _inputCtl.text.trim().isEmpty && _searchMode) {
      _deactivateSearch();
    }
  }

  void _activateSearch() {
    if (_searchMode) return;
    setState(() => _searchMode = true);
    _loadRecentProducts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inputFocus.requestFocus();
    });
    final text = _inputCtl.text.trim();
    if (text.length >= 2) {
      _onSearchChanged(text);
    }
  }

  void _deactivateSearch() {
    _inputFocus.unfocus();
    _inputCtl.clear();
    setState(() {
      _searchMode = false;
      _searchResults = [];
      _isSearching = false;
      _isRecognizing = false;
      _hasSearchText = false;
    });
  }

  Future<void> _loadRecentProducts() async {
    final recent = await _db.getRecentProducts(limit: 15);
    final favorites = await _db.getFavoriteProducts();
    if (mounted) {
      setState(() {
        _recentProducts = recent;
        _favoriteProducts = favorites;
      });
    }
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    final results = await _db.searchProducts(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _recognizeWithAI(String dateStr) async {
    final text = _inputCtl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isRecognizing = true);
    _inputFocus.unfocus();

    final savedText = text;

    if (_searchMode) {
      _deactivateSearch();
    } else {
      _inputCtl.clear();
      setState(() {
        _isRecognizing = false;
        _hasSearchText = false;
      });
    }

    await AiMealResultSheet.showWithTextLoading(
      context,
      mealType: defaultMealType(),
      dateStr: dateStr,
      text: savedText,
    );

    if (mounted) {
      setState(() => _isRecognizing = false);
    }
  }

  Future<void> _addProductFromSearch(Product product, String dateStr) async {
    final grams = await _showGramsDialog(product);
    if (grams == null || grams <= 0) return;

    final factor = grams / 100.0;
    final date = DateFormat('yyyy-MM-dd').parse(dateStr);

    await _db.addFoodLog(FoodLogsCompanion.insert(
      id: const Uuid().v4(),
      productId: drift.Value(product.productId),
      productName: product.name,
      mealType: defaultMealType(),
      mealDate: DateTime(date.year, date.month, date.day, 12),
      grams: grams,
      protein: drift.Value((product.proteinPer100g ?? 0) * factor),
      fat: drift.Value((product.fatPer100g ?? 0) * factor),
      carbs: drift.Value((product.carbsPer100g ?? 0) * factor),
      calories: drift.Value((product.caloriesPer100g ?? 0) * factor),
      imageUrl: drift.Value(product.imageUrl),
    ));

    if (mounted) _deactivateSearch();
  }

  Future<double?> _showGramsDialog(Product product) {
    final controller = TextEditingController(
      text: product.weightGrams?.toInt().toString() ?? '100',
    );

    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (product.caloriesPer100g != null)
              Text(
                ctx.l10n.per100gInfo(
                  product.caloriesPer100g!.toInt(),
                  product.proteinPer100g?.toStringAsFixed(1) ?? '-',
                  product.fatPer100g?.toStringAsFixed(1) ?? '-',
                  product.carbsPer100g?.toStringAsFixed(1) ?? '-',
                ),
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: ctx.l10n.gramsDialogLabel,
                suffixText: ctx.l10n.gramsUnit,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final grams = double.tryParse(controller.text);
              Navigator.pop(ctx, grams);
            },
            child: Text(ctx.l10n.add),
          ),
        ],
      ),
    );
  }

  String _preListenText = '';
  bool _listenCancelled = false;

  void _startVoiceTimer() {
    _voiceTimer?.cancel();
    final start = DateTime.now();
    _voiceDuration = '0:00';
    _voiceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final elapsed = DateTime.now().difference(start);
      setState(() {
        _voiceDuration =
            '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
      });
    });
  }

  void _stopVoiceTimer() {
    _voiceTimer?.cancel();
    _voiceTimer = null;
  }

  void _showMicTooltip() {
    _micTooltip?.remove();
    _micTooltip = null;

    final renderBox = _micKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final pos = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final centerX = pos.dx + size.width / 2;

    _micTooltip = OverlayEntry(
      builder: (ctx) => _MicTooltipOverlay(
        centerX: centerX,
        bottomY: pos.dy - 10,
        onDismiss: _dismissMicTooltip,
      ),
    );
    Overlay.of(context).insert(_micTooltip!);
  }

  void _dismissMicTooltip() {
    _micTooltip?.remove();
    _micTooltip = null;
  }

  void _onVoiceLongPressStart(LongPressStartDetails details) {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.voiceUnavailable),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    if (_isListening) return;
    HapticFeedback.mediumImpact();
    _voiceDragOrigin = details.globalPosition;
    _voiceSlideX = 0;
    _voiceLocked = false;
    _preListenText = _inputCtl.text;
    _listenCancelled = false;
    setState(() => _isListening = true);
    _startVoiceTimer();
    debugPrint('[STT] starting listen...');
    _speech.listen(
      localeId: 'ru_RU',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      listenMode: stt.ListenMode.dictation,
      onResult: (result) {
        debugPrint('[STT] result: "${result.recognizedWords}" final=${result.finalResult}');
        if (_listenCancelled || !mounted) return;
        setState(() {
          _inputCtl.text = _preListenText.isEmpty
              ? result.recognizedWords
              : '$_preListenText ${result.recognizedWords}';
          _inputCtl.selection = TextSelection.fromPosition(
            TextPosition(offset: _inputCtl.text.length),
          );
        });
      },
    );
  }

  void _onVoiceLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_isListening || _voiceLocked) return;
    final dx = details.globalPosition.dx - _voiceDragOrigin.dx;
    final dy = details.globalPosition.dy - _voiceDragOrigin.dy;

    setState(() => _voiceSlideX = dx.clamp(-200.0, 0.0));

    if (dy < -80) {
      HapticFeedback.mediumImpact();
      setState(() {
        _voiceLocked = true;
        _voiceSlideX = 0;
      });
      return;
    }

    if (dx < -100) {
      HapticFeedback.lightImpact();
      _doCancelVoice();
    }
  }

  void _onVoiceLongPressEnd(LongPressEndDetails details) {
    if (_voiceLocked) return;
    _doFinalizeVoice();
  }

  void _doCancelVoice() {
    _listenCancelled = true;
    _speech.cancel();
    _stopVoiceTimer();
    _inputCtl.text = _preListenText;
    _inputCtl.selection = TextSelection.fromPosition(
      TextPosition(offset: _inputCtl.text.length),
    );
    setState(() {
      _isListening = false;
      _voiceLocked = false;
      _voiceSlideX = 0;
    });
  }

  void _doFinalizeVoice() {
    if (!_isListening && !_voiceLocked) return;
    _speech.stop();
    _stopVoiceTimer();
    setState(() {
      _isListening = false;
      _voiceLocked = false;
      _voiceSlideX = 0;
    });
    if (_inputCtl.text.trim().isNotEmpty) {
      _activateSearch();
    }
  }

  Future<void> _initDb() async {
    _db = await AppDatabase.getInstance();
    await _loadGoal();
    await _loadWeekCalories();
    if (mounted) setState(() => _dbReady = true);
  }

  @override
  void dispose() {
    _weekPageCtl.dispose();
    _dayPageCtl.dispose();
    _inputCtl.removeListener(_onSearchTextChanged);
    _inputCtl.dispose();
    _inputFocus.removeListener(_onSearchFocusChanged);
    _inputFocus.dispose();
    _speech.stop();
    _voiceTimer?.cancel();
    _micTooltip?.remove();
    super.dispose();
  }

  Future<void> _loadGoal() async {
    final cal = await _db.getSetting('calorie_goal');
    _goalCalories = double.tryParse(cal ?? '') ?? 2000;
  }

  Future<void> _loadWeekCalories() async {
    final weekStart = _weekStart(_selectedDate);
    final result = <int, double>{};
    for (var i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final logs = await _db.getFoodLogsForDate(day);
      result[i] = logs.fold(0.0, (sum, l) => sum + l.calories);
    }
    if (mounted) setState(() => _weekCalories = result);
  }

  void _syncWeekCalories(List<FoodLog> logs) {
    final dayIndex = _selectedDate
        .difference(_weekStart(_selectedDate))
        .inDays
        .clamp(0, 6);
    final cal = logs.fold(0.0, (sum, l) => sum + l.calories);
    if (_weekCalories[dayIndex] != cal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _weekCalories[dayIndex] = cal);
      });
    }
  }

  DateTime _weekStart(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  DateTime _weekStartForPage(int page) {
    final offset = page - _weekPageCenter;
    return _weekAnchor.add(Duration(days: offset * 7));
  }

  int _pageForDate(DateTime date) {
    final ws = _weekStart(date);
    final diff = ws.difference(_weekAnchor).inDays;
    return _weekPageCenter + (diff ~/ 7);
  }

  DateTime _dateForDayPage(int page) {
    final offset = page - _dayPageCenter;
    return _dayAnchor.add(Duration(days: offset));
  }

  int _dayPageForDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return _dayPageCenter + d.difference(_dayAnchor).inDays;
  }

  void _onDayPageChanged(int page) {
    if (_syncingPages) return;
    final date = _dateForDayPage(page);
    final d = DateTime(date.year, date.month, date.day);
    final sel = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    if (d == sel) return;

    _syncingPages = true;
    setState(() => _selectedDate = date);

    final newWeekPage = _pageForDate(date);
    if (_weekPageCtl.hasClients) {
      final currentWeekPage = _weekPageCtl.page?.round() ?? _weekPageCenter;
      if (currentWeekPage != newWeekPage) {
        _weekPageCtl.jumpToPage(newWeekPage);
      }
    }

    _loadWeekCalories();
    _syncingPages = false;
  }

  void _selectDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    if (target.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.dayNotYet),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() => _selectedDate = date);

    if (_dayPageCtl.hasClients) {
      final dayPage = _dayPageForDate(date);
      if (_dayPageCtl.page?.round() != dayPage) {
        _dayPageCtl.animateToPage(
          dayPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }

    _loadWeekCalories();
  }

  String _formatHeaderDate() {
    final d = _selectedDate;
    final dayName = DateFormat('E', 'ru').format(d);
    final month = DateFormat('MMM', 'ru').format(d);
    return '${d.day} $month, $dayName';
  }

  Future<void> _openDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ru'),
    );
    if (picked != null) {
      _selectDate(picked);
    }
  }

  void _showAddMealSheet(String dateStr) {
    String selectedMealType = defaultMealType();

    final mealTypes = [
      (key: 'breakfast', label: context.l10n.mealBreakfast, icon: Icons.wb_sunny_outlined),
      (key: 'lunch', label: context.l10n.mealLunch, icon: Icons.wb_cloudy_outlined),
      (key: 'dinner', label: context.l10n.mealDinner, icon: Icons.nights_stay_outlined),
      (key: 'snack', label: context.l10n.mealSnack, icon: Icons.cookie_outlined),
    ];

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      ctx.l10n.addMealTitle,
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMealType,
                      decoration: InputDecoration(
                        labelText: ctx.l10n.mealTypeLabel,
                        prefixIcon: const Icon(Icons.restaurant),
                      ),
                      items: mealTypes.map((m) {
                        return DropdownMenuItem(
                          value: m.key,
                          child: Row(
                            children: [
                              Icon(m.icon, size: 20),
                              const SizedBox(width: 8),
                              Text(m.label),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setSheetState(() => selectedMealType = v);
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _CompactActionTile(
                            icon: Icons.search,
                            label: ctx.l10n.searchInDb,
                            onTap: () {
                              Navigator.pop(ctx);
                              context.push('/search?meal_type=$selectedMealType&date=$dateStr');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _CompactActionTile(
                            icon: Icons.photo_library_outlined,
                            label: ctx.l10n.fromGallery,
                            onTap: () {
                              Navigator.pop(ctx);
                              CameraScreen.pickAndShow(
                                context,
                                mealType: selectedMealType,
                                dateStr: dateStr,
                                source: ImageSource.gallery,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          CameraScreen.pickAndShow(
                            context,
                            mealType: selectedMealType,
                            dateStr: dateStr,
                            source: ImageSource.camera,
                          );
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: Text(ctx.l10n.recognizeByPhoto),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_dbReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final back2 = isDark ? AppColors.darkBack2 : AppColors.lightBack2;
    final onBack4 = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return PopScope(
      canPop: !_searchMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _searchMode) _deactivateSearch();
      },
      child: Scaffold(
        backgroundColor: back2,
        body: Column(
          children: [
            if (_searchMode)
              ColoredBox(
                color: isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4,
                child: SizedBox(height: MediaQuery.of(context).padding.top),
              )
            else
              SizedBox(height: MediaQuery.of(context).padding.top),
            Expanded(
              child: FocusScope(
                autofocus: false,
                child: Column(
                  children: [
                    if (_searchMode)
                      _buildSearchHeader(context, isDark)
                    else
                      _buildHeader(context),
                if (!_searchMode) ...[
                  const SizedBox(height: 16),
                  _buildWeekStrip(context, isDark),
                  _buildConnectorLine(context, isDark),
                ],
                Expanded(
                  child: _searchMode
                      ? _buildSearchBody(context, dateStr, isDark)
                      : _buildDayPageView(context, isDark, onBack4),
                ),
                _buildInputBar(context, dateStr, isDark),
              ],
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = AuthService();
    final initial = (auth.userName?.isNotEmpty == true)
        ? auth.userName![0].toUpperCase()
        : (auth.userEmail?.isNotEmpty == true)
            ? auth.userEmail![0].toUpperCase()
            : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _openDatePicker(context),
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 24,
                  color: cs.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatHeaderDate(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 22 / 16,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: cs.onSurface,
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/stats'),
            child: Icon(
              Icons.bar_chart_rounded,
              size: 24,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 24),
          GestureDetector(
            onTap: () => context.push('/favorites'),
            child: Icon(
              Icons.favorite_border,
              size: 24,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 24),
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 24 / 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context, bool isDark) {
    final cs = Theme.of(context).colorScheme;
    final bgColor = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: _deactivateSearch,
            icon: Icon(Icons.arrow_back, color: cs.onSurface),
          ),
          Text(
            context.l10n.searchTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              height: 28 / 20,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBody(BuildContext context, String dateStr, bool isDark) {
    final cs = Theme.of(context).colorScheme;
    final showPreSearch = _inputCtl.text.length < 2;

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isRecognizing) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(context.l10n.recognizingViaAi, style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    if (showPreSearch) {
      return Column(
        children: [
          const SizedBox(height: 12),
          _buildPreSearchTabs(cs, isDark),
          const SizedBox(height: 8),
          Expanded(
            child: _preSearchTab == 0
                ? _buildHistoryTab(cs, dateStr)
                : _buildFavoritesTab(cs, dateStr),
          ),
        ],
      );
    }

    if (_searchResults.isEmpty && _inputCtl.text.length >= 2) {
      return Center(
        child: Text(
          context.l10n.notFoundInDb,
          textAlign: TextAlign.center,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return ListTile(
          leading: product.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const SizedBox(
                      width: 48, height: 48,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 48, height: 48,
                      color: isDark ? AppColors.darkSurface2 : Colors.grey.shade200,
                      child: const Icon(Icons.restaurant, color: Colors.grey),
                    ),
                  ),
                )
              : CircleAvatar(
                  backgroundColor: isDark ? AppColors.darkSurface2 : Colors.grey.shade200,
                  child: const Icon(Icons.restaurant, color: Colors.grey),
                ),
          title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${context.l10n.kcalPer100g((product.caloriesPer100g?.toInt() ?? 0).toString())}  •  '
            '${product.brand ?? ""}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _addProductFromSearch(product, dateStr),
        );
      },
    );
  }

  Widget _buildPreSearchTabs(ColorScheme cs, bool isDark) {
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

  Widget _buildHistoryTab(ColorScheme cs, String dateStr) {
    if (_recentProducts.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noRecentRecords,
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      itemCount: _recentProducts.length,
      itemBuilder: (context, index) {
        final log = _recentProducts[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index < _recentProducts.length - 1 ? 8 : 0),
          child: GestureDetector(
            onTap: () async {
              if (log.productId != null) {
                final products = await _db.searchProducts(log.productName, limit: 1);
                if (products.isNotEmpty && mounted) {
                  _addProductFromSearch(products.first, dateStr);
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildRecentLogPhoto(log, cs),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 20 / 15,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              context.l10n.gramsValue(log.grams.toInt()),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 18 / 14,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              context.l10n.kcalValueInt(log.calories.toInt()),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 18 / 14,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoritesTab(ColorScheme cs, String dateStr) {
    if (_favoriteProducts.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noFavoriteProducts,
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      itemCount: _favoriteProducts.length,
      itemBuilder: (context, index) {
        final product = _favoriteProducts[index];
        final grams = product.weightGrams?.toInt() ?? 100;
        final factor = grams / 100.0;
        final cal = ((product.caloriesPer100g ?? 0) * factor).toInt();

        return Padding(
          padding: EdgeInsets.only(bottom: index < _favoriteProducts.length - 1 ? 8 : 0),
          child: GestureDetector(
            onTap: () => _addProductFromSearch(product, dateStr),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildFavProductPhoto(product, cs),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 20 / 15,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              context.l10n.gramsValue(grams),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 18 / 14,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              context.l10n.kcalValueInt(cal),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 18 / 14,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavProductPhoto(Product product, ColorScheme cs) {
    if (product.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: product.imageUrl!,
          width: 40, height: 40, fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _recentPlaceholder(cs),
        ),
      );
    }
    return _recentPlaceholder(cs);
  }

  Widget _buildRecentLogPhoto(FoodLog log, ColorScheme cs) {
    final url = log.imageUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('/')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(File(url), width: 40, height: 40, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _recentPlaceholder(cs)),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: url, width: 40, height: 40, fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _recentPlaceholder(cs),
        ),
      );
    }
    return _recentPlaceholder(cs);
  }

  Widget _recentPlaceholder(ColorScheme cs) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.restaurant, size: 20, color: cs.onSurfaceVariant),
    );
  }

  Widget _buildDayPageView(BuildContext context, bool isDark, Color onBack4) {
    final maxPage = _dayPageCenter;
    final mq = MediaQuery.of(context);
    final defaultSlop = mq.gestureSettings.touchSlop ?? 18.0;

    return MediaQuery(
      data: mq.copyWith(
        gestureSettings: DeviceGestureSettings(
          touchSlop: defaultSlop * 2.0,
        ),
      ),
      child: PageView.builder(
        controller: _dayPageCtl,
        onPageChanged: _onDayPageChanged,
        itemCount: maxPage + 1,
        itemBuilder: (_, page) {
          final date = _dateForDayPage(page);
          final dateStr = DateFormat('yyyy-MM-dd').format(date);

          return MediaQuery(
            data: mq,
            child: StreamBuilder<List<FoodLog>>(
              stream: _db.watchFoodLogsForDate(date),
              builder: (context, snapshot) {
                final logs = snapshot.data ?? [];
                final d = DateTime(date.year, date.month, date.day);
                final sel = DateTime(
                  _selectedDate.year, _selectedDate.month, _selectedDate.day,
                );
                if (d == sel) _syncWeekCalories(logs);
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return _buildDayContent(
                      context, logs, dateStr, isDark, onBack4, constraints.maxHeight,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayContent(BuildContext context, List<FoodLog> logs,
      String dateStr, bool isDark, Color back2, double viewportHeight) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = isDark ? AppColors.lineDT200 : AppColors.lineLight200;

    final grouped = {
      'breakfast': logs.where((l) => l.mealType == 'breakfast').toList(),
      'lunch': logs.where((l) => l.mealType == 'lunch').toList(),
      'dinner': logs.where((l) => l.mealType == 'dinner').toList(),
      'snack': logs.where((l) => l.mealType == 'snack').toList(),
    };

    final sections = [
      (key: 'breakfast', title: context.l10n.mealBreakfast, icon: Icons.wb_sunny_outlined),
      (key: 'lunch', title: context.l10n.mealLunch, icon: Icons.wb_cloudy_outlined),
      (key: 'dinner', title: context.l10n.mealDinner, icon: Icons.nights_stay_outlined),
      (key: 'snack', title: context.l10n.mealSnack, icon: Icons.cookie_outlined),
    ];

    final nonEmpty =
        sections.where((s) => grouped[s.key]!.isNotEmpty).toList();
    final date = DateFormat('yyyy-MM-dd').parse(dateStr);

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        DailySummaryCard(logs: logs, selectedDate: date),
        if (nonEmpty.isNotEmpty) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              context.l10n.diaryRecordsForDay,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 18 / 14,
                color: cs.onSurfaceVariant,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...nonEmpty.map((s) => _buildFoodCards(
                context,
                grouped[s.key]!,
                s.key,
                dateStr,
                isDark,
                back2,
                borderColor,
              )),
        ] else ...[
          Builder(
            builder: (context) {
              const fixedAbove = 120.0;
              final emptyHeight =
                  (viewportHeight - fixedAbove).clamp(200.0, viewportHeight);
              return SizedBox(
                height: emptyHeight,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Lottie.asset(
                        'assets/animations/empty_plate.json',
                        width: 90,
                        height: 90,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.diaryEmptyDay,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 22 / 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  void _onWeekPageChanged(int page) {
    if (_syncingPages) return;

    _syncingPages = true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final newWeekStart = _weekStartForPage(page);

    final currentWeekday = _selectedDate.weekday - 1;
    var candidate = newWeekStart.add(Duration(days: currentWeekday));
    if (candidate.isAfter(today)) candidate = today;
    if (candidate.isBefore(newWeekStart)) candidate = newWeekStart;

    setState(() => _selectedDate = candidate);

    if (_dayPageCtl.hasClients) {
      _dayPageCtl.jumpToPage(_dayPageForDate(candidate));
    }

    _loadWeekCalories();
    _syncingPages = false;
  }

  Widget _buildWeekStrip(BuildContext context, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return SizedBox(
      height: 64,
      child: PageView.builder(
        controller: _weekPageCtl,
        onPageChanged: _onWeekPageChanged,
        itemCount: _pageForDate(today) + 1,
        itemBuilder: (context, page) {
          return _buildWeekPage(context, page, isDark, today);
        },
      ),
    );
  }

  Widget _buildWeekPage(
    BuildContext context, int page, bool isDark, DateTime today,
  ) {
    final weekStart = _weekStartForPage(page);
    final selectedDay = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
    );

    final trackDefault = isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    final trackSelected = isDark ? AppColors.lineDT200 : AppColors.lineLight200;
    final cs = Theme.of(context).colorScheme;

    final dayLabels = [
      context.l10n.dayMon, context.l10n.dayTue, context.l10n.dayWed,
      context.l10n.dayThu, context.l10n.dayFri, context.l10n.daySat,
      context.l10n.daySun,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(7, (i) {
          final date = weekStart.add(Duration(days: i));
          final dayDate = DateTime(date.year, date.month, date.day);
          final isToday = dayDate == today;
          final isSelected = dayDate == selectedDay;
          final isFuture = dayDate.isAfter(today);
          final progress = _goalCalories > 0
              ? ((_weekCalories[i] ?? 0) / _goalCalories).clamp(0.0, 1.0)
              : 0.0;

          final numberColor = cs.onSurface;
          final labelColor = isToday ? cs.onSurface : cs.onSurfaceVariant;
          final showBorder = !isFuture;

          final content = Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dayLabels[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 12 / 10,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 24 / 18,
                    color: numberColor,
                  ),
                ),
              ],
            ),
          );

          return Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(date),
              child: Opacity(
                opacity: (isToday || isSelected) ? 1.0 : 0.5,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 0 : 2,
                    right: i == 6 ? 0 : 2,
                  ),
                  child: SizedBox(
                    height: 64,
                    child: showBorder
                        ? CustomPaint(
                            painter: _DayCellBorderPainter(
                              trackColor: isSelected ? trackSelected : trackDefault,
                              gradientColors: const [Color(0xFF22D33A), Color(0xFF1EBF92)],
                              progress: progress,
                              borderRadius: 12,
                              borderWidth: 4,
                            ),
                            child: content,
                          )
                        : content,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildConnectorLine(BuildContext context, bool isDark) {
    final weekStart = _weekStart(_selectedDate);
    final selectedDay = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
    );
    final weekStartDay = DateTime(
      weekStart.year, weekStart.month, weekStart.day,
    );
    final dayIndex = selectedDay.difference(weekStartDay).inDays.clamp(0, 6);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 16,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final cellWidth = totalWidth / 7;
            final centerX = cellWidth * dayIndex + cellWidth / 2;

            return Stack(
              children: [
                Positioned(
                  left: centerX - 1,
                  top: 0,
                  child: Container(
                    width: 2,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.lineDT100
                          : AppColors.lineLight100,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFoodCards(
    BuildContext context,
    List<FoodLog> logs,
    String mealType,
    String dateStr,
    bool isDark,
    Color back2,
    Color borderColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: logs.map((log) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: MealSection.buildSingleCard(
              context: context,
              log: log,
              mealType: mealType,
              dateStr: dateStr,
              onDelete: (id) => _db.deleteFoodLog(id),
              back2: back2,
              borderColor: borderColor,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, String dateStr, bool isDark) {
    final btnBack = isDark
        ? AppColors.neutralBtnBack
        : AppColors.neutralBtnBackLight;
    final placeholderColor = isDark
        ? const Color(0xFF9CA0B2)
        : const Color(0xFF676E85);
    final iconColor = isDark ? AppColors.darkSecondaryDark : AppColors.lightSecondaryDark;
    final textColor = isDark ? Colors.white : AppColors.lightOnSurface;
    const double iconSize = 36.0;

    return Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!_searchMode)
              GestureDetector(
                onTap: _activateSearch,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: btnBack,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(Icons.search, size: 22, color: iconColor),
                  ),
                ),
              ),
            if (!_searchMode) const SizedBox(width: 6),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                decoration: BoxDecoration(
                  color: btnBack,
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _inputCtl,
                        focusNode: _inputFocus,
                        minLines: 1,
                        maxLines: 4,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 22 / 16,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: _searchMode
                              ? context.l10n.productNameOrDish
                              : context.l10n.addEntry,
                          hintStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 22 / 16,
                            color: placeholderColor,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: _searchMode ? _onSearchChanged : null,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (!_searchMode && !_hasSearchText)
                      GestureDetector(
                        onTap: () {
                          context.push('/scanner?meal_type=${defaultMealType()}&date=$dateStr');
                        },
                        child: SizedBox(
                          width: iconSize,
                          height: iconSize,
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icons/barcode.svg',
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                            ),
                          ),
                        ),
                      ),
                    if (!_searchMode && !_hasSearchText)
                      GestureDetector(
                        onTap: () {
                          CameraScreen.pickAndShow(
                            context,
                            mealType: defaultMealType(),
                            dateStr: dateStr,
                            source: ImageSource.gallery,
                          );
                        },
                        child: SizedBox(
                          width: iconSize,
                          height: iconSize,
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icons/image.svg',
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
                onTap: _hasSearchText
                    ? () => _recognizeWithAI(dateStr)
                    : () {
                        CameraScreen.pickAndShow(
                          context,
                          mealType: defaultMealType(),
                          dateStr: dateStr,
                          source: ImageSource.camera,
                        );
                      },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _isRecognizing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : SvgPicture.asset(
                            _hasSearchText
                                ? 'assets/icons/send.svg'
                                : 'assets/icons/camera.svg',
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                  ),
                ),
              ),
          ],
        ),
    );
  }
}

class _DayCellBorderPainter extends CustomPainter {
  final Color trackColor;
  final List<Color> gradientColors;
  final double progress;
  final double borderRadius;
  final double borderWidth;

  _DayCellBorderPainter({
    required this.trackColor,
    required this.gradientColors,
    required this.progress,
    required this.borderRadius,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final halfBorder = borderWidth / 2;
    final rectW = size.width - borderWidth;
    final rectH = size.height - borderWidth;
    final r = borderRadius - halfBorder;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(halfBorder, halfBorder, rectW, rectH),
      Radius.circular(r),
    );

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawRRect(rrect, trackPaint);

    if (progress <= 0) return;

    final rect = Rect.fromLTWH(halfBorder, halfBorder, rectW, rectH);
    final rad = Radius.circular(r);
    final path = Path()
      ..moveTo(rect.left + rectW / 2, rect.top)
      ..lineTo(rect.right - r, rect.top)
      ..arcToPoint(Offset(rect.right, rect.top + r), radius: rad)
      ..lineTo(rect.right, rect.bottom - r)
      ..arcToPoint(Offset(rect.right - r, rect.bottom), radius: rad)
      ..lineTo(rect.left + r, rect.bottom)
      ..arcToPoint(Offset(rect.left, rect.bottom - r), radius: rad)
      ..lineTo(rect.left, rect.top + r)
      ..arcToPoint(Offset(rect.left + r, rect.top), radius: rad)
      ..lineTo(rect.left + rectW / 2, rect.top);

    final metrics = path.computeMetrics().first;
    final fillLength = metrics.length * progress.clamp(0.0, 1.0);

    final fillPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: gradientColors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(metrics.extractPath(0, fillLength), fillPaint);
  }

  @override
  bool shouldRepaint(_DayCellBorderPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.gradientColors != gradientColors;
}

class _CompactActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CompactActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_ctrl),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _MicTooltipOverlay extends StatefulWidget {
  final double centerX;
  final double bottomY;
  final VoidCallback onDismiss;

  const _MicTooltipOverlay({
    required this.centerX,
    required this.bottomY,
    required this.onDismiss,
  });

  @override
  State<_MicTooltipOverlay> createState() => _MicTooltipOverlayState();
}

class _MicTooltipOverlayState extends State<_MicTooltipOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _opacity;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _opacity = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<double>(begin: 8, end: 0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOut),
    );
    _anim.forward();
    Future.delayed(const Duration(milliseconds: 1800), _hide);
  }

  void _hide() {
    if (!mounted) return;
    _anim.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double tooltipWidth = 230;
    const double arrowSize = 7;

    final left = (widget.centerX - tooltipWidth / 2)
        .clamp(12.0, MediaQuery.of(context).size.width - tooltipWidth - 12);
    final arrowLeft = widget.centerX - left - arrowSize;

    return Stack(
      children: [
        GestureDetector(
          onTap: _hide,
          behavior: HitTestBehavior.translucent,
          child: const SizedBox.expand(),
        ),
        AnimatedBuilder(
          animation: _anim,
          builder: (context, _) => Positioned(
            left: left,
            top: widget.bottomY - 40 + _slide.value,
            child: Opacity(
              opacity: _opacity.value,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: tooltipWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(50),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      context.l10n.holdToRecord,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 18 / 13,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: arrowLeft.clamp(12.0, tooltipWidth - 24)),
                    child: CustomPaint(
                      size: const Size(arrowSize * 2, arrowSize),
                      painter: _ArrowPainter(color: AppColors.darkSurface),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  _ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) => old.color != color;
}
