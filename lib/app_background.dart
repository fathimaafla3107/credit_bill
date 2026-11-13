import 'package:flutter/material.dart';

import 'app_theme.dart';

/// The soft blue gradient background used across the app.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FBFF), Color(0xFFEDF5FF), Color(0xFFE3F0FF)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -100,
            child: _AppGlow(
              color: AppColors.primaryLight,
              size: 340,
              opacity: 0.30,
            ),
          ),
          Positioned(
            bottom: -140,
            left: -120,
            child: _AppGlow(color: AppColors.primary, size: 380, opacity: 0.16),
          ),
          Positioned(
            top: 180,
            left: -70,
            child: _AppGlow(
              color: const Color(0xFF7EC8FF),
              size: 190,
              opacity: 0.22,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppGlow extends StatelessWidget {
  const _AppGlow({
    required this.color,
    required this.size,
    required this.opacity,
  });

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
