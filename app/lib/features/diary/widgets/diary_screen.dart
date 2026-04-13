import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/api/api_client.dart';
import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/services/auth_service.dart';
import 'package:meal_tracker/core/utils/meal_type_helper.dart';
import 'package:meal_tracker/features/diary/widgets/daily_summary_card.dart';
import 'package:meal_tracker/features/diary/widgets/meal_section.dart';
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

  final _inputCtl = TextEditingController();
  final _inputFocus = FocusNode();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _recognizingText = false;

  @override
  void initState() {
    super.initState();
    _initDb();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
  }

  void _toggleListening() {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    } else if (_speechAvailable) {
      setState(() => _isListening = true);
      _speech.listen(
        localeId: 'ru_RU',
        onResult: (result) {
          setState(() {
            _inputCtl.text = result.recognizedWords;
            _inputCtl.selection = TextSelection.fromPosition(
              TextPosition(offset: _inputCtl.text.length),
            );
          });
          if (result.finalResult) {
            setState(() => _isListening = false);
          }
        },
      );
    }
  }

  Future<void> _submitTextRecognition(String dateStr) async {
    final text = _inputCtl.text.trim();
    if (text.isEmpty) return;

    setState(() => _recognizingText = true);
    _inputFocus.unfocus();

    try {
      final api = ApiClient();
      await api.ensureAuthenticated();
      final result = await api.recognizeText(text);

      if (!mounted) return;
      _inputCtl.clear();
      setState(() => _recognizingText = false);

      await CameraScreen.showWithResult(
        context,
        mealType: defaultMealType(),
        dateStr: dateStr,
        result: result,
      );
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _recognizingText = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _recognizingText = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка распознавания: $e')),
      );
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
    _inputCtl.dispose();
    _inputFocus.dispose();
    _speech.stop();
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

  DateTime _weekStart(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
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
      lastDate: DateTime(2030),
      locale: const Locale('ru'),
    );
    if (picked != null) {
      _selectDate(picked);
    }
  }

  void _showAddMealSheet(String dateStr) {
    String selectedMealType = defaultMealType();

    const mealTypes = [
      (key: 'breakfast', label: 'Завтрак', icon: Icons.wb_sunny_outlined),
      (key: 'lunch', label: 'Обед', icon: Icons.wb_cloudy_outlined),
      (key: 'dinner', label: 'Ужин', icon: Icons.nights_stay_outlined),
      (key: 'snack', label: 'Перекус', icon: Icons.cookie_outlined),
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
                      'Добавить приём пищи',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMealType,
                      decoration: const InputDecoration(
                        labelText: 'Приём пищи',
                        prefixIcon: Icon(Icons.restaurant),
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
                            label: 'Найти в базе',
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
                            label: 'Из галереи',
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
                        label: const Text('Распознать по фото'),
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
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      backgroundColor: back2,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: StreamBuilder<List<FoodLog>>(
                stream: _db.watchFoodLogsForDate(_selectedDate),
                builder: (context, snapshot) {
                  final logs = snapshot.data ?? [];
                  return _buildBody(context, logs, dateStr, isDark, back2);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildAddButton(context, dateStr, isDark),
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
            onTap: () => context.go('/profile'),
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

  Widget _buildBody(BuildContext context, List<FoodLog> logs, String dateStr,
      bool isDark, Color back2) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = isDark ? AppColors.lineDT200 : AppColors.lineLight200;

    final grouped = {
      'breakfast': logs.where((l) => l.mealType == 'breakfast').toList(),
      'lunch': logs.where((l) => l.mealType == 'lunch').toList(),
      'dinner': logs.where((l) => l.mealType == 'dinner').toList(),
      'snack': logs.where((l) => l.mealType == 'snack').toList(),
    };

    const sections = [
      (key: 'breakfast', title: 'Завтрак', icon: Icons.wb_sunny_outlined),
      (key: 'lunch', title: 'Обед', icon: Icons.wb_cloudy_outlined),
      (key: 'dinner', title: 'Ужин', icon: Icons.nights_stay_outlined),
      (key: 'snack', title: 'Перекус', icon: Icons.cookie_outlined),
    ];

    final nonEmpty =
        sections.where((s) => grouped[s.key]!.isNotEmpty).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        const SizedBox(height: 16),
        _buildWeekStrip(context, isDark),
        _buildConnectorLine(context, isDark),
        DailySummaryCard(logs: logs, selectedDate: _selectedDate),
        if (nonEmpty.isNotEmpty) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SvgPicture.asset('assets/icons/day.svg', width: 28, height: 28),
                const SizedBox(width: 8),
                Text(
                  'Записи за день',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 22 / 16,
                    color: cs.onSurface,
                  ),
                ),
              ],
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
          const SizedBox(height: 48),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: ClipRect(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: Lottie.asset(
                        'assets/animations/empty_plate.json',
                        width: 3840,
                        height: 2160,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ещё нет записей за этот день',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 22 / 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWeekStrip(BuildContext context, bool isDark) {
    final weekStart = _weekStart(_selectedDate);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
    );

    final trackDefault = isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    final trackSelected = isDark ? AppColors.lineDT200 : AppColors.lineLight200;
    final cs = Theme.of(context).colorScheme;

    const dayLabels = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

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
                opacity: isToday ? 1.0 : 0.5,
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

  Widget _buildAddButton(BuildContext context, String dateStr, bool isDark) {
    final btnBack = isDark
        ? AppColors.neutralBtnBack
        : AppColors.neutralBtnBackLight;
    final btnBorder = isDark ? AppColors.lineDT200 : AppColors.lineLight200;
    final placeholderColor = isDark
        ? const Color(0xFF9CA0B2)
        : const Color(0xFF676E85);
    final iconColor = isDark ? Colors.white : AppColors.lightOnSurface;
    final micColor = _isListening ? AppColors.primary : iconColor;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: btnBack,
            borderRadius: BorderRadius.circular(42),
            border: Border.all(
              color: _isListening ? AppColors.primary.withValues(alpha: 0.5) : btnBorder,
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              GestureDetector(
                onTap: _toggleListening,
                onLongPress: () => _showAddMealSheet(dateStr),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/microphone.svg',
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(micColor, BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _recognizingText
                    ? Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: placeholderColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Распознаю...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: placeholderColor,
                            ),
                          ),
                        ],
                      )
                    : TextField(
                        controller: _inputCtl,
                        focusNode: _inputFocus,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 22 / 16,
                          color: isDark ? Colors.white : AppColors.lightOnSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Добавить запись',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 22 / 16,
                            color: placeholderColor,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitTextRecognition(dateStr),
                      ),
              ),
              const SizedBox(width: 8),
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
                  width: 40,
                  height: 40,
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
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  CameraScreen.pickAndShow(
                    context,
                    mealType: defaultMealType(),
                    dateStr: dateStr,
                    source: ImageSource.camera,
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/camera.svg',
                      width: 24,
                      height: 24,
                      colorFilter:
                          const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().first;
    final totalLength = metrics.length;

    final topCenterOffset = (rectW / 2) - r;
    final fillLength = totalLength * progress.clamp(0.0, 1.0);

    final fillPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: gradientColors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final extractedPath =
        metrics.extractPath(topCenterOffset, topCenterOffset + fillLength);
    canvas.drawPath(extractedPath, fillPaint);
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
