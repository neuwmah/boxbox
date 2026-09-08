import 'dart:async';
import 'dart:math';

import 'package:boxbox/game/level.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'auth_service.dart';
import 'player_state.dart';

/// Offline-first persistence + sync with API (last-write-wins via `updatedAt`).
class SaveManager with WidgetsBindingObserver {
  SaveManager._();

  static final instance = SaveManager._();

  static const maxHearts = 5;
  static const heartRegen = Duration(minutes: 20);
  static const initialCoins = 500;
  static const initialLevel = 1;
  static const _syncEvery = Duration(seconds: 30);
  static const _debounce = Duration(seconds: 2);

  static const _kUid = 'auth_uid';
  static const _kPlayerId = 'player_id';
  static const _kLevel = 'current_level';
  static const _kCoins = 'coins';
  static const _kHearts = 'hearts';
  static const _kNoAds = 'no_ads';
  static const _kUpdatedAt = 'updated_at';
  static const _kDirty = 'save_dirty';
  static const _kNextHeartAt = 'next_heart_at'; // only local, not sent to API

  final ValueNotifier<int> level = ValueNotifier(initialLevel);
  final ValueNotifier<int> coins = ValueNotifier(initialCoins);
  final ValueNotifier<int> hearts = ValueNotifier(maxHearts);
  final ValueNotifier<bool> noAds = ValueNotifier(false);

  final ApiClient _api = ApiClient();

  SharedPreferences? _prefs;
  String _playerId = '';
  int _updatedAt = 0;
  bool _dirty = false;
  bool _ready = false;
  bool _observing = false;
  bool _syncing = false;
  bool _syncAgain = false;
  DateTime? _nextHeartAt;
  Timer? _debounceTimer;

  String get playerId => _playerId;
  DateTime? get nextHeartAt => _nextHeartAt;
  bool get isReady => _ready;

  int getLevel() => level.value;
  int getCoins() => coins.value;
  int getHearts() => hearts.value;
  bool hasNoAds() => noAds.value;

  PlayerState get _state => PlayerState(
        playerId: _playerId,
        currentLevel: level.value,
        coins: coins.value,
        hearts: hearts.value,
        noAds: noAds.value,
        updatedAt: _updatedAt,
      );

  String get _cachePrefix => AuthService.instance.uid ?? 'local';

  String _key(String name) => '${_cachePrefix}_$name';

  /// Loads the cache and triggers GET /me in background.
  Future<void> init() async {
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    _prefs = await SharedPreferences.getInstance();
    _loadCache();
    _catchUpHearts();
    if (!_ready) {
      _ready = true;
      Timer.periodic(_syncEvery, (_) => unawaited(_sync()));
    }
    debugPrint('SaveManager player_id=$_playerId updatedAt=$_updatedAt');
    unawaited(_sync());
  }

