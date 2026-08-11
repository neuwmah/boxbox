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
  static const _asset = 'lib/assets/background/sample.png';
  static const _assetScale = 4.0;
  static const _tileSize = 1000.0 / _assetScale;
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
          builder: (context, _) {
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
                        child: Image.asset(
                          _asset,
                          repeat: ImageRepeat.repeat,
                          scale: _assetScale,
                          alignment: Alignment.topLeft,
                          filterQuality: FilterQuality.none,
                          gaplessPlayback: true,
                        ),
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

class PopupBackground extends StatefulWidget {
  const PopupBackground({
    super.key,
    this.offset = Offset.zero,
  });

  final Offset offset;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final size =
            math.sqrt(w * w + h * h) + widget.offset.distance * 2;

        return AnimatedBuilder(
          animation: _controller,
          child: OverflowBox(
            alignment: Alignment.center,
            maxWidth: size,
            maxHeight: size,
            child: SizedBox(
              width: size,
              height: size,
              child: Image.asset(
                _asset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
              ),
            ),
          ),
          builder: (context, child) {
            return Transform.translate(
              offset: widget.offset,
              child: Transform.rotate(
                angle: _controller.value * 2 * math.pi,
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}
