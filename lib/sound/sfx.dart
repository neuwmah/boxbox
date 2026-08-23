import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class Sfx extends ChangeNotifier {
  Sfx._();

  static final instance = Sfx._();

  static const touchAsset = 'lib/assets/sound/touch.mp3';
  static const hitAsset = 'lib/assets/sound/hit.mp3';
  static const fallAsset = 'lib/assets/sound/fall.mp3';
  static const volume = 0.7;
  static const hitVolume = 0.85;
  static const fallVolume = 0.85;

  final SoLoud _soloud = SoLoud.instance;
  AudioSource? _touch;
  AudioSource? _hit;
  AudioSource? _fall;
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
    } catch (error) {
      debugPrint('Sfx preload failed: $error');
    }
  }

  void playTouch() => _play(_touch, volume);

  void playHit() => _play(_hit, hitVolume);

  void playFall() => _play(_fall, fallVolume);

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
