import 'dart:async';
import 'dart:io';

import 'package:boxbox/ads/ads.dart';
import 'package:boxbox/game/level.dart';
import 'package:boxbox/pages/game.dart';
import 'package:boxbox/pages/home.dart';
import 'package:boxbox/pages/settings.dart';
import 'package:boxbox/pages/shop.dart';
import 'package:boxbox/sound/sfx.dart';
import 'package:boxbox/sound/soundtrack.dart';
import 'package:boxbox/widgets/morelives.dart';
import 'package:boxbox/widgets/navbar.dart';
import 'package:boxbox/widgets/noads.dart';
import 'package:boxbox/widgets/retry.dart';
import 'package:boxbox/widgets/reward.dart';
import 'package:boxbox/widgets/start.dart';
import 'package:boxbox/widgets/status.dart';
import 'package:boxbox/widgets/titlebar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

bool get _isDesktop {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}

const _systemOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.light,
  systemNavigationBarDividerColor: Colors.transparent,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(_systemOverlayStyle);
  if (_isDesktop) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(300, 705),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const _logoMinDuration = Duration(seconds: 3);

  Widget? _shell;
  bool _showLaunchLogo = true;
  bool _showLaunchCover = true;

  @override
  void initState() {
    super.initState();
    unawaited(_boot());
  }

  Future<void> _hideLaunchLogo(DateTime until) async {
    if (!mounted || !_showLaunchLogo) return;
    final remaining = until.difference(DateTime.now());
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (!mounted || !_showLaunchLogo) return;
    setState(() => _showLaunchLogo = false);
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _boot() async {
    await WidgetsBinding.instance.endOfFrame;
    final logoUntil = DateTime.now().add(_logoMinDuration);
    await Ads.instance.initializeAndShowLaunchAd(
      onBeforeShow: () => _hideLaunchLogo(logoUntil),
    );
    await _hideLaunchLogo(logoUntil);
    await Soundtrack.instance.start();
    await Sfx.instance.preload();
    if (!mounted) return;
    final homeReady = Completer<void>();
    setState(() {
      _shell = MainShell(
        onFirstHomeReady: () {
          if (!homeReady.isCompleted) homeReady.complete();
        },
      );
    });
    await homeReady.future;
    if (!mounted) return;
    setState(() => _showLaunchCover = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder:
          (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: _systemOverlayStyle,
            child: child ?? const SizedBox.shrink(),
          ),
      home: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          if (_shell != null) _shell!,
          if (_showLaunchCover) _LaunchSplash(showLogo: _showLaunchLogo),
        ],
      ),
    );
  }
}

class _LaunchSplash extends StatelessWidget {
  const _LaunchSplash({this.showLogo = true});

  final bool showLogo;

  static const _logoAsset = 'lib/assets/logo.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: showLogo
          ? const Center(
              child: Image(
                image: AssetImage(_logoAsset),
                width: 300,
                height: 300,
                filterQuality: FilterQuality.medium,
              ),
            )
          : const SizedBox.expand(),
    );
  }
}

