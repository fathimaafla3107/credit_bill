import 'package:flutter/material.dart';

import 'app_theme.dart';

/// A white circular back button used by full-screen app pages.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.onPressed, this.buttonKey});

  final VoidCallback onPressed;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
        child: InkWell(
          key: buttonKey,
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
