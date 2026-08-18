import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:boxbox/game/level.dart';
import 'package:boxbox/pages/game.dart';
import 'package:boxbox/pages/home.dart';
import 'package:boxbox/pages/settings.dart';
import 'package:boxbox/pages/shop.dart';
import 'package:boxbox/widgets/morelives.dart';
import 'package:boxbox/widgets/noads.dart';
import 'package:boxbox/widgets/reward.dart';
import 'package:boxbox/widgets/navbar.dart';
import 'package:boxbox/widgets/retry.dart';
import 'package:boxbox/widgets/start.dart';
import 'package:boxbox/widgets/status.dart';
import 'package:boxbox/widgets/titlebar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(300, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainShell(),
    );
  }
}

enum _HomePopup { none, start, retry, moreLives, noAds }

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _maxHearts = 5;
  static const _maxLevel = 500;
  static const _heartRegen = Duration(minutes: 20);
  static const _refillPrice = 900;
  static const _noAdsPriceLabel = 'BRL 59.90';

  int _selectedIndex = 1;
  int _level = 1;
  int _coins = 500;
  int _displayedCoins = 500;
  int _hearts = _maxHearts;
  DateTime? _nextHeartAt;
  int? _pendingReward;
  _HomePopup _homePopup = _HomePopup.none;
  final GlobalKey _coinIconKey = GlobalKey();
  Timer? _heartTimer;
  int _playGen = 0;
  int _debugLevelOffset = 0;
  bool _loadingPrecached = false;

  @override
  void initState() {
    super.initState();
    _heartTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _tickHearts();
    });
    if (kDebugMode) {
      HardwareKeyboard.instance.addHandler(_onDebugKey);
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      HardwareKeyboard.instance.removeHandler(_onDebugKey);
    }
    _heartTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadingPrecached) return;
    _loadingPrecached = true;
    precacheImage(const AssetImage(loadingAsset), context);
  }

  bool _onDebugKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey == LogicalKeyboardKey.space) {
      _debugGoHome();
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.quote ||
        event.logicalKey == LogicalKeyboardKey.backquote) {
      final next = _debugLevelOffset + 10;
      _debugLevelOffset = next >= levels.length ? 0 : next;
      return true;
    }
    final level = switch (event.logicalKey) {
      LogicalKeyboardKey.digit1 => 1,
      LogicalKeyboardKey.digit2 => 2,
      LogicalKeyboardKey.digit3 => 3,
      LogicalKeyboardKey.digit4 => 4,
      LogicalKeyboardKey.digit5 => 5,
      LogicalKeyboardKey.digit6 => 6,
      LogicalKeyboardKey.digit7 => 7,
      LogicalKeyboardKey.digit8 => 8,
      LogicalKeyboardKey.digit9 => 9,
      LogicalKeyboardKey.digit0 => 10,
      _ => null,
    };
    if (level == null) return false;
    _debugStartLevel(_debugLevelOffset + level);
    return true;
  }

  void _debugGoHome() {
    setState(() {
      _selectedIndex = 1;
      _homePopup = _HomePopup.none;
      _pendingReward = null;
    });
    if (Navigator.of(context).canPop()) {
      _playGen++;
      Navigator.of(context).pop();
    }
  }

  Future<void> _debugStartLevel(int level) async {
    setState(() {
      _level = level;
      _homePopup = _HomePopup.none;
      _pendingReward = null;
    });
    if (Navigator.of(context).canPop()) {
      _playGen++;
      Navigator.of(context).pop();
      await Future<void>.delayed(Duration.zero);
    }
    if (!mounted) return;
    await _playLevel(debug: true);
  }

  String get _heartTimerLabel {
    if (_hearts >= _maxHearts || _nextHeartAt == null) return 'FULL';
    final remaining = _nextHeartAt!.difference(DateTime.now());
    if (remaining.isNegative) return '00:00';
    final totalSeconds = remaining.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _tickHearts() {
    if (_hearts >= _maxHearts) {
      if (_nextHeartAt != null) {
        setState(() => _nextHeartAt = null);
      }
      return;
    }
    final next = _nextHeartAt;
    if (next == null) return;
    if (DateTime.now().isBefore(next)) {
      setState(() {});
      return;
    }

    setState(() {
      _hearts += 1;
      if (_hearts >= _maxHearts) {
        _nextHeartAt = null;
      } else {
        _nextHeartAt = DateTime.now().add(_heartRegen);
      }
    });
  }

  void _scheduleHeartRegen() {
    _nextHeartAt ??= DateTime.now().add(_heartRegen);
  }

  bool _consumeHeart() {
    if (_hearts <= 0) return false;
    setState(() {
      _hearts -= 1;
      _scheduleHeartRegen();
    });
    return true;
  }

  void _onLevelTap() {
    if (_homePopup != _HomePopup.none || _pendingReward != null) return;
    setState(() {
      _homePopup =
          _hearts > 0 ? _HomePopup.start : _HomePopup.moreLives;
    });
  }

  void _onAdsTap() {
    if (_homePopup != _HomePopup.none || _pendingReward != null) return;
    setState(() => _homePopup = _HomePopup.noAds);
  }

  void _onPurchaseNoAds() {
    setState(() => _homePopup = _HomePopup.none);
  }

  void _onDefeat() {
    setState(() {
      _selectedIndex = 1;
      _homePopup = _hearts > 0 ? _HomePopup.retry : _HomePopup.moreLives;
    });
  }

  void _closeHomePopup() {
    setState(() => _homePopup = _HomePopup.none);
  }

  Future<void> _playLevel({bool debug = false}) async {
    if (!debug && !_consumeHeart()) {
      setState(() => _homePopup = _HomePopup.moreLives);
      return;
    }

    final gen = ++_playGen;
    setState(() {
      _homePopup = _HomePopup.none;
      _selectedIndex = 1;
    });

    final reward = await Navigator.of(context).push<int>(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => GamePage(
          coins: _coins,
          level: _level,
          onSpendCoins: _spendCoins,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
    if (!mounted || gen != _playGen) return;
    if (reward == GamePage.defeatCode) {
      _onDefeat();
      return;
    }
    if (reward != null && reward > 0) {
      _onReward(reward);
    }
  }

  void _onRefillLives() {
    if (!_spendCoins(_refillPrice)) return;
    setState(() {
      _hearts = _maxHearts;
      _nextHeartAt = null;
      _homePopup = _HomePopup.retry;
    });
  }

  void _onWatchAdForLife() {
    setState(() {
      _hearts = (_hearts + 1).clamp(0, _maxHearts);
      if (_hearts >= _maxHearts) {
        _nextHeartAt = null;
      } else {
        _scheduleHeartRegen();
      }
      _homePopup = _HomePopup.start;
    });
  }

  void _onReward(int amount) {
    if (amount <= 0) return;
    setState(() {
      if (_pendingReward != null) {
        _coins += _pendingReward!;
      }
      _hearts = (_hearts + 1).clamp(0, _maxHearts);
      if (_hearts >= _maxHearts) {
        _nextHeartAt = null;
      }
      _selectedIndex = 1;
      _pendingReward = amount;
      _displayedCoins = _coins;
      _homePopup = _HomePopup.none;
    });
  }

  void _onRewardComplete() {
    final amount = _pendingReward ?? 0;
    if (!mounted) return;
    setState(() {
      _coins += amount;
      _displayedCoins = _coins;
      _pendingReward = null;
      if (_level < _maxLevel) {
        _level += 1;
      }
      _homePopup = _HomePopup.start;
    });
  }

  bool _spendCoins(int amount) {
    if (amount <= 0 || _coins < amount) return false;
    setState(() {
      _coins -= amount;
      _displayedCoins = _coins;
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final showStatus = _selectedIndex == 0 || _selectedIndex == 1;
    final onHome = _selectedIndex == 1;
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final blocking =
        _pendingReward != null || _homePopup != _HomePopup.none;
    final status = StatusCounters(
      coins: _displayedCoins,
      hearts: _hearts,
      heartTimer: _heartTimerLabel,
      showHearts: onHome,
      showCoinPlus: onHome,
      showHeartPlus: onHome && _hearts < _maxHearts,
      gap: onHome ? 32 : 72,
      coinIconKey: onHome ? _coinIconKey : null,
      onCoinsTap: onHome
          ? () {
              if (blocking) return;
              setState(() => _selectedIndex = 0);
            }
          : null,
      onHeartsTap: onHome
          ? () {
              if (blocking) return;
              if (_hearts >= _maxHearts) return;
              setState(
                () => _homePopup = _HomePopup.moreLives,
              );
            }
          : null,
    );

    return Stack(
      children: [
        const Offstage(
          child: SizedBox(
            width: 1,
            height: 1,
            child: Image(
              image: AssetImage(loadingAsset),
              gaplessPlayback: true,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              IndexedStack(
                index: _selectedIndex,
                children: [
                  const Column(
                    children: [
                      AppTitleBar(title: 'Shop'),
                      Expanded(child: ShopPage()),
                    ],
                  ),
                  HomePage(
                    onLevelTap: _onLevelTap,
                    onAdsTap: _onAdsTap,
                  ),
                  const Column(
                    children: [
                      AppTitleBar(title: 'Settings'),
                      Expanded(child: SettingsPage()),
                    ],
                  ),
                ],
              ),
              if (showStatus)
                Positioned(
                  top: onHome ? 48 : 48,
                  left: onHome ? 32 : 12,
                  right: onHome ? 32 : 12,
                  child: onHome || !isTablet
                      ? status
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            status,
                            const SizedBox(width: 130),
                            const IgnorePointer(
                              child: Opacity(
                                opacity: 0,
                                child: StickerTitle(title: 'Shop'),
                              ),
                            ),
                          ],
                        ),
                ),
            ],
          ),
          bottomNavigationBar: AppNavbar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              if (blocking) return;
              setState(() => _selectedIndex = index);
            },
          ),
        ),
        if (_homePopup == _HomePopup.start)
          Positioned.fill(
            child: StartPopup(
              level: _level,
              onClose: _closeHomePopup,
              onStart: _playLevel,
            ),
          ),
        if (_homePopup == _HomePopup.retry)
          Positioned.fill(
            child: RetryPopup(
              level: _level,
              onClose: _closeHomePopup,
              onRetry: _playLevel,
            ),
          ),
        if (_homePopup == _HomePopup.moreLives)
          Positioned.fill(
            child: MoreLivesPopup(
              hearts: _hearts,
              heartTimer: _heartTimerLabel,
              refillPrice: _refillPrice,
              onClose: _closeHomePopup,
              onRefill: _onRefillLives,
              onWatchAd: _onWatchAdForLife,
            ),
          ),
        if (_homePopup == _HomePopup.noAds)
          Positioned.fill(
            child: NoAdsPopup(
              priceLabel: _noAdsPriceLabel,
              onClose: _closeHomePopup,
              onPurchase: _onPurchaseNoAds,
            ),
          ),
        if (_pendingReward != null)
          Positioned.fill(
            child: RewardOverlay(
              key: ValueKey('reward_${_coins}_${_pendingReward!}'),
              amount: _pendingReward!,
              fromCoins: _coins,
              targetKey: _coinIconKey,
              onCoinsDisplay: (value) {
                if (!mounted || _displayedCoins == value) return;
                setState(() => _displayedCoins = value);
              },
              onComplete: _onRewardComplete,
            ),
          ),
      ],
    );
  }
}
