import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Vertices, VertexMode;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class CubesBackground extends StatefulWidget {
  const CubesBackground({super.key});

  @override
  State<CubesBackground> createState() => _CubesBackgroundState();
}

class _CubesBackgroundState extends State<CubesBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final _Repaint _repaint;
  late final _CubesPainter _painter;

  @override
  void initState() {
    super.initState();
    _repaint = _Repaint();
    _painter = _CubesPainter(_repaint);
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    _painter.tick(elapsed);
    _repaint.bump();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _painter,
        size: Size.infinite,
        isComplex: true,
        willChange: true,
      ),
    );
  }
}

class _Repaint extends ChangeNotifier {
  void bump() => notifyListeners();
}

class _ColorWalk {
  double r = 0;
  double g = 0;
  double b = 255;
  double rs = 0;
  double gs = 0;
  double bs = 0;
  double rt = 0;
  double gt = 0;
  double bt = 255;
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
  _CubesPainter(Listenable repaint) : super(repaint: repaint) {
    _buildGrid();
    _bakeLights();
  }

  static const _extent = 18;
  static const _count = (_extent * 2 + 1) * (_extent * 2 + 1);
  static const _fovY = 45 * math.pi / 180;
  static const _fogNear = 22.0;
  static const _fogFar = 40.0;
  static const _fogFar2 = _fogFar * _fogFar;
  static const _lightReach = 8.5;
  static const _ambient = 0.055;
  static const _specular = 0.08;
  static const _shininess = 30.0;
  static const _plainAlbedo = 0.12;
  static const _half = 0.5;
  static const _maxFaces = _count * 5;
  static const _maxVerts = _maxFaces * 6;

  static const _lx = [
    -_half, _half, _half, -_half, -_half, _half, _half, -_half,
  ];
  static const _ly = [
    -_half, -_half, _half, _half, -_half, -_half, _half, _half,
  ];
  static const _lz = [
    -_half, -_half, -_half, -_half, _half, _half, _half, _half,
  ];
  static const _faceIndex = [
    0, 3, 2, 1,
    4, 5, 6, 7,
    3, 7, 6, 2,
    0, 4, 7, 3,
    1, 2, 6, 5,
  ];
  static const _nx = [0.0, 0.0, 0.0, -1.0, 1.0];
  static const _ny = [0.0, 0.0, 1.0, 0.0, 0.0];
  static const _nz = [-1.0, 1.0, 0.0, 0.0, 0.0];

  static const _lightX = [
    -15.0, -15.0, -15.0, -15.0, -15.0, -15.0, -15.0,
    -10.0, -10.0, -10.0, -10.0, -10.0, -10.0, -10.0,
    -5.0, -5.0, -5.0, -5.0, -5.0, -5.0, -5.0,
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
    5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0,
    10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0,
    15.0, 15.0, 15.0, 15.0, 15.0, 15.0, 15.0,
  ];
  static const _lightZ = [
    -15.0, -10.0, -5.0, 0.0, 5.0, 10.0, 15.0,
    -15.0, -10.0, -5.0, 0.0, 5.0, 10.0, 15.0,
    -15.0, -10.0, -5.0, 0.0, 5.0, 10.0, 15.0,
    -15.0, -10.0, -5.0, 0.0, 5.0, 10.0, 15.0,
    -15.0, -10.0, -5.0, 0.0, 5.0, 10.0, 15.0,
    -15.0, -10.0, -5.0, 0.0, 5.0, 10.0, 15.0,
    -15.0, -10.0, -5.0, 0.0, 5.0, 10.0, 15.0,
  ];

  final _walk = _ColorWalk();
  final _cx = Float64List(_count);
  final _cz = Float64List(_count);
  final _height = Float64List(_count);
  final _offset = Float64List(_count);
  final _colored = Uint8List(_count);
  final _baked = Float32List(_count * 5);
  final _px = Float64List(8);
  final _py = Float64List(8);
  final _ok = Uint8List(8);
  final _quad = Float32List(_maxFaces * 8);
  final _faceDepth = Float64List(_maxFaces);
  final _faceColor = Int32List(_maxFaces);
  final _faceOrder = <int>[];
  final _pos = Float32List(_maxVerts * 2);
  final _col = Int32List(_maxVerts);
  final _paint = Paint()..isAntiAlias = true;
  double _time = 0;

  void tick(Duration elapsed) {
    _time = elapsed.inMicroseconds / 16666.666666;
    _walk.step();
  }

