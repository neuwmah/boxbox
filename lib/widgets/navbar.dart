import 'package:flutter/material.dart';

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
      icon: (color) => Icon(Icons.shopping_bag, color: color),
      label: 'Shop',
    ),
    NavDestination(
      icon: (color) => CubeIcon(color: color),
      label: 'Home',
    ),
    NavDestination(
      icon: (color) => Icon(Icons.settings, color: color),
      label: 'Settings',
    ),
  ];

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / destinations.length;

          return Stack(
            children: [
              Positioned(
                left: selectedIndex * itemWidth,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: const ColoredBox(color: Color(0xFF101010)),
              ),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < destinations.length; i++)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onDestinationSelected(i),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 8,
                              bottom: 8,
                            ),
                            child: i == selectedIndex
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    spacing: 2,
                                    children: [
                                      destinations[i].icon(Colors.white),
                                      Text(
                                        destinations[i].label,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  )
                                : Center(
                                    child: destinations[i].icon(Colors.white),
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CubeIcon extends StatelessWidget {
  const CubeIcon({super.key, this.size = 24, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      child: Image.asset(
        'lib/assets/play/icon.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
