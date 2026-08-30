import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:boxbox/sound/sfx.dart';
import 'package:boxbox/widgets/cubes.dart';
import 'package:boxbox/widgets/titlebar.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    this.onLevelTap,
    this.onAdsTap,
  });

  final VoidCallback? onLevelTap;
  final VoidCallback? onAdsTap;

  static const _adsIconSize = 72.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: CubesBackground()),
        Center(
          child: Transform.translate(
            offset: const Offset(0, 40),
            child: GestureDetector(
              onTap: () => Sfx.instance.tap(onLevelTap),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF101010),
                    width: 1.6,
                  ),
                ),
                child: const StickerTitle(title: 'Play'),
              ),
            ),
          ),
        ),
        if (onAdsTap != null)
          Positioned(
            top: 120,
            right: MediaQuery.sizeOf(context).shortestSide >= 600 ? 130 : 32,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Sfx.instance.tap(onAdsTap),
              child: const _ShiningAdsIcon(
                size: _adsIconSize,
              ),
            ),
          ),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 40,
          child: DragToMoveArea(
            child: SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

class _ShiningAdsIcon extends StatefulWidget {
  const _ShiningAdsIcon({required this.size});

  final double size;

  @override
  State<_ShiningAdsIcon> createState() => _ShiningAdsIconState();
}

class _ShiningAdsIconState extends State<_ShiningAdsIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine;
  ui.Image? _icon;

  @override
  void initState() {
    super.initState();
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _loadIcon();
  }

  Future<void> _loadIcon() async {
    final data = await rootBundle.load('lib/assets/ad/icon.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (!mounted) {
      frame.image.dispose();
      return;
    }
    setState(() => _icon = frame.image);
  }

  @override
  void dispose() {
    _shine.dispose();
    _icon?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _shine,
        builder: (context, _) {
          return CustomPaint(
            painter: _ShiningAdsPainter(
              image: _icon,
              t: _shine.value,
            ),
          );
        },
      ),
    );
  }
}

class _ShiningAdsPainter extends CustomPainter {
  const _ShiningAdsPainter({
    required this.image,
    required this.t,
  });

  final ui.Image? image;
  final double t;

  static Rect _containDest(Size box, double imageW, double imageH) {
    final scale = (box.width / imageW < box.height / imageH)
        ? box.width / imageW
        : box.height / imageH;
    final w = imageW * scale;
    final h = imageH * scale;
    return Rect.fromLTWH(
      (box.width - w) / 2,
      (box.height - h) / 2,
      w,
      h,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final img = image;
    if (img == null) return;

    final src = Rect.fromLTWH(
      0,
      0,
      img.width.toDouble(),
      img.height.toDouble(),
    );
    final dest = _containDest(size, src.width, src.height);
    final paint = Paint()..filterQuality = FilterQuality.medium;

    canvas.drawImageRect(img, src, dest, paint);

    final active = t >= 0.12 && t <= 0.48;
    if (!active) return;

    final shineT = ((t - 0.12) / 0.36).clamp(0.0, 1.0);
    final travel = (shineT * 2.2 - 0.6) * dest.width;

    canvas.saveLayer(dest, Paint());
    canvas.drawImageRect(img, src, dest, paint);
    canvas.save();
    canvas.translate(dest.center.dx, dest.center.dy);
    canvas.rotate(-0.7);
    canvas.translate(-dest.center.dx, -dest.center.dy);
    final band = Rect.fromLTWH(
      dest.left + travel,
      dest.top - dest.height,
      dest.width * 0.42,
      dest.height * 3,
    );
    canvas.drawRect(
      band,
      Paint()
        ..blendMode = BlendMode.srcIn
        ..shader = ui.Gradient.linear(
          Offset(band.left, band.center.dy),
          Offset(band.right, band.center.dy),
          const [
            Color(0x00FFFFFF),
            Color(0x2EFFFFFF),
            Color(0x59FFFFFF),
            Color(0x2EFFFFFF),
            Color(0x00FFFFFF),
          ],
          const [0.0, 0.22, 0.5, 0.78, 1.0],
        ),
    );
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShiningAdsPainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.t != t;
  }
}
