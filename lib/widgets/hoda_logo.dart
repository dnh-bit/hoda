import 'package:flutter/material.dart';

import '../theme/hoda_theme.dart';

/// Circular app logo with an optional gold ring and glow, plus a gradient
/// monogram fallback when the asset is missing or fails to decode.
class HodaLogo extends StatelessWidget {
  const HodaLogo({
    super.key,
    this.size = 40,
    this.ring = false,
    this.glow = false,
  });

  final double size;

  /// Thin gold ring around the logo (used in heroes and onboarding).
  final bool ring;

  /// Soft turquoise halo behind the logo.
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final double pad = ring ? size * 0.055 : 0;
    return Container(
      width: size + pad * 2,
      height: size + pad * 2,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ring
            ? const LinearGradient(
                colors: <Color>[HodaColors.goldLight, HodaColors.gold],
              )
            : null,
        boxShadow: glow
            ? <BoxShadow>[
                BoxShadow(
                  color: HodaColors.turquoiseLight.withOpacity(0.45),
                  blurRadius: size * 0.42,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipOval(
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
                colors: <Color>[HodaColors.turquoise, HodaColors.gold],
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
      ),
    );
  }
}
