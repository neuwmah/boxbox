import 'package:flutter/material.dart';
import 'package:boxbox/widgets/background.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _music = true;
  bool _sound = true;
  bool _vibration = true;

  @override
  Widget build(BuildContext context) {
    return RectBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          children: [
            _SettingsPanel(
              children: [
                _ToggleControl(
                  label: 'Music',
                  icon: Icons.music_note_rounded,
                  enabled: _music,
                  onTap: () => setState(() => _music = !_music),
                ),
                _ToggleControl(
                  label: 'Sound',
                  icon: Icons.volume_up_rounded,
                  enabled: _sound,
                  onTap: () => setState(() => _sound = !_sound),
                ),
                _ToggleControl(
                  label: 'Vibration',
                  icon: Icons.vibration_rounded,
                  enabled: _vibration,
                  onTap: () => setState(() => _vibration = !_vibration),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Center(child: _PrimaryButton(label: 'Support')),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SecondaryButton(label: 'Terms'),
                SizedBox(width: 12),
                _SecondaryButton(label: 'Privacy'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.children});

  final List<Widget> children;

  static const _border = Color(0xFF101010);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 270),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: _border, width: 1.6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleControl extends StatelessWidget {
  const _ToggleControl({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  static const _labelStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1,
  );

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 52),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: _labelStyle,
              softWrap: false,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 1,
            child: GestureDetector(
              onTap: onTap,
              child: _GlossyTile(
                enabled: enabled,
                child: Icon(
                  icon,
                  color: enabled ? Colors.white : const Color(0xFF6A6A6A),
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label});

  final String label;

  static const _base = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    height: 1,
    letterSpacing: -.2,
  );

  static const _depthColor = Color(0xFF24580A);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB6F34A),
              Color(0xFF6FBF1E),
              Color(0xFF4E9A12),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
          border: Border.all(color: const Color(0xFF2F6B0C), width: 1.4),
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
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (final offset in const [
                    Offset(1, 1),
                    Offset(2, 2),
                    Offset(0, 1),
                    Offset(1, 0),
                    Offset(1, 2),
                    Offset(2, 1),
                  ])
                    Transform.translate(
                      offset: offset,
                      child: Text(
                        label,
                        style: _base.copyWith(color: _depthColor),
                      ),
                    ),
                  Text(
                    label,
                    style: _base.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label});

  final String label;

  static const _base = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1,
    letterSpacing: -.2,
  );

  static const _depthColor = Color(0xFF313131);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        constraints: const BoxConstraints(minWidth: 100),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (final offset in const [
              Offset(1, 1),
              Offset(2, 2),
              Offset(0, 1),
              Offset(1, 0),
              Offset(1, 2),
              Offset(2, 1),
            ])
              Transform.translate(
                offset: offset,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: _base.copyWith(color: _depthColor),
                ),
              ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: _base.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlossyTile extends StatelessWidget {
  const _GlossyTile({
    required this.enabled,
    required this.child,
    this.borderRadius = 8,
  });

  final bool enabled;
  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: enabled
              ? const [
                  Color(0xFFB6F34A),
                  Color(0xFF6FBF1E),
                  Color(0xFF4E9A12),
                ]
              : const [
                  Color(0xFF2A2A2A),
                  Color(0xFF1A1A1A),
                  Color(0xFF121212),
                ],
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
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(borderRadius - 1),
                    ),
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
          child,
        ],
      ),
    );
  }
}
