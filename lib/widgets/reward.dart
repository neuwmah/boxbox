import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:boxbox/sound/sfx.dart';

class RewardOverlay extends StatefulWidget {
  const RewardOverlay({
    super.key,
    required this.amount,
    required this.fromCoins,
    required this.targetKey,
    required this.onCoinsDisplay,
    required this.onComplete,
  });

  final int amount;
  final int fromCoins;
  final GlobalKey targetKey;
  final ValueChanged<int> onCoinsDisplay;
  final VoidCallback onComplete;

  @override
  State<RewardOverlay> createState() => _RewardOverlayState();
}

class _RewardOverlayState extends State<RewardOverlay>
    with SingleTickerProviderStateMixin {
  static const _asset = 'lib/assets/coin/icon1.png';
  static const _showcaseSize = 72.0;
  static const _readyT = 0.18;

  late final AnimationController _controller;
  Offset? _targetCenter;
  bool _counted = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
      value: _readyT,
    )..addListener(_onTick);
    Sfx.instance.playCoinFinish();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onCoinsDisplay(widget.fromCoins);
      _resolveTarget();
      _controller.forward();
    });
  }

  @override
  void dispose() {
    Sfx.instance.stopCoinRepeat();
    _controller
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  void _resolveTarget() {
    final ctx = widget.targetKey.currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final overlayBox = context.findRenderObject() as RenderBox?;
    if (overlayBox == null || !overlayBox.hasSize) return;
    final global = box.localToGlobal(box.size.center(Offset.zero));
    setState(() {
      _targetCenter = overlayBox.globalToLocal(global);
    });
  }

  void _onTick() {
    final t = _controller.value;

    if (t >= 0.78) {
      if (!_counted) {
        Sfx.instance.startCoinRepeat();
      }
      final countT = ((t - 0.78) / 0.22).clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(countT);
      final value = ui
          .lerpDouble(
            widget.fromCoins.toDouble(),
            (widget.fromCoins + widget.amount).toDouble(),
            eased,
          )!
          .round();
      widget.onCoinsDisplay(value);
      _counted = true;
    }

    if (_controller.isCompleted && !_finished) {
      _finished = true;
      Sfx.instance.stopCoinRepeat();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!_counted) {
          widget.onCoinsDisplay(widget.fromCoins + widget.amount);
        }
        widget.onComplete();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final size = MediaQuery.sizeOf(context);
        final center = Offset(size.width / 2, size.height / 2 - 17);
        final target = _targetCenter ?? const Offset(56, 48);

        final t = _controller.value;
        const appear = 1.0;
        const dim = 1.0;
        final flyT = Curves.easeInOutCubic.transform(
          ((t - 0.48) / 0.30).clamp(0.0, 1.0),
        );
        final fadeOut = (1 - ((t - 0.78) / 0.10).clamp(0.0, 1.0));

        final pos = _bezier(center, target, flyT);
        final coinSize = ui.lerpDouble(_showcaseSize, 32, flyT)!;
        final spin = t * math.pi * 6.2 + flyT * math.pi * 2.4;
        final labelOpacity = ((1 - flyT) * fadeOut).clamp(0.0, 1.0);
        final impactT = ((t - 0.76) / 0.18).clamp(0.0, 1.0);
        final labelTop = center.dy + _showcaseSize / 2 + 16;

        return IgnorePointer(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: Colors.black.withValues(alpha: 0.55 * dim * fadeOut),
              ),
              if (impactT > 0.01 && impactT < 1)
                Positioned(
                  left: target.dx - 28,
                  top: target.dy - 28,
                  width: 56,
                  height: 56,
                  child: Transform.scale(
                    scale: ui.lerpDouble(0.7, 1.55, impactT)!,
                    child: Opacity(
                      opacity: (1 - impactT) * 0.85,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFE082)
                                .withValues(alpha: 0.9),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: pos.dx - coinSize * 0.7,
                top: pos.dy - coinSize / 2,
                width: coinSize * 1.4,
                height: coinSize,
                child: Opacity(
                  opacity: (appear * fadeOut).clamp(0.0, 1.0),
                  child: Center(
                    child: _SpinningCoin3D(
                      angle: spin,
                      size: coinSize,
                      asset: _asset,
                    ),
                  ),
                ),
              ),
              if (labelOpacity > 0.01)
                Positioned(
                  left: 0,
                  right: 0,
                  top: labelTop,
                  child: Opacity(
                    opacity: labelOpacity,
                    child: Center(
                      child: _RewardAmountLabel(amount: widget.amount),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Offset _bezier(Offset start, Offset end, double t) {
    final control = Offset(
      ui.lerpDouble(start.dx, end.dx, 0.55)!,
      ui.lerpDouble(start.dy, end.dy, 0.45)! - 18,
    );
    final u = 1 - t;
    return Offset(
      u * u * start.dx + 2 * u * t * control.dx + t * t * end.dx,
      u * u * start.dy + 2 * u * t * control.dy + t * t * end.dy,
    );
  }
}

class _RewardAmountLabel extends StatelessWidget {
  const _RewardAmountLabel({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return Text(
      '+$amount',
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1,
        letterSpacing: -.4,
        color: Colors.white,
        decoration: TextDecoration.none,
        shadows: [
          Shadow(color: Color(0xFF000000), offset: Offset(1, 1), blurRadius: 0),
          Shadow(color: Color(0xFF000000), offset: Offset(2, 2), blurRadius: 0),
          Shadow(color: Color(0xFF000000), offset: Offset(0, 1), blurRadius: 0),
          Shadow(color: Color(0xFF000000), offset: Offset(1, 0), blurRadius: 0),
          Shadow(color: Color(0xFF000000), offset: Offset(1, 2), blurRadius: 0),
          Shadow(color: Color(0xFF000000), offset: Offset(2, 1), blurRadius: 0),
        ],
      ),
    );
  }
}

class _SpinningCoin3D extends StatelessWidget {
  const _SpinningCoin3D({
    required this.angle,
    required this.size,
    required this.asset,
  });

  final double angle;
  final double size;
  final String asset;

  static const _layers = 14;
  static const _rimEdge = Color(0xFF7C3401);
  static const _rimMid = Color(0xFF944012);

  @override
  Widget build(BuildContext context) {
    final thickness = size * 0.18;
    final cosY = math.cos(angle);
    final sinY = math.sin(angle);
    final scaleX = cosY.abs().clamp(0.04, 1.0);
    final flip = cosY < 0 ? -1.0 : 1.0;
    final rimVisible = sinY.abs();

    final slices = <({int i, double z, double depth})>[
      for (var i = 0; i < _layers; i++)
        (
          i: i,
          z: (i / (_layers - 1) - 0.5) * thickness,
          depth: (i / (_layers - 1) - 0.5) * thickness * cosY,
        ),
    ]..sort((a, b) => a.depth.compareTo(b.depth));

    final boundsW = size * scaleX + thickness * rimVisible + 4;

    return SizedBox(
      width: math.max(size, boundsW),
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          for (final slice in slices)
            Transform.translate(
              offset: Offset(slice.z * sinY, 0),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(scaleX * flip, 1, 1),
                child: _slice(slice.i, rimVisible),
              ),
            ),
        ],
      ),
    );
  }

  Widget _slice(int i, double rimVisible) {
    final isFace = i == 0 || i == _layers - 1;
    if (isFace) {
      return Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      );
    }

    final t = i / (_layers - 1);
    final shade = (math.sin(t * math.pi) * 0.45 + 0.4).clamp(0.0, 1.0);
    final color = Color.lerp(_rimEdge, _rimMid, shade)!;

    return Opacity(
      opacity: rimVisible.clamp(0.15, 1.0),
      child: Container(
        width: size + 2,
        height: size + 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
