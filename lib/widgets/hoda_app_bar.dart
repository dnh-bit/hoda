import 'package:flutter/material.dart';

import '../theme/hoda_theme.dart';
import 'hoda_pattern.dart';

/// The app bar used on every screen: the brand gradient, the star lattice, a
/// soft gold hairline at the bottom and rounded bottom corners.
///
/// It is a plain [AppBar] underneath, so titles, actions, back buttons and the
/// system overlay style all behave exactly as Material expects.
class HodaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HodaAppBar({
    super.key,
    this.title,
    this.titleText,
    this.actions,
    this.leading,
    this.leadingWidth,
    this.bottom,
    this.rounded = true,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
  });

  final Widget? title;
  final String? titleText;
  final List<Widget>? actions;
  final Widget? leading;
  final double? leadingWidth;
  final PreferredSizeWidget? bottom;
  final bool rounded;
  final bool centerTitle;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final HodaPalette palette = HodaPalette.of(context);
    final BorderRadius radius = rounded
        ? const BorderRadius.only(
            bottomLeft: Radius.circular(26),
            bottomRight: Radius.circular(26),
          )
        : BorderRadius.zero;

    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: centerTitle,
      titleSpacing: leading == null ? null : 0.0,
      leading: leading,
      leadingWidth: leadingWidth,
      title: title ?? (titleText == null ? null : Text(titleText!)),
      actions: actions,
      bottom: bottom,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: palette.heroGradient,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: palette.shadow,
              blurRadius: 18,
              offset: const Offset(0, 6),
              spreadRadius: -6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: PatternLayer(
                  color: Colors.white.withOpacity(0.055),
                  tile: 64,
                  drawGrid: false,
                ),
              ),
              PositionedDirectional(
                bottom: 0,
                start: 0,
                end: 0,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        HodaColors.gold.withOpacity(0),
                        HodaColors.goldLight.withOpacity(0.7),
                        HodaColors.gold.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
