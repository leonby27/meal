import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Title style for onboarding step headers.
///
/// Uses `Momo Trust Display` for Latin-script locales — it reads more like
/// a marketing header, matching the conversion-tuned look of the funnel.
/// The font's cmap has no Cyrillic, so Russian falls back to Inter; all of
/// en/de/es/fr/pt glyphs (incl. ÄÖÜß, áéíóúñ¿¡, àâæçœÿ«», ãõ) are covered.
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
  const momoSupported = {'en', 'de', 'es', 'fr', 'pt'};
  final lang = Localizations.localeOf(context).languageCode;
  if (!momoSupported.contains(lang)) return base;
  return GoogleFonts.momoTrustDisplay(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: resolvedColor,
    height: height,
    letterSpacing: letterSpacing,
  );
}