  /// After Google/Apple login: keep local progress and start cloud sync.
  Future<void> rebindAccount() async {
    if (_prefs == null) {
      await init();
      return;
    }
    await _prefs!.setString(_kUid, _cachePrefix);
    _dirty = true;
    _touchUpdatedAt();
    await _writeCache();
    unawaited(_sync());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_sync());
      return;
    }
    unawaited(forceSync());
  }

  /// Advances the current level (write-through + sync).
  void setLevel(int value) {
    final next = clampLevel(value);
    if (next == level.value) return;
    level.value = next;
    _markDirty();
  }

  /// Adds coins (use [spendCoins] to spend).
  void addCoins(int amount) {
    if (amount == 0) return;
    coins.value = max(0, coins.value + amount);
    _markDirty();
  }

  bool spendCoins(int amount) {
    if (amount <= 0 || coins.value < amount) return false;
    coins.value -= amount;
    _markDirty();
    return true;
  }

  /// Consumes 1 heart and triggers regeneration if there is no timer.
  bool useHeart() {
    if (hearts.value <= 0) return false;
    hearts.value -= 1;
    _nextHeartAt ??= DateTime.now().add(heartRegen);
    _markDirty();
    return true;
  }

  void addHeart() {
    if (hearts.value >= maxHearts) return;
    hearts.value += 1;
    if (hearts.value >= maxHearts) {
      _nextHeartAt = null;
    } else {
      _nextHeartAt ??= DateTime.now().add(heartRegen);
    }
    _markDirty();
  }

  void refillHearts() {
    if (hearts.value == maxHearts && _nextHeartAt == null) return;
    hearts.value = maxHearts;
    _nextHeartAt = null;
    _markDirty();
  }

  /// Turns on/off no_ads in cache and schedules sync.
  void setNoAds(bool value) {
    if (noAds.value == value) return;
    noAds.value = value;
    _markDirty();
  }

  /// Regenerates hearts with time (also when opening the app).
  void tickHearts() {
    if (hearts.value >= maxHearts) {
      if (_nextHeartAt != null) {
        _nextHeartAt = null;
        unawaited(_writeCache());
      }
      return;
    }
    if (_nextHeartAt == null) return;
    if (DateTime.now().isBefore(_nextHeartAt!)) return;

    var gained = 0;
    while (hearts.value < maxHearts &&
        _nextHeartAt != null &&
        !DateTime.now().isBefore(_nextHeartAt!)) {
      hearts.value += 1;
      gained++;
      if (hearts.value >= maxHearts) {
        _nextHeartAt = null;
      } else {
        _nextHeartAt = _nextHeartAt!.add(heartRegen);
      }
    }
    if (gained > 0) _markDirty();
  }

  /// Sends PUT immediately (pause, close, or explicit call).
  Future<void> forceSync() async {
    _debounceTimer?.cancel();
    await _sync();
  }

  void _loadCache() {
    final prefs = _prefs!;
    final uid = _cachePrefix;
    final storedUid = prefs.getString(_kUid);
    if (storedUid != uid) {
      _playerId = '';
      level.value = initialLevel;
      coins.value = initialCoins;
      hearts.value = maxHearts;
      noAds.value = false;
      _updatedAt = 0;
      _dirty = false;
      _nextHeartAt = null;
      unawaited(prefs.setString(_kUid, uid));
      return;
    }
    _playerId = prefs.getString(_key(_kPlayerId)) ?? '';
    level.value = prefs.getInt(_key(_kLevel)) ?? initialLevel;
    coins.value = prefs.getInt(_key(_kCoins)) ?? initialCoins;
    hearts.value = prefs.getInt(_key(_kHearts)) ?? maxHearts;
    noAds.value = prefs.getBool(_key(_kNoAds)) ?? false;
    _updatedAt = prefs.getInt(_key(_kUpdatedAt)) ?? 0;
    _dirty = prefs.getBool(_key(_kDirty)) ?? false;
    final nextMs = prefs.getInt(_key(_kNextHeartAt));
    _nextHeartAt =
        nextMs == null || nextMs <= 0
            ? null
            : DateTime.fromMillisecondsSinceEpoch(nextMs);
  }

  void _catchUpHearts() {
    final before = hearts.value;
    tickHearts();
    if (hearts.value == before && hearts.value < maxHearts && _nextHeartAt == null) {
      _nextHeartAt = DateTime.now().add(heartRegen);
      unawaited(_writeCache());
    }
  }

  void _markDirty() {
    _touchUpdatedAt();
    _dirty = true;
    unawaited(_writeCache());
    _scheduleSync();
  }

  void _touchUpdatedAt() {
    final now = _now();
    _updatedAt = now > _updatedAt ? now : _updatedAt + 1;
  }

  int _now() => DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

  void _scheduleSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () => unawaited(_sync()));
  }

  Future<void> _writeCache() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(_kUid, _cachePrefix);
    await prefs.setString(_key(_kPlayerId), _playerId);
    await prefs.setInt(_key(_kLevel), level.value);
    await prefs.setInt(_key(_kCoins), coins.value);
    await prefs.setInt(_key(_kHearts), hearts.value);
    await prefs.setBool(_key(_kNoAds), noAds.value);
    await prefs.setInt(_key(_kUpdatedAt), _updatedAt);
    await prefs.setBool(_key(_kDirty), _dirty);
    await prefs.setInt(
      _key(_kNextHeartAt),
      _nextHeartAt?.millisecondsSinceEpoch ?? 0,
    );
  }

  Future<void> _sync() async {
    if (!_ready) return;
    if (AuthService.required && !AuthService.instance.isSignedIn) return;
    if (_syncing) {
      _syncAgain = true;
      return;
    }
    _syncing = true;
    try {
      await _syncOnce();
    } catch (error, stack) {
      debugPrint('Sync falhou: $error');
      debugPrint('$stack');
    } finally {
      _syncing = false;
      if (_syncAgain) {
        _syncAgain = false;
        unawaited(_sync());
      }
    }
  }

  Future<void> _syncOnce() async {
    final remote = await _api.getMe();

    if (remote.unauthorized) return;

    if (remote.ok && remote.state != null) {
      if (_playerId.isEmpty) {
        _playerId = remote.state!.playerId;
        await _writeCache();
      }
      await _reconcile(remote.state!);
      return;
    }

    if (remote.notFound) {
      final created = await _api.createPlayer(_state);
      if (created.ok && created.state != null) {
        _playerId = created.state!.playerId;
        _dirty = false;
        await _writeCache();
        return;
      }
      if (created.isConflict && created.conflict != null) {
        await _reconcile(created.conflict!);
      }
      return;
    }

    if (_dirty) {
      await _push();
    }
  }

  Future<void> _reconcile(PlayerState remote) async {
    if (remote.updatedAt > _updatedAt) {
      _applyRemote(remote);
      return;
    }
    if (_updatedAt > remote.updatedAt) {
      await _push();
      return;
    }
    _dirty = false;
    await _writeCache();
  }

  void _applyRemote(PlayerState remote) {
    if (remote.playerId.isNotEmpty) _playerId = remote.playerId;
    level.value = clampLevel(remote.currentLevel);
    coins.value = max(0, remote.coins);
    hearts.value = remote.hearts.clamp(0, maxHearts);
    noAds.value = remote.noAds;
    _updatedAt = remote.updatedAt;
    _dirty = false;
    if (hearts.value >= maxHearts) {
      _nextHeartAt = null;
    } else {
      _nextHeartAt ??= DateTime.now().add(heartRegen);
    }
    unawaited(_writeCache());
  }

  Future<void> _push() async {
    var result = await _api.putMe(_state);
    if (result.unauthorized) return;
    if (result.notFound) {
      result = await _api.createPlayer(_state);
    }
    if (result.ok) {
      _dirty = false;
      await _writeCache();
      return;
    }
    if (result.isConflict && result.conflict != null) {
      _applyRemote(result.conflict!);
    }
  }
}
