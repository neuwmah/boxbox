import 'dart:math' as math;

import 'package:boxbox/popups/cancel.dart';
import 'package:boxbox/popups/popup.dart';
import 'package:flutter/material.dart';

class Purchase {
  Purchase._();

  static final instance = Purchase._();

  static const duration = Duration(milliseconds: 1500);

  bool _showing = false;

  Future<void> showLoading(BuildContext context) async {
    if (_showing || !context.mounted) return;
    _showing = true;
    final navigator = Navigator.of(context, rootNavigator: true);
    try {
      final closed = showGeneralDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        barrierLabel: 'Purchase',
        barrierColor: Colors.transparent,
        transitionDuration: Duration.zero,
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
        pageBuilder: (context, animation, __) {
          return const PopScope(
            canPop: false,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: Color.fromRGBO(0, 0, 0, popupDim)),
                ModalBarrier(dismissible: false),
                Center(child: _PurchaseLoader()),
              ],
            ),
          );
        },
      );
      await Future<void>.delayed(duration);
      if (navigator.mounted) navigator.pop();
      await closed;
      if (!context.mounted) return;
      await showGeneralDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        barrierLabel: 'Purchase Cancelled',
        barrierColor: Colors.transparent,
        transitionDuration: Duration.zero,
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
        pageBuilder: (context, _, __) {
          return PopScope(
            canPop: false,
            child: CancelPopup(
              onClose: () => Navigator.of(context, rootNavigator: true).pop(),
            ),
          );
        },
      );
    } finally {
      _showing = false;
    }
  }
}

class _PurchaseLoader extends StatefulWidget {
  const _PurchaseLoader();

  @override
  State<_PurchaseLoader> createState() => _PurchaseLoaderState();
}

class _PurchaseLoaderState extends State<_PurchaseLoader>
    with SingleTickerProviderStateMixin {
  static const _size = 156.0;
  static const _icon = 92.0;
  static const _stroke = 4.0;
  static const _arc = Color(0xFFAE81FF);

  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: _size,
        height: _size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const CustomPaint(
              size: Size(_size, _size),
              painter: _LoaderDiscPainter(trackWidth: _stroke),
            ),
            RotationTransition(
              turns: _spin,
              child: const CustomPaint(
                size: Size(_size, _size),
                painter: _LoadingArcPainter(
                  color: _arc,
                  stroke: _stroke,
                ),
              ),
            ),
            const Image(
              image: AssetImage('lib/assets/loading.png'),
              fit: BoxFit.contain,
              width: _icon,
              height: _icon,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoaderDiscPainter extends CustomPainter {
  const _LoaderDiscPainter({required this.trackWidth});

  final double trackWidth;

  static const _track = Color(0xFF221932);
  static const _fill = Color(0xFF000000);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    canvas.drawCircle(center, outer, Paint()..color = _track);
    canvas.drawCircle(center, outer - trackWidth, Paint()..color = _fill);
  }

  @override
  bool shouldRepaint(covariant _LoaderDiscPainter oldDelegate) {
    return oldDelegate.trackWidth != trackWidth;
  }
}

class _LoadingArcPainter extends CustomPainter {
  const _LoadingArcPainter({
    required this.color,
    required this.stroke,
  });

  final Color color;
  final double stroke;

  static const _start = -math.pi / 2;
  static const _sweep = math.pi * 0.40;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - stroke / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
      rect,
      _start,
      _sweep,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LoadingArcPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.stroke != stroke;
  }
}
