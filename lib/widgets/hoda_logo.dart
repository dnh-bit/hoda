import 'package:flutter/material.dart';

import '../theme/hoda_theme.dart';

/// Circular app logo with a gradient monogram fallback when the asset is
/// missing or fails to decode.
class HodaLogo extends StatelessWidget {
  final double size;
  const HodaLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/brand/app-profile.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [HodaColors.turquoise, HodaColors.gold],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              'هُد',
              style: TextStyle(
                fontFamily: HodaTheme.displayFontFamily,
                fontSize: size * 0.42,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
