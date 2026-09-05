import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const _extent = 18;
const _side = _extent * 2 + 1;
const _fovY = 45 * math.pi / 180;
const _plainAlbedo = 0.135;
const _coloredChance = 0.15;

class CubesBackground extends StatefulWidget {
  const CubesBackground({super.key, this.onReady});

  final VoidCallback? onReady;

  @override
  State<CubesBackground> createState() => _CubesBackgroundState();
}

class _CubesBackgroundState extends State<CubesBackground>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  _Repaint? _repaint;
  _CubesPainter? _painter;
  ui.FragmentShader? _shader;
  ui.Image? _grid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'lib/shaders/cubes.frag',
      );
      final grid = await _buildGridImage();
      if (!mounted) {
        grid.dispose();
        return;
      }
      final shader = program.fragmentShader();
      final repaint = _Repaint();
      setState(() {
        _grid = grid;
        _shader = shader;
        _repaint = repaint;
        _painter = _CubesPainter(repaint, shader, grid);
      });
      _ticker = createTicker(_onTick)..start();
    } catch (_) {}
    if (mounted) widget.onReady?.call();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    _painter?.tick(elapsed);
    _repaint?.bump();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _repaint?.dispose();
    _shader?.dispose();
    _grid?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painter = _painter;
    if (painter == null) return const SizedBox.expand();
    return RepaintBoundary(
      child: CustomPaint(
        painter: painter,
        size: Size.infinite,
        isComplex: true,
        willChange: true,
      ),
    );
  }
}

Future<ui.Image> _buildGridImage() {
  final pixels = Uint8List(_side * _side * 4);
  final rng = math.Random(7);
  for (var u = 0; u < _side; u++) {
    for (var v = 0; v < _side; v++) {
      final height = (rng.nextInt(10) + 1) / 10;
      final offset = (rng.nextInt(400) + 1) / 100;
      final colored = rng.nextDouble() < _coloredChance;
      final o = (v * _side + u) * 4;
      pixels[o] = (height * 255).round();
      pixels[o + 1] = (offset * 0.25 * 255).round();
      pixels[o + 2] = colored ? 255 : 0;
      pixels[o + 3] = 255;
    }
  }
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    pixels,
    _side,
    _side,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}

class _Repaint extends ChangeNotifier {
  void bump() => notifyListeners();
}

class _ColorWalk {
  double r = 121;
  double g = 11;
  double b = 136;
  double rs = 0;
  double gs = 0;
  double bs = 0;
  double rt = 121;
  double gt = 11;
  double bt = 136;
  final _rng = math.Random(3);

  int _randint(int min, int max) => _rng.nextInt(max) + min;

  void step() {
    if ((r - rt).abs() >= 5) r += rs;
    if ((g - gt).abs() >= 5) g += gs;
    if ((b - bt).abs() >= 5) b += bs;
    if ((r - rt).abs() < 5 && (g - gt).abs() < 5 && (b - bt).abs() < 5) {
      rt = _randint(0, 255).toDouble();
      gt = _randint(0, 255).toDouble();
      bt = _randint(0, 255).toDouble();
      const divisor = 20.0;
      rs = (rt > r ? _randint(5, 45) : -_randint(5, 45)) / divisor;
      gs = (gt > g ? _randint(5, 45) : -_randint(5, 45)) / divisor;
      bs = (bt > b ? _randint(5, 45) : -_randint(5, 45)) / divisor;
    }
  }
}

class _CubesPainter extends CustomPainter {
  _CubesPainter(Listenable repaint, this._shader, this._grid)
    : super(repaint: repaint);

  final ui.FragmentShader _shader;
  final ui.Image _grid;
  final _walk = _ColorWalk();
  final _paint = Paint();
  double _time = 0;

  void tick(Duration elapsed) {
    _time = elapsed.inMicroseconds / 16666.666666;
    _walk.step();
  }

  static double _drift(double t, double freq, double phase, double amp) {
    return (amp / freq) * (-math.cos(freq * t + phase) + math.cos(phase));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final time = _time;
    final camX = 6 + _drift(time, 0.004, 5, 0.005);
    final camY = 8 + _drift(time, 0.005, 10, 0.005);
    final camZ = 4 + _drift(time, 0.006, 0, 0.005);
    final roll = _drift(time, 0.0045, 15, 0.002);

    const invEye = 1 / 10.770329614269007;
    final fwdX = -6 * invEye;
    final fwdY = -8 * invEye;
    final fwdZ = -4 * invEye;
    var rightX = -fwdZ;
    var rightY = 0.0;
    var rightZ = fwdX;
    final rLen = math.sqrt(rightX * rightX + rightY * rightY + rightZ * rightZ);
    rightX /= rLen;
    rightY /= rLen;
    rightZ /= rLen;
    var upX = rightY * fwdZ - rightZ * fwdY;
    var upY = rightZ * fwdX - rightX * fwdZ;
    var upZ = rightX * fwdY - rightY * fwdX;
    final uLen = math.sqrt(upX * upX + upY * upY + upZ * upZ);
    upX /= uLen;
    upY /= uLen;
    upZ /= uLen;

    final cr = math.cos(roll);
    final sr = math.sin(roll);
    final rrX = rightX * cr + upX * sr;
    final rrY = rightY * cr + upY * sr;
    final rrZ = rightZ * cr + upZ * sr;
    final ruX = rightX * -sr + upX * cr;
    final ruY = rightY * -sr + upY * cr;
    final ruZ = rightZ * -sr + upZ * cr;

    final s = _shader;
    s.setImageSampler(0, _grid);
    var u = 0;
    s.setFloat(u++, size.width);
    s.setFloat(u++, size.height);
    s.setFloat(u++, 1 / math.tan(_fovY / 2));
    s.setFloat(u++, size.width / size.height);
    s.setFloat(u++, camX);
    s.setFloat(u++, camY);
    s.setFloat(u++, camZ);
    s.setFloat(u++, time);
    s.setFloat(u++, rrX);
    s.setFloat(u++, rrY);
    s.setFloat(u++, rrZ);
    s.setFloat(u++, _plainAlbedo);
    s.setFloat(u++, ruX);
    s.setFloat(u++, ruY);
    s.setFloat(u++, ruZ);
    s.setFloat(u++, 0);
    s.setFloat(u++, fwdX);
    s.setFloat(u++, fwdY);
    s.setFloat(u++, fwdZ);
    s.setFloat(u++, 0);
    s.setFloat(u++, _walk.r / 255);
    s.setFloat(u++, _walk.g / 255);
    s.setFloat(u++, _walk.b / 255);
    s.setFloat(u++, 0);

    _paint.shader = s;
    canvas.drawRect(Offset.zero & size, _paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
