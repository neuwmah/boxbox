import 'package:flutter/material.dart';
import 'package:boxbox/sound/sfx.dart';

class InSettingsMenu extends StatelessWidget {
  const InSettingsMenu({
    super.key,
    required this.animation,
    required this.music,
    required this.sound,
    required this.vibration,
    required this.onToggleMenu,
    required this.onClose,
    required this.onMusic,
    required this.onSound,
    required this.onVibration,
  });

  final Animation<double> animation;
  final bool music;
  final bool sound;
  final bool vibration;
  final VoidCallback onToggleMenu;
  final VoidCallback onClose;
  final VoidCallback onMusic;
  final VoidCallback onSound;
  final VoidCallback onVibration;

  static const iconSize = 24.0;
  static const buttonSize = 40.0;
  static const gap = 8.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(animation.value);
        final open = animation.value > 0.001;
        final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;

        return Stack(
          fit: StackFit.expand,
          children: [
            if (open)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onClose,
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.55 * t),
                  ),
                ),
              ),
            Positioned(
              top: 60,
              left: isTablet ? 0 : null,
              right: isTablet ? 0 : 32,
              child: Align(
                alignment: isTablet ? Alignment.topCenter : Alignment.topRight,
                child: Transform.translate(
                  offset: Offset(isTablet ? 100 : 0, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: buttonSize,
                        height: 48,
                        child: Center(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Sfx.instance.tap(onToggleMenu),
                            child: const Icon(
                              Icons.settings,
                              color: Colors.white,
                              size: iconSize,
                            ),
                          ),
                        ),
                      ),
                      if (open) ...[
                        SizedBox(height: gap),
                        _AnimatedMenuItem(
                          progress: _stagger(t, 0),
                          child: _MenuIconButton(
                            icon: Icons.music_note_rounded,
                            enabled: music,
                            onTap: () => Sfx.instance.tap(onMusic),
                          ),
                        ),
                        SizedBox(height: gap),
                        _AnimatedMenuItem(
                          progress: _stagger(t, 1),
                          child: _MenuIconButton(
                            icon: Icons.volume_up_rounded,
                            enabled: sound,
                            onTap: () => Sfx.instance.tap(onSound),
                          ),
                        ),
                        SizedBox(height: gap),
                        _AnimatedMenuItem(
                          progress: _stagger(t, 2),
                          child: _MenuIconButton(
                            icon: Icons.vibration_rounded,
                            enabled: vibration,
                            onTap: () => Sfx.instance.tap(onVibration),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static double _stagger(double t, int index) {
    final start = index * 0.12;
    final span = 1 - start;
    if (span <= 0) return t;
    return ((t - start) / span).clamp(0.0, 1.0);
  }
}

class _AnimatedMenuItem extends StatelessWidget {
  const _AnimatedMenuItem({
    required this.progress,
    required this.child,
  });

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOutCubic.transform(progress);
    return IgnorePointer(
      ignoring: progress < 0.05,
      child: Opacity(
        opacity: eased,
        child: Transform.translate(
          offset: Offset(0, (1 - eased) * -12),
          child: Transform.scale(
            scale: 0.86 + 0.14 * eased,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _MenuIconButton extends StatelessWidget {
  const _MenuIconButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = enabled
        ? const [
            Color(0xFFB6F34A),
            Color(0xFF6FBF1E),
            Color(0xFF4E9A12),
          ]
        : const [
            Color(0xFF2A2A2A),
            Color(0xFF1A1A1A),
            Color(0xFF121212),
          ];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: InSettingsMenu.buttonSize,
        height: InSettingsMenu.buttonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
            stops: const [0.0, 0.55, 1.0],
          ),
          border: Border.all(
            color: enabled ? const Color(0xFF2F6B0C) : const Color(0xFF101010),
            width: 1.4,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: FractionallySizedBox(
                  widthFactor: 1,
                  heightFactor: 0.42,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: enabled ? 0.18 : 0.06),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Icon(
              icon,
              color: enabled ? Colors.white : const Color(0xFF6A6A6A),
              size: InSettingsMenu.iconSize,
            ),
          ],
        ),
      ),
    );
  }
}
