import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:credit_bill_system/customer_accounts.dart';
import 'package:credit_bill_system/database_helper.dart';
import 'package:credit_bill_system/main.dart';
import 'package:credit_bill_system/statement_data.dart';
import 'package:credit_bill_system/statement_pdf.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const CreditBillApp());
  await tester.pumpAndSettle();
}

Future<void> _openRegister(
  WidgetTester tester, {
  Size size = const Size(430, 950),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await _pumpApp(tester);

  final createAccount = find.byKey(const Key('createAccountButton'));
  await tester.ensureVisible(createAccount);
  await tester.pumpAndSettle();
  await tester.tap(createAccount);
  await tester.pumpAndSettle();
}

Future<void> _fillRegisterForm(
  WidgetTester tester, {
  String confirmPassword = 'secret123',
}) async {
  await tester.enterText(
    find.byKey(const Key('registerNameField')),
    'Ravi Kumar',
  );
  await tester.enterText(
    find.byKey(const Key('registerEmailField')),
    'ravi@shop.com',
  );
  await tester.enterText(
    find.byKey(const Key('registerPhoneField')),
    '9876543210',
  );
  await tester.enterText(
    find.byKey(const Key('registerPasswordField')),
    'secret123',
  );
  await tester.enterText(
    find.byKey(const Key('registerConfirmPasswordField')),
    confirmPassword,
  );
}

Future<void> _openMenu(
  WidgetTester tester, {
  Size size = const Size(430, 950),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await _pumpApp(tester);

  await tester.enterText(find.byKey(const Key('emailField')), 'owner@shop.com');
  await tester.enterText(find.byKey(const Key('passwordField')), 'secret123');

  final loginButton = find.byKey(const Key('loginButton'));
  await tester.ensureVisible(loginButton);
  await tester.pumpAndSettle();
  await tester.tap(loginButton);
  await tester.pumpAndSettle();

  final getStarted = find.text('Get Started');
  await tester.ensureVisible(getStarted);
  await tester.pumpAndSettle();
  await tester.tap(getStarted);
  await tester.pumpAndSettle();
}

Future<void> _openDashboard(
  WidgetTester tester, {
  Size size = const Size(430, 950),
}) async {
  await _openMenu(tester, size: size);

  final dashboard = find.byKey(const Key('dashboardOption'));
  await tester.ensureVisible(dashboard);
  await tester.pumpAndSettle();
  await tester.tap(dashboard);
  await tester.pumpAndSettle();
}

Future<void> _openCustomers(
  WidgetTester tester, {
  Size size = const Size(430, 950),
}) async {
  await _openMenu(tester, size: size);

  final customer = find.byKey(const Key('customerOption'));
  await tester.ensureVisible(customer);
  await tester.pumpAndSettle();
  await tester.tap(customer);
  await tester.pumpAndSettle();
}

Future<void> _openCreditSale(
  WidgetTester tester, {
  Size size = const Size(430, 950),
}) async {
  await _openMenu(tester, size: size);

  final creditSale = find.byKey(const Key('creditSaleOption'));
  await tester.ensureVisible(creditSale);
  await tester.pumpAndSettle();
  await tester.tap(creditSale);
  await tester.pumpAndSettle();
}

Future<void> _openPayment(
  WidgetTester tester, {
  Size size = const Size(430, 950),
}) async {
  await _openMenu(tester, size: size);

  final payment = find.byKey(const Key('paymentOption'));
  await tester.ensureVisible(payment);
  await tester.pumpAndSettle();
  await tester.tap(payment);
  await tester.pumpAndSettle();
}

Future<void> _openStatement(
  WidgetTester tester, {
  Size size = const Size(430, 950),
}) async {
  await _openMenu(tester, size: size);

  final statement = find.byKey(const Key('statementOption'));
  await tester.ensureVisible(statement);
  await tester.pumpAndSettle();
  await tester.tap(statement);
  await tester.pumpAndSettle();
}

String _shortDateLabel(DateTime date) {
  const monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day.toString().padLeft(2, '0')} '
      '${monthNames[date.month - 1]} ${date.year}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  setUp(() async {
    DatabaseHelper.instance.useInMemoryDatabaseForTesting();
    await DatabaseHelper.instance.resetDatabaseForTesting();
  });

  testWidgets('login page shows all required controls', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('Credit Bill System'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('passwordField')), findsOneWidget);
    expect(find.byKey(const Key('loginButton')), findsOneWidget);
    expect(find.byKey(const Key('forgotPasswordButton')), findsOneWidget);
    expect(find.byKey(const Key('createAccountButton')), findsOneWidget);
  });

  testWidgets('login validates the required fields', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pump();

    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('valid credentials open the home page', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await tester.enterText(
      find.byKey(const Key('emailField')),
      'owner@shop.com',
    );
    await tester.enterText(find.byKey(const Key('passwordField')), 'secret123');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to your shop'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.byKey(const Key('loginButton')), findsNothing);
  });

  testWidgets('forgot password opens the reset dialog and sends a link', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('forgotPasswordButton')));
    await tester.pumpAndSettle();

    expect(find.text('Reset your password'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('resetEmailField')),
      'owner@shop.com',
    );
    await tester.tap(find.byKey(const Key('sendResetLinkButton')));
    await tester.pumpAndSettle();

    expect(find.textContaining('password reset link'), findsOneWidget);
  });

  testWidgets('create account opens the register page with every field', (
    WidgetTester tester,
  ) async {
    await _openRegister(tester);

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.byKey(const Key('registerNameField')), findsOneWidget);
    expect(find.byKey(const Key('registerEmailField')), findsOneWidget);
    expect(find.byKey(const Key('registerPhoneField')), findsOneWidget);
    expect(find.byKey(const Key('registerPasswordField')), findsOneWidget);
    expect(
      find.byKey(const Key('registerConfirmPasswordField')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('registerButton')), findsOneWidget);
    expect(find.byKey(const Key('signInLink')), findsOneWidget);
  });

  testWidgets('register validates the required fields', (
    WidgetTester tester,
  ) async {
    await _openRegister(tester);

    await tester.tap(find.byKey(const Key('registerButton')));
    await tester.pump();

    expect(find.text('Enter your full name'), findsOneWidget);
    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Enter your phone number'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(find.text('Confirm your password'), findsOneWidget);
  });

  testWidgets('register rejects mismatched passwords', (
    WidgetTester tester,
  ) async {
    await _openRegister(tester);
    await _fillRegisterForm(tester, confirmPassword: 'secret124');

    await tester.tap(find.byKey(const Key('registerButton')));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(find.byKey(const Key('registerButton')), findsOneWidget);
  });

  testWidgets('registering opens the home page', (WidgetTester tester) async {
    await _openRegister(tester);
    await _fillRegisterForm(tester);

    await tester.tap(find.byKey(const Key('registerButton')));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to your shop'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.byKey(const Key('registerButton')), findsNothing);
  });

  testWidgets('sign in link returns to the login page', (
    WidgetTester tester,
  ) async {
    await _openRegister(tester);

    await tester.tap(find.byKey(const Key('signInLink')));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byKey(const Key('loginButton')), findsOneWidget);
  });

  testWidgets('login page fits a small phone screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpApp(tester);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('loginButton')), findsOneWidget);
  });

  testWidgets('login page uses the two-panel layout on wide screens', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpApp(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Track customer credit with ease'), findsOneWidget);
    expect(find.byKey(const Key('loginButton')), findsOneWidget);
  });

  testWidgets('register page fits a small phone screen', (
    WidgetTester tester,
  ) async {
    await _openRegister(tester, size: const Size(320, 480));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('registerButton')), findsOneWidget);
  });

  testWidgets('register page uses the two-panel layout on wide screens', (
    WidgetTester tester,
  ) async {
    await _openRegister(tester, size: const Size(1280, 900));

    expect(tester.takeException(), isNull);
    expect(find.text('Track customer credit with ease'), findsOneWidget);
    expect(find.byKey(const Key('registerButton')), findsOneWidget);
  });

  testWidgets('menu page shows all five options', (WidgetTester tester) async {
    await _openMenu(tester);

    expect(find.text('What would you like to do?'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Credit Sale'), findsOneWidget);
    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('Statement'), findsOneWidget);
  });

  testWidgets('menu back button returns to the home page', (
    WidgetTester tester,
  ) async {
    await _openMenu(tester);

    await tester.tap(find.byKey(const Key('menuBackButton')));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to your shop'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('every menu destination opens and returns to the menu', (
    WidgetTester tester,
  ) async {
    await _openMenu(tester);

    final destinations = [
      (
        option: 'dashboardOption',
        back: 'dashboardBackButton',
        title: 'Dashboard',
      ),
      (
        option: 'customerOption',
        back: 'customersBackButton',
        title: 'Customers',
      ),
      (
        option: 'creditSaleOption',
        back: 'creditSaleBackButton',
        title: 'Credit Sale',
      ),
      (option: 'paymentOption', back: 'paymentBackButton', title: 'Payment'),
      (
        option: 'statementOption',
        back: 'statementBackButton',
        title: 'Statement',
      ),
    ];

    for (final destination in destinations) {
      final option = find.byKey(Key(destination.option));
      await tester.ensureVisible(option);
      await tester.pumpAndSettle();
      await tester.tap(option);
      await tester.pumpAndSettle();

      expect(find.text(destination.title), findsOneWidget);

      await tester.tap(find.byKey(Key(destination.back)));
      await tester.pumpAndSettle();

      expect(find.text('What would you like to do?'), findsOneWidget);
    }
  });

  testWidgets('menu page fits a small phone screen', (
    WidgetTester tester,
  ) async {
    await _openMenu(tester, size: const Size(320, 480));

    expect(tester.takeException(), isNull);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('customer page lists customers and filters by search', (
    WidgetTester tester,
  ) async {
    await _openCustomers(tester);

    expect(find.text('Customers'), findsOneWidget);
    expect(find.text('Ravi Kumar'), findsOneWidget);
    expect(find.text('Ganesh Stores'), findsOneWidget);
    expect(find.text('Meena Patel'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('customerSearchField')),
      'Sunita',
    );
    await tester.pump();

    expect(find.text('SEARCH RESULTS'), findsOneWidget);
    expect(find.text('Sunita Sharma'), findsOneWidget);
    expect(find.text('Ravi Kumar'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(find.text('ALL CUSTOMERS'), findsOneWidget);
    expect(find.text('Ravi Kumar'), findsOneWidget);
  });

  testWidgets('customer page adds a new customer', (WidgetTester tester) async {
    await _openCustomers(tester);

    await tester.tap(find.byKey(const Key('addCustomerButton')));
    await tester.pumpAndSettle();

    expect(find.text('Add customer'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('customerNameField')),
      'Kiran Rao',
    );
    await tester.enterText(
      find.byKey(const Key('customerPhoneField')),
      '91234 56789',
    );
    await tester.enterText(
      find.byKey(const Key('customerEmailField')),
      'kiran@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('customerAddressField')),
      '7 Lake View, Pune',
    );
    await tester.enterText(
      find.byKey(const Key('customerOutstandingField')),
      '750',
    );

    await tester.tap(find.byKey(const Key('saveCustomerButton')));
    await tester.pumpAndSettle();

    expect(find.text('Kiran Rao'), findsOneWidget);
    expect(find.text('₹750'), findsOneWidget);
    expect(find.text('Kiran Rao was added.'), findsOneWidget);
  });

  testWidgets('customer details sheet edits a customer', (
    WidgetTester tester,
  ) async {
    await _openCustomers(tester);

    await tester.tap(find.byKey(const Key('customerCard-c1')));
    await tester.pumpAndSettle();

    expect(find.text('Customer details'), findsOneWidget);
    expect(find.text('ravi.kumar@example.com'), findsOneWidget);

    await tester.tap(find.byKey(const Key('editCustomerButton')));
    await tester.pumpAndSettle();

    expect(find.text('Edit customer'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('customerNameField')),
      'Ravi Kumar Updated',
    );
    await tester.tap(find.byKey(const Key('saveCustomerButton')));
    await tester.pumpAndSettle();

    expect(find.text('Ravi Kumar Updated'), findsOneWidget);
    expect(find.text('Ravi Kumar Updated was updated.'), findsOneWidget);
  });

  testWidgets('customer details sheet deletes a customer', (
    WidgetTester tester,
  ) async {
    await _openCustomers(tester);

    await tester.tap(find.byKey(const Key('customerCard-c1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteCustomerButton')));
    await tester.pumpAndSettle();

    expect(find.text('Delete customer?'), findsOneWidget);
    expect(find.textContaining('Ravi Kumar will be removed'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirmDeleteButton')));
    await tester.pumpAndSettle();

    expect(find.text('Ravi Kumar'), findsNothing);
    expect(find.text('Ravi Kumar was deleted.'), findsOneWidget);
  });

  testWidgets('customer page back button returns to the menu', (
    WidgetTester tester,
  ) async {
    await _openCustomers(tester);

    await tester.tap(find.byKey(const Key('customersBackButton')));
    await tester.pumpAndSettle();

    expect(find.text('What would you like to do?'), findsOneWidget);
    expect(find.text('ALL CUSTOMERS'), findsNothing);
  });

  testWidgets('customer page fits a small phone screen', (
    WidgetTester tester,
  ) async {
    await _openCustomers(tester, size: const Size(320, 480));

    expect(tester.takeException(), isNull);
    expect(find.text('Customers'), findsOneWidget);
    expect(find.byKey(const Key('customerSearchField')), findsOneWidget);
  });

  testWidgets('customer details fit a small phone screen', (
    WidgetTester tester,
  ) async {
    await _openCustomers(tester, size: const Size(320, 480));

    await tester.tap(find.byKey(const Key('customerCard-c1')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Customer details'), findsOneWidget);
    expect(find.text('ravi.kumar@example.com'), findsOneWidget);
  });

  testWidgets('customer page uses the wide layout', (
    WidgetTester tester,
  ) async {
    await _openCustomers(tester, size: const Size(1280, 900));

    expect(tester.takeException(), isNull);
    expect(find.text('Ravi Kumar'), findsOneWidget);
    expect(find.text('Ganesh Stores'), findsOneWidget);
  });

  testWidgets('credit sale page shows all required fields', (
    WidgetTester tester,
  ) async {
    await _openCreditSale(tester);

    expect(find.text('Credit Sale'), findsOneWidget);
    expect(find.text('New credit sale'), findsOneWidget);
    expect(find.byKey(const Key('creditSaleCustomerField')), findsOneWidget);
    expect(find.byKey(const Key('creditSaleProductField')), findsOneWidget);
    expect(find.byKey(const Key('creditSaleAmountField')), findsOneWidget);
    expect(find.byKey(const Key('creditSaleDateField')), findsOneWidget);
    expect(find.byKey(const Key('saveCreditSaleButton')), findsOneWidget);
    expect(find.text('Recent credit sales'), findsOneWidget);

    expect(find.text(_shortDateLabel(DateTime.now())), findsOneWidget);
  });

  testWidgets('credit sale validates the required fields', (
    WidgetTester tester,
  ) async {
    await _openCreditSale(tester);

    final save = find.byKey(const Key('saveCreditSaleButton'));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('Select a customer'), findsOneWidget);
    expect(find.text('Enter the product name'), findsOneWidget);
    expect(find.text('Enter the amount'), findsOneWidget);
  });

  testWidgets('credit sale saves and adds to recent sales', (
    WidgetTester tester,
  ) async {
    await _openCreditSale(tester);

    await tester.tap(find.byKey(const Key('creditSaleCustomerField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sunita Sharma').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('creditSaleProductField')),
      'Sugar 10 kg',
    );
    await tester.enterText(
      find.byKey(const Key('creditSaleAmountField')),
      '850',
    );

    final save = find.byKey(const Key('saveCreditSaleButton'));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(
      find.text('₹850 credit sale saved for Sunita Sharma.'),
      findsOneWidget,
    );
    expect(find.textContaining('Sugar 10 kg'), findsOneWidget);
    expect(find.text('₹850'), findsOneWidget);
  });

  testWidgets('credit sale date picker opens from the date field', (
    WidgetTester tester,
  ) async {
    await _openCreditSale(tester);

    final dateField = find.byKey(const Key('creditSaleDateField'));
    await tester.ensureVisible(dateField);
    await tester.pumpAndSettle();
    await tester.tap(dateField);
    await tester.pumpAndSettle();

    expect(find.text('Select sale date'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Select sale date'), findsNothing);
    expect(dateField, findsOneWidget);
  });

  testWidgets('credit sale back button returns to the menu', (
    WidgetTester tester,
  ) async {
    await _openCreditSale(tester);

    await tester.tap(find.byKey(const Key('creditSaleBackButton')));
    await tester.pumpAndSettle();

    expect(find.text('What would you like to do?'), findsOneWidget);
    expect(find.text('Recent credit sales'), findsNothing);
  });

  testWidgets('credit sale page fits a small phone screen', (
    WidgetTester tester,
  ) async {
    await _openCreditSale(tester, size: const Size(320, 480));

    expect(tester.takeException(), isNull);
    expect(find.text('Credit Sale'), findsOneWidget);
    expect(find.byKey(const Key('creditSaleCustomerField')), findsOneWidget);
  });

  testWidgets('credit sale page uses the wide layout', (
    WidgetTester tester,
  ) async {
    await _openCreditSale(tester, size: const Size(1280, 900));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('saveCreditSaleButton')), findsOneWidget);
    expect(find.text('Recent credit sales'), findsOneWidget);
  });

  testWidgets('payment page shows all required fields', (
    WidgetTester tester,
  ) async {
    await _openPayment(tester);

    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('Record a payment'), findsOneWidget);
    expect(find.byKey(const Key('paymentCustomerField')), findsOneWidget);
    expect(find.text('Outstanding balance'), findsOneWidget);
    expect(find.text('Choose a customer'), findsOneWidget);
    expect(find.byKey(const Key('paymentAmountField')), findsOneWidget);
    expect(find.byKey(const Key('paymentDateField')), findsOneWidget);
    expect(find.byKey(const Key('savePaymentButton')), findsOneWidget);
    expect(find.text('Recent payments'), findsOneWidget);
    expect(find.text(_shortDateLabel(DateTime.now())), findsOneWidget);
  });

  testWidgets('payment page shows the selected customer balance', (
    WidgetTester tester,
  ) async {
    await _openPayment(tester);

    await tester.tap(find.byKey(const Key('paymentCustomerField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ganesh Stores').last);
    await tester.pumpAndSettle();

    expect(find.text('₹6,250'), findsOneWidget);
    expect(find.byKey(const Key('payFullButton')), findsOneWidget);
  });

  testWidgets('payment page validates the required fields', (
    WidgetTester tester,
  ) async {
    await _openPayment(tester);

    final save = find.byKey(const Key('savePaymentButton'));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('Select a customer'), findsOneWidget);
    expect(find.text('Enter the payment amount'), findsOneWidget);
  });

  testWidgets('payment saves and reduces the outstanding balance', (
    WidgetTester tester,
  ) async {
    await _openPayment(tester);

    await tester.tap(find.byKey(const Key('paymentCustomerField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sunita Sharma').last);
    await tester.pumpAndSettle();

    expect(find.text('₹2,000'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('paymentAmountField')), '500');

    final save = find.byKey(const Key('savePaymentButton'));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(
      find.text('₹500 payment recorded for Sunita Sharma.'),
      findsOneWidget,
    );
    expect(find.text('₹1,500'), findsOneWidget);
    expect(find.text('+₹500'), findsOneWidget);
  });

  testWidgets('payment rejects an amount above the outstanding balance', (
    WidgetTester tester,
  ) async {
    await _openPayment(tester);

    await tester.tap(find.byKey(const Key('paymentCustomerField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sunita Sharma').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('paymentAmountField')), '5000');

    final save = find.byKey(const Key('savePaymentButton'));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(
      find.text('Payment cannot exceed the outstanding balance'),
      findsOneWidget,
    );
    expect(find.text('+₹5,000'), findsNothing);
  });

  testWidgets('payment pay full clears the outstanding balance', (
    WidgetTester tester,
  ) async {
    await _openPayment(tester);

    await tester.tap(find.byKey(const Key('paymentCustomerField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ganesh Stores').last);
    await tester.pumpAndSettle();

    final payFull = find.byKey(const Key('payFullButton'));
    await tester.ensureVisible(payFull);
    await tester.pumpAndSettle();
    await tester.tap(payFull);
    await tester.pump();

    expect(find.text('6250'), findsOneWidget);

    final save = find.byKey(const Key('savePaymentButton'));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('₹0'), findsOneWidget);
    expect(find.text('All dues cleared'), findsOneWidget);
    expect(find.text('+₹6,250'), findsOneWidget);
  });

  testWidgets('payment date picker opens from the date field', (
    WidgetTester tester,
  ) async {
    await _openPayment(tester);

    final dateField = find.byKey(const Key('paymentDateField'));
    await tester.ensureVisible(dateField);
    await tester.pumpAndSettle();
    await tester.tap(dateField);
    await tester.pumpAndSettle();

    expect(find.text('Select payment date'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Select payment date'), findsNothing);
    expect(dateField, findsOneWidget);
  });

  testWidgets('payment back button returns to the menu', (
    WidgetTester tester,
  ) async {
    await _openPayment(tester);

    await tester.tap(find.byKey(const Key('paymentBackButton')));
    await tester.pumpAndSettle();

    expect(find.text('What would you like to do?'), findsOneWidget);
    expect(find.text('Recent payments'), findsNothing);
  });

  testWidgets('payment page fits a small phone screen', (
    WidgetTester tester,
  ) async {
    await _openPayment(tester, size: const Size(320, 480));

    expect(tester.takeException(), isNull);
    expect(find.text('Payment'), findsOneWidget);
    expect(find.byKey(const Key('paymentCustomerField')), findsOneWidget);
  });

  testWidgets('payment page uses the wide layout', (WidgetTester tester) async {
    await _openPayment(tester, size: const Size(1280, 900));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('savePaymentButton')), findsOneWidget);
    expect(find.text('Recent payments'), findsOneWidget);
  });

  testWidgets('customer changes persist when the page is reopened', (
    WidgetTester tester,
  ) async {
    await _openCustomers(tester);

    await tester.tap(find.byKey(const Key('addCustomerButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('customerNameField')),
      'Kiran Rao',
    );
    await tester.enterText(
      find.byKey(const Key('customerPhoneField')),
      '91234 56789',
    );
    await tester.tap(find.byKey(const Key('saveCustomerButton')));
    await tester.pumpAndSettle();

    expect(find.text('Kiran Rao'), findsOneWidget);

    await tester.tap(find.byKey(const Key('customersBackButton')));
    await tester.pumpAndSettle();

    final customerOption = find.byKey(const Key('customerOption'));
    await tester.ensureVisible(customerOption);
    await tester.pumpAndSettle();
    await tester.tap(customerOption);
    await tester.pumpAndSettle();

    expect(find.text('Kiran Rao'), findsOneWidget);
  });

  testWidgets('a new credit sale updates the payment page balance', (
    WidgetTester tester,
  ) async {
    await _openCreditSale(tester);

    await tester.tap(find.byKey(const Key('creditSaleCustomerField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sunita Sharma').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('creditSaleProductField')),
      'Sugar 10 kg',
    );
    await tester.enterText(
      find.byKey(const Key('creditSaleAmountField')),
      '500',
    );

    final save = find.byKey(const Key('saveCreditSaleButton'));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    final backButton = find.byKey(const Key('creditSaleBackButton'));
    await tester.ensureVisible(backButton);
    await tester.pumpAndSettle();
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    final paymentOption = find.byKey(const Key('paymentOption'));
    await tester.ensureVisible(paymentOption);
    await tester.pumpAndSettle();
    await tester.tap(paymentOption);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('paymentCustomerField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sunita Sharma').last);
    await tester.pumpAndSettle();

    expect(find.text('₹2,500'), findsOneWidget);
  });

  testWidgets('a payment updates the customer outstanding balance', (
    WidgetTester tester,
  ) async {
    await _openPayment(tester);

    await tester.tap(find.byKey(const Key('paymentCustomerField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ganesh Stores').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('paymentAmountField')), '250');

    final save = find.byKey(const Key('savePaymentButton'));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    final backButton = find.byKey(const Key('paymentBackButton'));
    await tester.ensureVisible(backButton);
    await tester.pumpAndSettle();
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    final customerOption = find.byKey(const Key('customerOption'));
    await tester.ensureVisible(customerOption);
    await tester.pumpAndSettle();
    await tester.tap(customerOption);
    await tester.pumpAndSettle();

    expect(find.text('₹6,000'), findsOneWidget);
  });

  testWidgets('statement page shows customer credit history', (
    WidgetTester tester,
  ) async {
    await _openStatement(tester);

    expect(find.text('Statement'), findsOneWidget);
    expect(find.byKey(const Key('statementCustomerField')), findsOneWidget);
    expect(find.byKey(const Key('printStatementButton')), findsOneWidget);
    expect(find.text('OUTSTANDING BALANCE'), findsOneWidget);

    final balance = tester.widget<Text>(
      find.byKey(const Key('statementBalance')),
    );
    final credit = tester.widget<Text>(
      find.byKey(const Key('statementCreditTotal')),
    );
    final payments = tester.widget<Text>(
      find.byKey(const Key('statementPaymentTotal')),
    );

    expect(balance.data, '₹4,500');
    expect(credit.data, '₹6,500');
    expect(payments.data, '₹2,000');
    expect(find.text('Transaction history'), findsOneWidget);
    expect(find.textContaining('Credit sale ·'), findsNWidgets(2));
    expect(find.textContaining('Payment ·'), findsOneWidget);
    expect(find.text('Balance ₹4,500'), findsOneWidget);

    final statement = buildCustomerStatement('Ravi Kumar');
    expect(
      find.textContaining(_shortDateLabel(statement.firstDate!)),
      findsOneWidget,
    );
  });

  testWidgets('statement changes when another customer is selected', (
    WidgetTester tester,
  ) async {
    await _openStatement(tester);

    await tester.tap(find.byKey(const Key('statementCustomerField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Meena Patel').last);
    await tester.pumpAndSettle();

    final balance = tester.widget<Text>(
      find.byKey(const Key('statementBalance')),
    );
    final credit = tester.widget<Text>(
      find.byKey(const Key('statementCreditTotal')),
    );
    final payments = tester.widget<Text>(
      find.byKey(const Key('statementPaymentTotal')),
    );

    expect(balance.data, '₹0');
    expect(credit.data, '₹1,500');
    expect(payments.data, '₹1,500');
    expect(find.text('All dues cleared'), findsOneWidget);
  });

  testWidgets('statement print report opens the preview', (
    WidgetTester tester,
  ) async {
    await _openStatement(tester);

    final printButton = find.byKey(const Key('printStatementButton'));
    await tester.ensureVisible(printButton);
    await tester.pumpAndSettle();
    await tester.tap(printButton);
    await tester.pumpAndSettle();

    expect(find.text('Statement report'), findsOneWidget);
    expect(find.text('CUSTOMER STATEMENT'), findsOneWidget);
    expect(find.text('Prepared for Ravi Kumar'), findsOneWidget);
    expect(find.text('TRANSACTION DETAILS'), findsOneWidget);
    expect(find.byKey(const Key('printReportButton')), findsOneWidget);
    expect(find.textContaining('Total credit sales'), findsOneWidget);

    await tester.tap(find.byKey(const Key('statementReportBackButton')));
    await tester.pumpAndSettle();

    expect(find.text('Statement'), findsOneWidget);
    expect(find.text('Transaction history'), findsOneWidget);
  });

  testWidgets('statement back button returns to the menu', (
    WidgetTester tester,
  ) async {
    await _openStatement(tester);

    await tester.tap(find.byKey(const Key('statementBackButton')));
    await tester.pumpAndSettle();

    expect(find.text('What would you like to do?'), findsOneWidget);
    expect(find.text('Transaction history'), findsNothing);
  });

  testWidgets('statement page fits a small phone screen', (
    WidgetTester tester,
  ) async {
    await _openStatement(tester, size: const Size(320, 480));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('statementBalance')), findsOneWidget);
    expect(find.byKey(const Key('printStatementButton')), findsOneWidget);
  });

  testWidgets('statement report fits a small phone screen', (
    WidgetTester tester,
  ) async {
    await _openStatement(tester, size: const Size(320, 480));

    final printButton = find.byKey(const Key('printStatementButton'));
    await tester.ensureVisible(printButton);
    await tester.pumpAndSettle();
    await tester.tap(printButton);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('CUSTOMER STATEMENT'), findsOneWidget);
    expect(find.byKey(const Key('printReportButton')), findsOneWidget);
  });

  testWidgets('statement page uses the wide layout', (
    WidgetTester tester,
  ) async {
    await _openStatement(tester, size: const Size(1280, 900));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('printStatementButton')), findsOneWidget);
    expect(find.text('Transaction history'), findsOneWidget);
  });

  test('sample statements match customer balances', () {
    for (final account in sampleCustomerAccounts) {
      final statement = buildCustomerStatement(account.name);
      expect(
        statement.remainingBalance,
        account.outstanding,
        reason: account.name,
      );
    }
  });

  test('statement report generates a PDF', () async {
    final bytes = await buildStatementPdf(
      buildCustomerStatement('Ravi Kumar'),
      PdfPageFormat.a4,
    );

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  testWidgets('dashboard shows totals and recent transactions', (
    WidgetTester tester,
  ) async {
    await _openDashboard(tester);

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Outstanding Balance'), findsOneWidget);
    expect(find.text('Total Credit'), findsOneWidget);
    expect(find.text('Total Payments'), findsOneWidget);
    expect(find.text('₹46,500'), findsOneWidget);
    expect(find.text('₹1,24,500'), findsOneWidget);
    expect(find.text('₹78,000'), findsOneWidget);
    expect(find.text('Recent transactions'), findsOneWidget);
    expect(find.text('Ravi Kumar'), findsOneWidget);
    expect(find.text('Sunita Sharma'), findsOneWidget);
  });

  testWidgets('dashboard back button returns to the menu', (
    WidgetTester tester,
  ) async {
    await _openDashboard(tester);

    await tester.tap(find.byKey(const Key('dashboardBackButton')));
    await tester.pumpAndSettle();

    expect(find.text('What would you like to do?'), findsOneWidget);
    expect(find.text('Recent transactions'), findsNothing);
  });

  testWidgets('dashboard fits a small phone screen', (
    WidgetTester tester,
  ) async {
    await _openDashboard(tester, size: const Size(320, 480));

    expect(tester.takeException(), isNull);
    expect(find.text('Outstanding Balance'), findsOneWidget);
    expect(find.text('Recent transactions'), findsOneWidget);
  });

  testWidgets('dashboard uses the wide summary layout', (
    WidgetTester tester,
  ) async {
    await _openDashboard(tester, size: const Size(1280, 900));

    expect(tester.takeException(), isNull);
    expect(find.text('Total Credit'), findsOneWidget);
    expect(find.text('Total Payments'), findsOneWidget);
  });
}
