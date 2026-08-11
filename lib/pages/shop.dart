import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:boxbox/widgets/background.dart';

const double kShopPileHeight = 40;
const double kShopPileWidth = 40;

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage>
    with SingleTickerProviderStateMixin {
  static const _products = <_ShopProduct>[
    _ShopProduct(amount: 1000, price: '12.90'),
    _ShopProduct(amount: 5000, price: '49.90'),
    _ShopProduct(amount: 10000, price: '99.90'),
    _ShopProduct(amount: 25000, price: '199.90'),
    _ShopProduct(amount: 50000, price: '349.90'),
    _ShopProduct(amount: 100000, price: '599.90'),
  ];

  late final AnimationController _shine;
  ui.Image? _pile;

  @override
  void initState() {
    super.initState();
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _loadPile();
  }

  Future<void> _loadPile() async {
    final data = await rootBundle.load('lib/assets/coin/pile.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (!mounted) {
      frame.image.dispose();
      return;
    }
    setState(() => _pile = frame.image);
  }

  @override
  void dispose() {
    _shine.dispose();
    _pile?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RectBackground(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        itemCount: _products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          return _ShopProductTile(
            product: _products[index],
            shine: _shine,
            pile: _pile,
          );
        },
      ),
    );
  }
}

class _ShopProduct {
  const _ShopProduct({required this.amount, required this.price});

  final int amount;
  final String price;
}

class _ShopProductTile extends StatelessWidget {
  const _ShopProductTile({
    required this.product,
    required this.shine,
    required this.pile,
  });

  final _ShopProduct product;
  final Animation<double> shine;
  final ui.Image? pile;

  static const _border = Color(0xFF101010);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(0),
        border: Border.all(color: _border, width: 1.6),
      ),
      child: Row(
        children: [
          _ShiningPile(shine: shine, pile: pile),
          const SizedBox(width: 8),
          Expanded(
            child: _AmountLabel(value: _formatDots(product.amount)),
          ),
          const SizedBox(width: 8),
          _BuyButton(label: 'BRL ${product.price}'),
        ],
      ),
    );
  }
}

class _ShiningPile extends StatelessWidget {
  const _ShiningPile({
    required this.shine,
    required this.pile,
  });

  final Animation<double> shine;
  final ui.Image? pile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kShopPileWidth,
      height: kShopPileHeight,
      child: AnimatedBuilder(
        animation: shine,
        builder: (context, _) {
          return CustomPaint(
            painter: _PilePainter(
              image: pile,
              t: shine.value,
            ),
          );
        },
      ),
    );
  }
}

class _PilePainter extends CustomPainter {
  const _PilePainter({
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
  bool shouldRepaint(covariant _PilePainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.t != t;
  }
}

class _AmountLabel extends StatelessWidget {
  const _AmountLabel({required this.value});

  final String value;

  static const _base = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1,
    letterSpacing: -.4,
  );

  @override
  Widget build(BuildContext context) {
    const depthColor = Color(0xFF313131);

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        for (final offset in const [
          Offset(1, 1),
          Offset(2, 2),
          Offset(0, 1),
          Offset(1, 0),
          Offset(1, 2),
          Offset(2, 1),
        ])
          Transform.translate(
            offset: offset,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _base.copyWith(color: depthColor),
            ),
          ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _base.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}

class _BuyButton extends StatelessWidget {
  const _BuyButton({required this.label});

  final String label;

  static const _base = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    height: 1,
    letterSpacing: -.2,
  );

  static const _depthColor = Color(0xFF24580A);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
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
        border: Border.all(color: const Color(0xFF2F6B0C), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                widthFactor: 1,
                heightFactor: 0.42,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (final offset in const [
                  Offset(1, 1),
                  Offset(2, 2),
                  Offset(0, 1),
                  Offset(1, 0),
                  Offset(1, 2),
                  Offset(2, 1),
                ])
                  Transform.translate(
                    offset: offset,
                    child: Text(
                      label,
                      style: _base.copyWith(color: _depthColor),
                    ),
                  ),
                Text(
                  label,
                  style: _base.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
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
