import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:app_store/views/customer/account_view.dart';

class AccountDialog {
  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Account",
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => const AccountView(),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8 * anim.value,
            sigmaY: 8 * anim.value,
          ),
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
