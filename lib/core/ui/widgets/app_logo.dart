import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders the Louvor4 logo, recoloring the "louvor" wordmark to match the
/// current theme while keeping the "4" mark's brand blue fixed.
class AppLogo extends StatelessWidget {
  final double height;

  const AppLogo({super.key, required this.height});

  static const _asset = 'assets/images/logos/logo-louvor4.svg';
  static const _wordmarkColorToken = '#b3b3b3';

  @override
  Widget build(BuildContext context) {
    final wordmarkColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final hex = '#${wordmarkColor.toARGB32().toRadixString(16).substring(2)}';

    return FutureBuilder<String>(
      future: DefaultAssetBundle.of(context).loadString(_asset),
      builder: (context, snapshot) {
        final svg = snapshot.data;
        if (svg == null) return SizedBox(height: height);
        return SvgPicture.string(
          svg.replaceAll(_wordmarkColorToken, hex),
          height: height,
        );
      },
    );
  }
}
