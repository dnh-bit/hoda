import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/hoda_theme.dart';
import '../utils/fa_num.dart';

/// Fade + rise entrance animation.
///
/// Used with an increasing [delay] per item so lists and dashboards assemble
/// themselves instead of snapping into place. Pure Flutter, no packages.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 18,
    this.duration = HodaMotion.reveal,
  });

  final Widget child;
  final Duration delay;
  final double offset;
  final Duration duration;

  /// Convenience for list builders: staggers by [index], capped so long lists
  /// never wait.
  static Duration stagger(int index, {int stepMs = 55, int maxMs = 420}) {
    final int ms = index * stepMs;
    return Duration(milliseconds: ms > maxMs ? maxMs : ms);
  }

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<double> _slide = CurvedAnimation(
    parent: _controller,
    curve: HodaMotion.enter,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - _slide.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Tap target that scales down while pressed — the single detail that makes an
/// app feel responsive rather than static.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.haptic = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: HodaMotion.fast,
    reverseDuration: const Duration(milliseconds: 220),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) => _controller.forward();
  void _up(TapUpDetails _) => _controller.reverse();
  void _cancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? _down : null,
      onTapUp: enabled ? _up : null,
      onTapCancel: enabled ? _cancel : null,
      onTap: enabled
          ? () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap?.call();
            }
          : null,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final double t = 1 - ((1 - widget.scale) * _controller.value);
          return Transform.scale(scale: t, child: child);
        },
        child: widget.child,
      ),
    );
  }
}

/// A number that counts up to its new value, rendered with Persian digits.
class AnimatedFaNumber extends StatelessWidget {
  const AnimatedFaNumber({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 420),
    this.textAlign,
  });

  final int value;
  final TextStyle? style;
  final Duration duration;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double v, Widget? child) {
        return Text(
          FaNum.number(v.round()),
          style: style,
          textAlign: textAlign,
        );
      },
    );
  }
}

/// Skeleton block used while content loads — a shimmering placeholder reads as
/// "almost there", a bare spinner reads as "stuck".
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.height = 16,
    this.width,
    this.radius = HodaRadius.xs,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final HodaPalette palette = HodaPalette.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = _controller.value * 2 - 1;
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: HodaRadius.all(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(t - 0.6, 0),
              end: Alignment(t + 0.6, 0),
              colors: <Color>[
                palette.surfaceSunken.withOpacity(0.55),
                palette.surface.withOpacity(0.95),
                palette.surfaceSunken.withOpacity(0.55),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A full card-shaped skeleton, matching the real content card silhouette.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.lines = 3});

  final int lines;

  @override
  Widget build(BuildContext context) {
    final HodaPalette palette = HodaPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: palette.card(elevated: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const SkeletonBox(height: 34, width: 34, radius: HodaRadius.sm),
              const SizedBox(width: 10),
              const Expanded(child: SkeletonBox(height: 14)),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 16),
          const SkeletonBox(height: 22),
          const SizedBox(height: 14),
          for (int i = 0; i < lines; i++) ...<Widget>[
            SkeletonBox(width: i.isEven ? null : 220, height: 12),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
