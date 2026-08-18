import 'package:flutter/material.dart';

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
      constraints: const BoxConstraints(minWidth: 0, maxWidth: 100),
      child: _StatusCounter(
        iconAsset: 'lib/assets/coin/icon1.png',
        value: _formatDots(coins),
        onTap: onCoinsTap,
        iconKey: coinIconKey,
        showPlus: showCoinPlus,
      ),
    );
    final heartsCounter = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 0, maxWidth: 100),
      child: _StatusCounter(
        iconAsset: 'lib/assets/heart/icon1.png',
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
    required this.value,
    this.iconLabel,
    this.onTap,
    this.iconKey,
    this.showPlus = true,
  });

  final String iconAsset;
  final String value;
  final String? iconLabel;
  final VoidCallback? onTap;
  final GlobalKey? iconKey;
  final bool showPlus;

  static const _barHeight = 24.0;
  static const _iconSize = 32.0;
  static const _plusSize = 16.0;
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
            left: _iconSize * 0.42,
            right: 0,
            top: (_iconSize - _barHeight) / 2,
            child: Container(
              height: _barHeight,
              alignment: Alignment.center,
              padding: EdgeInsets.only(left: _iconSize * 0.55, right: 8),
              decoration: BoxDecoration(
                color: _cream,
                borderRadius: BorderRadius.circular(_barHeight / 2),
                border: Border.all(color: const Color(0xFF101010), width: 1.6),
              ),
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1
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
                      right: -4,
                      bottom: -4,
                      child: IgnorePointer(
                        child: Container(
                          width: _plusSize,
                          height: _plusSize,
                          decoration: BoxDecoration(
                            color: _plusGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF101010), width: 1.6),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 12,
                            color: Colors.white,
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
      onTap: onTap,
      child: content,
    );
  }
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
