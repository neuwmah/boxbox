import 'package:flutter/material.dart';
import 'package:boxbox/sound/sfx.dart';

class NavDestination {
  const NavDestination({required this.icon, required this.label});

  final Widget Function(Color color) icon;
  final String label;
}

class AppNavbar extends StatelessWidget {
  const AppNavbar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  static final destinations = [
    NavDestination(
      icon: (_) => const NavAssetIcon('lib/assets/play/shop.png'),
      label: 'Shop',
    ),
    NavDestination(
      icon: (_) => const NavAssetIcon('lib/assets/play/home.png'),
      label: 'Home',
    ),
    NavDestination(
      icon: (_) => const NavAssetIcon('lib/assets/play/settings.png'),
      label: 'Settings',
    ),
  ];

  static const _maxWidth = 300.0;
  static const _topRadius = Radius.circular(16);
  static const _selectedExtra = 16.0;
  static const _padTop = 4.0;
  static const _padBottom = 4.0;
  static const _iconSize = 32.0;
  static const _labelGap = 2.0;
  static const _labelBlock = 14 * 1.4 + 4;
  static const _barHeight =
      _padTop + _iconSize + _labelGap + _labelBlock + _padBottom;

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  BorderRadius _selectedRadius(bool wide) {
    if (wide) {
      return const BorderRadius.vertical(top: _topRadius);
    }
    switch (selectedIndex) {
      case 0:
        return const BorderRadius.only(topRight: _topRadius);
      case 2:
        return const BorderRadius.only(topLeft: _topRadius);
      default:
        return const BorderRadius.vertical(top: _topRadius);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, outer) {
          final wide = outer.maxWidth > _maxWidth;

          return Align(
            alignment: Alignment.center,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxWidth),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth =
                      constraints.maxWidth / destinations.length;

                  return SizedBox(
                    height: _barHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < destinations.length; i++)
                              Expanded(
                                child: i == selectedIndex
                                    ? const SizedBox.expand()
                                    : GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          Sfx.instance.playTouch();
                                          onDestinationSelected(i);
                                        },
                                        child: Center(
                                          child: destinations[i].icon(
                                            Colors.white,
                                          ),
                                        ),
                                      ),
                              ),
                          ],
                        ),
                        Positioned(
                          left: selectedIndex * itemWidth,
                          bottom: 0,
                          width: itemWidth,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              Sfx.instance.playTouch();
                              onDestinationSelected(selectedIndex);
                            },
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF101010),
                                    Color(0xFF050505),
                                  ],
                                ),
                                borderRadius: _selectedRadius(wide),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black,
                                    blurRadius: 4,
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: _padTop + _selectedExtra / 1.5,
                                  bottom: _padBottom + _selectedExtra / 2,
                                ),
                                child: _NavTabBody(
                                  destination: destinations[selectedIndex],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavTabBody extends StatelessWidget {
  const _NavTabBody({required this.destination});

  final NavDestination destination;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        destination.icon(Colors.white),
        _NavLabel(destination.label),
      ],
    );
  }
}

class NavAssetIcon extends StatelessWidget {
  const NavAssetIcon(this.asset, {super.key, this.size = 32});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

class _NavLabel extends StatelessWidget {
  const _NavLabel(this.text);

  final String text;

  static const _style = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  static const _depthColor = Color(0xFF050505);
  static const _offsets = [
    Offset(1, 1),
    Offset(2, 2),
    Offset(0, 1),
    Offset(1, 0),
    Offset(1, 2),
    Offset(2, 1),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          for (final offset in _offsets)
            Transform.translate(
              offset: offset,
              child: Text(text, style: _style.copyWith(color: _depthColor)),
            ),
          Text(text, style: _style.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}
