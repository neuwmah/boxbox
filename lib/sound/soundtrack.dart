import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class Soundtrack extends ChangeNotifier {
  Soundtrack._();

  static final instance = Soundtrack._();

  static const homeAsset = 'lib/assets/sound/background1.mp3';
  static const gameAsset = 'lib/assets/sound/background2.mp3';
  static const volume = 0.05;

  final SoLoud _soloud = SoLoud.instance;
  AudioSource? _gameSource;
  SoundHandle? _homeHandle;
  SoundHandle? _gameHandle;
  bool enabled = true;
  bool _started = false;
  bool _foreground = true;
  bool _gameActive = false;
  int _gameGen = 0;
  int _gameSession = 0;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final device = _pickDevice(_soloud.listPlaybackDevices());
      await _soloud.init(device: device, bufferSize: 512);
      if (kDebugMode) {
        debugPrint('Soundtrack device: ${device?.name ?? 'default'}');
      }
      final source = await _soloud.loadAsset(homeAsset);
      _homeHandle = await _soloud.play(
        source,
        volume: _homePlaying ? volume : 0,
        looping: true,
        paused: !_homePlaying,
      );
    } catch (error, stack) {
      _started = false;
      debugPrint('Soundtrack start failed: $error');
      debugPrint('$stack');
    }
  }

  Future<void> preloadGame() async {
    if (!_started || _gameSource != null) return;
    try {
      _gameSource = await _soloud.loadAsset(gameAsset);
    } catch (error) {
      debugPrint('Soundtrack game preload failed: $error');
    }
  }

  PlaybackDevice? _pickDevice(List<PlaybackDevice> devices) {
    PlaybackDevice? pulse;
    PlaybackDevice? fallback;
    for (final device in devices) {
      if (!_usable(device)) continue;
      fallback ??= device;
      if (device.isDefault) fallback = device;
      if (device.name.toLowerCase().contains('pulse')) {
        pulse = device;
      }
    }
    return pulse ?? fallback;
  }

  bool _usable(PlaybackDevice device) {
    final name = device.name.toLowerCase();
    if (name.contains('discard')) return false;
    if (name.contains('rate converter')) return false;
    if (name.contains('upmix')) return false;
    if (name.contains('downmix')) return false;
    if (name.contains('speex')) return false;
    return true;
  }

  bool get _homePlaying => enabled && _foreground;
  bool get _gamePlaying => enabled && _gameActive;

  int claimGame() {
    final session = ++_gameSession;
    _foreground = false;
    _gameActive = false;
    _gameGen++;
    _stopGame();
    _apply();
    return session;
  }

  Future<void> playGame(int session) async {
    if (session != _gameSession) return;
    _gameActive = true;
    final gen = _gameGen;
    await _playGame();
    if (gen != _gameGen || session != _gameSession || !_gameActive) {
      _stopGame();
    }
  }

  void releaseGame(int session, {bool restoreHome = true}) {
    if (session != _gameSession) return;
    _gameActive = false;
    _gameGen++;
    _stopGame();
    if (restoreHome) {
      _foreground = true;
      _apply(restartHome: true);
    } else {
      _apply();
    }
  }

  void setForeground(bool value) {
    if (_foreground == value) return;
    _foreground = value;
    _apply(restartHome: value);
  }

  Future<void> setGameActive(bool value) async {
    if (_gameActive == value) return;
    _gameActive = value;
    if (!value) {
      _gameGen++;
      _stopGame();
      return;
    }
    final gen = _gameGen;
    await _playGame();
    if (gen != _gameGen || !_gameActive) {
      _stopGame();
    }
  }

  Future<void> _playGame() async {
    if (!_started) return;
    try {
      _gameSource ??= await _soloud.loadAsset(gameAsset);
      final source = _gameSource;
      if (source == null) return;
      _stopGame();
      _gameHandle = await _soloud.play(
        source,
        volume: _gamePlaying ? volume : 0,
        looping: true,
        paused: !_gamePlaying,
      );
    } catch (error) {
      debugPrint('Soundtrack game play failed: $error');
    }
  }

  void _stopGame() {
    final handle = _gameHandle;
    _gameHandle = null;
    if (handle == null) return;
    try {
      _soloud.stop(handle);
    } catch (_) {}
  }

  Future<void> toggle() async {
    enabled = !enabled;
    notifyListeners();
    if (!_started) {
      await start();
      return;
    }
    _apply();
  }

  void _apply({bool restartHome = false}) {
    final home = _homeHandle;
    if (home != null) {
      try {
        if (_homePlaying) {
          if (restartHome) {
            _soloud.seek(home, Duration.zero);
          }
          _soloud.setVolume(home, volume);
          _soloud.setPause(home, false);
        } else {
          _soloud.setVolume(home, 0);
          _soloud.setPause(home, true);
        }
      } catch (_) {}
    }

    final game = _gameHandle;
    if (game == null) return;
    try {
      if (_gamePlaying) {
        _soloud.setVolume(game, volume);
        _soloud.setPause(game, false);
      } else {
        _soloud.setVolume(game, 0);
        _soloud.setPause(game, true);
      }
    } catch (_) {}
  }
}