  void _buildGrid() {
    final rng = math.Random(7);
    var i = 0;
    for (var x = -_extent; x <= _extent; x++) {
      for (var z = -_extent; z <= _extent; z++) {
        _cx[i] = x.toDouble();
        _cz[i] = z.toDouble();
        _height[i] = (rng.nextInt(10) + 1) / 10;
        _offset[i] = (rng.nextInt(400) + 1) / 100;
        _colored[i] = rng.nextDouble() > 0.75 ? 1 : 0;
        i++;
      }
    }
  }

  void _bakeLights() {
    const viewX = 6.0;
    const viewY = 8.0;
    const viewZ = 4.0;
    for (var i = 0; i < _count; i++) {
      for (var f = 0; f < 5; f++) {
        final px = _cx[i] + _half * _nx[f];
        final py = _half * _ny[f];
        final pz = _cz[i] + _half * _nz[f];
        var lit = _ambient;
        var vx = viewX - px;
        var vy = viewY - py;
        var vz = viewZ - pz;
        final vLen = math.sqrt(vx * vx + vy * vy + vz * vz);
        if (vLen > 1e-8) {
          vx /= vLen;
          vy /= vLen;
          vz /= vLen;
        }
        for (var l = 0; l < _lightX.length; l++) {
          final lx = _lightX[l] - px;
          final lz = _lightZ[l] - pz;
          if (lx.abs() > _lightReach || lz.abs() > _lightReach) continue;
          final ly = 2 - py;
          final d2 = lx * lx + ly * ly + lz * lz;
          if (d2 > _lightReach * _lightReach || d2 < 1e-6) continue;
          final d = math.sqrt(d2);
          final atten = 1 - d / _lightReach;
          final inv = 1 / d;
          final ndotl = math.max(
            0.0,
            _nx[f] * lx * inv + _ny[f] * ly * inv + _nz[f] * lz * inv,
          );
          if (ndotl <= 0) continue;
          lit += ndotl * atten;
          final rx = _nx[f] * (2 * ndotl) - lx * inv;
          final ry = _ny[f] * (2 * ndotl) - ly * inv;
          final rz = _nz[f] * (2 * ndotl) - lz * inv;
          final rdotv = math.max(0.0, rx * vx + ry * vy + rz * vz);
          lit += math.pow(rdotv, _shininess) * atten * _specular;
        }
        _baked[i * 5 + f] = lit.toDouble();
      }
    }
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
    var fwdX = -6 * invEye;
    var fwdY = -8 * invEye;
    var fwdZ = -4 * invEye;
    var rightX = fwdY * 0 - fwdZ * 1;
    var rightY = fwdZ * 0 - fwdX * 0;
    var rightZ = fwdX * 1 - fwdY * 0;
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
    rightX = rrX;
    rightY = rrY;
    rightZ = rrZ;
    upX = ruX;
    upY = ruY;
    upZ = ruZ;

    final aspect = size.width / size.height;
    final f = 1 / math.tan(_fovY / 2);
    final width = size.width;
    final height = size.height;
    final tintR = _walk.r / 255;
    final tintG = _walk.g / 255;
    final tintB = _walk.b / 255;

    canvas.clipRect(Offset.zero & size);

    final px = _px;
    final py = _py;
    final ok = _ok;
    final order = _faceOrder..clear();
    var nFaces = 0;

    for (var i = 0; i < _count; i++) {
      final x = _cx[i];
      final z = _cz[i];
      final y = math.sin(time / 100 + _offset[i]) * _height[i];
      final dx = x - camX;
      final dy = y - camY;
      final dz = z - camZ;
      final d2 = dx * dx + dy * dy + dz * dz;
      if (d2 > _fogFar2) continue;
      final czv = dx * fwdX + dy * fwdY + dz * fwdZ;
      if (czv < 0.35) continue;
      final invC = 1 / czv;
      final scx =
          (f * (dx * rightX + dy * rightY + dz * rightZ) * invC / aspect * 0.5 +
              0.5) *
          width;
      final scy =
          (0.5 - f * (dx * upX + dy * upY + dz * upZ) * invC * 0.5) * height;
      if (scx < -90 || scx > width + 90 || scy < -90 || scy > height + 90) {
        continue;
      }

      var any = false;
      var minX = double.infinity;
      var maxX = -double.infinity;
      var minY = double.infinity;
      var maxY = -double.infinity;
      for (var k = 0; k < 8; k++) {
        final relX = x + _lx[k] - camX;
        final relY = y + _ly[k] - camY;
        final relZ = z + _lz[k] - camZ;
        final depth = relX * fwdX + relY * fwdY + relZ * fwdZ;
        if (depth < 0.35) {
          ok[k] = 0;
          continue;
        }
        final inv = 1 / depth;
        final sx =
            (f *
                        (relX * rightX + relY * rightY + relZ * rightZ) *
                        inv /
                        aspect *
                        0.5 +
                    0.5) *
                width;
        final sy =
            (0.5 - f * (relX * upX + relY * upY + relZ * upZ) * inv * 0.5) *
            height;
        px[k] = sx;
        py[k] = sy;
        ok[k] = 1;
        any = true;
        if (sx < minX) minX = sx;
        if (sx > maxX) maxX = sx;
        if (sy < minY) minY = sy;
        if (sy > maxY) maxY = sy;
      }
      if (!any ||
          maxX < -8 ||
          minX > width + 8 ||
          maxY < -8 ||
          minY > height + 8) {
        continue;
      }

      final fogT = (math.sqrt(d2) - _fogNear) / (_fogFar - _fogNear);
      final fog = fogT.clamp(0.0, 1.0);
      final keep = 1 - fog * fog * (3 - 2 * fog);
      if (keep <= 0.02) continue;

      final colored = _colored[i] == 1;
      final ar = colored ? tintR : _plainAlbedo;
      final ag = colored ? tintG : _plainAlbedo;
      final ab = colored ? tintB : _plainAlbedo;

      for (var fce = 0; fce < 5; fce++) {
        if ((camX - x) * _nx[fce] +
                (camY - y) * _ny[fce] +
                (camZ - z) * _nz[fce] <=
            _half) {
          continue;
        }
        final i0 = _faceIndex[fce * 4];
        final i1 = _faceIndex[fce * 4 + 1];
        final i2 = _faceIndex[fce * 4 + 2];
        final i3 = _faceIndex[fce * 4 + 3];
        if (ok[i0] == 0 || ok[i1] == 0 || ok[i2] == 0 || ok[i3] == 0) continue;

        final lit = _baked[i * 5 + fce] * keep;
        final ri = (ar * lit * 255).clamp(0, 255).toInt();
        final gi = (ag * lit * 255).clamp(0, 255).toInt();
        final bi = (ab * lit * 255).clamp(0, 255).toInt();

        final fcx = x + _nx[fce] * _half;
        final fcy = y + _ny[fce] * _half;
        final fcz = z + _nz[fce] * _half;
        var depth =
            (fcx - camX) * fwdX + (fcy - camY) * fwdY + (fcz - camZ) * fwdZ;
        if (fce == 2) depth -= 0.12;

        final fi = nFaces++;
        final q = fi * 8;
        _quad[q] = px[i0];
        _quad[q + 1] = py[i0];
        _quad[q + 2] = px[i1];
        _quad[q + 3] = py[i1];
        _quad[q + 4] = px[i2];
        _quad[q + 5] = py[i2];
        _quad[q + 6] = px[i3];
        _quad[q + 7] = py[i3];
        _faceDepth[fi] = depth;
        _faceColor[fi] = 0xFF000000 | (ri << 16) | (gi << 8) | bi;
        order.add(fi);
      }
    }

    order.sort((a, b) => _faceDepth[b].compareTo(_faceDepth[a]));

    var v = 0;
    for (final fi in order) {
      final q = fi * 8;
      final packed = _faceColor[fi];
      final p = v * 2;
      _pos[p] = _quad[q];
      _pos[p + 1] = _quad[q + 1];
      _pos[p + 2] = _quad[q + 2];
      _pos[p + 3] = _quad[q + 3];
      _pos[p + 4] = _quad[q + 4];
      _pos[p + 5] = _quad[q + 5];
      _pos[p + 6] = _quad[q];
      _pos[p + 7] = _quad[q + 1];
      _pos[p + 8] = _quad[q + 4];
      _pos[p + 9] = _quad[q + 5];
      _pos[p + 10] = _quad[q + 6];
      _pos[p + 11] = _quad[q + 7];
      _col[v] = packed;
      _col[v + 1] = packed;
      _col[v + 2] = packed;
      _col[v + 3] = packed;
      _col[v + 4] = packed;
      _col[v + 5] = packed;
      v += 6;
    }

    if (v == 0) return;
    canvas.drawVertices(
      Vertices.raw(
        VertexMode.triangles,
        Float32List.sublistView(_pos, 0, v * 2),
        colors: Int32List.sublistView(_col, 0, v),
      ),
      BlendMode.srcOver,
      _paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
