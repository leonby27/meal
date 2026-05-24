import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';

/// Bottom-sheet language picker shown from the welcome screen.
/// Returns the chosen 2-letter language code (`'ru'`, `'en'`, …) or
/// `null` when the user dismisses without selecting.
Future<String?> showLanguageSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.lightOnBack,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => const _LanguageSheet(),
  );
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  static const _entries = [
    ('en', 'English', 'gb'),
    ('ru', 'Русский', 'ru'),
    ('de', 'Deutsch', 'de'),
    ('es', 'Español', 'es'),
    ('fr', 'Français', 'fr'),
    ('pt', 'Português', 'pt'),
    ('pl', 'Polski', 'pl'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentCode = Localizations.localeOf(context).languageCode;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grabber.
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cs.outline.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
              child: Text(
                context.l10n.onbLanguageSheetTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
            for (final entry in _entries)
              _LanguageRow(
                code: entry.$1,
                label: entry.$2,
                flagCode: entry.$3,
                isSelected: entry.$1 == currentCode,
                onTap: () => Navigator.of(context).pop(entry.$1),
              ),
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final String code;
  final String label;
  final String flagCode;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageRow({
    required this.code,
    required this.label,
    required this.flagCode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/onboarding/flags/$flagCode.svg',
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              )
            else
              Icon(
                Icons.radio_button_unchecked,
                color: cs.outline,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
