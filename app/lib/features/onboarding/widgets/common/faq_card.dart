import 'package:flutter/material.dart';

import 'package:meal_tracker/features/onboarding/widgets/steps/_title_style.dart';

/// Reusable FAQ card with collapsible Q&A rows.
///
/// Extracted from `result_step.dart` so both the onboarding result screen
/// and the paywall can share the same widget. The result screen passes the
/// lavender bg from Figma; the paywall passes `#F5F6F8` to match its
/// surrounding cards. Default keeps the paywall tone so callers that don't
/// specify a colour get the more neutral look.
class FaqCard extends StatefulWidget {
  final String header;
  final List<({String question, String answer})> items;

  /// Background colour for the card. Defaults to `#F5F6F8` (paywall tone);
  /// result_step passes the lavender `#E2E2F0` it had hardcoded before.
  final Color background;

  const FaqCard({
    super.key,
    required this.header,
    required this.items,
    this.background = const Color(0xFFF5F6F8),
  });

  @override
  State<FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<FaqCard> {
  // Tracks which row is currently open. Null = all collapsed. Only one row
  // open at a time keeps the card compact and avoids long vertical jumps.
  int? _expanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.background,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.header,
            style: onboardingTitleStyle(
              context,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 24 / 18,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < widget.items.length; i++) ...[
            _FaqRow(
              question: widget.items[i].question,
              answer: widget.items[i].answer,
              expanded: _expanded == i,
              onTap: () => setState(
                () => _expanded = _expanded == i ? null : i,
              ),
            ),
            if (i != widget.items.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _FaqRow extends StatelessWidget {
  final String question;
  final String answer;
  final bool expanded;
  final VoidCallback onTap;

  const _FaqRow({
    required this.question,
    required this.answer,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                    height: 20 / 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 6, right: 28),
                    child: Text(
                      answer,
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurface,
                        height: 20 / 14,
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
