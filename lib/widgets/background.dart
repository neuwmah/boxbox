import 'dart:ui';

import 'package:flutter/material.dart';

class RectBackground extends StatelessWidget {
  const RectBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: 1,
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              1, 0, 0, 0, 4,
              0, 1, 0, 0, 4,
              0, 0, 1, 0, 4,
              0, 0, 0, 1, 0,
            ]),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: Image.asset(
                'lib/assets/background/rect.gif',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}
