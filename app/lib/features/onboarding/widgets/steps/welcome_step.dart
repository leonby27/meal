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

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  const _HeroScan(),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      context.l10n.onbWelcomeTitle,
                      textAlign: TextAlign.center,
                      style: onboardingTitleStyle(
                        context,
                        height: 32 / 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
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
                  _LanguagePill(localeCode: localeCode),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Hero scan card: a pre-rendered illustration (phone frame + scan brackets
// + macro chips), exported from Figma. Bundled as a single asset so the
// composition matches the design pixel-for-pixel.
// ---------------------------------------------------------------------------
class _HeroScan extends StatelessWidget {
  const _HeroScan();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/onboarding/welcome_food.png',
      fit: BoxFit.contain,
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
