import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'menu_page.dart';

/// The landing screen of the Credit Bill System app.
///
/// The layout adapts to small phones, tablets, and desktop windows, and the
/// call to action can be wired to any destination through [onGetStarted].
class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onGetStarted});

  /// Called when the user taps "Get Started".
  ///
  /// When omitted, the main menu is opened.
  final VoidCallback? onGetStarted;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleGetStarted() {
    final callback = widget.onGetStarted;
    if (callback != null) {
      callback();
      return;
    }

    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (context) => const MenuPage()));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: _Background()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 700;
                  final verticalPadding = compact ? 20.0 : 32.0;
                  final horizontalPadding = constraints.maxWidth < 400
                      ? 18.0
                      : 24.0;

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: math.max(
                          0,
                          constraints.maxHeight - verticalPadding * 2,
                        ),
                      ),
                      child: Center(
                        child: FadeTransition(
                          opacity: _fade,
                          child: SlideTransition(
                            position: _slide,
                            child: _HomeContent(
                              compact: compact,
                              onGetStarted: _handleGetStarted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.compact, required this.onGetStarted});

  final bool compact;
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 480),
      padding: EdgeInsets.fromLTRB(
        compact ? 24 : 36,
        compact ? 28 : 42,
        compact ? 24 : 36,
        compact ? 26 : 38,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(compact ? 28 : 34),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.10),
            blurRadius: 48,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ShopIcon(size: compact ? 84 : 104),
          SizedBox(height: compact ? 20 : 26),
          const _WelcomePill(),
          SizedBox(height: compact ? 12 : 16),
          Text(
            'Credit Bill System',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 29 : 35,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: AppColors.ink,
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            'Track customer credit, create bills in seconds, and keep every '
            'payment organised — all in one simple app.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 14 : 15,
              height: 1.6,
              fontWeight: FontWeight.w400,
              color: AppColors.muted,
            ),
          ),
          SizedBox(height: compact ? 22 : 30),
          _GetStartedButton(onPressed: onGetStarted),
          SizedBox(height: compact ? 14 : 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: Color(0xFF8A9DB1),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Your records stay private',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WelcomePill extends StatelessWidget {
  const _WelcomePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.tint,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.waving_hand_rounded,
            size: 15,
            color: AppColors.primaryDark,
          ),
          SizedBox(width: 7),
          Flexible(
            child: Text(
              'Welcome to your shop',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopIcon extends StatelessWidget {
  const _ShopIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final badgeSize = size * 0.32;

    return Semantics(
      label: 'Grocery shop icon',
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryLight,
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(size * 0.30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.32),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Icon(
                Icons.storefront_rounded,
                size: size * 0.46,
                color: Colors.white,
              ),
            ),
            Positioned(
              right: -size * 0.04,
              bottom: -size * 0.04,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: badgeSize * 0.56,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GetStartedButton extends StatelessWidget {
  const _GetStartedButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(18),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Get Started',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background();

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
            child: _Glow(
              color: AppColors.primaryLight,
              size: 340,
              opacity: 0.30,
            ),
          ),
          Positioned(
            bottom: -140,
            left: -120,
            child: _Glow(color: AppColors.primary, size: 380, opacity: 0.16),
          ),
          Positioned(
            top: 170,
            left: -70,
            child: _Glow(
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

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size, required this.opacity});

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
