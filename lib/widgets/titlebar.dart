import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class AppTitleBar extends StatelessWidget {
  const AppTitleBar({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF000000),
            Color(0xFF000000),
          ],
        ),
      ),
      child: DragToMoveArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 35),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: Center(
              child: StickerTitle(title: title),
            ),
          ),
        ),
      ),
    );
  }
}

class StickerTitle extends StatelessWidget {
  const StickerTitle({
    super.key,
    required this.title,
    this.fontSize = 20,
  });

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
            child: Text(
              title,
              style: base.copyWith(color: depthColor),
            ),
          ),
        Text(
          title,
          style: base.copyWith(color: Colors.white),
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
  });

  final String title;
  final double fontSize;

  static const _padding = 10.0;
  static const _borderWidth = 1.0;
  static const _borderColor = Color(0xFF101010);
  static const _gapBelow = 24.0;
  static const _shadeSteps = [4.0, 3.0, 2.0, 1.0];

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
                for (final o in _shadeSteps)
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(o, o),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF101010),
                              Color(0xFF050505),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(
                      color: _borderColor,
                      width: _borderWidth,
                    ),
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
  });

  final VoidCallback onTap;

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
          border: Border.all(color: _border, width: 1.6),
        ),
        child: const Center(
          child: CustomPaint(
            size: Size(8, 8),
            painter: _CloseIconPainter(
              color: Colors.white,
              strokeWidth: 2.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseIconPainter extends CustomPainter {
  const _CloseIconPainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _CloseIconPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
