import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:meal_tracker/app/theme.dart';

/// Horizontal ruler-style numeric picker.
///
/// Replacement for [ListWheelScrollView] in onboarding measurements
/// (height, weight, target weight). Compared to a wheel:
///
/// - The whole scale is visible at a glance — labels every
///   [labelEvery] steps act as anchors so the user can position
///   themselves quickly.
/// - The fixed center marker makes the selection unambiguous.
class RulerPicker extends StatefulWidget {
  /// Current value. Will be clamped into [[min], [max]] and snapped
  /// to the nearest [step].
  final double value;
  final double min;
  final double max;

  /// Snapping increment. Each tick on the ruler corresponds to one
  /// [step]. For weight in kg this is typically `0.5`, for height
  /// in cm `1.0`, for years `1.0`.
  final double step;

  /// Called whenever the snapped value changes.
  final ValueChanged<double> onChanged;

  /// Pixel distance between two adjacent ticks. Smaller values make
  /// the ruler more compact, larger values give more "throw" per
  /// unit. 12 is a comfortable default for cm/year scales; for
  /// finer steps (0.5) consider 8.
  final double tickSpacing;

  /// Every Nth tick is rendered taller (a "major" tick). Counted in
  /// steps, not in units.
  final int majorTickEvery;

  /// Every Nth tick gets a label printed above it. Counted in steps.
  final int labelEvery;

  /// Total height of the ruler portion (ticks + labels).
  final double rulerHeight;

  /// Format function for tick labels (top of the ruler). Defaults
  /// to integer formatting.
  final String Function(double value)? formatLabel;

  /// Format function for the big readout. Defaults to the same
  /// formatter as [formatLabel] when omitted, otherwise identity
  /// integer formatting.
  final String Function(double value)? formatReadout;

  /// Optional small text shown under the readout (units like "cm").
  final String? unit;

  const RulerPicker({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    this.tickSpacing = 12.0,
    this.majorTickEvery = 5,
    this.labelEvery = 5,
    this.rulerHeight = 80.0,
    this.formatLabel,
    this.formatReadout,
    this.unit,
  });

  @override
  State<RulerPicker> createState() => _RulerPickerState();
}

class _RulerPickerState extends State<RulerPicker> {
  late final ScrollController _controller;
  int _lastTickIndex = 0;
  bool _isProgrammaticScroll = false;

  int get _stepCount => math.max(
    0,
    ((widget.max - widget.min) / widget.step).round(),
  );

  int _valueToIndex(double v) {
    final clamped = v.clamp(widget.min, widget.max);
    return ((clamped - widget.min) / widget.step).round().clamp(0, _stepCount);
  }

  double _indexToValue(int i) {
    final v = widget.min + i * widget.step;
    return v.clamp(widget.min, widget.max);
  }

