import 'package:flutter/material.dart';

import '../theme/hoda_theme.dart';
import 'hoda_pattern.dart';

/// Friendly placeholder shown when a list or collection has no items.
///
/// The icon sits inside a slowly breathing halo, so an empty screen still feels
/// alive rather than broken.
class EmptyState extends StatefulWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final Color? color;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HodaPalette palette = HodaPalette.of(context);
    final Color color = widget.color ?? palette.accent;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                final double t =
                    Curves.easeInOut.transform(_controller.value);
                return Container(
                  width: 128 + t * 8,
                  height: 128 + t * 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        color.withOpacity(0.16 + t * 0.06),
                        color.withOpacity(0),
                      ],
                    ),
                  ),
                  child: child,
                );
              },
              child: Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.surface,
                    border: Border.all(color: color.withOpacity(0.35)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: PatternLayer(
                          color: color.withOpacity(0.10),
                          tile: 42,
                          drawGrid: false,
                        ),
                      ),
                      Center(
                        child: Icon(widget.icon, size: 36, color: color),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (widget.message != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                widget.message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (widget.action != null) ...<Widget>[
              const SizedBox(height: 22),
              widget.action!,
            ],
          ],
        ),
      ),
    );
  }
}
