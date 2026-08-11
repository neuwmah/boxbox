import 'package:flutter/material.dart';
import 'package:boxbox/widgets/background.dart';
import 'package:boxbox/widgets/titlebar.dart';

class MoreLivesPopup extends StatefulWidget {
  const MoreLivesPopup({
    super.key,
    required this.hearts,
    required this.heartTimer,
    required this.refillPrice,
    required this.onClose,
    required this.onRefill,
    required this.onWatchAd,
  });

  final int hearts;
  final String heartTimer;
  final int refillPrice;
  final VoidCallback onClose;
  final VoidCallback onRefill;
  final VoidCallback onWatchAd;

  @override
  State<MoreLivesPopup> createState() => _MoreLivesPopupState();
}

class _MoreLivesPopupState extends State<MoreLivesPopup>
    with SingleTickerProviderStateMixin {
  static const _border = Color(0xFF101010);
  static const _coinSize = 32.0;
  static const _heartSize = 72.0;
  static const _statusHeartSize = 32.0;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final appear = Curves.easeOut.transform(t);
        final dim =
            Curves.easeOut.transform((t / (0.12 / 0.18)).clamp(0.0, 1.0));

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.55 * dim),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Opacity(
                  opacity: appear,
                  child: Material(
                    color: Colors.transparent,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              for (final o in [4.0, 3.0, 2.0, 1.0])
                                Positioned(
                                  left: o,
                                  top: o,
                                  right: 4 - o,
                                  bottom: 4 - o,
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
                              Padding(
                                padding:
                                    const EdgeInsets.only(right: 4, bottom: 4),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    border: Border.all(
                                      color: _border,
                                      width: 1.6,
                                    ),
                                  ),
                                  child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const PopupTitleBadge(title: 'More Lives!'),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Center(
                                  child: Container(
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Stack(
                                      children: [
                                        const Positioned.fill(
                                          child: PopupBackground(
                                            offset: Offset(0, -36),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            32,
                                            20,
                                            32,
                                            20,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: _heartSize,
                                                height: _heartSize,
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    Image.asset(
                                                      'lib/assets/heart/icon1.png',
                                                      width: _heartSize,
                                                      height: _heartSize,
                                                      fit: BoxFit.contain,
                                                    ),
                                                    _StickerLabel(
                                                      text: '${widget.hearts}',
                                                      depthColor:
                                                          const Color(0xFF5A1018),
                                                      style: const TextStyle(
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        height: 1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              const _StickerLabel(
                                                text: 'Time to next life!',
                                                depthColor: Color(0xFF212121),
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.4,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: _border,
                                                    width: 1.6,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .access_time_rounded,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      widget.heartTimer,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        height: 1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Center(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: widget.onRefill,
                                  child: Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(40),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFFB6F34A),
                                          Color(0xFF6FBF1E),
                                          Color(0xFF4E9A12),
                                        ],
                                        stops: [0.0, 0.55, 1.0],
                                      ),
                                      border: Border.all(
                                        color: const Color(0xFF2F6B0C),
                                        width: 4,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x66000000),
                                          blurRadius: 2,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const _StickerLabel(
                                          text: 'Refill',
                                          depthColor: Color(0xFF24580A),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            height: 1,
                                            letterSpacing: -.2,
                                          ),
                                        ),
                                        const SizedBox(width: 4.5),
                                        SizedBox(
                                          width: _coinSize,
                                          height: _coinSize,
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Image.asset(
                                                'lib/assets/coin/icon1.png',
                                                width: _coinSize,
                                                height: _coinSize,
                                                fit: BoxFit.contain,
                                              ),
                                              const DecoratedBox(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border:
                                                      Border.fromBorderSide(
                                                    BorderSide(
                                                      color: Color(0xFF905D00),
                                                      width: 1,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        _StickerLabel(
                                          text: '${widget.refillPrice}',
                                          depthColor: const Color(0xFF24580A),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            height: 1,
                                            letterSpacing: -.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Center(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: widget.onWatchAd,
                                  child: Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(40),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFFC42A1E),
                                          Color(0xFFA11309),
                                          Color(0xFF7E0E07),
                                        ],
                                        stops: [0.0, 0.55, 1.0],
                                      ),
                                      border: Border.all(
                                        color: const Color(0xFF6B0C06),
                                        width: 4,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x66000000),
                                          blurRadius: 2,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: _statusHeartSize,
                                          height: _statusHeartSize,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Image.asset(
                                                'lib/assets/heart/icon1.png',
                                                width: _statusHeartSize,
                                                height: _statusHeartSize,
                                                fit: BoxFit.contain,
                                              ),
                                              const _StickerLabel(
                                                text: '+1',
                                                depthColor: Color(0xFF5A1018),
                                                offsets: _StickerLabel.offsets1,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const _StickerLabel(
                                          text: 'Life',
                                          depthColor: Color(0xFF4A0804),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            height: 1,
                                            letterSpacing: -.2,
                                          ),
                                        ),
                                      ],
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
                      ),
                      Positioned(
                        top: 24,
                        right: 12,
                        child: PopupCloseButton(onTap: widget.onClose),
                      ),
                    ],
                  ),
                ),
              ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StickerLabel extends StatelessWidget {
  const _StickerLabel({
    required this.text,
    required this.style,
    this.depthColor = const Color(0xFF313131),
    this.offsets = offsets2,
    this.textAlign,
    this.innerBorderColor,
  });

  final String text;
  final TextStyle style;
  final Color depthColor;
  final List<Offset> offsets;
  final TextAlign? textAlign;
  final Color? innerBorderColor;

  static const offsets1 = [
    Offset(1, 1),
    Offset(0, 1),
    Offset(1, 0),
  ];

  static const offsets2 = [
    Offset(1, 1),
    Offset(2, 2),
    Offset(0, 1),
    Offset(1, 0),
    Offset(1, 2),
    Offset(2, 1),
  ];

  static const offsets4 = [
    Offset(1, 1),
    Offset(2, 2),
    Offset(3, 3),
    Offset(4, 4),
    Offset(0, 1),
    Offset(1, 0),
    Offset(1, 2),
    Offset(2, 1),
    Offset(2, 3),
    Offset(3, 2),
    Offset(3, 4),
    Offset(4, 3),
  ];

  @override
  Widget build(BuildContext context) {
    final fill = Text(
      text,
      textAlign: textAlign,
      style: style.copyWith(color: Colors.white),
    );

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          for (final offset in offsets)
            Transform.translate(
              offset: offset,
              child: Text(
                text,
                textAlign: textAlign,
                style: style.copyWith(color: depthColor),
              ),
            ),
          if (innerBorderColor == null)
            fill
          else
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    innerBorderColor!,
                    Colors.white,
                  ],
                  stops: const [0.0, 0.28],
                ).createShader(bounds);
              },
              child: fill,
            ),
        ],
      ),
    );
  }
}
