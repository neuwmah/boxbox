import 'package:flutter/material.dart';
import 'package:boxbox/sound/sfx.dart';
import 'package:boxbox/widgets/titlebar.dart';

const popupDim = 0.35;

class PopupAppear {
  PopupAppear._();

  static const duration = Duration(milliseconds: 300);
  static const opacityTween = _PopupOpacityTween();
  static const scaleTween = _PopupScaleTween();

  static double dim(double t) =>
      Curves.easeOut.transform((t / 0.36).clamp(0.0, 1.0));

  static double opacity(double t) =>
      Curves.easeOut.transform((t / 0.32).clamp(0.0, 1.0));

  static double scale(double t) {
    t = t.clamp(0.0, 1.0);
    if (t < 0.55) {
      final p = Curves.easeOutCubic.transform(t / 0.55);
      return 0.62 + 0.38 * p;
    }
    if (t < 0.78) {
      final p = Curves.easeInOutCubic.transform((t - 0.55) / 0.23);
      return 1.00 - 0.03 * p;
    }
    final p = Curves.easeOutCubic.transform((t - 0.78) / 0.22);
    return 0.97 + 0.03 * p;
  }
}

class _PopupOpacityTween extends Animatable<double> {
  const _PopupOpacityTween();

  @override
  double transform(double t) => PopupAppear.opacity(t);
}

class _PopupScaleTween extends Animatable<double> {
  const _PopupScaleTween();

  @override
  double transform(double t) => PopupAppear.scale(t);
}

class PopupDim extends StatelessWidget {
  const PopupDim({super.key, required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          return ColoredBox(
            color: Color.fromRGBO(
              0,
              0,
              0,
              popupDim * PopupAppear.dim(animation.value),
            ),
          );
        },
      ),
    );
  }
}

class PopupAppearFade extends StatelessWidget {
  const PopupAppearFade({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation.drive(PopupAppear.opacityTween),
      child: child,
    );
  }
}

class PopupAppearScale extends StatelessWidget {
  const PopupAppearScale({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation.drive(PopupAppear.opacityTween),
      child: ScaleTransition(
        scale: animation.drive(PopupAppear.scaleTween),
        alignment: Alignment.center,
        filterQuality: FilterQuality.low,
        child: RepaintBoundary(child: child),
      ),
    );
  }
}

class PopupShade {
  PopupShade._();

  static const start = Color(0xFF101010);
  static const end = Color(0xFF050505);
  static const depth = 4.0;
  static const steps = [4.0, 3.0, 2.0, 1.0];
  static const radius = 8.0;
  static const largeRadius = 32.0;
  static const _fillMix = 0.025;
  static const _borderMix = 0.25;

  static BorderRadius corners({
    double radius = radius,
    double largeRadius = largeRadius,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(largeRadius),
      topRight: Radius.circular(radius),
      bottomLeft: Radius.circular(radius),
      bottomRight: Radius.circular(largeRadius),
    );
  }

  static LinearGradient gradient([
    Color startColor = start,
    Color endColor = end,
  ]) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [startColor, endColor],
    );
  }

  static Color muted(Color color) => Color.lerp(Colors.black, color, _fillMix)!;

  static Color borderTint(Color color) =>
      Color.lerp(Colors.black, color, _borderMix)!;

  static LinearGradient fillGradient(Color color) {
    return LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [muted(color), Colors.black],
    );
  }

  static BoxDecoration panel({
    Color? color,
    double radius = radius,
    double largeRadius = largeRadius,
    double borderWidth = 1.6,
  }) {
    final tinted = color != null && color != start;
    return BoxDecoration(
      color: tinted ? null : Colors.black,
      gradient: tinted ? fillGradient(color!) : null,
      borderRadius: corners(radius: radius, largeRadius: largeRadius),
      border: Border.all(
        color: tinted ? borderTint(color!) : start,
        width: borderWidth,
      ),
    );
  }
}

class PopupBodyShade extends StatelessWidget {
  const PopupBodyShade({
    super.key,
    this.color = PopupShade.start,
    this.endColor = PopupShade.end,
  });

  final Color color;
  final Color endColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final o in PopupShade.steps)
          Positioned(
            left: o,
            top: o,
            right: PopupShade.depth - o,
            bottom: PopupShade.depth - o,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: PopupShade.corners(),
                gradient: PopupShade.gradient(color, endColor),
              ),
            ),
          ),
      ],
    );
  }
}

class PopupTitleBadge extends StatelessWidget {
  const PopupTitleBadge({
    super.key,
    required this.title,
    this.fontSize = 20,
    this.shadeColor = PopupShade.start,
    this.endColor = PopupShade.end,
  });

  final String title;
  final double fontSize;
  final Color shadeColor;
  final Color endColor;

  static const _padding = 10.0;
  static const _borderWidth = 1.0;
  static const _gapBelow = 24.0;
  static const _radius = 0.0;

  static double boxHeight([double fontSize = 24]) =>
      _padding * 2 + fontSize + _borderWidth * 2;

  static double overhang([double fontSize = 24]) => boxHeight(fontSize) / 2;

  @override
  Widget build(BuildContext context) {
    final half = overhang(fontSize);

    return SizedBox(
      height: half + _gapBelow,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: -half - 1,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final o in PopupShade.steps)
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(o, o),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: PopupShade.corners(
                            radius: _radius,
                            largeRadius: _radius,
                          ),
                          gradient: PopupShade.gradient(shadeColor, endColor),
                        ),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  decoration: PopupShade.panel(
                    color: shadeColor,
                    radius: _radius,
                    largeRadius: _radius,
                    borderWidth: _borderWidth,
                  ),
                  child: StickerTitle(title: title, fontSize: fontSize),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PopupCloseButton extends StatelessWidget {
  const PopupCloseButton({super.key, required this.onTap});

  final VoidCallback onTap;

  static const _size = 32.0;
  static const _asset = 'lib/assets/close.png';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Sfx.instance.tap(onTap),
      child: Image.asset(
        _asset,
        width: _size,
        height: _size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
