import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class AppTitleBar extends StatelessWidget {
  const AppTitleBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF000000), Color(0xFF000000)],
        ),
      ),
      child: DragToMoveArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 35),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: Center(child: StickerTitle(title: title)),
          ),
        ),
      ),
    );
  }
}

class StickerTitle extends StatelessWidget {
  const StickerTitle({super.key, required this.title, this.fontSize = 20});

  final String title;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    const depthColor = Color(0xFF313131);
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      height: 1,
      letterSpacing: -.4,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        for (final offset in const [
          Offset(1, 1),
          Offset(2, 2),
          Offset(0, 1),
          Offset(1, 0),
          Offset(1, 2),
          Offset(2, 1),
        ])
          Transform.translate(
            offset: offset,
            child: Text(title, style: base.copyWith(color: depthColor)),
          ),
        Text(title, style: base.copyWith(color: Colors.white)),
      ],
    );
  }
}

class PopupAppear {
  PopupAppear._();

  static const duration = Duration(milliseconds: 300);
  static const dimAlpha = 0.55;
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
              PopupAppear.dimAlpha * PopupAppear.dim(animation.value),
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
  static const _fillMix = 0.025;
  static const _borderMix = 0.25;

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
    double radius = 8,
    double borderWidth = 1.6,
  }) {
    final tinted = color != null && color != start;
    return BoxDecoration(
      color: tinted ? null : Colors.black,
      gradient: tinted ? fillGradient(color!) : null,
      borderRadius: BorderRadius.circular(radius),
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
                borderRadius: const BorderRadius.all(Radius.circular(8)),
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
                          borderRadius: const BorderRadius.all(
                            Radius.circular(4),
                          ),
                          gradient: PopupShade.gradient(shadeColor, endColor),
                        ),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: PopupShade.panel(
                    color: shadeColor,
                    radius: 4,
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
  const PopupCloseButton({
    super.key,
    required this.onTap,
    this.borderColor = _border,
  });

  final VoidCallback onTap;
  final Color borderColor;

  static const _size = 32.0;
  static const _border = Color(0xFF101010);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.6),
        ),
        child: const Center(
          child: CustomPaint(
            size: Size(8, 8),
            painter: _CloseIconPainter(color: Colors.white, strokeWidth: 2.4),
          ),
        ),
      ),
    );
  }
}

class _CloseIconPainter extends CustomPainter {
  const _CloseIconPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _CloseIconPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
