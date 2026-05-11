import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:meal_tracker/app/theme.dart';

/// Vertical ruler-style numeric picker.
///
/// Pairs a vertical scrollable scale (ticks + occasional labels) on the
/// left with a large readout to the right, both anchored on a centre
/// indicator line. Higher values render visually higher — natural for
/// height input ("taller = up"). See [RulerPicker] for the horizontal
/// sibling used by weight/age scales.
class VerticalRulerPicker extends StatefulWidget {
  final double value;
  final double min;
  final double max;

  /// Snapping increment (1.0 for cm, 1.0 for years, 0.5 for kg, etc.).
  final double step;

  /// Pixel distance between two adjacent ticks along the vertical axis.
  final double tickSpacing;

  /// Every Nth tick is rendered taller (a "major" tick). Counted in steps.
  final int majorTickEvery;

  /// Every Nth tick gets a numeric label next to it. Counted in steps.
  final int labelEvery;

  /// Optional small text shown after the readout (e.g. "cm").
  final String? unit;

  final ValueChanged<double> onChanged;

  final String Function(double value)? formatLabel;
  final String Function(double value)? formatReadout;

  const VerticalRulerPicker({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    this.tickSpacing = 8.0,
    this.majorTickEvery = 10,
    this.labelEvery = 10,
    this.unit,
    this.formatLabel,
    this.formatReadout,
  });

  @override
  State<VerticalRulerPicker> createState() => _VerticalRulerPickerState();
}

class _VerticalRulerPickerState extends State<VerticalRulerPicker> {
  late final ScrollController _controller;
  int _lastTickIndex = 0;
  bool _isProgrammaticScroll = false;

  // The ruler content lays out `max` at the top, `min` at the bottom,
  // so index 0 corresponds to the highest value. This lets a user
  // intuitively flick downward to "go shorter" and upward to "go taller".
  int get _stepCount =>
      math.max(0, ((widget.max - widget.min) / widget.step).round());

  int _valueToIndex(double v) {
    final clamped = v.clamp(widget.min, widget.max);
    return ((widget.max - clamped) / widget.step).round().clamp(0, _stepCount);
  }

  double _indexToValue(int i) {
    final v = widget.max - i * widget.step;
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
  void didUpdateWidget(covariant VerticalRulerPicker oldWidget) {
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
      await _controller.animateTo(offset, duration: duration, curve: curve);
    } finally {
      _isProgrammaticScroll = false;
    }
  }

  Future<void> _animateToIndex(int idx) async {
    if (!_controller.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _animateToIndex(idx);
      });
      return;
    }
    _lastTickIndex = idx;
    await _runProgrammaticScroll(idx * widget.tickSpacing);
  }

  String _defaultFormat(double v) {
    if (widget.step >= 1) return v.round().toString();
    return v.toStringAsFixed(1);
  }

  String _readoutText(double v) {
    final f = widget.formatReadout ?? widget.formatLabel ?? _defaultFormat;
    return f(v);
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

    const rulerWidth = 88.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.maxHeight;
        final totalHeight = _stepCount * widget.tickSpacing;
        return Stack(
          fit: StackFit.expand,
          children: [
            // Full-area scrollable: dragging anywhere in the picker — even
            // over the empty space beside the readout — moves the ruler.
            // Ticks are still painted only in the leftmost [rulerWidth].
            Positioned.fill(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScrollNotification,
                child: ScrollConfiguration(
                  behavior: const _NoGlowBehavior(),
                  child: ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black,
                        Colors.black,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.14, 0.86, 1.0],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: SingleChildScrollView(
                      controller: _controller,
                      scrollDirection: Axis.vertical,
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: viewport / 2),
                        child: SizedBox(
                          width: double.infinity,
                          height: totalHeight,
                          child: CustomPaint(
                            painter: _VerticalRulerPainter(
                              stepCount: _stepCount,
                              tickSpacing: widget.tickSpacing,
                              majorEvery: widget.majorTickEvery,
                              labelEvery: widget.labelEvery,
                              max: widget.max,
                              step: widget.step,
                              rulerWidth: rulerWidth,
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
            // Centre indicator — short horizontal bar pinned at the
            // viewport's vertical centre, aligned to the ruler column.
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: rulerWidth,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            // Readout sits in the space to the right of the ruler. It
            // ignores pointer events so the full picker area remains
            // scrollable.
            Positioned(
              left: rulerWidth,
              top: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    final live = _currentLiveValue();
                    return Center(
                      child: _Readout(
                        text: _readoutText(live),
                        unit: widget.unit,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
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
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
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
            child: Text(text, key: ValueKey(text), style: readoutStyle),
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

class _VerticalRulerPainter extends CustomPainter {
  final int stepCount;
  final double tickSpacing;
  final int majorEvery;
  final int labelEvery;
  final double max;
  final double step;
  final double rulerWidth;
  final String Function(double value) formatLabel;
  final Color labelColor;
  final Color majorTickColor;
  final Color minorTickColor;

  _VerticalRulerPainter({
    required this.stepCount,
    required this.tickSpacing,
    required this.majorEvery,
    required this.labelEvery,
    required this.max,
    required this.step,
    required this.rulerWidth,
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

    // Ticks extend horizontally from the right edge of the ruler column
    // inward. Major ticks are longer; label sits to the left of the tick.
    final tickRightEdge = rulerWidth - 12; // leave room for the indicator
    final majorTickLength = 16.0;
    final minorTickLength = 8.0;

    for (var i = 0; i <= stepCount; i++) {
      final y = i * tickSpacing;
      final isMajor = i % majorEvery == 0;
      final paint = isMajor ? majorPaint : minorPaint;
      final length = isMajor ? majorTickLength : minorTickLength;
      canvas.drawLine(
        Offset(tickRightEdge - length, y),
        Offset(tickRightEdge, y),
        paint,
      );
    }

    for (var i = 0; i <= stepCount; i++) {
      if (i % labelEvery != 0) continue;
      final y = i * tickSpacing;
      final value = max - i * step;
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
      // Labels sit left of the ticks, vertically centered on the tick.
      tp.paint(
        canvas,
        Offset(
          tickRightEdge - majorTickLength - 6 - tp.width,
          y - tp.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalRulerPainter old) =>
      old.stepCount != stepCount ||
      old.tickSpacing != tickSpacing ||
      old.majorEvery != majorEvery ||
      old.labelEvery != labelEvery ||
      old.max != max ||
      old.step != step ||
      old.rulerWidth != rulerWidth ||
      old.labelColor != labelColor ||
      old.majorTickColor != majorTickColor ||
      old.minorTickColor != minorTickColor;
}
