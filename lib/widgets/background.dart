import 'dart:math' as math;

import 'package:flutter/material.dart';

class RectBackground extends StatefulWidget {
  const RectBackground({super.key, this.child});

  final Widget? child;

  @override
  State<RectBackground> createState() => _RectBackgroundState();
}

class _RectBackgroundState extends State<RectBackground>
    with SingleTickerProviderStateMixin {
  static const _tileSize = 250.0;
  static const _duration = Duration(seconds: 16);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _controller,
          child: const RepaintBoundary(
            child: CustomPaint(
              painter: _RectPatternPainter(),
              isComplex: true,
              child: SizedBox.expand(),
            ),
          ),
          builder: (context, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final shift = _tileSize * _controller.value;
                return ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        left: -shift,
                        top: shift - _tileSize,
                        width: constraints.maxWidth + _tileSize,
                        height: constraints.maxHeight + _tileSize,
                        child: child!,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _RectPatternPainter extends CustomPainter {
  const _RectPatternPainter();

  static const _cell = 25.0;
  static const _light = Color(0xFF212121);
  static const _dark = Color(0xFF111111);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = _light
        ..isAntiAlias = false,
    );

    final dark = Paint()
      ..color = _dark
      ..isAntiAlias = false;
    final path = Path();
    final cols = (size.width / _cell).ceil();
    final rows = (size.height / _cell).ceil();
    for (var row = 0; row < rows; row++) {
      final y = row * _cell;
      for (var col = 0; col < cols; col++) {
        if ((row + col).isOdd) {
          path.addRect(Rect.fromLTWH(col * _cell, y, _cell, _cell));
        }
      }
    }
    canvas.drawPath(path, dark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PopupBackground extends StatefulWidget {
  const PopupBackground({super.key, this.offset = Offset.zero, this.tint});

  final Offset offset;
  final Color? tint;

  @override
  State<PopupBackground> createState() => _PopupBackgroundState();
}

class _PopupBackgroundState extends State<PopupBackground>
    with SingleTickerProviderStateMixin {
  static const _asset = 'lib/assets/background/highlight.png';
  static const _duration = Duration(seconds: 16);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    Future<void>.delayed(const Duration(milliseconds: 320), () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final size = math.sqrt(w * w + h * h) + widget.offset.distance * 2;

        return AnimatedBuilder(
          animation: _controller,
          child: OverflowBox(
            alignment: Alignment.center,
            maxWidth: size,
            maxHeight: size,
            child: SizedBox(
              width: size,
              height: size,
              child: RepaintBoundary(
                child: Image.asset(
                  _asset,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.low,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
          builder: (context, child) {
            return Transform.translate(
              offset: widget.offset,
              child: Transform.rotate(
                angle: _controller.value * 2 * math.pi,
                filterQuality: FilterQuality.low,
                child: child,
              ),
            );
          },
        );
      },
    );
  }

  Widget _tinted(Widget child) {
    final tint = widget.tint;
    if (tint == null) return child;
    return ColorFiltered(colorFilter: _lumaTint(tint), child: child);
  }

  static ColorFilter _lumaTint(Color tint, [double amount = 0.050]) {
    const source = 5 / 255;
    final s = amount / source / 3;
    final tr = tint.r * s;
    final tg = tint.g * s;
    final tb = tint.b * s;
    return ColorFilter.matrix([
      tr, tr, tr, 0, 0,
      tg, tg, tg, 0, 0,
      tb, tb, tb, 0, 0,
      0, 0, 0, 1, 0,
    ]);
  }
}
