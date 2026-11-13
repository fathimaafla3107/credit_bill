import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_background.dart';
import 'app_date_utils.dart';
import 'app_theme.dart';
import 'app_widgets.dart';
import 'currency_utils.dart';
import 'database_helper.dart';
import 'form_utils.dart';
import 'models.dart';

const Color _paymentColor = Color(0xFF1E8E5A);
const Color _paymentTint = Color(0xFFE8F6EF);
const Color _paymentBorder = Color(0xFFCDEBDD);

/// Records a payment against a customer's outstanding balance.
class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _customerFieldKey = GlobalKey<FormFieldState<String>>();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();

  String? _selectedCustomerId;
  DateTime _selectedDate = DateTime.now();
  List<Customer> _customers = [];
  List<Payment> _payments = [];
  final Map<String, double> _balances = {};
  bool _isLoading = true;
  bool _isSaving = false;

  Customer? get _selectedCustomer {
    for (final customer in _customers) {
      if (customer.id == _selectedCustomerId) return customer;
    }
    return null;
  }

  double get _outstandingBalance {
    final customer = _selectedCustomer;
    if (customer == null) return 0;
    return _balances[customer.id] ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _dateController.text = formatShortDate(_selectedDate);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final customers = await DatabaseHelper.instance.getCustomers();
      final payments = await DatabaseHelper.instance.getPayments();
      if (!mounted) return;
      setState(() {
        _customers = customers;
        _payments = payments;
        _balances
          ..clear()
          ..addEntries(
            customers.map(
              (customer) => MapEntry(customer.id, customer.outstanding),
            ),
          );
        if (_selectedCustomerId != null &&
            !_customers.any((customer) => customer.id == _selectedCustomerId)) {
          _selectedCustomerId = null;
        }
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Could not load payments from the database.');
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      helpText: 'Select payment date',
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedDate = picked;
      _dateController.text = formatShortDate(picked);
    });
  }

  Future<void> _savePayment() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSaving) return;

    final customer = _selectedCustomer;
    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', ''),
    );
    if (customer == null || amount == null || amount <= 0) return;

    final outstanding = _balances[customer.id] ?? 0;
    if (outstanding <= 0 || amount > outstanding) return;

    setState(() => _isSaving = true);

    try {
      final saved = await DatabaseHelper.instance.recordPayment(
        Payment(
          customerId: customer.id,
          customerName: customer.name,
          amount: amount,
          date: _selectedDate,
        ),
      );

      if (!saved) {
        if (!mounted) return;
        _showMessage('Payment could not be recorded. Check the balance.');
        return;
      }

      await _loadData();
      if (!mounted) return;

      setState(() => _amountController.clear());
      _showMessage(
        '${formatRupees(amount)} payment recorded for ${customer.name}.',
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not save the payment. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
                Icons.check_circle_rounded,
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
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _PaymentTopBar(
                              compact: compact,
                              onBack: () => Navigator.of(context).maybePop(),
                            ),
                            SizedBox(height: compact ? 18 : 24),
                            const _PaymentIntroCard(),
                            SizedBox(height: compact ? 18 : 22),
                            _PaymentFormCard(
                              formKey: _formKey,
                              customerFieldKey: _customerFieldKey,
                              customers: _customers,
                              amountController: _amountController,
                              dateController: _dateController,
                              selectedCustomer: _selectedCustomer?.name,
                              outstandingBalance: _outstandingBalance,
                              onCustomerChanged: (value) {
                                setState(() => _selectedCustomerId = value);
                              },
                              onPickDate: _pickDate,
                              onSave: _savePayment,
                              isSaving: _isSaving,
                            ),
                            SizedBox(height: compact ? 24 : 28),
                            _RecentPaymentsSection(
                              payments: _payments,
                              isLoading: _isLoading,
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

class _PaymentTopBar extends StatelessWidget {
  const _PaymentTopBar({required this.compact, required this.onBack});

  final bool compact;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppBackButton(
          buttonKey: const Key('paymentBackButton'),
          onPressed: onBack,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment',
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
                'Record a customer payment and update their balance.',
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

class _PaymentIntroCard extends StatelessWidget {
  const _PaymentIntroCard();

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
              top: -40,
              right: -30,
              child: _PaymentBubble(size: 130, opacity: 0.09),
            ),
            const Positioned(
              bottom: -50,
              left: -30,
              child: _PaymentBubble(size: 150, opacity: 0.06),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
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
                      Icons.payments_rounded,
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
                          'Record a payment',
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Reduce a customer's outstanding balance and keep "
                          'their account up to date.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
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

class _PaymentBubble extends StatelessWidget {
  const _PaymentBubble({required this.size, required this.opacity});

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

class _PaymentFormCard extends StatelessWidget {
  const _PaymentFormCard({
    required this.formKey,
    required this.customerFieldKey,
    required this.customers,
    required this.amountController,
    required this.dateController,
    required this.selectedCustomer,
    required this.outstandingBalance,
    required this.onCustomerChanged,
    required this.onPickDate,
    required this.onSave,
    required this.isSaving,
  });

  final GlobalKey<FormState> formKey;
  final GlobalKey<FormFieldState<String>> customerFieldKey;
  final List<Customer> customers;
  final TextEditingController amountController;
  final TextEditingController dateController;
  final String? selectedCustomer;
  final double outstandingBalance;
  final ValueChanged<String?> onCustomerChanged;
  final VoidCallback onPickDate;
  final VoidCallback onSave;
  final bool isSaving;

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
      child: Form(
        key: formKey,
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
                    Icons.payments_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Payment details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            KeyedSubtree(
              key: const Key('paymentCustomerField'),
              child: DropdownButtonFormField<String>(
                key: customerFieldKey,
                initialValue: null,
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
                  for (final customer in customers)
                    DropdownMenuItem<String>(
                      value: customer.id,
                      child: Text(
                        customer.name,
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Select a customer';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),
            _OutstandingSummary(
              customer: selectedCustomer,
              outstanding: outstandingBalance,
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('paymentAmountField'),
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: appFieldDecoration(
                label: 'Payment amount (₹)',
                hint: 'e.g. 2000',
                icon: Icons.currency_rupee_rounded,
              ),
              onFieldSubmitted: (_) => onSave(),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Enter the payment amount';

                final amount = double.tryParse(text);
                if (amount == null || amount <= 0) {
                  return 'Enter a valid amount';
                }
                if (selectedCustomer != null && outstandingBalance <= 0) {
                  return 'This customer has no outstanding balance';
                }
                if (selectedCustomer != null && amount > outstandingBalance) {
                  return 'Payment cannot exceed the outstanding balance';
                }
                return null;
              },
            ),
            if (selectedCustomer != null && outstandingBalance > 0)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const Key('payFullButton'),
                  onPressed: () {
                    final value = outstandingBalance;
                    amountController.text = value == value.roundToDouble()
                        ? value.toStringAsFixed(0)
                        : value.toString();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: _paymentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: const Text('Pay full'),
                ),
              ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('paymentDateField'),
              controller: dateController,
              readOnly: true,
              showCursor: false,
              onTap: onPickDate,
              decoration: appFieldDecoration(
                label: 'Payment date',
                hint: 'Select a date',
                icon: Icons.event_outlined,
                suffixIcon: const Icon(
                  Icons.calendar_month_rounded,
                  size: 19,
                  color: AppColors.primary,
                ),
              ),
              validator: (_) {
                if (dateController.text.trim().isEmpty) {
                  return 'Select a payment date';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                key: const Key('savePaymentButton'),
                onPressed: isSaving ? null : onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: Text(isSaving ? 'Saving…' : 'Save payment'),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Payments reduce the customer's outstanding balance.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutstandingSummary extends StatelessWidget {
  const _OutstandingSummary({
    required this.customer,
    required this.outstanding,
  });

  final String? customer;
  final double outstanding;

  @override
  Widget build(BuildContext context) {
    final hasCustomer = customer != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasCustomer ? _paymentTint : AppColors.fieldFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasCustomer ? _paymentBorder : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: hasCustomer
                  ? Colors.white.withValues(alpha: 0.72)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 18,
              color: hasCustomer ? _paymentColor : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Outstanding balance',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 3),
                if (!hasCustomer)
                  const Text(
                    'Choose a customer',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  )
                else ...[
                  Text(
                    formatRupees(outstanding),
                    style: TextStyle(
                      fontSize: 21,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: outstanding > 0 ? AppColors.ink : _paymentColor,
                    ),
                  ),
                  if (outstanding <= 0) ...[
                    const SizedBox(height: 2),
                    const Text(
                      'All dues cleared',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: _paymentColor,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentPaymentsSection extends StatelessWidget {
  const _RecentPaymentsSection({
    required this.payments,
    required this.isLoading,
  });

  final List<Payment> payments;
  final bool isLoading;

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
                    'Recent payments',
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
                    'Your latest customer payments appear here.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _paymentTint,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '${payments.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _paymentColor,
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
          child: Column(
            children: [
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                for (var index = 0; index < payments.length; index++) ...[
                  _PaymentRow(payment: payments[index]),
                  if (index < payments.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 70,
                      endIndent: 16,
                      color: AppColors.border,
                    ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _paymentTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.south_west_rounded,
              size: 19,
              color: _paymentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Payment · ${formatRelativeDate(payment.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '+${formatRupees(payment.amount)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: _paymentColor,
            ),
          ),
        ],
      ),
    );
  }
}
