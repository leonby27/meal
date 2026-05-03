/// Bibliographic citations for the health/nutrition science behind the
/// app's daily calorie and macronutrient recommendations.
///
/// Citations are kept in standard scientific format (English author/journal
/// names are universal across locales). Display labels around them are
/// localized via the regular l10n system.
library;

enum MethodologySourceCategory { calories, macros, general }

class MethodologySource {
  final MethodologySourceCategory category;
  final String title;
  final String publisher;
  final String citation;
  final String url;

  const MethodologySource({
    required this.category,
    required this.title,
    required this.publisher,
    required this.citation,
    required this.url,
  });
}

const String kMethodologyCitationCalories =
    'Mifflin MD, St Jeor ST, Hill LA, Scott BJ, Daugherty SA, Koh YO. '
    'A new predictive equation for resting energy expenditure in healthy '
    'individuals. Am J Clin Nutr. 1990;51(2):241–247.';

const String kMethodologyCitationMacros =
    'Institute of Medicine. Dietary Reference Intakes for Energy, '
    'Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and '
    'Amino Acids. Washington, DC: National Academies Press; 2005.';

const List<MethodologySource> kMethodologySources = [
  MethodologySource(
    category: MethodologySourceCategory.calories,
    title: 'Mifflin-St Jeor equation',
    publisher: 'PubMed',
    citation: kMethodologyCitationCalories,
    url: 'https://pubmed.ncbi.nlm.nih.gov/2305711/',
  ),
  MethodologySource(
    category: MethodologySourceCategory.macros,
    title: 'Dietary Reference Intakes',
    publisher: 'National Academies / NCBI',
    citation: kMethodologyCitationMacros,
    url: 'https://www.ncbi.nlm.nih.gov/books/NBK545442/',
  ),
  MethodologySource(
    category: MethodologySourceCategory.macros,
    title: 'USDA DRI Calculator',
    publisher: 'USDA',
    citation:
        'USDA National Agricultural Library. DRI Calculator for Healthcare Professionals.',
    url:
        'https://www.nal.usda.gov/human-nutrition-and-food-safety/dri-calculator',
  ),
  MethodologySource(
    category: MethodologySourceCategory.general,
    title: 'Healthy diet',
    publisher: 'World Health Organization',
    citation: 'World Health Organization. Healthy diet fact sheet.',
    url: 'https://www.who.int/news-room/fact-sheets/detail/healthy-diet',
  ),
];
