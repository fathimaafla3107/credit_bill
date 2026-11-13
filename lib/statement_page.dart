import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_background.dart';
import 'app_date_utils.dart';
import 'app_theme.dart';
import 'app_widgets.dart';
import 'currency_utils.dart';
import 'customer_accounts.dart';
import 'form_utils.dart';
import 'statement_data.dart';
import 'statement_report_page.dart';

const Color _paymentColor = Color(0xFF1E8E5A);
const Color _paymentTint = Color(0xFFE8F6EF);

/// Shows a customer's credit sales, payments and remaining balance.
class StatementPage extends StatefulWidget {
  const StatementPage({super.key});

  @override
  State<StatementPage> createState() => _StatementPageState();
}

class _StatementPageState extends State<StatementPage> {
  late String _selectedCustomer = sampleCustomerAccounts.first.name;

  CustomerStatement get _statement => buildCustomerStatement(_selectedCustomer);

  void _openReport() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StatementReportPage(statement: _statement),
      ),
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
                        constraints: const BoxConstraints(maxWidth: 860),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _StatementTopBar(
                              compact: compact,
                              onBack: () => Navigator.of(context).maybePop(),
                            ),
                            SizedBox(height: compact ? 18 : 24),
                            _CustomerSelectorCard(
                              selectedCustomer: _selectedCustomer,
                              onCustomerChanged: (value) {
                                if (value == null) return;
                                setState(() => _selectedCustomer = value);
                              },
                              onPrint: _openReport,
                            ),
                            SizedBox(height: compact ? 18 : 22),
                            _StatementSummaryCard(statement: _statement),
                            SizedBox(height: compact ? 24 : 28),
                            _TransactionHistorySection(statement: _statement),
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

class _StatementTopBar extends StatelessWidget {
  const _StatementTopBar({required this.compact, required this.onBack});

  final bool compact;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppBackButton(
          buttonKey: const Key('statementBackButton'),
          onPressed: onBack,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statement',
                style: TextStyle(
                  fontSize: compact ? 22 : 26,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Review a customer’s credit and payment history.',
                style: TextStyle(
                  fontSize: compact ? 11.5 : 12.5,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CustomerSelectorCard extends StatelessWidget {
  const _CustomerSelectorCard({
    required this.selectedCustomer,
    required this.onCustomerChanged,
    required this.onPrint,
  });

  final String selectedCustomer;
  final ValueChanged<String?> onCustomerChanged;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.tint,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer statement',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Choose a customer to generate their statement.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 560;

              final customerField = KeyedSubtree(
                key: const Key('statementCustomerField'),
                child: DropdownButtonFormField<String>(
                  initialValue: selectedCustomer,
                  isExpanded: true,
                  decoration: appFieldDecoration(
                    label: 'Customer',
                    hint: '',
                    icon: Icons.person_outline_rounded,
                  ),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.muted,
                  ),
                  dropdownColor: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  menuMaxHeight: 320,
                  items: [
                    for (final account in sampleCustomerAccounts)
                      DropdownMenuItem<String>(
                        value: account.name,
                        child: Text(
                          account.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                  ],
                  onChanged: onCustomerChanged,
                ),
              );

              final printButton = SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  key: const Key('printStatementButton'),
                  onPressed: onPrint,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    backgroundColor: AppColors.tint.withValues(alpha: 0.5),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.24),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.print_outlined, size: 19),
                  label: const Text('Print report'),
                ),
              );

              if (wide) {
                return Row(
                  children: [
                    Expanded(child: customerField),
                    const SizedBox(width: 14),
                    SizedBox(width: 190, child: printButton),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  customerField,
                  const SizedBox(height: 14),
                  printButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatementSummaryCard extends StatelessWidget {
  const _StatementSummaryCard({required this.statement});

  final CustomerStatement statement;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -42,
              right: -34,
              child: _SummaryBubble(size: 140, opacity: 0.08),
            ),
            const Positioned(
              bottom: -52,
              left: -34,
              child: _SummaryBubble(size: 150, opacity: 0.05),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'OUTSTANDING BALANCE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: Color(0xBFFFFFFF),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: double.infinity,
                              child: FittedBox(
                                alignment: Alignment.centerLeft,
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  formatRupees(statement.remainingBalance),
                                  key: const Key('statementBalance'),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    height: 1.05,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.9,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${statement.customer} · As of '
                              '${formatShortDate(DateTime.now())}',
                              maxLines: 2,
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.4,
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                            if (statement.remainingBalance <= 0) ...[
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 13,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'All dues cleared',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryStat(
                          label: 'Credit sales',
                          value: formatRupees(statement.totalCredit),
                          valueKey: const Key('statementCreditTotal'),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 34,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                      Expanded(
                        child: _SummaryStat(
                          label: 'Payments',
                          value: formatRupees(statement.totalPayments),
                          valueKey: const Key('statementPaymentTotal'),
                        ),
                      ),
                    ],
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

class _SummaryBubble extends StatelessWidget {
  const _SummaryBubble({required this.size, required this.opacity});

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

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value, this.valueKey});

  final String label;
  final String value;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: Colors.white.withValues(alpha: 0.68),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              key: valueKey,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TransactionHistorySection extends StatelessWidget {
  const _TransactionHistorySection({required this.statement});

  final CustomerStatement statement;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction history',
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Credit sales and payments, oldest first.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.tint,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '${statement.lines.length} entries',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: statement.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 34,
                        color: AppColors.muted,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No transactions yet',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Credit sales and payments for this customer '
                        'will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.45,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (
                      var index = 0;
                      index < statement.lines.length;
                      index++
                    ) ...[
                      _LedgerRow(line: statement.lines[index]),
                      if (index < statement.lines.length - 1)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          indent: 68,
                          endIndent: 16,
                          color: AppColors.border,
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.line});

  final StatementLine line;

  @override
  Widget build(BuildContext context) {
    final entry = line.entry;
    final isPayment = entry.isPayment;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPayment ? _paymentTint : AppColors.tint,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              isPayment
                  ? Icons.south_west_rounded
                  : Icons.shopping_bag_outlined,
              size: 18,
              color: isPayment ? _paymentColor : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        entry.details,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isPayment
                          ? '+${formatRupees(entry.amount)}'
                          : formatRupees(entry.amount),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isPayment ? _paymentColor : AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.typeLabel} · ${formatShortDate(entry.date)}',
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Balance ${formatRupees(line.balanceAfter)}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
