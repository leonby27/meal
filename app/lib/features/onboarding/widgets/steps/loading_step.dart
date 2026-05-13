import 'dart:async';

import 'package:flutter/material.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/services/analytics_service.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';

class LoadingStep extends StatefulWidget {
  final VoidCallback onFinished;

  const LoadingStep({super.key, required this.onFinished});

  @override
  State<LoadingStep> createState() => _LoadingStepState();
}

class _LoadingStepState extends State<LoadingStep>
    with SingleTickerProviderStateMixin {
  static const _totalDuration = Duration(seconds: 6);
  static const _captionInterval = Duration(milliseconds: 1200);

  static const _captionsCount = 5;

  List<String> _captions(BuildContext context) {
    final l10n = context.l10n;
    return [
      l10n.loadingMetabolism,
      l10n.loadingCalories,
      l10n.loadingMacros,
      l10n.loadingPsychotype,
      l10n.loadingPlanCreate,
    ];
  }

  late final AnimationController _controller;
  late final Timer _textTimer;
  int _textIndex = 0;
  final Stopwatch _stopwatch = Stopwatch();
  bool _loggedCompletion = false;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    unawaited(
      AnalyticsService.instance.logEvent(
        'onboarding_loading_started',
        parameters: {'duration_ms_target': _totalDuration.inMilliseconds},
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: _totalDuration,
    )..forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _logCompletionOnce();
        widget.onFinished();
      }
    });

    _textTimer = Timer.periodic(_captionInterval, (timer) {
      if (!mounted) return;
      if (_textIndex < _captionsCount - 1) {
        setState(() => _textIndex++);
      } else {
        timer.cancel();
      }
    });
  }

  /// Fires exactly once per mount. We log on both natural completion
  /// (status listener) and on dispose-before-completion, so the started/
  /// completed counts diverge cleanly into «finished» vs «abandoned».
  void _logCompletionOnce({bool abandoned = false}) {
    if (_loggedCompletion) return;
    _loggedCompletion = true;
    _stopwatch.stop();
    unawaited(
      AnalyticsService.instance.logEvent(
        abandoned
            ? 'onboarding_loading_abandoned'
            : 'onboarding_loading_completed',
        parameters: {'elapsed_ms': _stopwatch.elapsedMilliseconds},
      ),
    );
  }

  @override
  void dispose() {
    // If the step is unmounted before the animation completed, it means
    // the user either backgrounded the app and we got killed, or moved
    // backwards in the flow — both count as «abandoned» for the loader.
    if (!_loggedCompletion) _logCompletionOnce(abandoned: true);
    _controller.dispose();
    _textTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: _controller.value,
                        strokeWidth: 6,
                        backgroundColor: cs.outline.withAlpha(60),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '${(_controller.value * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Padding(
              key: ValueKey(_textIndex),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _captions(context)[_textIndex],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
