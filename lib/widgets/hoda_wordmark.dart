import 'package:flutter/material.dart';

/// The «الله» gold calligraphy wordmark (user-supplied artwork, white removed).
/// Replaces the text «هُدا» in app bars and heroes; height-driven so it scales
/// cleanly. Fallback tint keeps it visible if the PNG ever fails to decode.
class HodaWordmark extends StatelessWidget {
  const HodaWordmark({super.key, this.height = 34});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/hoda-allah-calligraphy.png',
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => Text(
        'هُدا',
        style: TextStyle(fontSize: height * 0.72, fontWeight: FontWeight.w700),
      ),
    );
  }
}
