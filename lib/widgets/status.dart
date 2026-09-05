import 'package:flutter/material.dart';
import 'package:boxbox/sound/sfx.dart';

class StatusCounters extends StatelessWidget {
  const StatusCounters({
    super.key,
    this.coins = 0,
    this.hearts = 0,
    this.heartTimer = '20:00',
    this.showHearts = true,
    this.showCoinPlus = true,
    this.showHeartPlus = true,
    this.gap = 72,
    this.onCoinsTap,
    this.onHeartsTap,
    this.coinIconKey,
  });

  final int coins;
  final int hearts;
  final String heartTimer;
  final bool showHearts;
  final bool showCoinPlus;
  final bool showHeartPlus;
  final double gap;
  final VoidCallback? onCoinsTap;
  final VoidCallback? onHeartsTap;
  final GlobalKey? coinIconKey;

  @override
  Widget build(BuildContext context) {
    final coinsCounter = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 0, maxWidth: 110),
      child: _StatusCounter(
        iconAsset: 'lib/assets/coin/icon1.png',
        accent: _StatusCounter.coinAccent,
        value: _formatDots(coins),
        onTap: onCoinsTap,
        iconKey: coinIconKey,
        showPlus: showCoinPlus,
      ),
    );
    final heartsCounter = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 0, maxWidth: 110),
      child: _StatusCounter(
        iconAsset: 'lib/assets/heart/icon1.png',
        accent: _StatusCounter.heartAccent,
        value: heartTimer,
        iconLabel: '$hearts',
        onTap: onHeartsTap,
        showPlus: showHeartPlus,
      ),
    );

    return Row(
      mainAxisAlignment: showHearts
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      mainAxisSize: showHearts ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (showHearts) Flexible(child: coinsCounter) else coinsCounter,
        if (showHearts) ...[
          SizedBox(width: gap),
          Flexible(child: heartsCounter),
        ],
      ],
    );
  }
}

String _formatDots(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

class _StatusCounter extends StatelessWidget {
  const _StatusCounter({
    required this.iconAsset,
    required this.accent,
    required this.value,
    this.iconLabel,
    this.onTap,
    this.iconKey,
    this.showPlus = true,
  });

  final String iconAsset;
  final Color accent;
  final String value;
  final String? iconLabel;
  final VoidCallback? onTap;
  final GlobalKey? iconKey;
  final bool showPlus;

  static const coinAccent = Color(0xFFF5C518);
  static const heartAccent = Color(0xFFE53935);
  static const _barHeight = 28.0;
  static const _iconSize = 40.0;
  static const _plusSize = 20.0;
  static const _topRim = 1.2;
  static const _bottomRim = 0.6;
  static const _cream = Color(0xFF000000);
  static const _text = Color(0xFFFFFFFF);
  static const _plusGreen = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      height: _iconSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: _iconSize * 0.42 - 2,
            right: 0,
            top: (_iconSize - _barHeight) / 2,
            child: SizedBox(
              height: _barHeight,
              child: CustomPaint(
                painter: _StatusBarPainter(
                  accent: accent,
                  fill: _cream,
                  topRim: _topRim,
                  bottomRim: _bottomRim,
                ),
                child: SizedBox.expand(
                  child: Padding(
                    padding: EdgeInsets.only(left: 30, right: 8),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: SizedBox(
              key: iconKey,
              width: _iconSize,
              height: _iconSize,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    iconAsset,
                    width: _iconSize,
                    height: _iconSize,
                    fit: BoxFit.contain,
                  ),
                  if (iconLabel != null)
                    _HeartValueLabel(text: iconLabel!),
                  if (showPlus)
                    Positioned(
                      right: -8,
                      bottom: -1,
                      child: IgnorePointer(
                        child: Container(
                          width: _plusSize,
                          height: _plusSize,
                          decoration: BoxDecoration(
                            color: _plusGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF333333), width: 1.6),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CustomPaint(
                                painter: _PlusMarkPainter(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Sfx.instance.tap(onTap),
      child: content,
    );
  }
}

class _StatusBarPainter extends CustomPainter {
  const _StatusBarPainter({
    required this.accent,
    required this.fill,
    required this.topRim,
    required this.bottomRim,
  });

  final Color accent;
  final Color fill;
  final double topRim;
  final double bottomRim;

  static const _outline = Color(0xFF000000);

  @override
  void paint(Canvas canvas, Size size) {
    const outlineW = 1.6;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );

    canvas.drawRRect(rrect, Paint()..color = fill);

    canvas.drawRRect(
      rrect.deflate(outlineW / 2),
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = outlineW,
    );

    canvas.save();
    canvas.clipRRect(rrect);

    final fadeColors = [
      accent,
      Color.lerp(accent, fill, 0.45)!,
      fill,
    ];
    final bottomColors = [
      Color.lerp(accent, fill, 0.42)!,
      Color.lerp(accent, fill, 0.7)!,
      fill,
    ];
    final topPaint = Paint()
      ..shader = LinearGradient(
        colors: fadeColors,
        stops: const [0.0, 0.48, 0.84],
      ).createShader(Offset.zero & size)
      ..isAntiAlias = true;

    final bottomLength = size.width * 0.60;
    final bottomPaint = Paint()
      ..shader = LinearGradient(
        colors: bottomColors,
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, bottomLength, size.height))
      ..isAntiAlias = true;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, topRim), topPaint);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - bottomRim, bottomLength, bottomRim),
      bottomPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StatusBarPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.fill != fill ||
        oldDelegate.topRim != topRim ||
        oldDelegate.bottomRim != bottomRim;
  }
}

class _PlusMarkPainter extends CustomPainter {
  const _PlusMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final arm = size.shortestSide * 0.28;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(c.dx - arm, c.dy), Offset(c.dx + arm, c.dy), paint);
    canvas.drawLine(Offset(c.dx, c.dy - arm), Offset(c.dx, c.dy + arm), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeartValueLabel extends StatelessWidget {
  const _HeartValueLabel({required this.text});

  final String text;

  static const _depthColor = Color(0xFF5A1018);
  static const _style = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1,
  );
  static const _offsets = [
    Offset(1, 1),
    Offset(0, 1),
    Offset(1, 0),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        for (final offset in _offsets)
          Transform.translate(
            offset: offset,
            child: Text(
              text,
              style: _style.copyWith(color: _depthColor),
            ),
          ),
        Text(
          text,
          style: _style.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}
