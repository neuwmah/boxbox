import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class Sfx extends ChangeNotifier {
  Sfx._();

  static final instance = Sfx._();

  static const touchAsset = 'lib/assets/sound/touch.mp3';
  static const hitAsset = 'lib/assets/sound/hit.mp3';
  static const fallAsset = 'lib/assets/sound/fall.mp3';
  static const failAsset = 'lib/assets/sound/fail.mp3';
  static const shotAsset = 'lib/assets/sound/shot.mp3';
  static const ggAsset = 'lib/assets/sound/gg.mp3';
  static const coinFinishAsset = 'lib/assets/sound/coin_finish.mp3';
  static const coinRepeatAsset = 'lib/assets/sound/coin_repeat.mp3';
  static const volume = 0.7;
  static const hitVolume = 0.85;
  static const fallVolume = 0.85;
  static const failVolume = 0.85;
  static const shotVolume = 0.85;
  static const ggVolume = 0.85;
  static const coinVolume = 0.85;

  final SoLoud _soloud = SoLoud.instance;
  AudioSource? _touch;
  AudioSource? _hit;
  AudioSource? _fall;
  AudioSource? _fail;
  AudioSource? _shot;
  AudioSource? _gg;
  AudioSource? _coinFinish;
  AudioSource? _coinRepeat;
  SoundHandle? _coinRepeatHandle;
  int _coinRepeatGen = 0;
  bool enabled = true;

  Future<void> preload() async {
    if (!_soloud.isInitialized) return;
    try {
      _touch ??= await _soloud.loadAsset(
        touchAsset,
        mode: LoadMode.memory,
      );
      _hit ??= await _soloud.loadAsset(
        hitAsset,
        mode: LoadMode.memory,
      );
      _fall ??= await _soloud.loadAsset(
        fallAsset,
        mode: LoadMode.memory,
      );
      _fail ??= await _soloud.loadAsset(
        failAsset,
        mode: LoadMode.memory,
      );
      _shot ??= await _soloud.loadAsset(
        shotAsset,
        mode: LoadMode.memory,
      );
      _gg ??= await _soloud.loadAsset(
        ggAsset,
        mode: LoadMode.memory,
      );
      _coinFinish ??= await _soloud.loadAsset(
        coinFinishAsset,
        mode: LoadMode.memory,
      );
      _coinRepeat ??= await _soloud.loadAsset(
        coinRepeatAsset,
        mode: LoadMode.memory,
      );
    } catch (error) {
      debugPrint('Sfx preload failed: $error');
    }
  }

  void invalidate() {
    _coinRepeatGen++;
    _coinRepeatHandle = null;
    _touch = null;
    _hit = null;
    _fall = null;
    _fail = null;
    _shot = null;
    _gg = null;
    _coinFinish = null;
    _coinRepeat = null;
  }

  void playTouch() => _play(_touch, volume);

  void playHit() => _play(_hit, hitVolume);

  void playFall() => _play(_fall, fallVolume);

  void playFail() => _play(_fail, failVolume);

  void playShot() => _play(_shot, shotVolume);

  void playGg() => _play(_gg, ggVolume);

  void playCoinFinish() => _play(_coinFinish, coinVolume);

  void startCoinRepeat() {
    final gen = ++_coinRepeatGen;
    _stopCoinRepeatHandle();
    if (!enabled || !_soloud.isInitialized) return;
    unawaited(_coinRepeatLoop(gen));
  }

  void stopCoinRepeat() {
    _coinRepeatGen++;
    _stopCoinRepeatHandle();
  }

  Future<void> _coinRepeatLoop(int gen) async {
    var source = _coinRepeat;
    if (source == null) {
      await preload();
      source = _coinRepeat;
    }
    if (source == null || gen != _coinRepeatGen || !enabled) return;
    var wait = _soloud.getLength(source);
    if (wait.inMilliseconds < 40) {
      wait = const Duration(milliseconds: 80);
    }
    while (gen == _coinRepeatGen && enabled && _soloud.isInitialized) {
      try {
        final handle = await _soloud.play(source, volume: coinVolume);
        if (gen != _coinRepeatGen) {
          try {
            _soloud.stop(handle);
          } catch (_) {}
          return;
        }
        _coinRepeatHandle = handle;
      } catch (_) {
        return;
      }
      await Future<void>.delayed(wait);
    }
  }

  void _stopCoinRepeatHandle() {
    final handle = _coinRepeatHandle;
    _coinRepeatHandle = null;
    if (handle == null) return;
    try {
      _soloud.stop(handle);
    } catch (_) {}
  }

  void _play(AudioSource? source, double gain) {
    if (!enabled || !_soloud.isInitialized) return;
    if (source == null) {
      preload();
      return;
    }
    try {
      _soloud.play(source, volume: gain);
    } catch (_) {}
  }

  void tap([VoidCallback? action]) {
    playTouch();
    action?.call();
  }

  void toggle() {
    enabled = !enabled;
    notifyListeners();
  }
}
