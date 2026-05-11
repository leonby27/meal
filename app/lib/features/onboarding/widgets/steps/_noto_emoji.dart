import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders a Noto Color Emoji as an SVG, sourced from the Iconify
/// `noto` icon set and bundled under `assets/onboarding/emoji/`.
///
/// Using SVG (not the platform color-emoji font) guarantees the exact
/// same illustration on iOS, Android and web — Apple Color Emoji is
/// stylistically different from Noto, so for product visuals we need
/// the SVG. Each glyph is small (~1-10 KB) and tree-shaken into the
/// bundle by Flutter's asset compiler.
class NotoEmoji extends StatelessWidget {
  final String name;
  final double size;

  const NotoEmoji({super.key, required this.name, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/onboarding/emoji/$name.svg',
      width: size,
      height: size,
      // Iconify SVGs are color-correct on their own — no tinting.
    );
  }
}
