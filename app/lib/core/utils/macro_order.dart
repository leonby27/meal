import 'package:flutter/widgets.dart';

/// The three tracked macronutrients. Used together with [MacroOrder] to
/// render every macro list/donut/chip group in the locale's culturally
/// expected sequence.
enum Macro { protein, fat, carbs }

/// Locale-dependent display order for proteins / fats / carbs.
///
/// Russian uses the long-established «БЖУ» order (Protein → Fat → Carbs),
/// which appears on virtually every Russian-language nutrition product
/// and tracking app. Western tracking apps overwhelmingly lead with carbs
/// (Carbs → Protein → Fat) because they're the largest macro group by
/// grams for most users. We standardize the rest of our locales on that
/// convention; add a new branch here to deviate per language.
class MacroOrder {
  MacroOrder._();

  static List<Macro> forLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'ru':
        return const [Macro.protein, Macro.fat, Macro.carbs];
      default:
        return const [Macro.carbs, Macro.protein, Macro.fat];
    }
  }

  static List<Macro> of(BuildContext context) =>
      forLocale(Localizations.localeOf(context));
}
