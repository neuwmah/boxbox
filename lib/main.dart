import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:boxbox/pages/home.dart';
import 'package:boxbox/pages/settings.dart';
import 'package:boxbox/pages/shop.dart';
import 'package:boxbox/widgets/reward.dart';
import 'package:boxbox/widgets/navbar.dart';
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

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 1;
  int _coins = 500;
  int _displayedCoins = 500;
  int? _pendingReward;
  final GlobalKey _coinIconKey = GlobalKey();

  void _onReward(int amount) {
    if (amount <= 0) return;
    setState(() {
      if (_pendingReward != null) {
        _coins += _pendingReward!;
      }
      _selectedIndex = 1;
      _pendingReward = amount;
      _displayedCoins = _coins;
    });
  }

  void _onRewardComplete() {
    final amount = _pendingReward ?? 0;
    if (!mounted) return;
    setState(() {
      _coins += amount;
      _displayedCoins = _coins;
      _pendingReward = null;
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

    return Stack(
      children: [
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
                    coins: _coins,
                    onReward: _onReward,
                    onSpendCoins: _spendCoins,
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
                  child: StatusCounters(
                    coins: _displayedCoins,
                    showHearts: onHome,
                    showCoinPlus: onHome,
                    gap: onHome ? 32 : 72,
                    coinIconKey: onHome ? _coinIconKey : null,
                    onCoinsTap: onHome
                        ? () => setState(() => _selectedIndex = 0)
                        : null,
                  ),
                ),
            ],
          ),
          bottomNavigationBar: AppNavbar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              if (_pendingReward != null) return;
              setState(() => _selectedIndex = index);
            },
          ),
        ),
        if (_pendingReward != null)
          Positioned.fill(
            child: RewardOverlay(
              key: ValueKey('reward_$_coins}_${_pendingReward!}'),
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
