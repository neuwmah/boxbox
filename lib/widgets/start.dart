import 'package:flutter/material.dart';
import 'package:boxbox/game/level.dart';
import 'package:boxbox/widgets/background.dart';
import 'package:boxbox/widgets/titlebar.dart';

class StartPopup extends StatefulWidget {
  const StartPopup({
    super.key,
    required this.level,
    required this.onClose,
    required this.onStart,
  });

  final int level;
  final VoidCallback onClose;
  final VoidCallback onStart;

  @override
  State<StartPopup> createState() => _StartPopupState();
}

class _StartPopupState extends State<StartPopup>
    with SingleTickerProviderStateMixin {
  static const _shade = Color(0xFF333333);
  static const _shadeEnd = Color(0xFF050505);
  static const _heartSize = 72.0;

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
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: PopupAppearScale(
                animation: _controller,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
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
                                      PopupTitleBadge(
                                        title: 'Level ${widget.level}',
                                        shadeColor: _shade,
                                        endColor: _shadeEnd,
                                      ),
                                      Center(
                                        child: Container(
                                          constraints: const BoxConstraints(
                                            minWidth: 150,
                                          ),
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
                                            alignment: Alignment.center,
                                            children: [
                                              const Positioned.fill(
                                                child: PopupBackground(
                                                  offset: Offset(0, -28),
                                                  tint: _shade,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                      24,
                                                      20,
                                                      24,
                                                      20,
                                                    ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                      width: _heartSize,
                                                      height: _heartSize,
                                                      child: Stack(
                                                        alignment:
                                                            Alignment.center,
                                                        children: [
                                                          Image.asset(
                                                            'lib/assets/heart/icon1.png',
                                                            width: _heartSize,
                                                            height: _heartSize,
                                                            fit: BoxFit.contain,
                                                          ),
                                                          const _StickerLabel(
                                                            text: '1',
                                                            depthColor: Color(
                                                              0xFF5A1018,
                                                            ),
                                                            style: TextStyle(
                                                              fontSize: 24,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w900,
                                                              height: 1,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    _StickerLabel(
                                                      text: levelTitleAt(
                                                        widget.level,
                                                      ),
                                                      depthColor: const Color(
                                                        0xFF212121,
                                                      ),
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
                                          onTap: widget.onStart,
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
                                            child: const _StickerLabel(
                                              text: 'Start',
                                              depthColor: Color(0xFF24580A),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                height: 1,
                                                letterSpacing: -.2,
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
