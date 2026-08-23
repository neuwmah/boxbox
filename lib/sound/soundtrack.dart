import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class Soundtrack extends ChangeNotifier {
  Soundtrack._();

  static final instance = Soundtrack._();

  static const asset = 'lib/assets/sound/background1.mp3';
  static const volume = 0.05;

  final SoLoud _soloud = SoLoud.instance;
  SoundHandle? _handle;
  bool enabled = true;
  bool _started = false;
  bool _foreground = true;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final device = _pickDevice(_soloud.listPlaybackDevices());
      await _soloud.init(device: device);
      if (kDebugMode) {
        debugPrint('Soundtrack device: ${device?.name ?? 'default'}');
      }
      final source = await _soloud.loadAsset(asset);
      _handle = await _soloud.play(
        source,
        volume: _playing ? volume : 0,
        looping: true,
        paused: !_playing,
      );
    } catch (error, stack) {
      _started = false;
      debugPrint('Soundtrack start failed: $error');
      debugPrint('$stack');
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

  bool get _playing => enabled && _foreground;

  void setForeground(bool value) {
    if (_foreground == value) return;
    _foreground = value;
    _apply();
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

  void _apply() {
    final handle = _handle;
    if (handle == null) return;
    try {
      _soloud.setVolume(handle, _playing ? volume : 0);
      _soloud.setPause(handle, !_playing);
    } catch (_) {}
  }
}
