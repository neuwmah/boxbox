import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:window_manager/window_manager.dart';

import 'package:cannon_physics/cannon_physics.dart' as cannon;
import 'package:boxbox/widgets/background.dart';
import 'package:boxbox/widgets/continue.dart';
import 'package:boxbox/widgets/insettings.dart';
import 'package:boxbox/widgets/return.dart';
import 'package:vector_math/vector_math.dart' hide Colors, Sphere;

class GamePage extends StatefulWidget {
  const GamePage({
    super.key,
    required this.coins,
    this.onSpendCoins,
  });

  static const defeatCode = -1;

  final int coins;
  final bool Function(int amount)? onSpendCoins;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _Vec3 {
  const _Vec3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  _Vec3 operator +(_Vec3 o) => _Vec3(x + o.x, y + o.y, z + o.z);

  _Vec3 operator -(_Vec3 o) => _Vec3(x - o.x, y - o.y, z - o.z);

  double dot(_Vec3 o) => x * o.x + y * o.y + z * o.z;

  _Vec3 cross(_Vec3 o) => _Vec3(
        y * o.z - z * o.y,
        z * o.x - x * o.z,
        x * o.y - y * o.x,
      );
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  static const _gravity = 16.0;
  static const _ballRadius = 0.18;
  static const _cubeHalf = 0.28;
  static const _throwSpeed = 18.5;
  static const _camY = 3.4;
  static const _focal = 320.0;
  static const _horizon = 0.56;
  static const _maxBalls = 10;
  static const _continueBalls = 5;
  static const _continueCost = 500;
  static const _clearDelay = 3.0;
  static const _outOfBallsDelay = 3.0;

  static const _ballMass = 2.4;
  static const _cubeMass = 2.2;

  static const _platformHalfW = 1.6;
  static const _platformDistance = 8.0;
  static const _platformDepth = 1.0;
  static const _platformNear = _platformDistance - _platformDepth / 2;
  static const _platformFar = _platformDistance + _platformDepth / 2;
  static const _platformTop = 2.4;
  static const _platformThickness = 0.08;
  static const _groundY = -1.0;
  static const _groundFar = 13.5;
  static const _pyramidZ = _platformDistance;

  late final Ticker _ticker;
  late final AnimationController _menuAnim;
  late cannon.World _world;
  late cannon.Material _cubeMaterial;
  late cannon.Material _ballMaterial;
  late cannon.Material _staticMaterial;

  final List<cannon.Body> _cubes = [];
  final List<cannon.Body> _balls = [];
  Duration _lastElapsed = Duration.zero;
  Size _viewSize = Size.zero;
  int _ballsLeft = _maxBalls;
  late int _coins;
  double _clearTimer = 0;
  double _outOfBallsTimer = 0;
  bool _exiting = false;
  bool _continueOpen = false;
  bool _returnOpen = false;
  bool _menuOpen = false;
  bool _music = true;
  bool _sound = true;
  bool _vibration = true;

  @override
  void initState() {
    super.initState();
    _coins = widget.coins;
    _initWorld();
    _buildLevel();
    _ticker = createTicker(_onTick)..start();
    _menuAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _menuAnim.dispose();
    _ticker.dispose();
    super.dispose();
  }

  void _setMenuOpen(bool open) {
    if (_exiting || _continueOpen || _returnOpen || open == _menuOpen) return;
    setState(() => _menuOpen = open);
    if (open) {
      _menuAnim.forward();
    } else {
      _menuAnim.reverse();
    }
  }

  void _initWorld() {
    final solver = cannon.GSSolver()..iterations = 24;
    _world = cannon.World(
      gravity: Vector3(0, -_gravity, 0),
      allowSleep: true,
      solver: solver,
    );
    _world.defaultContactMaterial.friction = 0.55;
    _world.defaultContactMaterial.restitution = 0.08;

    _staticMaterial = cannon.Material(friction: 0.75, restitution: 0.02);
    _cubeMaterial = cannon.Material(friction: 0.6, restitution: 0.05);
    _ballMaterial = cannon.Material(friction: 0.35, restitution: 0.18);

    _world.addContactMaterial(
      cannon.ContactMaterial(
        _ballMaterial,
        _cubeMaterial,
        friction: 0.35,
        restitution: 0.22,
      ),
    );
    _world.addContactMaterial(
      cannon.ContactMaterial(
        _cubeMaterial,
        _cubeMaterial,
        friction: 0.65,
        restitution: 0.02,
      ),
    );
    _world.addContactMaterial(
      cannon.ContactMaterial(
        _cubeMaterial,
        _staticMaterial,
        friction: 0.7,
        restitution: 0.02,
      ),
    );
    _world.addContactMaterial(
      cannon.ContactMaterial(
        _ballMaterial,
        _staticMaterial,
        friction: 0.35,
        restitution: 0.15,
      ),
    );
  }

  void _clearWorldBodies() {
    for (final body in [..._world.bodies]) {
      _world.removeBody(body);
    }
    _cubes.clear();
    _balls.clear();
  }

  void _buildLevel() {
    _clearWorldBodies();

    final ground = cannon.Body(
      mass: 0,
      material: _staticMaterial,
      shape: cannon.Plane(),
      position: Vector3(0, _groundY, 0),
      type: cannon.BodyTypes.static,
    );
    ground.quaternion.setFromEuler(-math.pi / 2, 0, 0);
    _world.addBody(ground);

    final platformHalfZ = (_platformFar - _platformNear) / 2;
    final platformZ = (_platformFar + _platformNear) / 2;
    final platform = cannon.Body(
      mass: 0,
      material: _staticMaterial,
      shape: cannon.Box(
        Vector3(_platformHalfW, _platformThickness / 2, platformHalfZ),
      ),
      position: Vector3(
        0,
        _platformTop - _platformThickness / 2,
        platformZ,
      ),
      type: cannon.BodyTypes.static,
    );
    _world.addBody(platform);

    const gap = _cubeHalf * 2 + 0.004;
    const baseY = _platformTop + _cubeHalf + 0.002;
    const counts = [5, 3, 1];
    for (var row = 0; row < counts.length; row++) {
      final count = counts[row];
      final y = baseY + row * gap;
      final startX = -(count - 1) * gap / 2;
      for (var i = 0; i < count; i++) {
        _cubes.add(
          _createCube(Vector3(startX + i * gap, y, _pyramidZ)),
        );
      }
    }
  }

  cannon.Body _createCube(Vector3 position) {
    final body = cannon.Body(
      mass: _cubeMass,
      material: _cubeMaterial,
      shape: cannon.Box(Vector3(_cubeHalf, _cubeHalf, _cubeHalf)),
      position: position,
      linearDamping: 0.12,
      angularDamping: 0.22,
      allowSleep: true,
      sleepSpeedLimit: 0.18,
      sleepTimeLimit: 0.4,
    );
    _world.addBody(body);
    return body;
  }

  cannon.Body _createBall(Vector3 position, Vector3 velocity) {
    final body = cannon.Body(
      mass: _ballMass,
      material: _ballMaterial,
      shape: cannon.Sphere(_ballRadius),
      position: position,
      velocity: velocity,
      linearDamping: 0.04,
      angularDamping: 0.15,
      allowSleep: true,
      sleepSpeedLimit: 0.25,
      sleepTimeLimit: 0.6,
    );
    _world.addBody(body);
    return body;
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    var dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    if (dt <= 0) return;
    dt = dt.clamp(0.0, 1 / 30);

    if (_exiting || _continueOpen) return;

    _world.step(1 / 120, dt, 5);

    _balls.removeWhere((ball) {
      final out = ball.position.y < -8;
      if (out) _world.removeBody(ball);
      return out;
    });

    final anyOnPlatform = _cubes.any((cube) {
      final p = cube.position;
      return p.x.abs() <= _platformHalfW &&
          p.z >= _platformNear &&
          p.z <= _platformFar &&
          p.y >= _platformTop;
    });

    if (anyOnPlatform) {
      _clearTimer = 0;
    } else {
      _clearTimer += dt;
      if (_clearTimer >= _clearDelay) {
        _exitGame(50);
        return;
      }
    }

    if (_ballsLeft <= 0 && anyOnPlatform) {
      _outOfBallsTimer += dt;
      if (_outOfBallsTimer >= _outOfBallsDelay) {
        _offerContinueOrExit();
        return;
      }
    } else {
      _outOfBallsTimer = 0;
    }

    setState(() {});
  }

  void _offerContinueOrExit() {
    if (_coins < _continueCost) {
      _exitGame(GamePage.defeatCode);
      return;
    }
    if (_menuOpen) _setMenuOpen(false);
    setState(() => _continueOpen = true);
  }

  void _buyContinue() {
    final spend = widget.onSpendCoins;
    if (spend == null || !spend(_continueCost)) {
      _exitGame(GamePage.defeatCode);
      return;
    }
    setState(() {
      _coins -= _continueCost;
      _ballsLeft = _continueBalls;
      _continueOpen = false;
      _outOfBallsTimer = 0;
    });
  }

  void _exitGame(int? reward) {
    if (_exiting) return;
    _exiting = true;
    _continueOpen = false;
    _returnOpen = false;
    _ticker.stop();
    if (!mounted) return;
    Navigator.of(context).pop(reward);
  }

  Vector3 _screenToWorld(Offset local) {
    final sx = local.dx;
    final sy = local.dy;

    final v = (sy / _viewSize.height).clamp(0.0, 1.0);
    final targetZ = ui.lerpDouble(_groundFar - 0.5, 3.6, v)!;

    final scale = _focal / targetZ;
    final targetX = (sx - _viewSize.width / 2) / scale;
    final targetY = _camY + (_viewSize.height * _horizon - sy) / scale;

    return Vector3(targetX, targetY, targetZ);
  }

  void _throwBall(Offset local) {
    if (_viewSize == Size.zero ||
        !_menuAnim.isDismissed ||
        _exiting ||
        _continueOpen ||
        _returnOpen ||
        _ballsLeft <= 0) {
      return;
    }

    final target = _screenToWorld(local);
    final origin = Vector3(0, 2.0, 1.4);

    final dx = target.x - origin.x;
    final dy = target.y - origin.y;
    final dz = target.z - origin.z;
    final flat = math.sqrt(dx * dx + dz * dz);
    if (flat < 0.05) return;

    final t = math.max(0.16, flat / _throwSpeed);
    final vx = dx / t;
    final vz = dz / t;
    final vy = (dy + 0.5 * _gravity * t * t) / t;

    setState(() {
      _ballsLeft -= 1;
      _balls.add(_createBall(origin, Vector3(vx, vy, vz)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RectBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            LayoutBuilder(
            builder: (context, constraints) {
              _viewSize = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _throwBall(details.localPosition),
                child: CustomPaint(
                  painter: _ScenePainter(
                    cubes: [
                      for (final cube in _cubes)
                        (
                          pos: _Vec3(
                            cube.position.x,
                            cube.position.y,
                            cube.position.z,
                          ),
                          rot: Quaternion.copy(cube.quaternion),
                        ),
                    ],
                    balls: [
                      for (final ball in _balls)
                        _Vec3(
                          ball.position.x,
                          ball.position.y,
                          ball.position.z,
                        ),
                    ],
                    platformHalfW: _platformHalfW,
                    platformNear: _platformNear,
                    platformFar: _platformFar,
                    platformTop: _platformTop,
                    platformThickness: _platformThickness,
                    cubeHalf: _cubeHalf,
                    ballRadius: _ballRadius,
                  ),
                  child: const SizedBox.expand(),
                ),
              );
            },
          ),
          if (_ballsLeft > 0) ...[
            Positioned(
              top: 40,
              left: 38,
              height: 48,
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_menuOpen) {
                      _setMenuOpen(false);
                      return;
                    }
                    if (_exiting || _continueOpen || _returnOpen) return;
                    setState(() => _returnOpen = true);
                  },
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              height: 48,
              child: IgnorePointer(
                child: Center(
                  child: Text(
                    '$_ballsLeft',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      letterSpacing: -.4,
                    ),
                  ),
                ),
              ),
            ),
            InSettingsMenu(
              animation: _menuAnim,
              music: _music,
              sound: _sound,
              vibration: _vibration,
              onToggleMenu: () => _setMenuOpen(!_menuOpen),
              onClose: () => _setMenuOpen(false),
              onMusic: () => setState(() => _music = !_music),
              onSound: () => setState(() => _sound = !_sound),
              onVibration: () => setState(() => _vibration = !_vibration),
            ),
          ],
          if (_continueOpen)
            ContinuePopup(
              coins: _coins,
              price: _continueCost,
              balls: _continueBalls,
              onClose: () => _exitGame(GamePage.defeatCode),
              onContinue: _buyContinue,
            ),
          if (_returnOpen)
            ReturnPopup(
              onClose: () => setState(() => _returnOpen = false),
              onQuit: () => _exitGame(null),
            ),
        ],
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required this.cubes,
    required this.balls,
    required this.platformHalfW,
    required this.platformNear,
    required this.platformFar,
    required this.platformTop,
    required this.platformThickness,
    required this.cubeHalf,
    required this.ballRadius,
  });

  final List<({_Vec3 pos, Quaternion rot})> cubes;
  final List<_Vec3> balls;
  final double platformHalfW;
  final double platformNear;
  final double platformFar;
  final double platformTop;
  final double platformThickness;
  final double cubeHalf;
  final double ballRadius;

  static const _camY = 3.4;
  static const _camZ = 0.0;
  static const _focal = 320.0;
  static const _horizon = 0.56;

  static const _cubeColors = [
    Color(0xFFBDBDBD),
    Color(0xFF757575),
    Color(0xFF9E9E9E),
    Color(0xFFE0E0E0),
    Color(0xFF8D8D8D),
    Color(0xFFA8A8A8),
  ];

  Offset _project(_Vec3 p, Size size) {
    final z = math.max(0.8, p.z - _camZ);
    final scale = _focal / z;
    return Offset(
      size.width / 2 + p.x * scale,
      size.height * _horizon - (p.y - _camY) * scale,
    );
  }

  double _scaleAt(double z) => _focal / math.max(0.8, z - _camZ);

  double _camDist2(_Vec3 p) {
    final dx = p.x;
    final dy = p.y - _camY;
    final dz = p.z - _camZ;
    return dx * dx + dy * dy + dz * dz;
  }

  _Vec3 _rotate(_Vec3 v, Quaternion rot) {
    final out = rot.vmult(Vector3(v.x, v.y, v.z));
    return _Vec3(out.x, out.y, out.z);
  }

  bool _isBehindPlatform(_Vec3 pos) {
    if (pos.z > platformFar) return true;
    final inFootprint = pos.x.abs() <= platformHalfW &&
        pos.z >= platformNear &&
        pos.z <= platformFar;
    final platformBottom = platformTop - platformThickness;
    return inFootprint && pos.y < platformBottom + 0.02;
  }

  void _paintDepthLayer(
    Canvas canvas,
    Size size,
    List<({_Vec3 pos, Quaternion rot})> layerCubes,
    List<_Vec3> layerBalls,
  ) {
    final items = <({double depth, Path? path, Color? color, _Vec3? ball})>[];

    for (final cube in layerCubes) {
      _collectBoxFaces(
        items,
        size,
        center: cube.pos,
        half: _Vec3(cubeHalf, cubeHalf, cubeHalf),
        rot: cube.rot,
        colors: _cubeColors,
      );
    }

    for (final ball in layerBalls) {
      items.add((
        depth: _camDist2(ball),
        path: null,
        color: null,
        ball: ball,
      ));
    }

    items.sort((a, b) => b.depth.compareTo(a.depth));

    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF111111);

    for (final item in items) {
      final ball = item.ball;
      if (ball != null) {
        _paintBall(canvas, size, ball);
        continue;
      }
      fill.color = item.color!;
      canvas.drawPath(item.path!, fill);
      canvas.drawPath(item.path!, stroke);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final behindBalls = <_Vec3>[];
    final frontBalls = <_Vec3>[];
    for (final ball in balls) {
      if (_isBehindPlatform(ball)) {
        behindBalls.add(ball);
      } else {
        frontBalls.add(ball);
      }
    }

    final behindCubes = <({_Vec3 pos, Quaternion rot})>[];
    final frontCubes = <({_Vec3 pos, Quaternion rot})>[];
    for (final cube in cubes) {
      if (_isBehindPlatform(cube.pos)) {
        behindCubes.add(cube);
      } else {
        frontCubes.add(cube);
      }
    }

    _paintDepthLayer(canvas, size, behindCubes, behindBalls);
    _paintPlatform(canvas, size);
    _paintDepthLayer(canvas, size, frontCubes, frontBalls);
  }

  void _paintPlatform(Canvas canvas, Size size) {
    final cx = 0.0;
    final cz = (platformNear + platformFar) / 2;
    final hx = platformHalfW;
    final hz = (platformFar - platformNear) / 2;
    final hy = platformThickness / 2;
    _paintBox(
      canvas,
      size,
      center: _Vec3(cx, platformTop - hy, cz),
      half: _Vec3(hx, hy, hz),
      rot: Quaternion.identity(),
      colors: const [
        Color(0xFF2A2A2A),
        Color(0xFF151515),
        Color(0xFF222222),
        Color(0xFF3A3A3A),
        Color(0xFF1C1C1C),
        Color(0xFF252525),
      ],
    );
  }

  void _collectBoxFaces(
    List<({double depth, Path? path, Color? color, _Vec3? ball})> out,
    Size size, {
    required _Vec3 center,
    required _Vec3 half,
    required Quaternion rot,
    required List<Color> colors,
  }) {
    final locals = [
      _Vec3(-half.x, -half.y, -half.z),
      _Vec3(half.x, -half.y, -half.z),
      _Vec3(half.x, half.y, -half.z),
      _Vec3(-half.x, half.y, -half.z),
      _Vec3(-half.x, -half.y, half.z),
      _Vec3(half.x, -half.y, half.z),
      _Vec3(half.x, half.y, half.z),
      _Vec3(-half.x, half.y, half.z),
    ];

    final vertices = [
      for (final local in locals) center + _rotate(local, rot),
    ];

    const faces = [
      [0, 3, 2, 1],
      [4, 5, 6, 7],
      [0, 1, 5, 4],
      [3, 7, 6, 2],
      [0, 4, 7, 3],
      [1, 2, 6, 5],
    ];

    final projected = [for (final v in vertices) _project(v, size)];

    for (var index = 0; index < faces.length; index++) {
      final face = faces[index];
      final a = vertices[face[0]];
      final b = vertices[face[1]];
      final c = vertices[face[2]];
      final ab = b - a;
      final ac = c - a;
      final normal = ab.cross(ac);
      final faceCenter = _Vec3(
        (a.x + b.x + c.x + vertices[face[3]].x) / 4,
        (a.y + b.y + c.y + vertices[face[3]].y) / 4,
        (a.z + b.z + c.z + vertices[face[3]].z) / 4,
      );
      final toCam = _Vec3(
        -faceCenter.x,
        _camY - faceCenter.y,
        _camZ - faceCenter.z,
      );
      if (normal.dot(toCam) <= 0) continue;

      final path = Path()
        ..moveTo(projected[face[0]].dx, projected[face[0]].dy)
        ..lineTo(projected[face[1]].dx, projected[face[1]].dy)
        ..lineTo(projected[face[2]].dx, projected[face[2]].dy)
        ..lineTo(projected[face[3]].dx, projected[face[3]].dy)
        ..close();

      out.add((
        depth: _camDist2(faceCenter),
        path: path,
        color: colors[index],
        ball: null,
      ));
    }
  }

  void _paintBox(
    Canvas canvas,
    Size size, {
    required _Vec3 center,
    required _Vec3 half,
    required Quaternion rot,
    required List<Color> colors,
  }) {
    final items = <({double depth, Path? path, Color? color, _Vec3? ball})>[];
    _collectBoxFaces(
      items,
      size,
      center: center,
      half: half,
      rot: rot,
      colors: colors,
    );
    items.sort((a, b) => b.depth.compareTo(a.depth));

    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF111111);

    for (final item in items) {
      fill.color = item.color!;
      canvas.drawPath(item.path!, fill);
      canvas.drawPath(item.path!, stroke);
    }
  }

  void _paintBall(Canvas canvas, Size size, _Vec3 ball) {
    final fill = Paint()..color = Colors.white;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF1A1A1A);

    final p = _project(ball, size);
    final r = (ballRadius * _scaleAt(ball.z)).clamp(2.0, 28.0).toDouble();
    canvas.drawCircle(p, r, fill);
    canvas.drawCircle(p, r, stroke);
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) => true;
}
