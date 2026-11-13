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

/// Records a new credit sale against a customer's account.
class CreditSalePage extends StatefulWidget {
  const CreditSalePage({super.key});

  @override
  State<CreditSalePage> createState() => _CreditSalePageState();
}

class _CreditSalePageState extends State<CreditSalePage> {
  final _formKey = GlobalKey<FormState>();
  final _customerFieldKey = GlobalKey<FormFieldState<String>>();
  final _productController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();

  String? _selectedCustomerId;
  DateTime _selectedDate = DateTime.now();
  List<Customer> _customers = [];
  List<CreditSale> _sales = [];
  bool _isLoading = true;
  bool _isSaving = false;

  Customer? get _selectedCustomer {
    for (final customer in _customers) {
      if (customer.id == _selectedCustomerId) return customer;
    }
    return null;
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
      final sales = await DatabaseHelper.instance.getCreditSales();
      if (!mounted) return;
      setState(() {
        _customers = customers;
        _sales = sales;
        if (_selectedCustomerId != null &&
            !_customers.any((customer) => customer.id == _selectedCustomerId)) {
          _selectedCustomerId = null;
        }
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Could not load credit sales from the database.');
    }
  }

  @override
  void dispose() {
    _productController.dispose();
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
      helpText: 'Select sale date',
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedDate = picked;
      _dateController.text = formatShortDate(picked);
    });
  }

  Future<void> _saveSale() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSaving) return;

    final customer = _selectedCustomer;
    final date = _selectedDate;
    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', ''),
    );
    final product = _productController.text.trim();

    if (customer == null || amount == null || amount <= 0 || product.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await DatabaseHelper.instance.insertCreditSale(
        CreditSale(
          customerId: customer.id,
          customerName: customer.name,
          product: product,
          amount: amount,
          date: date,
        ),
      );
      await _loadData();
      if (!mounted) return;

      _formKey.currentState?.reset();
      setState(() {
        _selectedCustomerId = null;
        _selectedDate = DateTime.now();
        _productController.clear();
        _amountController.clear();
        _dateController.text = formatShortDate(_selectedDate);
      });

      _showMessage(
        '${formatRupees(amount)} credit sale saved for ${customer.name}.',
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not save the credit sale. Please try again.');
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
                            _CreditSaleTopBar(
                              compact: compact,
                              onBack: () => Navigator.of(context).maybePop(),
                            ),
                            SizedBox(height: compact ? 18 : 24),
                            const _SaleIntroCard(),
                            SizedBox(height: compact ? 18 : 22),
                            _SaleFormCard(
                              formKey: _formKey,
                              customerFieldKey: _customerFieldKey,
                              customers: _customers,
                              productController: _productController,
                              amountController: _amountController,
                              dateController: _dateController,
                              onCustomerChanged: (value) {
                                setState(() => _selectedCustomerId = value);
                              },
                              onPickDate: _pickDate,
                              onSave: _saveSale,
                              isSaving: _isSaving,
                            ),
                            SizedBox(height: compact ? 24 : 28),
                            _RecentSalesSection(
                              sales: _sales,
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

class _CreditSaleTopBar extends StatelessWidget {
  const _CreditSaleTopBar({required this.compact, required this.onBack});

  final bool compact;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppBackButton(
          buttonKey: const Key('creditSaleBackButton'),
          onPressed: onBack,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Credit Sale',
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
                'Record a new sale against customer credit.',
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

class _SaleIntroCard extends StatelessWidget {
  const _SaleIntroCard();

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
              child: _SaleBubble(size: 130, opacity: 0.09),
            ),
            const Positioned(
              bottom: -50,
              left: -30,
              child: _SaleBubble(size: 150, opacity: 0.06),
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
                      Icons.receipt_long_rounded,
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
                          'New credit sale',
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
                          "The amount is added to the customer's "
                          'outstanding balance.',
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

class _SaleBubble extends StatelessWidget {
  const _SaleBubble({required this.size, required this.opacity});

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

class _SaleFormCard extends StatelessWidget {
  const _SaleFormCard({
    required this.formKey,
    required this.customerFieldKey,
    required this.customers,
    required this.productController,
    required this.amountController,
    required this.dateController,
    required this.onCustomerChanged,
    required this.onPickDate,
    required this.onSave,
    required this.isSaving,
  });

  final GlobalKey<FormState> formKey;
  final GlobalKey<FormFieldState<String>> customerFieldKey;
  final List<Customer> customers;
  final TextEditingController productController;
  final TextEditingController amountController;
  final TextEditingController dateController;
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
                    Icons.edit_note_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Sale details',
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
              key: const Key('creditSaleCustomerField'),
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
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('creditSaleProductField'),
              controller: productController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: appFieldDecoration(
                label: 'Product name',
                hint: 'e.g. Basmati rice 25 kg',
                icon: Icons.inventory_2_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter the product name';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('creditSaleAmountField'),
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: appFieldDecoration(
                label: 'Amount (₹)',
                hint: 'e.g. 4500',
                icon: Icons.account_balance_wallet_outlined,
              ),
              onFieldSubmitted: (_) => onSave(),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Enter the amount';
                final amount = double.tryParse(text);
                if (amount == null || amount <= 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('creditSaleDateField'),
              controller: dateController,
              readOnly: true,
              showCursor: false,
              onTap: onPickDate,
              decoration: appFieldDecoration(
                label: 'Sale date',
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
                  return 'Select a sale date';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                key: const Key('saveCreditSaleButton'),
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
                label: Text(isSaving ? 'Saving…' : 'Save sale'),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "The sale will be added to the customer's outstanding balance.",
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

class _RecentSalesSection extends StatelessWidget {
  const _RecentSalesSection({required this.sales, required this.isLoading});

  final List<CreditSale> sales;
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
                    'Recent credit sales',
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
                    'Your latest credit sales appear here.',
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
                '${sales.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
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
                for (var index = 0; index < sales.length; index++) ...[
                  _SaleRow(sale: sales[index]),
                  if (index < sales.length - 1)
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

class _SaleRow extends StatelessWidget {
  const _SaleRow({required this.sale});

  final CreditSale sale;

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
              color: AppColors.tint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 19,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.customerName,
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
                  '${sale.product} · ${formatRelativeDate(sale.date)}',
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
            formatRupees(sale.amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
