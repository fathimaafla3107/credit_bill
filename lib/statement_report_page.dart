import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import 'app_background.dart';
import 'app_date_utils.dart';
import 'app_theme.dart';
import 'app_widgets.dart';
import 'currency_utils.dart';
import 'statement_data.dart';
import 'statement_pdf.dart';

const Color _paymentColor = Color(0xFF1E8E5A);
const Color _paymentTint = Color(0xFFE8F6EF);

/// A paper-like preview of a customer statement with a print action.
class StatementReportPage extends StatefulWidget {
  const StatementReportPage({super.key, required this.statement});

  final CustomerStatement statement;

  @override
  State<StatementReportPage> createState() => _StatementReportPageState();
}

class _StatementReportPageState extends State<StatementReportPage> {
  bool _printing = false;

  Future<void> _printReport() async {
    if (_printing) return;

    setState(() => _printing = true);

    try {
      final safeName = widget.statement.customer.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]+'),
        '-',
      );
      await Printing.layoutPdf(
        name: 'statement-$safeName.pdf',
        onLayout: (format) => buildStatementPdf(widget.statement, format),
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('Printing is not available right now. Please try again.');
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.ink,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF9CD0FF),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
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
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ReportTopBar(
                              compact: compact,
                              onBack: () => Navigator.of(context).maybePop(),
                            ),
                            SizedBox(height: compact ? 18 : 24),
                            _ReportSheet(statement: widget.statement),
                            SizedBox(height: compact ? 18 : 22),
                            SizedBox(
                              height: 54,
                              child: FilledButton.icon(
                                key: const Key('printReportButton'),
                                onPressed: _printing ? null : _printReport,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: AppColors.primary
                                      .withValues(alpha: 0.55),
                                  disabledForegroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                icon: _printing
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.print_rounded, size: 20),
                                label: Text(
                                  _printing
                                      ? 'Preparing report...'
                                      : 'Print report',
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Your device's print dialog also lets you save "
                              'the report as a PDF.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.45,
                                color: AppColors.muted,
                              ),
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

class _ReportTopBar extends StatelessWidget {
  const _ReportTopBar({required this.compact, required this.onBack});

  final bool compact;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppBackButton(
          buttonKey: const Key('statementReportBackButton'),
          onPressed: onBack,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statement report',
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
                'Preview and print a copy for your customer.',
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

class _ReportSheet extends StatelessWidget {
  const _ReportSheet({required this.statement});

  final CustomerStatement statement;

  @override
  Widget build(BuildContext context) {
    final firstDate = statement.firstDate;
    final lastDate = statement.lastDate;
    final period = firstDate == null || lastDate == null
        ? 'No transactions'
        : '${formatShortDate(firstDate)} – ${formatShortDate(lastDate)}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryLight, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CREDIT BILL SYSTEM',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Customer credit statement',
                      style: TextStyle(fontSize: 10.5, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          const Text(
            'CUSTOMER STATEMENT',
            style: TextStyle(
              fontSize: 18,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Prepared for ${statement.customer}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Statement date ${formatShortDate(DateTime.now())} · $period',
            style: const TextStyle(
              fontSize: 10.5,
              height: 1.4,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _ReportSummaryRow(
                  label: 'Total credit sales',
                  value: formatRupees(statement.totalCredit),
                  color: AppColors.primary,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: AppColors.border),
                ),
                _ReportSummaryRow(
                  label: 'Total payments',
                  value: formatRupees(statement.totalPayments),
                  color: _paymentColor,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: AppColors.border),
                ),
                _ReportSummaryRow(
                  label: 'Remaining balance',
                  value: formatRupees(statement.remainingBalance),
                  color: AppColors.primaryDark,
                  emphasize: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'TRANSACTION DETAILS',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppColors.muted,
                  ),
                ),
              ),
              Text(
                '${statement.lines.length} entries',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          if (statement.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'No transactions have been recorded for '
                '${statement.customer}.',
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.5,
                  color: AppColors.muted,
                ),
              ),
            )
          else
            for (var index = 0; index < statement.lines.length; index++) ...[
              _ReportTransactionRow(line: statement.lines[index]),
              if (index < statement.lines.length - 1)
                const Divider(height: 1, thickness: 1, color: AppColors.border),
            ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.tint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'REMAINING BALANCE',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                Text(
                  formatRupees(statement.remainingBalance),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Thank you for your business. Please contact the shop if you '
            'have any questions about this statement.',
            style: TextStyle(fontSize: 10, height: 1.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ReportSummaryRow extends StatelessWidget {
  const _ReportSummaryRow({
    required this.label,
    required this.value,
    required this.color,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: emphasize ? 11 : 10.5,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              color: emphasize ? AppColors.ink : AppColors.muted,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasize ? 15 : 12.5,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ReportTransactionRow extends StatelessWidget {
  const _ReportTransactionRow({required this.line});

  final StatementLine line;

  @override
  Widget build(BuildContext context) {
    final entry = line.entry;
    final isPayment = entry.isPayment;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isPayment ? _paymentTint : AppColors.tint,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              isPayment ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: 15,
              color: isPayment ? _paymentColor : AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.details,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${formatShortDate(entry.date)} · ${entry.typeLabel}',
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 9.5,
                    height: 1.35,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isPayment
                    ? '+${formatRupees(entry.amount)}'
                    : formatRupees(entry.amount),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isPayment ? _paymentColor : AppColors.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Bal. ${formatRupees(line.balanceAfter)}',
                style: const TextStyle(fontSize: 9, color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
