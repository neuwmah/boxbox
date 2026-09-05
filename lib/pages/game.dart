import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'package:cannon_physics/cannon_physics.dart' as cannon;
import 'package:boxbox/game/insettings.dart';
import 'package:boxbox/game/level.dart';
import 'package:boxbox/popups/continue.dart';
import 'package:boxbox/popups/return.dart';
import 'package:boxbox/sound/sfx.dart';
import 'package:boxbox/sound/soundtrack.dart';
import 'package:vector_math/vector_math.dart' hide Colors, Sphere, Matrix4;

class LoadingCover extends StatelessWidget {
  const LoadingCover({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Image(
          image: AssetImage(loadingAsset),
          fit: BoxFit.contain,
          width: 100,
          height: 100,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({
    super.key,
    required this.coins,
    required this.level,
    this.onSpendCoins,
    this.onPrepareReward,
    this.onCoverBeforeExit,
  });

  static const defeatCode = -1;

  final int coins;
  final int level;
  final bool Function(int amount)? onSpendCoins;
  final ValueChanged<int>? onPrepareReward;
  final VoidCallback? onCoverBeforeExit;

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

class _HitSpark {
  _HitSpark(this.pos);

  final _Vec3 pos;
  double age = 0;
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  static const _gravity = 16.0;
  static const _ballRadius = 0.18;
  static const _cubeHalf = 0.28;
  static const _throwSpeed = 18.5;
  static const _camY = 3.4;
  static const _focal = 320.0;
  static const _horizon = 0.56;
  static const _maxBalls = 20;
  static const _continueBalls = 5;
  static const _continueCost = 500;
  static const _clearDelay = 3.0;
  static const _clearBannerDuration = 3.0;
  static const _outOfBallsDelay = 3.0;
  static const _loadingMinDuration = Duration(milliseconds: 500);
  static const _loadingFadeDuration = Duration(milliseconds: 250);
  static const _exitLoadingDuration = Duration(seconds: 1);
  static const _ballMass = 3.2;
  static const _hitSpeed2 = 6.25;
  static const _hitLookAhead = 0.04;
  static const _hitSparkDuration = 0.28;
  static const _fallLookAhead = 0.04;
  static const _fallSpeed = 1.2;
  static const _cubeGap = _cubeHalf * 2;
  static const _startX = -(levelSize - 1) * _cubeGap / 2;
  static const _platformX = 0.0;
  static const _platformHalfW = (levelSize - 1) * _cubeGap / 2 + _cubeHalf;
  static const _platformDistance = 8.0;
  static const _platformDepth = 6 * _cubeHalf;
  static const _platformNear = _platformDistance - _platformDepth / 2;
  static const _platformFar = _platformDistance + _platformDepth / 2;
  static const _platformTop = 1.6;
  static const _platformThickness = _cubeGap;
  static const _groundY = -1.0;
  static const _groundFar = 13.5;
  static const _layer1Z = _platformDistance - 2 * _cubeHalf;
  static const _layer2Z = _platformDistance;
  static const _layer3Z = _platformDistance + 2 * _cubeHalf;

  late final Ticker _ticker;
  late final AnimationController _menuAnim;
  late final AnimationController _loadingFade;
  late cannon.World _world;
  late cannon.Material _cubeSoftMaterial;
  late cannon.Material _cubeMidMaterial;
  late cannon.Material _cubeHardMaterial;
  late cannon.Material _ballMaterial;
  late cannon.Material _staticMaterial;
  late cannon.Body _ground;

  final List<cannon.Body> _cubes = [];
  final List<Color> _cubeColors = [];
  final List<BlockShape> _cubeShapes = [];
  final List<_Vec3> _cubeHalves = [];
  final List<cannon.Body> _balls = [];
  final List<_HitSpark> _hitSparks = [];
  final Set<int> _hitPlayed = {};
  final Set<int> _sparkPlayed = {};
  final Set<int> _fallPlayed = {};
  bool _ggPlayed = false;
  late final void Function(dynamic) _onBeginContact;
  Duration _lastElapsed = Duration.zero;
  Size _viewSize = Size.zero;
  int _ballsLeft = _maxBalls;
  late int _coins;
  final Map<String, ui.Image> _floorImages = {};
  bool _loadingStarted = false;
  bool _assetsReady = false;
  double _clearTimer = 0;
  double _outOfBallsTimer = 0;
  bool _exiting = false;
  bool _continueOpen = false;
  bool _returnOpen = false;
  bool _menuOpen = false;
  bool _vibration = true;
  late final int _musicSession;
  bool _restoreHomeOnDispose = true;

  @override
  void initState() {
    super.initState();
    _coins = widget.coins;
    _onBeginContact = _handleBeginContact;
    _initWorld();
    _ticker = createTicker(_onTick);
    _menuAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _loadingFade = AnimationController(
      vsync: this,
      duration: _loadingFadeDuration,
      value: 1,
    )..addStatusListener((status) {
        if (status == AnimationStatus.dismissed && mounted) {
          Soundtrack.instance.playGame(_musicSession);
          setState(() {});
        }
      });
    _musicSession = Soundtrack.instance.claimGame();
  }

  FloorSkin get _floor => floorAt(widget.level);

  BackgroundSkin get _background => backgroundAt(widget.level);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadingStarted) return;
    _loadingStarted = true;
    _loadLevelAssets();
  }

  Future<void> _loadLevelAssets() async {
    await Future.wait([
      _buildLevel(),
      _decodeFloor(_floor.asset),
      precacheImage(AssetImage(_background.asset), context),
      precacheImage(AssetImage(ballsBadgeAt(widget.level)), context),
      Future<void>.delayed(_loadingMinDuration),
      Soundtrack.instance.preloadGame(),
      Sfx.instance.preload(),
    ]);
    if (!mounted) return;

    _ticker.start();
    setState(() {});
    await _waitPaintedFrames(3);
    if (!mounted) return;

    setState(() => _assetsReady = true);
    await _waitPaintedFrames(2);
    if (!mounted) return;

    _loadingFade.reverse();
    _loadRemainingFloors();
  }

  Future<void> _waitPaintedFrames(int count) async {
    for (var i = 0; i < count; i++) {
      if (!mounted) return;
      setState(() {});
      await SchedulerBinding.instance.endOfFrame;
    }
  }

  Future<void> _decodeFloor(String? asset) async {
    if (asset == null || asset.isEmpty) return;
    if (_floorImages.containsKey(asset)) return;
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (!mounted) {
      frame.image.dispose();
      return;
    }
    _floorImages[asset] = frame.image;
  }

  Future<void> _loadRemainingFloors() async {
    for (final floor in floors) {
      if (!mounted) return;
      await _decodeFloor(floor.asset);
    }
  }

  @override
  void dispose() {
    for (final image in _floorImages.values) {
      image.dispose();
    }
    _loadingFade.dispose();
    _menuAnim.dispose();
    _ticker.dispose();
    _world.removeEventListener('beginContact', _onBeginContact);
    Soundtrack.instance.releaseGame(
      _musicSession,
      restoreHome: _restoreHomeOnDispose,
    );
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
    _cubeSoftMaterial = cannon.Material(friction: 0.45, restitution: 0.12);
    _cubeMidMaterial = cannon.Material(friction: 0.65, restitution: 0.05);
    _cubeHardMaterial = cannon.Material(friction: 0.9, restitution: 0.01);
    _ballMaterial = cannon.Material(friction: 0.35, restitution: 0.18);

    void contact(cannon.Material a, cannon.Material b, {
      required double friction,
      required double restitution,
    }) {
      _world.addContactMaterial(
        cannon.ContactMaterial(a, b, friction: friction, restitution: restitution),
      );
    }

    contact(_ballMaterial, _cubeSoftMaterial, friction: 0.3, restitution: 0.28);
    contact(_ballMaterial, _cubeMidMaterial, friction: 0.35, restitution: 0.18);
    contact(_ballMaterial, _cubeHardMaterial, friction: 0.45, restitution: 0.08);
    contact(_cubeSoftMaterial, _cubeSoftMaterial, friction: 0.5, restitution: 0.06);
    contact(_cubeMidMaterial, _cubeMidMaterial, friction: 0.7, restitution: 0.03);
    contact(_cubeHardMaterial, _cubeHardMaterial, friction: 0.9, restitution: 0.01);
    contact(_cubeSoftMaterial, _cubeMidMaterial, friction: 0.55, restitution: 0.04);
    contact(_cubeSoftMaterial, _cubeHardMaterial, friction: 0.65, restitution: 0.02);
    contact(_cubeMidMaterial, _cubeHardMaterial, friction: 0.8, restitution: 0.015);
    contact(_cubeSoftMaterial, _staticMaterial, friction: 0.55, restitution: 0.04);
    contact(_cubeMidMaterial, _staticMaterial, friction: 0.75, restitution: 0.02);
    contact(_cubeHardMaterial, _staticMaterial, friction: 0.9, restitution: 0.01);
    contact(_ballMaterial, _staticMaterial, friction: 0.35, restitution: 0.15);
    _world.addEventListener('beginContact', _onBeginContact);
  }

  void _handleBeginContact(dynamic event) {
    if (event is! cannon.ContactEvent) return;
    final a = event.bodyA;
    final b = event.bodyB;
    if (a == null || b == null) return;
    _tryBallHitContact(a, b);
    _tryCubeFallContact(a, b);
  }

  void _tryBallHitContact(cannon.Body a, cannon.Body b) {
    final aIsBall = _balls.contains(a);
    final bIsBall = _balls.contains(b);
    final aIsCube = _cubes.contains(a);
    final bIsCube = _cubes.contains(b);
    if (!(aIsBall && bIsCube) && !(bIsBall && aIsCube)) return;

    final ball = aIsBall ? a : b;
    final cube = aIsBall ? b : a;

    final dx = a.velocity.x - b.velocity.x;
    final dy = a.velocity.y - b.velocity.y;
    final dz = a.velocity.z - b.velocity.z;
    if (dx * dx + dy * dy + dz * dz < _hitSpeed2) return;

    _playBallHit(ball.id);
    if (!_sparkPlayed.add(ball.id)) return;
    _hitSparks.add(_HitSpark(_ballCubeContact(ball, cube)));
  }

  _Vec3 _ballCubeContact(cannon.Body ball, cannon.Body cube) {
    final i = _cubes.indexOf(cube);
    final half = i >= 0
        ? _cubeHalves[i]
        : const _Vec3(_cubeHalf, _cubeHalf, _cubeHalf);
    final ox = ball.position.x - cube.position.x;
    final oy = ball.position.y - cube.position.y;
    final oz = ball.position.z - cube.position.z;
    final local = Quaternion.copy(cube.quaternion).conjugated().vmult(
          Vector3(ox, oy, oz),
        );
    final cx = local.x.clamp(-half.x, half.x);
    final cy = local.y.clamp(-half.y, half.y);
    final cz = local.z.clamp(-half.z, half.z);
    final world = cube.quaternion.vmult(Vector3(cx, cy, cz));
    return _Vec3(
      cube.position.x + world.x,
      cube.position.y + world.y,
      cube.position.z + world.z,
    );
  }

  void _tryCubeFallContact(cannon.Body a, cannon.Body b) {
    if (!_assetsReady) return;
    final cube = _cubeHittingGround(a, b);
    if (cube == null || cube.velocity.y > -_fallSpeed) return;
    _playCubeFall(cube.id);
  }

  cannon.Body? _cubeHittingGround(cannon.Body a, cannon.Body b) {
    if (a == _ground && _cubes.contains(b)) return b;
    if (b == _ground && _cubes.contains(a)) return a;
    return null;
  }

  void _predictBallHits() {
    for (final ball in _balls) {
      if (_hitPlayed.contains(ball.id)) continue;
      final speed2 = ball.velocity.length2;
      if (speed2 < _hitSpeed2) continue;

      for (var i = 0; i < _cubes.length; i++) {
        final cube = _cubes[i];
        final half = _cubeHalves[i];
        if (_ballWillHitCube(ball, cube, half, _hitLookAhead)) {
          _playBallHit(ball.id);
          break;
        }
      }
    }
  }

  bool _ballWillHitCube(
    cannon.Body ball,
    cannon.Body cube,
    _Vec3 half,
    double tMax,
  ) {
    final hx = half.x + _ballRadius;
    final hy = half.y + _ballRadius;
    final hz = half.z + _ballRadius;
    final ox = ball.position.x - cube.position.x;
    final oy = ball.position.y - cube.position.y;
    final oz = ball.position.z - cube.position.z;
    final vx = ball.velocity.x - cube.velocity.x;
    final vy = ball.velocity.y - cube.velocity.y;
    final vz = ball.velocity.z - cube.velocity.z;

    if (ox.abs() <= hx && oy.abs() <= hy && oz.abs() <= hz) {
      return vx * vx + vy * vy + vz * vz >= _hitSpeed2;
    }

    var tEnter = 0.0;
    var tExit = tMax;

    bool slab(double origin, double vel, double extent) {
      if (vel.abs() < 1e-8) return origin.abs() <= extent;
      final inv = 1.0 / vel;
      var t1 = (-extent - origin) * inv;
      var t2 = (extent - origin) * inv;
      if (t1 > t2) {
        final swap = t1;
        t1 = t2;
        t2 = swap;
      }
      if (t1 > tEnter) tEnter = t1;
      if (t2 < tExit) tExit = t2;
      return tEnter <= tExit && tExit >= 0;
    }

    return slab(ox, vx, hx) &&
        slab(oy, vy, hy) &&
        slab(oz, vz, hz) &&
        tEnter <= tMax;
  }

  void _playBallHit(int ballId) {
    if (!_hitPlayed.add(ballId)) return;
    Sfx.instance.playHit();
  }

  void _playCubeFall(int cubeId) {
    if (!_fallPlayed.add(cubeId)) return;
    Sfx.instance.playFall();
  }

  void _predictCubeFalls() {
    if (!_assetsReady) return;
    for (var i = 0; i < _cubes.length; i++) {
      final cube = _cubes[i];
      if (_fallPlayed.contains(cube.id)) continue;
      final vy = cube.velocity.y;
      if (vy > -_fallSpeed) continue;
      final half = _cubeHalves[i];
      final extent = math.max(half.x, math.max(half.y, half.z));
      final dist = cube.position.y - extent - _groundY;
      if (dist <= 0 || dist / -vy <= _fallLookAhead) {
        _playCubeFall(cube.id);
      }
    }
  }

  void _clearWorldBodies() {
    for (final body in [..._world.bodies]) {
      _world.removeBody(body);
    }
    _cubes.clear();
    _cubeColors.clear();
    _cubeShapes.clear();
    _cubeHalves.clear();
    _balls.clear();
    _hitSparks.clear();
    _hitPlayed.clear();
    _sparkPlayed.clear();
    _fallPlayed.clear();
    _ggPlayed = false;
  }

  Future<void> _buildLevel() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    _clearWorldBodies();

    _ground = cannon.Body(
      mass: 0,
      material: _staticMaterial,
      shape: cannon.Plane(),
      position: Vector3(0, _groundY, 0),
      type: cannon.BodyTypes.static,
    );
    _ground.quaternion.setFromEuler(-math.pi / 2, 0, 0);
    _world.addBody(_ground);

    final platformHalfZ = (_platformFar - _platformNear) / 2;
    final platformZ = (_platformFar + _platformNear) / 2;
    final platform = cannon.Body(
      mass: 0,
      material: _staticMaterial,
      shape: cannon.Box(
        Vector3(_platformHalfW, _platformThickness / 2, platformHalfZ),
      ),
      position: Vector3(
        _platformX,
        _platformTop - _platformThickness / 2,
        platformZ,
      ),
      type: cannon.BodyTypes.static,
    );
    _world.addBody(platform);

    const gap = _cubeGap;
    var placed = 0;
    for (final block in levelAt(widget.level)) {
      if (block.x < 0 ||
          block.x >= levelSize ||
          block.y < 0 ||
          block.y >= levelSize) {
        continue;
      }

      final shape = block.type;
      final color = Color(block.color);
      final row = block.y;
      final col = block.x;
      final coneRadius = _cubeHalf * 1.05;
      final coneHeight = coneRadius * 1.55;
      final half = switch (shape) {
        BlockShape.rect => _Vec3(_cubeHalf, _cubeHalf * 2, _cubeHalf),
        BlockShape.triangle => _Vec3(coneRadius, coneHeight / 2, coneRadius),
        BlockShape.box => _Vec3(_cubeHalf, _cubeHalf, _cubeHalf),
      };
      final y = switch (shape) {
        BlockShape.rect =>
          _platformTop + _cubeHalf + (row - 1) * gap + gap / 2,
        BlockShape.triangle => _platformTop + row * gap + coneHeight / 2,
        BlockShape.box => _platformTop + _cubeHalf + row * gap,
      };
      final x = _startX + col * gap;

      void place(double z) {
        _cubes.add(
          _createBlock(
            Vector3(x, y, z),
            color: color,
            shape: shape,
            half: half,
          ),
        );
        _cubeColors.add(color);
        _cubeShapes.add(shape);
        _cubeHalves.add(half);
      }

      final layers = block.layer.toString();
      if (layers.contains('1')) place(_layer1Z);
      if (layers.contains('2')) place(_layer2Z);
      if (layers.contains('3')) place(_layer3Z);

      placed += 1;
      if (placed % 16 == 0) {
        await Future<void>.delayed(Duration.zero);
        if (!mounted) return;
      }
    }

    for (var i = 0; i < 12; i++) {
      _world.step(1 / 120, 1 / 60, 5);
    }
  }

  cannon.Material _materialForMass(double mass) {
    if (mass < 1.75) return _cubeSoftMaterial;
    if (mass < 2.5) return _cubeMidMaterial;
    return _cubeHardMaterial;
  }

  cannon.Body _createBlock(
    Vector3 position, {
    required Color color,
    required BlockShape shape,
    required _Vec3 half,
  }) {
    final baseMass = massForColor(color);
    final mass = shape == BlockShape.rect ? baseMass * 2 : baseMass;
    final body = cannon.Body(
      mass: mass,
      material: _materialForMass(baseMass),
      shape: switch (shape) {
        BlockShape.triangle => cannon.Cone(
            radius: half.x,
            height: half.y * 2,
            numSegments: 20,
          ),
        _ => cannon.Box(Vector3(half.x, half.y, half.z)),
      },
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

    if (_exiting || _continueOpen || _returnOpen) return;

    _predictBallHits();
    _predictCubeFalls();
    _world.step(1 / 120, dt, 5);

    for (final spark in _hitSparks) {
      spark.age += dt;
    }
    _hitSparks.removeWhere((spark) => spark.age >= _hitSparkDuration);

    if (!_assetsReady) {
      setState(() {});
      return;
    }

    _balls.removeWhere((ball) {
      final out = ball.position.y < -8;
      if (out) {
        _hitPlayed.remove(ball.id);
        _sparkPlayed.remove(ball.id);
        _world.removeBody(ball);
      }
      return out;
    });

    final anyOnPlatform = _cubes.any((cube) {
      final p = cube.position;
      return (p.x - _platformX).abs() <= _platformHalfW &&
          p.y >= _platformTop &&
          p.z >= _platformNear &&
          p.z <= _platformFar;
    });

    if (anyOnPlatform) {
      _clearTimer = 0;
    } else {
      if (!_ggPlayed) {
        _ggPlayed = true;
        Sfx.instance.playGg();
      }
      _clearTimer += dt;
      if (_clearTimer >= _clearDelay) {
        _exitGame(100);
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

  Future<void> _exitGame(int? reward) async {
    if (_exiting) return;
    _exiting = true;
    _continueOpen = false;
    _returnOpen = false;
    _ticker.stop();
    _restoreHomeOnDispose =
        reward == null || reward <= 0 || reward == GamePage.defeatCode;
    Soundtrack.instance.releaseGame(_musicSession, restoreHome: false);
    _loadingFade.value = 1;
    if (mounted) setState(() {});
    widget.onCoverBeforeExit?.call();
    await Future<void>.delayed(_exitLoadingDuration);
    if (!mounted) return;
    if (reward != null && reward > 0) {
      widget.onPrepareReward?.call(reward);
    }
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
    if (!_assetsReady ||
        _viewSize == Size.zero ||
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

    Sfx.instance.playShot();

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
      backgroundColor: _assetsReady ? Colors.transparent : Colors.black,
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Transform.scale(
            scale: _background.scale,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0xA0000000),
                BlendMode.srcATop,
              ),
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Image(
                  image: AssetImage(_background.asset),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              _viewSize = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _throwBall(details.localPosition),
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: 0.55,
                    sigmaY: 0.55,
                    tileMode: TileMode.decal,
                  ),
                  child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _ScenePainter(
                    cubes: [
                      for (var i = 0; i < _cubes.length; i++)
                        (
                          pos: _Vec3(
                            _cubes[i].position.x,
                            _cubes[i].position.y,
                            _cubes[i].position.z,
                          ),
                          rot: Quaternion.copy(_cubes[i].quaternion),
                          color: _cubeColors[i],
                          shape: _cubeShapes[i],
                          half: _cubeHalves[i],
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
                    platformXs: const [_platformX],
                    platformTops: const [_platformTop],
                    platformHalfW: _platformHalfW,
                    platformNear: _platformNear,
                    platformFar: _platformFar,
                    platformThickness: _platformThickness,
                    ballRadius: _ballRadius,
                    floorImage: _floor.asset == null
                        ? null
                        : _floorImages[_floor.asset!],
                    floorTopColor: Color(_floor.topColor),
                    floorBottomColor: Color(_floor.bottomColor),
                    floorStyle: _floor.style,
                    hitSparks: [
                      for (final spark in _hitSparks)
                        (
                          pos: spark.pos,
                          t: (spark.age / _hitSparkDuration).clamp(0.0, 1.0),
                        ),
                    ],
                    ),
                    child: const SizedBox.expand(),
                  ),
                  ),
                ),
              );
            },
          ),
          if (_assetsReady && _ballsLeft > 0) ...[
            Positioned(
              top: 93,
              left: 0,
              right: 0,
              height: 48,
              child: Align(
                alignment: Alignment.center,
                child: Transform.translate(
                  offset: const Offset(-100, 0),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Sfx.instance.playTouch();
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
            ),
            Positioned(
              top: 72,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: _BallsBadge(
                    value: _ballsLeft,
                    asset: ballsBadgeAt(widget.level),
                  ),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: Listenable.merge([
                Soundtrack.instance,
                Sfx.instance,
              ]),
              builder: (context, _) {
                return InSettingsMenu(
                  animation: _menuAnim,
                  music: Soundtrack.instance.enabled,
                  sound: Sfx.instance.enabled,
                  vibration: _vibration,
                  onToggleMenu: () => _setMenuOpen(!_menuOpen),
                  onClose: () => _setMenuOpen(false),
                  onMusic: Soundtrack.instance.toggle,
                  onSound: Sfx.instance.toggle,
                  onVibration: () => setState(() => _vibration = !_vibration),
                );
              },
            ),
          ],
          if (_clearTimer > 0 && _clearTimer < _clearBannerDuration)
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: const Alignment(0, 0),
                  child: _ClearBanner(
                    t: (_clearTimer / _clearBannerDuration).clamp(0.0, 1.0),
                  ),
                ),
              ),
            ),
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
          if (!_loadingFade.isDismissed)
            Positioned.fill(
              child: RepaintBoundary(
                child: FadeTransition(
                  opacity: _loadingFade,
                  child: const LoadingCover(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BallsBadge extends StatelessWidget {
  const _BallsBadge({required this.value, required this.asset});

  final int value;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            asset,
            fit: BoxFit.contain,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Color(0xFFF8F8F8),
                    Color(0xFFF1F1F1),
                  ],
                  stops: [0.0, 0.4, 1.0],
                ).createShader(bounds);
              },
              child: Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: -.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClearBanner extends StatelessWidget {
  const _ClearBanner({required this.t});

  final double t;

  static const _style = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w900,
    fontStyle: FontStyle.italic,
    height: 1,
    letterSpacing: -1.2,
  );

  static const _depth = [
    Offset(1, 1),
    Offset(2, 2),
    Offset(0, 1),
    Offset(1, 0),
    Offset(1, 2),
    Offset(2, 1),
  ];

  @override
  Widget build(BuildContext context) {
    late final double opacity;
    late final double dy;

    if (t < 0.18) {
      final p = Curves.easeOutCubic.transform(t / 0.18);
      opacity = p;
      dy = ui.lerpDouble(48, 0, p)!;
    } else if (t < 0.38) {
      opacity = 1;
      dy = 0;
    } else if (t < 0.56) {
      final p = Curves.easeInCubic.transform((t - 0.38) / 0.18);
      opacity = 1 - p;
      dy = ui.lerpDouble(0, -48, p)!;
    } else {
      opacity = 0;
      dy = -48;
    }

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            for (final offset in _depth)
              Transform.translate(
                offset: offset,
                child: Text(
                  'GG!',
                  style: _style.copyWith(color: Colors.black),
                ),
              ),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.white,
                    Colors.white,
                  ],
                  stops: [0.0, 0.4, 1.0],
                ).createShader(bounds);
              },
              child: const Text(
                'GG!',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  height: 1,
                  letterSpacing: -1.2,
                  color: Colors.white,
                ),
              ),
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
    required this.platformXs,
    required this.platformTops,
    required this.platformHalfW,
    required this.platformNear,
    required this.platformFar,
    required this.platformThickness,
    required this.ballRadius,
    required this.floorImage,
    required this.floorTopColor,
    required this.floorBottomColor,
    required this.floorStyle,
    required this.hitSparks,
  });

  final List<
      ({
        _Vec3 pos,
        Quaternion rot,
        Color color,
        BlockShape shape,
        _Vec3 half,
      })> cubes;
  final List<_Vec3> balls;
  final List<double> platformXs;
  final List<double> platformTops;
  final double platformHalfW;
  final double platformNear;
  final double platformFar;
  final double platformThickness;
  final double ballRadius;
  final ui.Image? floorImage;
  final Color floorTopColor;
  final Color floorBottomColor;
  final FloorStyle floorStyle;
  final List<({_Vec3 pos, double t})> hitSparks;

  static const _camY = 3.4;
  static const _camZ = 0.0;
  static const _focal = 320.0;
  static const _horizon = 0.56;
  static const _coneSegments = 20;
  static const _glassAlpha = 0.5;
  static const _cubeEdgeAlpha = 0.35;
  static const _edgeWidth = 1.2;
  static const _edgeBlack = Color(0xFF000000);
  static const _edgeColorMix = 0.0;

  static Color _edgeColor(Color color) =>
      Color.lerp(_edgeBlack, color, _edgeColorMix)!
          .withValues(alpha: _cubeEdgeAlpha);

  static bool _isGlassCube(Color color) =>
      color.r == 0 && color.g == 0 && color.b == 0;

  static double _lightLift(Color base) {
    return base.computeLuminance() < 0.05 ? 0.25 : 1.0;
  }

  static List<Color> _shadeCube(Color base) {
    final lift = _lightLift(base);
    final shades = [
      Color.lerp(base, Colors.white, 0.08 * lift)!,
      Color.lerp(base, Colors.black, 0.22)!,
      Color.lerp(base, Colors.black, 0.34)!,
      Color.lerp(base, Colors.white, 0.32 * lift)!,
      Color.lerp(base, Colors.black, 0.14)!,
      Color.lerp(base, Colors.white, 0.06 * lift)!,
    ];
    if (!_isGlassCube(base)) return shades;
    final glass = Color.lerp(base, Colors.white, 0.1)!.withValues(alpha: _glassAlpha);
    return List.filled(6, glass);
  }

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
    if (pos.z < platformNear || pos.z > platformFar) return false;
    for (var i = 0; i < platformXs.length; i++) {
      if ((pos.x - platformXs[i]).abs() > platformHalfW) continue;
      final platformBottom = platformTops[i] - platformThickness;
      if (pos.y < platformBottom + 0.02) return true;
    }
    return false;
  }

  void _paintDepthLayer(
    Canvas canvas,
    Size size,
    List<
            ({
              _Vec3 pos,
              Quaternion rot,
              Color color,
              BlockShape shape,
              _Vec3 half,
            })>
        layerCubes,
    List<_Vec3> layerBalls,
  ) {
    final items = <
        ({
          double depth,
          Path? path,
          Color? color,
          _Vec3? ball,
          bool shiny,
          bool stroke,
        })>[];

    for (final cube in layerCubes) {
      final colors = _shadeCube(cube.color);
      if (cube.shape == BlockShape.triangle) {
        _collectPyramidFaces(
          items,
          size,
          center: cube.pos,
          half: cube.half,
          rot: cube.rot,
          colors: colors,
        );
      } else {
        _collectBoxFaces(
          items,
          size,
          center: cube.pos,
          half: cube.half,
          rot: cube.rot,
          colors: colors,
          shinyTop: !_isGlassCube(cube.color),
        );
      }
    }

    for (final ball in layerBalls) {
      items.add((
        depth: _camDist2(ball),
        path: null,
        color: null,
        ball: ball,
        shiny: false,
        stroke: false,
      ));
    }

    items.sort((a, b) => b.depth.compareTo(a.depth));

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _edgeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _edgeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final gloss = Paint()..style = PaintingStyle.fill;

    for (final item in items) {
      final ball = item.ball;
      if (ball != null) {
        _paintBall(canvas, size, ball);
        continue;
      }

      final path = item.path!;
      final color = item.color;
      final alpha = color?.a ?? 1.0;
      if (color != null) {
        final bounds = path.getBounds();
        final lift = _lightLift(color);
        fill.color = color.withValues(alpha: alpha);
        fill.shader = alpha >= 1
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(color, Colors.white, 0.18 * lift)!
                      .withValues(alpha: alpha),
                  color.withValues(alpha: alpha),
                  Color.lerp(color, Colors.black, 0.08)!
                      .withValues(alpha: alpha),
                ],
                stops: const [0.0, 0.55, 1.0],
              ).createShader(bounds)
            : null;
        canvas.drawPath(path, fill);
        fill.shader = null;

        if (alpha >= 1) {
          seam.color = color;
          canvas.drawPath(path, seam);
        }
        edge.color = _edgeColor(color);
        canvas.drawPath(path, edge);

        if (item.shiny && bounds.shortestSide > 4) {
          final r = bounds.shortestSide * 0.18;
          gloss.color = Colors.white.withValues(alpha: 0.2 * lift * alpha);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(
                bounds.left + bounds.width * 0.3,
                bounds.top + bounds.height * 0.28,
              ),
              width: r * 1.7,
              height: r,
            ),
            gloss,
          );
        }
      }
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

    final behindCubes = <
        ({
          _Vec3 pos,
          Quaternion rot,
          Color color,
          BlockShape shape,
          _Vec3 half,
        })>[];
    final frontCubes = <
        ({
          _Vec3 pos,
          Quaternion rot,
          Color color,
          BlockShape shape,
          _Vec3 half,
        })>[];
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
    _paintHitSparks(canvas, size);
  }

  void _paintHitSparks(Canvas canvas, Size size) {
    if (hitSparks.isEmpty) return;
    final ordered = [...hitSparks]
      ..sort((a, b) => _camDist2(b.pos).compareTo(_camDist2(a.pos)));

    for (final spark in ordered) {
      final t = spark.t;
      final p = _project(spark.pos, size);
      final expand = Curves.easeOutCubic.transform(t);
      final mark = ui.lerpDouble(0, 15, expand)!;
      final half = mark / 2;
      final stroke = ui.lerpDouble(1.5, 1.5, expand)!;
      final fade = (1.0 -
              Curves.easeInCubic.transform(
                (t - 0.62).clamp(0.0, 1.0) / 0.38,
              ))
          .clamp(0.0, 1.0);
      final holeT = Curves.easeInCubic.transform(t);
      final holeR = mark * 1.5 * holeT;

      final bounds = Rect.fromCenter(
        center: p,
        width: mark + stroke * 4,
        height: mark + stroke * 4,
      );
      canvas.saveLayer(bounds, Paint());

      void drawX(Color color, double width) {
        final paint = Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true;
        canvas.drawLine(
          p + Offset(-half, -half),
          p + Offset(half, half),
          paint,
        );
        canvas.drawLine(
          p + Offset(half, -half),
          p + Offset(-half, half),
          paint,
        );
      }

      drawX(
        const Color(0xFF000000).withValues(alpha: 0.32 * fade),
        stroke + 1.3,
      );
      drawX(Colors.white.withValues(alpha: fade), stroke);

      if (holeR > 0.4) {
        canvas.drawCircle(
          p,
          holeR,
          Paint()
            ..blendMode = BlendMode.dstOut
            ..shader = RadialGradient(
              colors: const [
                Color(0xFFFFFFFF),
                Color(0xCCFFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: const [0.0, 0.42, 1.0],
            ).createShader(Rect.fromCircle(center: p, radius: holeR)),
        );
      }

      canvas.restore();
    }
  }

  void _paintGlassPlatform(Canvas canvas, Size size) {
    final cz = (platformNear + platformFar) / 2;
    final hy = platformThickness / 2;
    final hz = (platformFar - platformNear) / 2;
    final rot = Quaternion.identity();
    const glass = Color(0xFF000000);
    final slabs = <
        ({
          _Vec3 pos,
          Quaternion rot,
          Color color,
          BlockShape shape,
          _Vec3 half,
        })>[
      for (var i = 0; i < platformXs.length; i++)
        (
          pos: _Vec3(platformXs[i], platformTops[i] - hy, cz),
          rot: rot,
          color: glass,
          shape: BlockShape.box,
          half: _Vec3(platformHalfW, hy, hz),
        ),
    ];

    _paintDepthLayer(canvas, size, slabs, const []);
  }

  void _paintPlatform(Canvas canvas, Size size) {
    if (floorStyle == FloorStyle.glass) {
      _paintGlassPlatform(canvas, size);
      return;
    }

    final cz = (platformNear + platformFar) / 2;
    final hx = platformHalfW;
    final hz = (platformFar - platformNear) / 2;
    final hy = platformThickness / 2;
    final topColor = floorTopColor;
    final bottomColor = floorBottomColor;
    final sideFallback = [
      Color.lerp(topColor, bottomColor, 0.25)!,
      Color.lerp(topColor, Colors.black, 0.22)!,
      bottomColor,
      topColor,
      bottomColor,
      Color.lerp(topColor, Colors.black, 0.22)!,
    ];

    for (var i = 0; i < platformXs.length; i++) {
      final center = _Vec3(platformXs[i], platformTops[i] - hy, cz);
      final half = _Vec3(hx, hy, hz);
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
      final vertices = [for (final local in locals) center + local];
      final projected = [for (final v in vertices) _project(v, size)];

      const faces = [
        [0, 3, 2, 1],
        [4, 5, 6, 7],
        [0, 1, 5, 4],
        [3, 7, 6, 2],
        [0, 4, 7, 3],
        [1, 2, 6, 5],
      ];
      final faceSpanU = [
        half.x * 2,
        half.x * 2,
        0.0,
        0.0,
        half.z * 2,
        half.z * 2,
      ];

      final items = <({double depth, int index, Path path})>[];
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

        items.add((
          depth: _camDist2(faceCenter),
          index: index,
          path: path,
        ));
      }

      items.sort((a, b) => b.depth.compareTo(a.depth));

      final fill = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _edgeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      final cubeSize = platformThickness;
      final image = floorImage;

      for (final item in items) {
        final index = item.index;
        final face = faces[index];
        final pts = [
          projected[face[0]],
          projected[face[1]],
          projected[face[2]],
          projected[face[3]],
        ];

        final isSide = index == 0 || index == 1 || index == 4 || index == 5;
        if (isSide && image != null) {
          final tilesU = faceSpanU[index] / cubeSize;
          final uv = switch (index) {
            0 || 5 => const [
                Offset(0, 1),
                Offset(0, 0),
                Offset(1, 0),
                Offset(1, 1),
              ],
            _ => const [
                Offset(0, 1),
                Offset(1, 1),
                Offset(1, 0),
                Offset(0, 0),
              ],
          };
          _paintTexturedQuad(
            canvas,
            pts,
            image,
            tilesU: tilesU,
            tilesV: 1,
            uv: uv,
          );
        } else {
          fill.color = switch (index) {
            3 => topColor,
            2 => bottomColor,
            _ => sideFallback[index],
          };
          canvas.drawPath(item.path, fill);
        }
        final faceColor = switch (index) {
          3 => topColor,
          2 => bottomColor,
          _ => sideFallback[index],
        };
        stroke.color = _edgeColor(faceColor);
        canvas.drawPath(item.path, stroke);
      }
    }
  }

  void _paintTexturedQuad(
    Canvas canvas,
    List<Offset> pts,
    ui.Image image, {
    required double tilesU,
    required double tilesV,
    required List<Offset> uv,
  }) {
    final w = image.width.toDouble();
    final h = image.height.toDouble();
    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none
      ..shader = ImageShader(
        image,
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.identity().storage,
      );

    Offset tex(Offset u) => Offset(u.dx * tilesU * w, u.dy * tilesV * h);

    final vertices = ui.Vertices(
      ui.VertexMode.triangles,
      [pts[0], pts[1], pts[2], pts[0], pts[2], pts[3]],
      textureCoordinates: [
        tex(uv[0]),
        tex(uv[1]),
        tex(uv[2]),
        tex(uv[0]),
        tex(uv[2]),
        tex(uv[3]),
      ],
    );
    canvas.drawVertices(vertices, BlendMode.srcOver, paint);
  }

  void _collectBoxFaces(
    List<
            ({
              double depth,
              Path? path,
              Color? color,
              _Vec3? ball,
              bool shiny,
              bool stroke,
            })>
        out,
    Size size, {
    required _Vec3 center,
    required _Vec3 half,
    required Quaternion rot,
    required List<Color> colors,
    bool shinyTop = false,
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
        shiny: shinyTop && index == 3,
        stroke: false,
      ));
    }
  }

  void _collectPyramidFaces(
    List<
            ({
              double depth,
              Path? path,
              Color? color,
              _Vec3? ball,
              bool shiny,
              bool stroke,
            })>
        out,
    Size size, {
    required _Vec3 center,
    required _Vec3 half,
    required Quaternion rot,
    required List<Color> colors,
  }) {
    final radius = half.x;
    final hy = half.y;
    final n = _coneSegments;

    final apexLocal = _Vec3(0, hy, 0);
    final baseLocals = <_Vec3>[
      for (var i = 0; i < n; i++)
        _Vec3(
          -radius * math.sin(i * 2 * math.pi / n),
          -hy,
          radius * math.cos(i * 2 * math.pi / n),
        ),
    ];

    final apex = center + _rotate(apexLocal, rot);
    final base = [
      for (final local in baseLocals) center + _rotate(local, rot),
    ];
    final apexP = _project(apex, size);
    final baseP = [for (final v in base) _project(v, size)];

    var bx = 0.0, by = 0.0, bz = 0.0;
    for (final v in base) {
      bx += v.x;
      by += v.y;
      bz += v.z;
    }
    final baseCenter = _Vec3(bx / n, by / n, bz / n);
    final depth = (_camDist2(apex) + _camDist2(baseCenter)) * 0.5;

    final hull = _convexHull([apexP, ...baseP]);
    if (hull.length < 3) return;
    final body = Path()..moveTo(hull[0].dx, hull[0].dy);
    for (var i = 1; i < hull.length; i++) {
      body.lineTo(hull[i].dx, hull[i].dy);
    }
    body.close();

    out.add((
      depth: depth + 0.001,
      path: body,
      color: colors[3],
      ball: null,
      shiny: false,
      stroke: false,
    ));

    final baseNormal = _rotate(const _Vec3(0, -1, 0), rot);
    final toCamBase = _Vec3(
      -baseCenter.x,
      _camY - baseCenter.y,
      _camZ - baseCenter.z,
    );
    if (baseNormal.dot(toCamBase) > 0) {
      final ellipse = Path()..moveTo(baseP[0].dx, baseP[0].dy);
      for (var k = 1; k < n; k++) {
        ellipse.lineTo(baseP[k].dx, baseP[k].dy);
      }
      ellipse.close();
      out.add((
        depth: _camDist2(baseCenter),
        path: ellipse,
        color: colors[2],
        ball: null,
        shiny: false,
        stroke: false,
      ));
    }
  }

  static List<Offset> _convexHull(List<Offset> points) {
    if (points.length <= 2) return List.of(points);
    final pts = [...points]..sort((a, b) {
        final dx = a.dx.compareTo(b.dx);
        return dx != 0 ? dx : a.dy.compareTo(b.dy);
      });

    double cross(Offset o, Offset a, Offset b) =>
        (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);

    final lower = <Offset>[];
    for (final p in pts) {
      while (lower.length >= 2 &&
          cross(lower[lower.length - 2], lower[lower.length - 1], p) <= 0) {
        lower.removeLast();
      }
      lower.add(p);
    }

    final upper = <Offset>[];
    for (final p in pts.reversed) {
      while (upper.length >= 2 &&
          cross(upper[upper.length - 2], upper[upper.length - 1], p) <= 0) {
        upper.removeLast();
      }
      upper.add(p);
    }

    lower.removeLast();
    upper.removeLast();
    return [...lower, ...upper];
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
