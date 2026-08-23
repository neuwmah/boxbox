import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class Sfx extends ChangeNotifier {
  Sfx._();

  static final instance = Sfx._();

  static const touchAsset = 'lib/assets/sound/touch.mp3';
  static const hitAsset = 'lib/assets/sound/hit.mp3';
  static const volume = 0.7;
  static const hitVolume = 0.85;

  final SoLoud _soloud = SoLoud.instance;
  AudioSource? _touch;
  AudioSource? _hit;
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
    } catch (error) {
      debugPrint('Sfx preload failed: $error');
    }
  }

  Future<void> playTouch() async {
    if (!enabled) return;
    if (!_soloud.isInitialized) return;
    try {
      _touch ??= await _soloud.loadAsset(touchAsset, mode: LoadMode.memory);
      await _soloud.play(_touch!, volume: volume);
    } catch (_) {}
  }

  void playHit() {
    if (!enabled || !_soloud.isInitialized) return;
    final hit = _hit;
    if (hit == null) {
      preload();
      return;
    }
    try {
      _soloud.play(hit, volume: hitVolume);
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