enum _HomePopup { none, start, retry, moreLives, noAds }

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.onFirstHomeReady});

  final VoidCallback? onFirstHomeReady;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  static const _maxHearts = 5;
  static const _heartRegen = Duration(minutes: 20);
  static const _refillPrice = 900;
  static const _noAdsPriceLabel = 'BRL 59.90';
  static const _homeLoadingFadeDuration = Duration(milliseconds: 250);
  static const _homeAssets = [
    loadingAsset,
    'lib/assets/coin/icon1.png',
    'lib/assets/heart/icon1.png',
    'lib/assets/play/home.png',
    'lib/assets/play/shop.png',
    'lib/assets/play/settings.png',
    'lib/assets/ad.png',
  ];

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
  bool _homeAssetsReady = false;
  bool _cubesReady = false;
  bool _adsIconReady = false;
  bool _firstHomeRevealed = false;
  bool _adsRemoved = false;
  bool _adBusy = false;
  late final AnimationController _homeLoadingFade;
  Future<void>? _homeLoadingTask;

  @override
  void initState() {
    super.initState();
    _homeLoadingFade = AnimationController(
      vsync: this,
      duration: _homeLoadingFadeDuration,
    )..addStatusListener((status) {
      if (status == AnimationStatus.dismissed && mounted) {
        setState(() {});
      }
    });
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
    _homeLoadingFade.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadingPrecached) return;
    _loadingPrecached = true;
    unawaited(_precacheHomeAssets());
  }

  Future<void> _precacheHomeAssets() async {
    await Future.wait([
      for (final asset in _homeAssets)
        precacheImage(AssetImage(asset), context),
    ]);
    if (!mounted) return;
    _homeAssetsReady = true;
    unawaited(_tryRevealHome());
  }

  void _onCubesReady() {
    _cubesReady = true;
    unawaited(_tryRevealHome());
  }

  void _onAdsIconReady() {
    _adsIconReady = true;
    unawaited(_tryRevealHome());
  }

  Future<void> _tryRevealHome() async {
    if (_firstHomeRevealed) return;
    if (!_homeAssetsReady || !_cubesReady || !_adsIconReady) return;
    _firstHomeRevealed = true;
    for (var i = 0; i < 5; i++) {
      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!mounted) return;
    widget.onFirstHomeReady?.call();
  }

  void _coverHome() {
    _homeLoadingTask = null;
    _homeLoadingFade.value = 1;
    if (mounted) setState(() {});
  }

  Future<void> _finishHomeLoading() {
    return _homeLoadingTask ??= _runHomeLoadingFade();
  }

  Future<void> _runHomeLoadingFade() async {
    if (_homeLoadingFade.isDismissed) return;
    for (var i = 0; i < 5; i++) {
      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!mounted || _homeLoadingFade.isDismissed) return;
    await _homeLoadingFade.reverse();
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
    final replace = Navigator.of(context).canPop();
    await _playLevel(debug: true, replace: replace);
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
      _homePopup = _hearts > 0 ? _HomePopup.start : _HomePopup.moreLives;
    });
  }

  void _onAdsTap() {
    if (_homePopup != _HomePopup.none || _pendingReward != null) return;
    setState(() => _homePopup = _HomePopup.noAds);
  }

  void _onPurchaseNoAds() {
    setState(() {
      _adsRemoved = true;
      _homePopup = _HomePopup.none;
    });
    Ads.instance.setAdsRemoved(true);
  }

  Future<void> _presentInterstitial() async {
    if (_adsRemoved || _adBusy) return;
    _adBusy = true;
    Soundtrack.instance.setForeground(false);
    await Ads.instance.showInterstitial();
    Soundtrack.instance.restoreHome();
    _adBusy = false;
  }

  Future<void> _onDefeat() async {
    await _presentInterstitial();
    if (!mounted) return;
    setState(() {
      _selectedIndex = 1;
      _homePopup = _hearts > 0 ? _HomePopup.retry : _HomePopup.moreLives;
    });
  }

  void _closeHomePopup() {
    setState(() => _homePopup = _HomePopup.none);
  }

  Future<void> _playLevel({bool debug = false, bool replace = false}) async {
    if (!debug && !_consumeHeart()) {
      setState(() => _homePopup = _HomePopup.moreLives);
      return;
    }

    final gen = ++_playGen;
    setState(() {
      _level = clampLevel(_level);
      _homePopup = _HomePopup.none;
      _selectedIndex = 1;
    });

    final route = PageRouteBuilder<int>(
      pageBuilder:
          (_, __, ___) => GamePage(
            coins: _coins,
            level: _level,
            onSpendCoins: _spendCoins,
            onPrepareReward: _onReward,
            onCoverBeforeExit: _coverHome,
          ),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
    final reward = replace
        ? await Navigator.of(context).pushReplacement<int, int>(route)
        : await Navigator.of(context).push<int>(route);
    if (!mounted || gen != _playGen) return;
    await _finishHomeLoading();
    if (!mounted || gen != _playGen) return;
    if (reward == GamePage.defeatCode) {
      await _onDefeat();
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

  Future<void> _onWatchAdForLife() async {
    if (_adBusy) return;
    _adBusy = true;
    Soundtrack.instance.setForeground(false);
    final earned = await Ads.instance.showRewarded();
    Soundtrack.instance.restoreHome();
    _adBusy = false;
    if (!earned || !mounted) return;
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
    if (_pendingReward == amount) return;
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

  Future<void> _onRewardComplete() async {
    final amount = _pendingReward ?? 0;
    if (!mounted) return;
    await _presentInterstitial();
    if (!mounted) return;
    setState(() {
      _coins += amount;
      _displayedCoins = _coins;
      _pendingReward = null;
      _level = clampLevel(_level + 1);
      _homePopup = _HomePopup.start;
    });
    Soundtrack.instance.restoreHome();
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
    final blocking = _pendingReward != null || _homePopup != _HomePopup.none;
    final status = StatusCounters(
      coins: _displayedCoins,
      hearts: _hearts,
      heartTimer: _heartTimerLabel,
      showHearts: onHome,
      showCoinPlus: onHome,
      showHeartPlus: onHome && _hearts < _maxHearts,
      gap: onHome ? 32 : 72,
      coinIconKey: onHome ? _coinIconKey : null,
      onCoinsTap:
          onHome
              ? () {
                if (blocking) return;
                setState(() => _selectedIndex = 0);
              }
              : null,
      onHeartsTap:
          onHome && _hearts < _maxHearts
              ? () {
                if (blocking) return;
                setState(() => _homePopup = _HomePopup.moreLives);
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
                    onCubesReady: _onCubesReady,
                    onAdsIconReady: _onAdsIconReady,
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
                  top: onHome ? 68 : 68,
                  left: onHome ? 32 : 12,
                  right: onHome ? 32 : 12,
                  child:
                      onHome || !isTablet
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
        if (!_homeLoadingFade.isDismissed)
          Positioned.fill(
            child: RepaintBoundary(
              child: FadeTransition(
                opacity: _homeLoadingFade,
                child: const LoadingCover(),
              ),
            ),
          ),
      ],
    );
  }
}
