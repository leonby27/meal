import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/services/locale_service.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/widgets/language_sheet.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_title_style.dart';

/// First onboarding screen: a marketing-style hero that introduces the
/// AI scanning feature, plus an inline language switcher so users who
/// landed in the wrong locale can fix it before answering any questions.
class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final localeCode = Localizations.localeOf(context).languageCode;

    // The welcome screen always fits a single viewport on supported
    // devices, so we drop the SingleChildScrollView wrapper — it was the
    // only source of the rubber-band overscroll the rest of the
    // onboarding doesn't have.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),
        const AspectRatio(
          aspectRatio: 1598 / 1396,
          child: _HeroScan(),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            context.l10n.onbWelcomeTitle,
            textAlign: TextAlign.center,
            style: onboardingTitleStyle(context, height: 32 / 24),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            context.l10n.onbWelcomeSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 22 / 16,
              color: cs.onSurface,
            ),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _LanguagePill(localeCode: localeCode),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hero scan card: the food photo loads immediately; layered animations
// (scan brackets fade-in for now, more coming) play on top, orchestrated
// from a single controller. Adding a new layer = add an Interval-curved
// animation that reads from [_ctrl] and pin its widget into the Stack.
// ---------------------------------------------------------------------------
class _HeroScan extends StatefulWidget {
  const _HeroScan();

  @override
  State<_HeroScan> createState() => _HeroScanState();
}

class _HeroScanState extends State<_HeroScan>
    with SingleTickerProviderStateMixin {
  // Master timeline (ms) — every layer's Interval maps into this range.
  // Bump this when adding later/longer animations.
  static const _timelineMs = 1600;

  // Food labels: anchor on the image (Alignment-space, [-1..1]) + content.
  // [offset] is a px nudge on top of the alignment, for fine-tuning.
  // [connectorSide] + [connectorLength] draw a thin line + dot pointing from
  // the pill toward the food. Order = appearance order on the timeline.
  static const _labels = <_LabelData>[
    _LabelData(
      kind: _LabelKind.salmon,
      calories: 127,
      align: Alignment(-0.05, -0.75),
      offset: Offset(-8, 0),
      connectorSide: _ConnectorSide.bottom,
      connectorLength: 60,
      connectorOffset: Offset(-40, 0),
    ),
    _LabelData(
      kind: _LabelKind.eggs,
      calories: 72,
      align: Alignment(0.5, -0.1),
      offset: Offset(32, -8),
      connectorSide: _ConnectorSide.left,
      connectorLength: 50,
    ),
    _LabelData(
      kind: _LabelKind.avocado,
      calories: 98,
      align: Alignment(-0.3, 0.3),
      offset: Offset(-20, -8),
      connectorSide: _ConnectorSide.top,
      connectorLength: 40,
    ),
    _LabelData(
      kind: _LabelKind.bread,
      calories: 189,
      align: Alignment(0.25, 0.7),
      offset: Offset(24, -8),
      connectorSide: _ConnectorSide.top,
      connectorLength: 60,
    ),
  ];

  late final AnimationController _ctrl;
  late final Animation<double> _scanOpacity;
  late final List<Animation<double>> _labelAnims;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _timelineMs),
    );
    _scanOpacity = _segment(200, 600);
    // Labels: each pops in over 250ms, staggered by 150ms after scan settles.
    _labelAnims = [
      for (var i = 0; i < _labels.length; i++)
        _segment(600 + i * 150, 850 + i * 150),
    ];
    _ctrl.forward();
  }

  Animation<double> _segment(int startMs, int endMs) {
    return CurvedAnimation(
      parent: _ctrl,
      curve: Interval(
        startMs / _timelineMs,
        endMs / _timelineMs,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/onboarding/welcome_food.jpg',
          fit: BoxFit.fitWidth,
          width: double.infinity,
          alignment: Alignment.topCenter,
        ),
        FadeTransition(
          opacity: _scanOpacity,
          child: Image.asset(
            'assets/onboarding/welcome_scan.png',
            fit: BoxFit.fitWidth,
            width: double.infinity,
            alignment: Alignment.topCenter,
          ),
        ),
        for (var i = 0; i < _labels.length; i++)
          Align(
            alignment: _labels[i].align,
            child: Transform.translate(
              offset: _labels[i].offset,
              child: _AnimatedPill(
                animation: _labelAnims[i],
                label: _labels[i].labelOf(context),
                value: context.l10n.kcalValue('${_labels[i].calories}'),
                connectorSide: _labels[i].connectorSide,
                connectorLength: _labels[i].connectorLength,
                connectorOffset: _labels[i].connectorOffset,
              ),
            ),
          ),
      ],
    );
  }
}

enum _ConnectorSide { top, bottom, left, right }

enum _LabelKind { salmon, eggs, avocado, bread }

class _LabelData {
  final _LabelKind kind;
  final int calories;
  final Alignment align;
  final Offset offset;
  final _ConnectorSide? connectorSide;
  final double connectorLength;
  final Offset connectorOffset;

  const _LabelData({
    required this.kind,
    required this.calories,
    required this.align,
    this.offset = Offset.zero,
    this.connectorSide,
    this.connectorLength = 0,
    this.connectorOffset = Offset.zero,
  });

