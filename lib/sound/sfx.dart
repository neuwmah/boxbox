import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class Sfx extends ChangeNotifier {
  Sfx._();

  static final instance = Sfx._();

  static const touchAsset = 'lib/assets/sound/touch.mp3';
  static const volume = 0.7;

  final SoLoud _soloud = SoLoud.instance;
  AudioSource? _touch;
  bool enabled = true;

  Future<void> preload() async {
    if (!_soloud.isInitialized || _touch != null) return;
    try {
      _touch = await _soloud.loadAsset(touchAsset);
    } catch (error) {
      debugPrint('Sfx preload failed: $error');
    }
  }

  Future<void> playTouch() async {
    if (!enabled) return;
    if (!_soloud.isInitialized) return;
    try {
      _touch ??= await _soloud.loadAsset(touchAsset);
      await _soloud.play(_touch!, volume: volume);
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
