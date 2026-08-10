import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:boxbox/pages/game.dart';
import 'package:boxbox/widgets/titlebar.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.coins,
    this.onReward,
    this.onSpendCoins,
    this.onBeforePlay,
    this.onDefeat,
  });

  final int coins;
  final ValueChanged<int>? onReward;
  final bool Function(int amount)? onSpendCoins;
  final bool Function()? onBeforePlay;
  final VoidCallback? onDefeat;

  static const _scale = 1.1;
  static const _bgOpacity = 0.08;
  static const _grayscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  Future<void> _openGame(BuildContext context) async {
    if (onBeforePlay != null && !onBeforePlay!()) return;

    final reward = await Navigator.of(context).push<int>(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => GamePage(
          coins: coins,
          onSpendCoins: onSpendCoins,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
    if (!context.mounted) return;
    if (reward == GamePage.defeatCode) {
      onDefeat?.call();
      return;
    }
    if (reward != null && reward > 0) {
      onReward?.call(reward);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: _bgOpacity,
          child: Transform.scale(
            scale: _scale,
            child: ColorFiltered(
              colorFilter: _grayscale,
              child: Image.asset(
                'lib/assets/background/giphy.webp',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
        Center(
          child: Transform.translate(
            offset: const Offset(0, 40),
            child: GestureDetector(
              onTap: () => _openGame(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(
                    color: const Color(0xFF101010),
                    width: 1.6,
                  ),
                ),
                child: const StickerTitle(title: 'Lv. 1'),
              ),
            ),
          ),
        ),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 40,
          child: DragToMoveArea(
            child: SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}
