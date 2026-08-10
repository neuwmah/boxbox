import 'package:flutter/material.dart';
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
  static const _border = Color(0xFF101010);
  static const _heartSize = 72.0;

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
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                              PopupTitleBadge(title: 'Level ${widget.level}'),
                              Center(
                                child: Container(
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Stack(
                                    children: [
                                      const Positioned.fill(
                                        child: PopupBackground(),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
                                        child: SizedBox(
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
                                              const _StickerLabel(
                                                text: '1',
                                                depthColor: Color(0xFF5A1018),
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w900,
                                                  height: 1,
                                                ),
                                              ),
                                            ],
                                          ),
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
                                        width: 1.4,
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
                        top: 0,
                        right: 14,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onClose,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                              border: Border.all(color: _border, width: 1.6),
                            ),
                            child: const Center(
                              child: CustomPaint(
                                size: Size(8, 8),
                                painter: _CloseIconPainter(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
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
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CloseIconPainter extends CustomPainter {
  const _CloseIconPainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _CloseIconPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
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
