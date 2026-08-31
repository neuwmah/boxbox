import 'dart:async';
import 'dart:io';

import 'package:boxbox/ads/ads_ids.dart';
import 'package:boxbox/sound/soundtrack.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class Ads {
  Ads._();

  static final instance = Ads._();

  static bool get supported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  bool adsRemoved = false;
  bool _ready = false;
  bool _loadingInterstitial = false;
  bool _loadingRewarded = false;
  bool _loadingAppOpen = false;
  bool _showingFullscreen = false;
  bool _showAppOpenWhenReady = true;
  bool _inBackground = false;
  int _interstitialAttempts = 0;
  int _rewardedAttempts = 0;
  int _appOpenAttempts = 0;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  AppOpenAd? _appOpen;
  DateTime? _appOpenLoadedAt;
  StreamSubscription<AppState>? _appStateSub;

  static const _maxAttempts = 3;
  static const _appOpenMaxAge = Duration(hours: 4);

  bool get showingFullscreen => _showingFullscreen;

  Future<void> initialize() async {
    if (!supported || adsRemoved || _ready) return;
    try {
      await MobileAds.instance.initialize();
      _ready = true;
      await AppStateEventNotifier.startListening();
      _appStateSub ??= AppStateEventNotifier.appStateStream.listen(_onAppState);
    } catch (error, stack) {
      debugPrint('AdMob initialize failed: $error');
      debugPrint('$stack');
    }
  }

  Future<bool> prepareLaunchAd() async {
    await initialize();
    if (!supported || adsRemoved || !_ready) return false;
    _showAppOpenWhenReady = false;
    final ad = await _loadAppOpenAwaitingFirst();
    if (ad == null) return false;
    _appOpen = ad;
    _appOpenLoadedAt = DateTime.now();
    return true;
  }

  void preload() {
    _loadInterstitial();
    _loadRewarded();
    _loadAppOpen();
  }

  void setAdsRemoved(bool value) {
    adsRemoved = value;
    if (!value) {
      preload();
      return;
    }
    _interstitial?.dispose();
    _interstitial = null;
    _rewarded?.dispose();
    _rewarded = null;
    _appOpen?.dispose();
    _appOpen = null;
    _appOpenLoadedAt = null;
  }

  void _onAppState(AppState state) {
    if (state == AppState.background) {
      _inBackground = true;
      return;
    }
    if (state == AppState.foreground && _inBackground) {
      _inBackground = false;
      unawaited(showAppOpenIfAvailable());
    }
  }

  Future<bool> showAppOpenIfAvailable() async {
    if (!supported || adsRemoved || _showingFullscreen) return false;
    if (_expiredAppOpen) {
      _appOpen?.dispose();
      _appOpen = null;
      _appOpenLoadedAt = null;
    }
    final ad = _appOpen;
    if (ad == null) {
      _loadAppOpen();
      return false;
    }
    _appOpen = null;
    _appOpenLoadedAt = null;
    _showingFullscreen = true;
    Soundtrack.instance.setForeground(false);
    final done = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showingFullscreen = false;
        Soundtrack.instance.restoreHome();
        if (!done.isCompleted) done.complete(true);
        _loadAppOpen();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('App Open failed to show: $error');
        ad.dispose();
        _showingFullscreen = false;
        Soundtrack.instance.restoreHome();
        if (!done.isCompleted) done.complete(false);
        _loadAppOpen();
      },
    );
    try {
      await ad.show();
    } catch (error) {
      debugPrint('App Open show error: $error');
      ad.dispose();
      _showingFullscreen = false;
      Soundtrack.instance.restoreHome();
      if (!done.isCompleted) done.complete(false);
      _loadAppOpen();
      return false;
    }
    return done.future;
  }

  bool get _expiredAppOpen {
    final loadedAt = _appOpenLoadedAt;
    if (loadedAt == null) return true;
    return DateTime.now().difference(loadedAt) > _appOpenMaxAge;
  }

  Future<bool> showInterstitial() async {
    if (!supported || adsRemoved || _showingFullscreen) return false;
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return false;
    }
    _interstitial = null;
    _showingFullscreen = true;
    final done = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showingFullscreen = false;
        if (!done.isCompleted) done.complete(true);
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial failed to show: $error');
        ad.dispose();
        _showingFullscreen = false;
        if (!done.isCompleted) done.complete(false);
        _loadInterstitial();
      },
    );
    try {
      await ad.show();
    } catch (error) {
      debugPrint('Interstitial show error: $error');
      ad.dispose();
      _showingFullscreen = false;
      if (!done.isCompleted) done.complete(false);
      _loadInterstitial();
      return false;
    }
    return done.future;
  }

  Future<bool> showRewarded() async {
    if (!supported || adsRemoved || _showingFullscreen) return false;
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    _rewarded = null;
    var earned = false;
    _showingFullscreen = true;
    final done = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showingFullscreen = false;
        if (!done.isCompleted) done.complete(earned);
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded failed to show: $error');
        ad.dispose();
        _showingFullscreen = false;
        if (!done.isCompleted) done.complete(false);
        _loadRewarded();
      },
    );
    try {
      await ad.show(
        onUserEarnedReward: (_, _) {
          earned = true;
        },
      );
    } catch (error) {
      debugPrint('Rewarded show error: $error');
      ad.dispose();
      _showingFullscreen = false;
      if (!done.isCompleted) done.complete(false);
      _loadRewarded();
      return false;
    }
    return done.future;
  }

  bool get _useTestAds => kDebugMode;

  String? get _interstitialId {
    if (_useTestAds) {
      return Platform.isAndroid
          ? AdsIds.testAndroidInterstitial
          : AdsIds.testIosInterstitial;
    }
    final id = Platform.isAndroid
        ? AdsIds.androidInterstitial
        : AdsIds.iosInterstitial;
    if (AdsIds.isUsable(id)) return id;
    return null;
  }

  String? get _rewardedId {
    if (_useTestAds) {
      return Platform.isAndroid
          ? AdsIds.testAndroidRewarded
          : AdsIds.testIosRewarded;
    }
    final id = Platform.isAndroid ? AdsIds.androidRewarded : AdsIds.iosRewarded;
    if (AdsIds.isUsable(id)) return id;
    return null;
  }

  String? get _appOpenId {
    if (_useTestAds) {
      return Platform.isAndroid
          ? AdsIds.testAndroidAppOpen
          : AdsIds.testIosAppOpen;
    }
    final id = Platform.isAndroid ? AdsIds.androidAppOpen : AdsIds.iosAppOpen;
    if (AdsIds.isUsable(id)) return id;
    return null;
  }

  void _loadInterstitial() {
    if (!supported || !_ready || adsRemoved) return;
    if (_loadingInterstitial || _interstitial != null) return;
    final adUnitId = _interstitialId;
    if (adUnitId == null) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Interstitial loaded.');
          _interstitial = ad;
          _loadingInterstitial = false;
          _interstitialAttempts = 0;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load: $error');
          _loadingInterstitial = false;
          _interstitialAttempts++;
          if (_interstitialAttempts < _maxAttempts) {
            Future<void>.delayed(
              Duration(seconds: _interstitialAttempts * 2),
              _loadInterstitial,
            );
          }
        },
      ),
    );
  }

  void _loadRewarded() {
    if (!supported || !_ready || adsRemoved) return;
    if (_loadingRewarded || _rewarded != null) return;
    final adUnitId = _rewardedId;
    if (adUnitId == null) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Rewarded loaded.');
          _rewarded = ad;
          _loadingRewarded = false;
          _rewardedAttempts = 0;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded failed to load: $error');
          _loadingRewarded = false;
          _rewardedAttempts++;
          if (_rewardedAttempts < _maxAttempts) {
            Future<void>.delayed(
              Duration(seconds: _rewardedAttempts * 2),
              _loadRewarded,
            );
          }
        },
      ),
    );
  }

  Future<AppOpenAd?> _loadAppOpenAwaitingFirst() async {
    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      final ad = await _loadAppOpenOnce();
      if (ad != null) return ad;
    }
    return null;
  }

  Future<AppOpenAd?> _loadAppOpenOnce() {
    if (!supported || !_ready || adsRemoved) return Future<AppOpenAd?>.value();
    final adUnitId = _appOpenId;
    if (adUnitId == null) return Future<AppOpenAd?>.value();
    final done = Completer<AppOpenAd?>();
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('App Open loaded.');
          if (!done.isCompleted) done.complete(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('App Open failed to load: $error');
          if (!done.isCompleted) done.complete(null);
        },
      ),
    );
    return done.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => null,
    );
  }

  void _loadAppOpen() {
    if (!supported || !_ready || adsRemoved) return;
    if (_loadingAppOpen || _appOpen != null) return;
    final adUnitId = _appOpenId;
    if (adUnitId == null) return;
    _loadingAppOpen = true;
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('App Open loaded.');
          _appOpen = ad;
          _appOpenLoadedAt = DateTime.now();
          _loadingAppOpen = false;
          _appOpenAttempts = 0;
          if (_showAppOpenWhenReady) {
            _showAppOpenWhenReady = false;
            unawaited(showAppOpenIfAvailable());
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('App Open failed to load: $error');
          _loadingAppOpen = false;
          _appOpenAttempts++;
          if (_appOpenAttempts < _maxAttempts) {
            Future<void>.delayed(
              Duration(seconds: _appOpenAttempts * 2),
              _loadAppOpen,
            );
          }
        },
      ),
    );
  }
}
