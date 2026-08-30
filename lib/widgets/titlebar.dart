import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class AppTitleBar extends StatelessWidget {
  const AppTitleBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF000000), Color(0xFF000000)],
        ),
      ),
      child: DragToMoveArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 55),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: Center(child: StickerTitle(title: title)),
          ),
        ),
      ),
    );
  }
}

class StickerTitle extends StatelessWidget {
  const StickerTitle({super.key, required this.title, this.fontSize = 20});

  final String title;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    const depthColor = Color(0xFF313131);
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      height: 1,
      letterSpacing: -.4,
    );

    return Stack(
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
            child: Text(title, style: base.copyWith(color: depthColor)),
          ),
        Text(title, style: base.copyWith(color: Colors.white)),
      ],
    );
  }
}
