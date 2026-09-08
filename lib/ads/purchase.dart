import 'package:boxbox/popups/cancel.dart';
import 'package:boxbox/popups/loader.dart';
import 'package:boxbox/popups/popup.dart';
import 'package:boxbox/popups/success.dart';
import 'package:flutter/material.dart';

class Purchase {
  Purchase._();

  static final instance = Purchase._();

  static const duration = Duration(milliseconds: 1500);

  bool _showing = false;

  Future<void> showLoading(
    BuildContext context, {
    bool success = false,
    VoidCallback? onGranted,
  }) async {
    if (_showing || !context.mounted) return;
    _showing = true;
    final navigator = Navigator.of(context, rootNavigator: true);
    try {
      final closed = showGeneralDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        barrierLabel: 'Purchase',
        barrierColor: Colors.transparent,
        transitionDuration: Duration.zero,
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
        pageBuilder: (context, animation, __) {
          return const PopScope(
            canPop: false,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: Color.fromRGBO(0, 0, 0, popupDim)),
                ModalBarrier(dismissible: false),
                Center(child: CubeLoader()),
              ],
            ),
          );
        },
      );
      await Future<void>.delayed(duration);
      if (navigator.mounted) navigator.pop();
      await closed;
      if (!context.mounted) return;
      if (success) onGranted?.call();
      await showGeneralDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        barrierLabel: success ? 'Purchase success' : 'Purchase cancelled',
        barrierColor: Colors.transparent,
        transitionDuration: Duration.zero,
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
        pageBuilder: (context, _, __) {
          void close() => Navigator.of(context, rootNavigator: true).pop();
          return PopScope(
            canPop: false,
            child: success
                ? SuccessPopup(onClose: close)
                : CancelPopup(onClose: close),
          );
        },
      );
    } finally {
      _showing = false;
    }
  }
}
