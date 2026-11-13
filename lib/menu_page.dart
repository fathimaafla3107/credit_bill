import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_background.dart';
import 'app_theme.dart';
import 'app_widgets.dart';
import 'credit_sale_page.dart';
import 'customer_page.dart';
import 'dashboard_page.dart';
import 'payment_page.dart';
import 'statement_page.dart';

/// The main navigation hub of the Credit Bill System app.
///
/// Every option opens its dedicated screen. [onOptionSelected] can be used by
/// callers that want to handle navigation themselves.
class MenuPage extends StatelessWidget {
  const MenuPage({super.key, this.onOptionSelected});

  /// Called with the selected option name, for example `Customer`.
  final ValueChanged<String>? onOptionSelected;

  void _openDashboard(BuildContext context) {
    final callback = onOptionSelected;
    if (callback != null) {
      callback('Dashboard');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const DashboardPage()),
    );
  }

  void _openCustomers(BuildContext context) {
    final callback = onOptionSelected;
    if (callback != null) {
      callback('Customer');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const CustomerManagementPage(),
      ),
    );
  }

  void _openCreditSale(BuildContext context) {
    final callback = onOptionSelected;
    if (callback != null) {
      callback('Credit Sale');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const CreditSalePage()),
    );
  }

  void _openPayment(BuildContext context) {
    final callback = onOptionSelected;
    if (callback != null) {
      callback('Payment');
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => const PaymentPage()));
  }

  void _openStatement(BuildContext context) {
    final callback = onOptionSelected;
    if (callback != null) {
      callback('Statement');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const StatementPage()),
    );
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
            const Positioned.fill(child: AppBackground()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 700;
                  final horizontalPadding = constraints.maxWidth < 400
                      ? 18.0
                      : 24.0;

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      compact ? 12 : 18,
                      horizontalPadding,
                      32,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _MenuTopBar(
                              compact: compact,
                              onBack: () => Navigator.of(context).maybePop(),
                            ),
                            SizedBox(height: compact ? 20 : 28),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: _MenuPill(),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'What would you like to do?',
                              style: TextStyle(
                                fontSize: compact ? 27 : 31,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Choose an option below to manage your shop's "
                              'credit and billing.',
                              style: TextStyle(
                                fontSize: compact ? 13.5 : 14.5,
                                height: 1.55,
                                color: AppColors.muted,
                              ),
                            ),
                            SizedBox(height: compact ? 20 : 26),
                            _DashboardCard(
                              onTap: () => _openDashboard(context),
                            ),
                            SizedBox(height: compact ? 24 : 28),
                            const _QuickActionsLabel(),
                            const SizedBox(height: 14),
                            _MenuActionTile(
                              tileKey: const Key('customerOption'),
                              icon: Icons.people_alt_outlined,
                              title: 'Customer',
                              subtitle:
                                  'Add and manage your customer accounts.',
                              onTap: () => _openCustomers(context),
                            ),
                            const SizedBox(height: 12),
                            _MenuActionTile(
                              tileKey: const Key('creditSaleOption'),
                              icon: Icons.shopping_bag_outlined,
                              title: 'Credit Sale',
                              subtitle: 'Record a credit sale in a few taps.',
                              onTap: () => _openCreditSale(context),
                            ),
                            const SizedBox(height: 12),
                            _MenuActionTile(
                              tileKey: const Key('paymentOption'),
                              icon: Icons.payments_outlined,
                              title: 'Payment',
                              subtitle: 'Collect and track customer payments.',
                              onTap: () => _openPayment(context),
                            ),
                            const SizedBox(height: 12),
                            _MenuActionTile(
                              tileKey: const Key('statementOption'),
                              icon: Icons.description_outlined,
                              title: 'Statement',
                              subtitle: 'View and print customer statements.',
                              onTap: () => _openStatement(context),
                            ),
                          ],
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

class _MenuTopBar extends StatelessWidget {
  const _MenuTopBar({required this.compact, required this.onBack});

  final bool compact;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppBackButton(
          buttonKey: const Key('menuBackButton'),
          onPressed: onBack,
        ),
        const SizedBox(width: 12),
        Container(
          width: compact ? 38 : 42,
          height: compact ? 38 : 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryLight, AppColors.primary],
            ),
            borderRadius: BorderRadius.circular((compact ? 38 : 42) * 0.30),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.24),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.storefront_rounded,
            size: (compact ? 38 : 42) * 0.46,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Credit Bill System',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuPill extends StatelessWidget {
  const _MenuPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.tint,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.grid_view_rounded, size: 14, color: AppColors.primaryDark),
          SizedBox(width: 6),
          Text(
            'SHOP MENU',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: InkWell(
            key: const Key('dashboardOption'),
            onTap: onTap,
            child: Stack(
              children: [
                Positioned(
                  top: -38,
                  right: -24,
                  child: _CardDecoration(size: 130, opacity: 0.09),
                ),
                Positioned(
                  bottom: -56,
                  left: -28,
                  child: _CardDecoration(size: 150, opacity: 0.06),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: const Icon(
                          Icons.space_dashboard_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dashboard',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'View sales, credit and payment insights at a '
                              'glance.',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.5,
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardDecoration extends StatelessWidget {
  const _CardDecoration({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _QuickActionsLabel extends StatelessWidget {
  const _QuickActionsLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'QUICK ACTIONS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Divider(height: 1, thickness: 1, color: AppColors.border),
        ),
      ],
    );
  }
}

class _MenuActionTile extends StatelessWidget {
  const _MenuActionTile({
    required this.tileKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Key tileKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          key: tileKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.tint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 22, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.muted.withValues(alpha: 0.55),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
