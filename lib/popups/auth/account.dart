import 'package:boxbox/popups/loader.dart';
import 'package:boxbox/popups/popup.dart';
import 'package:flutter/material.dart';

class AccountFlow {
  AccountFlow._();

  static final instance = AccountFlow._();

  static const duration = Duration(milliseconds: 1500);

  bool _showing = false;

  Future<void> run(
    BuildContext context,
    Future<bool> Function() action, {
    required Widget Function(VoidCallback onClose) success,
    required Widget Function(VoidCallback onClose) cancel,
  }) async {
    if (_showing || !context.mounted) return;
    _showing = true;
    final navigator = Navigator.of(context, rootNavigator: true);
    var ok = false;
    try {
      final closed = showGeneralDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        barrierLabel: 'Account',
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
      try {
        await Future<void>.delayed(duration);
        try {
          ok = await action();
        } catch (error) {
          debugPrint('Account action failed: $error');
          ok = false;
        }
        await Future<void>.delayed(duration);
      } finally {
        if (navigator.mounted) navigator.pop();
        await closed;
      }
      if (!context.mounted) return;
      await showGeneralDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        barrierLabel: ok ? 'Account success' : 'Account cancelled',
        barrierColor: Colors.transparent,
        transitionDuration: Duration.zero,
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
        pageBuilder: (context, _, __) {
          void close() => Navigator.of(context, rootNavigator: true).pop();
          return PopScope(
            canPop: false,
            child: ok ? success(close) : cancel(close),
          );
        },
      );
    } finally {
      _showing = false;
    }
  }
}
