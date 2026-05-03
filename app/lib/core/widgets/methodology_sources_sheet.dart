import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/core/utils/methodology_sources.dart';

Future<void> showMethodologySourcesSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return const _MethodologySourcesSheet();
    },
  );
}

class _MethodologySourcesSheet extends StatelessWidget {
  const _MethodologySourcesSheet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.86;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + media.padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withAlpha(70),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                context.l10n.profileMethodology,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.profileMethodologyIntro,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              _DisclaimerCard(text: context.l10n.resultDisclaimer),
              const SizedBox(height: 16),
              _SourceSection(
                title: context.l10n.methodologyCaloriesSection,
                sources: _sourcesFor(MethodologySourceCategory.calories),
              ),
              const SizedBox(height: 14),
              _SourceSection(
                title: context.l10n.methodologyMacrosSection,
                sources: _sourcesFor(MethodologySourceCategory.macros),
              ),
              const SizedBox(height: 14),
              _SourceSection(
                title: context.l10n.methodologyGeneralSection,
                sources: _sourcesFor(MethodologySourceCategory.general),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static List<MethodologySource> _sourcesFor(
    MethodologySourceCategory category,
  ) {
    return kMethodologySources
        .where((source) => source.category == category)
        .toList(growable: false);
  }
}

class _DisclaimerCard extends StatelessWidget {
  final String text;

  const _DisclaimerCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: cs.onSurfaceVariant.withAlpha(155),
        height: 1.35,
      ),
    );
  }
}

class _SourceSection extends StatelessWidget {
  final String title;
  final List<MethodologySource> sources;

  const _SourceSection({required this.title, required this.sources});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        for (var i = 0; i < sources.length; i++) ...[
          _SourceRow(source: sources[i]),
          if (i != sources.length - 1) const SizedBox(height: 2),
        ],
      ],
    );
  }
}

class _SourceRow extends StatelessWidget {
  final MethodologySource source;

  const _SourceRow({required this.source});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final secondaryColor = isDark
        ? AppColors.darkSecondaryDark
        : AppColors.lightSecondaryDark;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _openSource(context, source.url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: source.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                            height: 1.3,
                          ),
                        ),
                        TextSpan(
                          text: ' · ${source.publisher}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: secondaryColor,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.open_in_new, size: 14, color: secondaryColor),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              _descriptionFor(context, source),
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant.withAlpha(170),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _descriptionFor(BuildContext context, MethodologySource source) {
    if (source.url.contains('pubmed.ncbi.nlm.nih.gov')) {
      return context.l10n.methodologySourceMifflinDescription;
    }
    if (source.url.contains('NBK545442')) {
      return context.l10n.methodologySourceDriDescription;
    }
    if (source.url.contains('nal.usda.gov')) {
      return context.l10n.methodologySourceUsdaDescription;
    }
    return context.l10n.methodologySourceWhoDescription;
  }

  Future<void> _openSource(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorText = context.l10n.methodologyOpenSourceFailed;
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      messenger.showSnackBar(SnackBar(content: Text(errorText)));
    }
  }
}