  String labelOf(BuildContext context) {
    final l10n = context.l10n;
    return switch (kind) {
      _LabelKind.salmon => l10n.onbWelcomeLabelSalmon,
      _LabelKind.eggs => l10n.onbWelcomeLabelEggs,
      _LabelKind.avocado => l10n.onbWelcomeLabelAvocado,
      _LabelKind.bread => l10n.onbWelcomeLabelBread,
    };
  }
}

/// Dark pill — Inter Medium label (70% opacity) + Inter Bold weight on the
/// right. Optional connector line + dot points from one of the pill's sides
/// to a spot on the food. Pops in with a scale-from-0.85 + fade.
class _AnimatedPill extends StatelessWidget {
  static const _pillColor = Color(0xFF0E1220);

  final Animation<double> animation;
  final String label;
  final String value;
  final _ConnectorSide? connectorSide;
  final double connectorLength;
  final Offset connectorOffset;

  const _AnimatedPill({
    required this.animation,
    required this.label,
    required this.value,
    this.connectorSide,
    this.connectorLength = 0,
    this.connectorOffset = Offset.zero,
  });

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.fromLTRB(14, 7, 11, 7),
      decoration: BoxDecoration(
        color: _pillColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
              fontSize: 13,
              height: 1.2,
            ),
          ),
          const SizedBox(width: 22),
          const SizedBox(width: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              height: 1.2,
            ),
          ),
        ],
      ),
    );

    final pillWithConnector = connectorSide == null
        ? pill
        : Stack(
            clipBehavior: Clip.none,
            children: [
              // Connector first so the pill renders ON TOP — any overlap of
              // the line into the pill is hidden behind the pill rectangle.
              Positioned.fill(
                child: _Connector(
                  side: connectorSide!,
                  length: connectorLength,
                  offset: connectorOffset,
                  color: _pillColor,
                ),
              ),
              pill,
            ],
          );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.85 + 0.15 * t,
            child: child,
          ),
        );
      },
      child: pillWithConnector,
    );
  }
}

/// Thin line + small circular dot extending from one side of the pill toward
/// the food. Lives inside a Clip.none Stack with the pill so it can overflow
/// the pill's bounds.
class _Connector extends StatelessWidget {
  static const _lineWidth = 1.5;

  final _ConnectorSide side;
  final double length;
  final Offset offset;
  final Color color;

  const _Connector({
    required this.side,
    required this.length,
    required this.color,
    this.offset = Offset.zero,
  });

  @override
  Widget build(BuildContext context) {
    final isVertical =
        side == _ConnectorSide.top || side == _ConnectorSide.bottom;
    // Extend the line 2px into the pill so it sits flush behind it.
    final extendedLength = length + 2;
    final lineSize = isVertical
        ? Size(_lineWidth, extendedLength)
        : Size(extendedLength, _lineWidth);
    final dir = switch (side) {
      _ConnectorSide.top => -1.0,
      _ConnectorSide.bottom => 1.0,
      _ConnectorSide.left => -1.0,
      _ConnectorSide.right => 1.0,
    };
    final pillEdgeAlignment = switch (side) {
      _ConnectorSide.top => Alignment.topCenter,
      _ConnectorSide.bottom => Alignment.bottomCenter,
      _ConnectorSide.left => Alignment.centerLeft,
      _ConnectorSide.right => Alignment.centerRight,
    };
    // Align centers the line on the pill edge; shift outward by length/2
    // (less 1px so 2px overlaps into the pill). Plus any caller-supplied
    // [offset] for fine-tuning the attachment point on the pill edge.
    final lineOffset = (isVertical
            ? Offset(0, dir * (length / 2 - 1))
            : Offset(dir * (length / 2 - 1), 0)) +
        offset;

    return Align(
      alignment: pillEdgeAlignment,
      child: Transform.translate(
        offset: lineOffset,
        child: SizedBox.fromSize(
          size: lineSize,
          child: ColoredBox(color: color),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Language pill — flag + short code, opens the [LanguageSheet] modal.
// ---------------------------------------------------------------------------
class _LanguagePill extends StatelessWidget {
  final String localeCode;

  const _LanguagePill({required this.localeCode});

  String _shortLabel(BuildContext context, String code) {
    final l10n = context.l10n;
    switch (code) {
      case 'ru':
        return l10n.langShortRu;
      case 'de':
        return l10n.langShortDe;
      case 'es':
        return l10n.langShortEs;
      case 'fr':
        return l10n.langShortFr;
      case 'pt':
        return l10n.langShortPt;
      case 'pl':
        return l10n.langShortPl;
      case 'en':
      default:
        return l10n.langShortEn;
    }
  }

  String _flagAsset(String code) {
    // App locales use ISO 639-1; circle-flags uses ISO 3166-1 alpha-2.
    // English → Great Britain flag (matches Figma reference design).
    final flag = code == 'en' ? 'gb' : code;
    return 'assets/onboarding/flags/$flag.svg';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(122),
        onTap: () async {
          final next = await showLanguageSheet(context);
          if (next != null) {
            await LocaleNotifier.instance.setLocale(Locale(next));
          }
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
          decoration: BoxDecoration(
            color: AppColors.lightOnBack,
            borderRadius: BorderRadius.circular(122),
            border: Border.all(color: AppColors.lineLight100),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                offset: Offset(0, 7),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                _flagAsset(localeCode),
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 8),
              Text(
                _shortLabel(context, localeCode),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 22 / 16,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
