import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_background.dart';
import 'app_theme.dart';
import 'app_widgets.dart';
import 'currency_utils.dart';
import 'database_helper.dart';
import 'form_utils.dart';
import 'models.dart';

const Color _settledColor = Color(0xFF1E8E5A);

/// Customer management screen with search, add, edit, delete and details.
class CustomerManagementPage extends StatefulWidget {
  const CustomerManagementPage({super.key});

  @override
  State<CustomerManagementPage> createState() => _CustomerManagementPageState();
}

class _CustomerManagementPageState extends State<CustomerManagementPage> {
  final _searchController = TextEditingController();
  final List<Customer> _customers = [];
  bool _isLoading = true;

  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    try {
      final customers = await DatabaseHelper.instance.getCustomers();
      if (!mounted) return;
      setState(() {
        _customers
          ..clear()
          ..addAll(customers);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Could not load customers from the database.');
    }
  }

  double get _totalOutstanding =>
      _customers.fold(0, (total, customer) => total + customer.outstanding);

  List<_Customer> get _visibleCustomers {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _customers;

    return _customers.where((customer) {
      return customer.name.toLowerCase().contains(query) ||
          customer.phone.toLowerCase().contains(query) ||
          customer.email.toLowerCase().contains(query);
    }).toList();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  Future<void> _openCustomerForm({_Customer? customer}) async {
    final customerId =
        customer?.id ?? DateTime.now().microsecondsSinceEpoch.toString();

    final result = await showModalBottomSheet<_Customer>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _CustomerFormSheet(customer: customer, customerId: customerId),
    );

    if (!mounted || result == null) return;

    try {
      if (customer == null) {
        await DatabaseHelper.instance.insertCustomer(result);
      } else {
        await DatabaseHelper.instance.updateCustomer(result);
      }
      await _loadCustomers();
      if (!mounted) return;
      _showMessage(
        customer == null
            ? '${result.name} was added.'
            : '${result.name} was updated.',
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not save ${result.name}. Please try again.');
    }
  }

  Future<void> _showCustomerDetails(_Customer customer) async {
    final action = await showModalBottomSheet<_CustomerAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomerDetailsSheet(customer: customer),
    );

    if (!mounted) return;

    if (action == _CustomerAction.edit) {
      await _openCustomerForm(customer: customer);
    } else if (action == _CustomerAction.delete) {
      await _confirmDelete(customer);
    }
  }

  Future<void> _confirmDelete(_Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Delete customer?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          content: Text(
            '${customer.name} will be removed from your customer list. '
            'This cannot be undone.',
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.muted,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            TextButton(
              key: const Key('cancelDeleteButton'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirmDeleteButton'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    try {
      await DatabaseHelper.instance.deleteCustomer(customer.id);
      await _loadCustomers();
      if (!mounted) return;
      _showMessage('${customer.name} was deleted.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not delete ${customer.name}. Please try again.');
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
    final visibleCustomers = _visibleCustomers;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('addCustomerButton'),
          onPressed: () => _openCustomerForm(),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
          label: const Text(
            'Add Customer',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
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
                      112,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _CustomerTopBar(
                              compact: compact,
                              onBack: () => Navigator.of(context).maybePop(),
                              customerCount: _customers.length,
                              totalOutstanding: _totalOutstanding,
                            ),
                            SizedBox(height: compact ? 18 : 24),
                            TextField(
                              key: const Key('customerSearchField'),
                              controller: _searchController,
                              onChanged: (value) =>
                                  setState(() => _query = value),
                              textInputAction: TextInputAction.search,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.ink,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search by name, phone or email',
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                suffixIcon: _query.isEmpty
                                    ? null
                                    : IconButton(
                                        onPressed: _clearSearch,
                                        tooltip: 'Clear search',
                                        icon: Icon(
                                          Icons.close_rounded,
                                          size: 19,
                                          color: AppColors.muted.withValues(
                                            alpha: 0.75,
                                          ),
                                        ),
                                      ),
                                filled: true,
                                fillColor: AppColors.surface,
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.muted.withValues(
                                    alpha: 0.70,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 15,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.6,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: compact ? 20 : 24),
                            _CustomerListHeader(
                              label: _query.trim().isEmpty
                                  ? 'ALL CUSTOMERS'
                                  : 'SEARCH RESULTS',
                              count: visibleCustomers.length,
                            ),
                            const SizedBox(height: 12),
                            if (_isLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (visibleCustomers.isEmpty)
                              _EmptyCustomers(
                                hasQuery: _query.trim().isNotEmpty,
                                onClearSearch: _clearSearch,
                              )
                            else
                              Column(
                                children: [
                                  for (
                                    var index = 0;
                                    index < visibleCustomers.length;
                                    index++
                                  ) ...[
                                    _CustomerCard(
                                      customer: visibleCustomers[index],
                                      onTap: () => _showCustomerDetails(
                                        visibleCustomers[index],
                                      ),
                                    ),
                                    if (index < visibleCustomers.length - 1)
                                      const SizedBox(height: 12),
                                  ],
                                ],
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

class _CustomerTopBar extends StatelessWidget {
  const _CustomerTopBar({
    required this.compact,
    required this.onBack,
    required this.customerCount,
    required this.totalOutstanding,
  });

  final bool compact;
  final VoidCallback onBack;
  final int customerCount;
  final double totalOutstanding;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppBackButton(
          buttonKey: const Key('customersBackButton'),
          onPressed: onBack,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customers',
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
                '$customerCount customers · '
                '${formatRupees(totalOutstanding)} outstanding',
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

class _CustomerListHeader extends StatelessWidget {
  const _CustomerListHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.15,
              color: AppColors.primary,
            ),
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
            '$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer, required this.onTap});

  final _Customer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDues = customer.outstanding > 0;

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
          key: Key('customerCard-${customer.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.tint,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    customer.initials,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        customer.phone,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasDues ? formatRupees(customer.outstanding) : 'Settled',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: hasDues ? AppColors.ink : _settledColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasDues ? 'Outstanding' : 'No dues',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCustomers extends StatelessWidget {
  const _EmptyCustomers({required this.hasQuery, required this.onClearSearch});

  final bool hasQuery;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
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
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: AppColors.tint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No customers found',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasQuery
                ? 'Try a different name, phone or email address.'
                : 'Add your first customer to start tracking credit.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: AppColors.muted,
            ),
          ),
          if (hasQuery) ...[
            const SizedBox(height: 14),
            TextButton(
              key: const Key('clearCustomerSearchButton'),
              onPressed: onClearSearch,
              child: const Text('Clear search'),
            ),
          ],
        ],
      ),
    );
  }
}

enum _CustomerAction { edit, delete }

class _CustomerDetailsSheet extends StatelessWidget {
  const _CustomerDetailsSheet({required this.customer});

  final _Customer customer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: _SheetHandle()),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Customer details',
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.tint,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        customer.initials,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      customer.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Customer',
                      style: TextStyle(fontSize: 11.5, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _DetailRow(
                icon: Icons.phone_outlined,
                label: 'Phone number',
                value: customer.phone,
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.mail_outline_rounded,
                label: 'Email address',
                value: customer.email.isEmpty ? 'Not provided' : customer.email,
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: customer.address.isEmpty
                    ? 'Not provided'
                    : customer.address,
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Outstanding balance',
                value: formatRupees(customer.outstanding),
                valueColor: customer.outstanding > 0
                    ? AppColors.ink
                    : _settledColor,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        key: const Key('deleteCustomerButton'),
                        onPressed: () =>
                            Navigator.of(context).pop(_CustomerAction.delete),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: BorderSide(
                            color: AppColors.danger.withValues(alpha: 0.35),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('Delete'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: FilledButton(
                        key: const Key('editCustomerButton'),
                        onPressed: () =>
                            Navigator.of(context).pop(_CustomerAction.edit),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('Edit'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.tint,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 17, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.ink,
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

class _CustomerFormSheet extends StatefulWidget {
  const _CustomerFormSheet({required this.customerId, this.customer});

  final String customerId;
  final _Customer? customer;

  @override
  State<_CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends State<_CustomerFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _outstandingController;

  @override
  void initState() {
    super.initState();
    final customer = widget.customer;
    _nameController = TextEditingController(text: customer?.name ?? '');
    _phoneController = TextEditingController(text: customer?.phone ?? '');
    _emailController = TextEditingController(text: customer?.email ?? '');
    _addressController = TextEditingController(text: customer?.address ?? '');
    _outstandingController = TextEditingController(
      text: (customer?.outstanding ?? 0) > 0
          ? customer!.outstanding.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _outstandingController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final outstanding =
        double.tryParse(
          _outstandingController.text.trim().replaceAll(',', ''),
        ) ??
        0;

    Navigator.of(context).pop(
      _Customer(
        id: widget.customerId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        outstanding: outstanding < 0 ? 0 : outstanding,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: _SheetHandle()),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit customer' : 'Add customer',
                          style: const TextStyle(
                            fontSize: 20,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('closeCustomerFormButton'),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Close',
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEditing
                        ? 'Update contact details or adjust the outstanding '
                              'balance.'
                        : 'Add contact details and an opening balance if any.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    key: const Key('customerNameField'),
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: appFieldDecoration(
                      label: 'Full name',
                      hint: 'e.g. Ravi Kumar',
                      icon: Icons.person_outline_rounded,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 2) {
                        return 'Enter the customer name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('customerPhoneField'),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: appFieldDecoration(
                      label: 'Phone number',
                      hint: 'e.g. 98765 43210',
                      icon: Icons.phone_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a phone number';
                      }
                      if (!isValidPhoneNumber(value)) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('customerEmailField'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: appFieldDecoration(
                      label: 'Email (optional)',
                      hint: 'e.g. ravi@example.com',
                      icon: Icons.mail_outline_rounded,
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isNotEmpty && !isValidEmail(email)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('customerAddressField'),
                    controller: _addressController,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    maxLines: 2,
                    decoration: appFieldDecoration(
                      label: 'Address (optional)',
                      hint: 'Shop or home address',
                      icon: Icons.location_on_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('customerOutstandingField'),
                    controller: _outstandingController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: appFieldDecoration(
                      label: 'Outstanding (₹)',
                      hint: 'e.g. 2500',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return null;
                      final amount = double.tryParse(text.replaceAll(',', ''));
                      if (amount == null || amount < 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      key: const Key('saveCustomerButton'),
                      onPressed: _submit,
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
                      child: Text(isEditing ? 'Save changes' : 'Save customer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }
}

typedef _Customer = Customer;
