class AdsIds {
  AdsIds._();

  /// Spam
  static const androidInterstitial = 'ca-app-pub-5796139289910595/7938598096';
  static const iosInterstitial = 'ca-app-pub-5796139289910595/7938598096';

  /// Reward
  static const androidRewarded = '';
  static const iosRewarded = '';

  /// Open
  static const androidAppOpen = 'ca-app-pub-5796139289910595/9882235158';
  static const iosAppOpen = 'ca-app-pub-5796139289910595/9882235158';

  static const testAndroidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const testIosInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const testAndroidRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const testIosRewarded = 'ca-app-pub-3940256099942544/1712485313';
  static const testAndroidAppOpen = 'ca-app-pub-3940256099942544/9257395921';
  static const testIosAppOpen = 'ca-app-pub-3940256099942544/5575463023';

  static bool isUsable(String id) =>
      id.startsWith('ca-app-pub-') && id.contains('/');
}