  @override
  void initState() {
    super.initState();
    _lastTickIndex = _valueToIndex(widget.value);
    _controller = ScrollController(
      initialScrollOffset: _lastTickIndex * widget.tickSpacing,
    );
    _controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant RulerPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final externalIndex = _valueToIndex(widget.value);
    if (externalIndex != _lastTickIndex) {
      _animateToIndex(externalIndex);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    if (_isProgrammaticScroll) return;
    final raw = _controller.offset / widget.tickSpacing;
    final idx = raw.round().clamp(0, _stepCount);
    if (idx != _lastTickIndex) {
      _lastTickIndex = idx;
      HapticFeedback.selectionClick();
      widget.onChanged(_indexToValue(idx));
    }
  }

  bool _onScrollNotification(ScrollNotification n) {
    if (n is ScrollEndNotification &&
        _controller.hasClients &&
        !_isProgrammaticScroll) {
      final idx = (_controller.offset / widget.tickSpacing).round().clamp(
        0,
        _stepCount,
      );
      final target = idx * widget.tickSpacing;
      if ((_controller.offset - target).abs() > 0.25) {
        _runProgrammaticScroll(
          target,
          duration: const Duration(milliseconds: 180),
        );
      }
    }
    return false;
  }

  Future<void> _runProgrammaticScroll(
    double offset, {
    Duration duration = const Duration(milliseconds: 220),
    Curve curve = Curves.easeOutCubic,
  }) async {
    if (!_controller.hasClients) return;
    _isProgrammaticScroll = true;
    try {
      await _controller.animateTo(
        offset,
        duration: duration,
        curve: curve,
      );
    } finally {
      _isProgrammaticScroll = false;
    }
  }

  Future<void> _animateToIndex(int idx) async {
    if (!_controller.hasClients) {
      // The controller isn't attached yet (first frame). Schedule an
      // animation on the next frame so the position is correct after
      // mount.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _animateToIndex(idx);
      });
      return;
    }
    _lastTickIndex = idx;
    await _runProgrammaticScroll(idx * widget.tickSpacing);
  }

  String _readoutText(double v) {
    final f = widget.formatReadout ?? widget.formatLabel ?? _defaultFormat;
    return f(v);
  }

  String _defaultFormat(double v) {
    if (widget.step >= 1) return v.round().toString();
    return v.toStringAsFixed(1);
  }

  double _currentLiveValue() {
    if (!_controller.hasClients) return _indexToValue(_lastTickIndex);
    final raw = _controller.offset / widget.tickSpacing;
    final idx = raw.round().clamp(0, _stepCount);
    return _indexToValue(idx);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const readoutBlockHeight = 60.0;
    const gap = 16.0;
    final totalPickerHeight = readoutBlockHeight + gap + widget.rulerHeight;

    return SizedBox(
      height: totalPickerHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = constraints.maxWidth;
          final totalWidth = _stepCount * widget.tickSpacing;
          return Stack(
            fit: StackFit.expand,
            children: [
              // Full-area horizontal scrollable: dragging anywhere in the
              // picker (including over the big readout) moves the ruler.
              // The painter draws ticks only in the bottom ruler band.
              Positioned.fill(
                child: NotificationListener<ScrollNotification>(
                  onNotification: _onScrollNotification,
                  child: ScrollConfiguration(
                    behavior: const _NoGlowBehavior(),
                    child: ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.black,
                          Colors.black,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.10, 0.90, 1.0],
                      ).createShader(rect),
                      blendMode: BlendMode.dstIn,
                      child: SingleChildScrollView(
                        controller: _controller,
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: viewport / 2,
                          ),
                          child: SizedBox(
                            width: totalWidth,
                            height: totalPickerHeight,
                            child: CustomPaint(
                              painter: _RulerPainter(
                                stepCount: _stepCount,
                                tickSpacing: widget.tickSpacing,
                                majorEvery: widget.majorTickEvery,
                                labelEvery: widget.labelEvery,
                                min: widget.min,
                                step: widget.step,
                                rulerOffsetY: readoutBlockHeight + gap,
                                rulerHeight: widget.rulerHeight,
                                formatLabel:
                                    widget.formatLabel ?? _defaultFormat,
                                labelColor: cs.onSurfaceVariant,
                                majorTickColor: cs.onSurface.withAlpha(
                                  isDark ? 200 : 220,
                                ),
                                minorTickColor: cs.onSurfaceVariant.withAlpha(
                                  isDark ? 110 : 140,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Readout sits in the top band, aligned to the bottom so it
              // hugs the ruler with the same gap the Column used before.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: readoutBlockHeight,
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) {
                        final live = _currentLiveValue();
                        return _Readout(
                          text: _readoutText(live),
                          unit: widget.unit,
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Centre indicator — vertical bar pinned in the middle of
              // the ruler band.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: widget.rulerHeight,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 4,
                      height: widget.rulerHeight - 24,
                      margin: const EdgeInsets.only(top: 24),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Readout extends StatelessWidget {
  final String text;
  final String? unit;

  const _Readout({required this.text, this.unit});

  static Widget _readoutTransition(Widget child, Animation<double> animation) {
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: slide, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final readoutStyle = TextStyle(
      fontSize: 52,
      height: 1.05,
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          alignment: Alignment.centerRight,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 140),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: _readoutTransition,
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.bottomCenter,
                children: [...previousChildren, ?currentChild],
              );
            },
            child: Text(
              text,
              key: ValueKey(text),
              style: readoutStyle,
            ),
          ),
        ),
        if (unit != null) ...[
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              unit!,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _NoGlowBehavior extends ScrollBehavior {
  const _NoGlowBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

class _RulerPainter extends CustomPainter {
  final int stepCount;
  final double tickSpacing;
  final int majorEvery;
  final int labelEvery;
  final double min;
  final double step;
  final double rulerOffsetY;
  final double rulerHeight;
  final String Function(double value) formatLabel;
  final Color labelColor;
  final Color majorTickColor;
  final Color minorTickColor;

  _RulerPainter({
    required this.stepCount,
    required this.tickSpacing,
    required this.majorEvery,
    required this.labelEvery,
    required this.min,
    required this.step,
    required this.rulerOffsetY,
    required this.rulerHeight,
    required this.formatLabel,
    required this.labelColor,
    required this.majorTickColor,
    required this.minorTickColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final majorPaint = Paint()
      ..color = majorTickColor
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final minorPaint = Paint()
      ..color = minorTickColor
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    const labelAreaHeight = 24.0;
    final tickAreaTop = rulerOffsetY + labelAreaHeight;
    final tickAreaBottom = rulerOffsetY + rulerHeight;
    final tickAreaHeight = tickAreaBottom - tickAreaTop;
    final majorTickHeight = tickAreaHeight * 0.62;
    final minorTickHeight = tickAreaHeight * 0.34;

    for (var i = 0; i <= stepCount; i++) {
      final x = i * tickSpacing;
      final isMajor = i % majorEvery == 0;
      final paint = isMajor ? majorPaint : minorPaint;
      final h = isMajor ? majorTickHeight : minorTickHeight;
      canvas.drawLine(
        Offset(x, tickAreaBottom - h),
        Offset(x, tickAreaBottom),
        paint,
      );
    }

    for (var i = 0; i <= stepCount; i++) {
      if (i % labelEvery != 0) continue;
      final x = i * tickSpacing;
      final value = min + i * step;
      final tp = TextPainter(
        text: TextSpan(
          text: formatLabel(value),
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, rulerOffsetY + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter old) =>
      old.stepCount != stepCount ||
      old.tickSpacing != tickSpacing ||
      old.majorEvery != majorEvery ||
      old.labelEvery != labelEvery ||
      old.min != min ||
      old.step != step ||
      old.rulerOffsetY != rulerOffsetY ||
      old.rulerHeight != rulerHeight ||
      old.labelColor != labelColor ||
      old.majorTickColor != majorTickColor ||
      old.minorTickColor != minorTickColor;
}
