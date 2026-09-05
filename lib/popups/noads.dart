import 'package:flutter/material.dart';
import 'package:boxbox/popups/popup.dart';
import 'package:boxbox/sound/sfx.dart';
import 'package:boxbox/widgets/background.dart';

class NoAdsPopup extends StatefulWidget {
  const NoAdsPopup({
    super.key,
    required this.priceLabel,
    required this.onClose,
    required this.onPurchase,
  });

  final String priceLabel;
  final VoidCallback onClose;
  final VoidCallback onPurchase;

  @override
  State<NoAdsPopup> createState() => _NoAdsPopupState();
}

class _NoAdsPopupState extends State<NoAdsPopup>
    with SingleTickerProviderStateMixin {
  static const _shade = Color(0xFF515151);
  static const _shadeEnd = Color(0xFF212121);
  static const _iconSize = 72.0;

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
                                    24,
                                    0,
                                    24,
                                    24,
                                  ),
                                  decoration: PopupShade.panel(color: _shade),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const PopupTitleBadge(
                                        title: 'Remove Ads',
                                        shadeColor: _shade,
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
                                                  offset: Offset(0, -28),
                                                  tint: _shade,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                      16,
                                                      24,
                                                      16,
                                                      20,
                                                    ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Image.asset(
                                                      'lib/assets/ad.png',
                                                      width: _iconSize,
                                                      height: _iconSize,
                                                      fit: BoxFit.contain,
                                                    ),
                                                    const SizedBox(height: 12),
                                                    const _StickerLabel(
                                                      text:
                                                          'All pop-up ads will be permanently removed!',
                                                      depthColor: Color(
                                                        0xFF212121,
                                                      ),
                                                      offsets:
                                                          _StickerLabel
                                                              .offsets2,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: 16,
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
                                          onTap: () => Sfx.instance.tap(widget.onPurchase),
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
                                            child: _StickerLabel(
                                              text: widget.priceLabel,
                                              depthColor: const Color(
                                                0xFF24580A,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
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
                          child: PopupCloseButton(onTap: widget.onClose),
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
  });

  final String text;
  final TextStyle style;
  final Color depthColor;
  final List<Offset> offsets;
  final TextAlign? textAlign;

  static const offsets2 = [
    Offset(1, 1),
    Offset(2, 2),
    Offset(0, 1),
    Offset(1, 0),
    Offset(1, 2),
    Offset(2, 1),
  ];

  @override
  Widget build(BuildContext context) {
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
          Text(
            text,
            textAlign: textAlign,
            style: style.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
