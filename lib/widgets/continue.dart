import 'package:flutter/material.dart';
import 'package:boxbox/sound/sfx.dart';
import 'package:boxbox/widgets/background.dart';
import 'package:boxbox/widgets/status.dart';
import 'package:boxbox/widgets/titlebar.dart';

class ContinuePopup extends StatefulWidget {
  const ContinuePopup({
    super.key,
    required this.coins,
    required this.price,
    required this.balls,
    required this.onClose,
    required this.onContinue,
  });

  final int coins;
  final int price;
  final int balls;
  final VoidCallback onClose;
  final VoidCallback onContinue;

  @override
  State<ContinuePopup> createState() => _ContinuePopupState();
}

class _ContinuePopupState extends State<ContinuePopup>
    with SingleTickerProviderStateMixin {
  static const _shade = Color(0xFF333333);
  static const _shadeEnd = Color(0xFF050505);
  static const _coinSize = 32.0;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: PopupAppear.duration,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          PopupDim(animation: _controller),
          Positioned(
            top: 48,
            left: 16,
            right: 12,
            child: PopupAppearFade(
              animation: _controller,
              child: StatusCounters(
                coins: widget.coins,
                showHearts: false,
                showCoinPlus: false,
                gap: 72,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: PopupAppearScale(
                animation: _controller,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 270),
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
                              const Positioned.fill(
                                child: PopupBodyShade(
                                  color: _shade,
                                  endColor: _shadeEnd,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: 4,
                                  bottom: 4,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    24,
                                  ),
                                  decoration: PopupShade.panel(color: _shade),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const PopupTitleBadge(
                                        title: 'Continue?',
                                        shadeColor: _shade,
                                        endColor: _shadeEnd,
                                      ),
                                      Center(
                                        child: Container(
                                          clipBehavior: Clip.antiAlias,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          foregroundDecoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: PopupShade.borderTint(
                                                _shade,
                                              ),
                                              width: 1.6,
                                            ),
                                          ),
                                          child: Stack(
                                            children: [
                                              const Positioned.fill(
                                                child: PopupBackground(
                                                  offset: Offset(0, -12),
                                                  tint: _shade,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                      24,
                                                      12,
                                                      24,
                                                      20,
                                                    ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    _StickerLabel(
                                                      text: '+${widget.balls}',
                                                      depthColor: const Color(
                                                        0xFF212121,
                                                      ),
                                                      offsets:
                                                          _StickerLabel
                                                              .offsets4,
                                                      innerBorderColor:
                                                          const Color(
                                                            0xFFCCCCCC,
                                                          ),
                                                      style: const TextStyle(
                                                        fontSize: 72,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        height: 1,
                                                        letterSpacing: -.4,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    _StickerLabel(
                                                      text:
                                                          'Add ${widget.balls} balls to continue!',
                                                      depthColor: const Color(
                                                        0xFF212121,
                                                      ),
                                                      offsets:
                                                          _StickerLabel
                                                              .offsets2,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Center(
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () => Sfx.instance.tap(widget.onContinue),
                                          child: Container(
                                            height: 48,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(40),
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
                                                  text: 'Play On',
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
                                                          shape:
                                                              BoxShape.circle,
                                                          border:
                                                              Border.fromBorderSide(
                                                                BorderSide(
                                                                  color: Color(
                                                                    0xFF905D00,
                                                                  ),
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
                                                  text: '${widget.price}',
                                                  depthColor: const Color(
                                                    0xFF24580A,
                                                  ),
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
                          child: PopupCloseButton(
                            onTap: widget.onClose,
                            borderColor: PopupShade.borderTint(_shade),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
                  colors: [innerBorderColor!, Colors.white],
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
