import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Title style for onboarding step headers.
///
/// For the English locale we swap the body font for `Momo Trust Display`
/// — it reads more like a marketing header in Latin script, which matches
/// the conversion-tuned look of the funnel. For other locales we keep the
/// current Inter family so Cyrillic/CJK/extended Latin glyphs render
/// correctly (Momo Trust Display has limited script coverage).
TextStyle onboardingTitleStyle(
  BuildContext context, {
  double fontSize = 24,
  FontWeight fontWeight = FontWeight.w700,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  final cs = Theme.of(context).colorScheme;
  final resolvedColor = color ?? cs.onSurface;
  final base = TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: resolvedColor,
    height: height,
    letterSpacing: letterSpacing,
  );
  final isEnglish = Localizations.localeOf(context).languageCode == 'en';
  if (!isEnglish) return base;
  return GoogleFonts.momoTrustDisplay(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: resolvedColor,
    height: height,
    letterSpacing: letterSpacing,
  );
}
