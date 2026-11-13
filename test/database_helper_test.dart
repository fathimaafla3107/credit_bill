import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:credit_bill_system/database_helper.dart';
import 'package:credit_bill_system/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  setUp(() async {
    DatabaseHelper.instance.useInMemoryDatabaseForTesting();
    await DatabaseHelper.instance.resetDatabaseForTesting();
  });

  test('database seeds customers, credit sales and payments', () async {
    final customers = await DatabaseHelper.instance.getCustomers();
    final sales = await DatabaseHelper.instance.getCreditSales();
    final payments = await DatabaseHelper.instance.getPayments();

    expect(customers, hasLength(5));
    expect(customers.first.id, 'c1');
    expect(customers.first.name, 'Ravi Kumar');
    expect(sales, hasLength(3));
    expect(payments, hasLength(3));
  });

  test('customers support add, view, update and delete', () async {
    const customer = Customer(
      id: 'c6',
      name: 'Kiran Rao',
      phone: '91234 56789',
      email: 'kiran@example.com',
      address: '7 Lake View, Pune',
      outstanding: 750,
    );

    await DatabaseHelper.instance.insertCustomer(customer);

    final inserted = await DatabaseHelper.instance.getCustomer('c6');
    expect(inserted?.name, 'Kiran Rao');
    expect(inserted?.outstanding, 750);

    await DatabaseHelper.instance.updateCustomer(
      const Customer(
        id: 'c6',
        name: 'Kiran Rao Updated',
        phone: '91234 56789',
        email: 'kiran@example.com',
        address: '7 Lake View, Pune',
        outstanding: 500,
      ),
    );

    final updated = await DatabaseHelper.instance.getCustomer('c6');
    expect(updated?.name, 'Kiran Rao Updated');
    expect(updated?.outstanding, 500);

    await DatabaseHelper.instance.deleteCustomer('c6');
    expect(await DatabaseHelper.instance.getCustomer('c6'), isNull);
  });

  test('deleting a customer removes their sales and payments', () async {
    await DatabaseHelper.instance.deleteCustomer('c1');

    final customers = await DatabaseHelper.instance.getCustomers();
    final sales = await DatabaseHelper.instance.getCreditSales();
    final payments = await DatabaseHelper.instance.getPayments();

    expect(customers.any((customer) => customer.id == 'c1'), isFalse);
    expect(sales.any((sale) => sale.customerId == 'c1'), isFalse);
    expect(payments.any((payment) => payment.customerId == 'c1'), isFalse);
  });

  test('credit sales add to and update the customer balance', () async {
    final insertedId = await DatabaseHelper.instance.insertCreditSale(
      CreditSale(
        customerId: 'c1',
        customerName: 'Ravi Kumar',
        product: 'Sugar 10 kg',
        amount: 1000,
        date: DateTime.now(),
      ),
    );

    expect(
      (await DatabaseHelper.instance.getCustomer('c1'))?.outstanding,
      5500,
    );

    await DatabaseHelper.instance.updateCreditSale(
      CreditSale(
        id: insertedId,
        customerId: 'c1',
        customerName: 'Ravi Kumar',
        product: 'Sugar 10 kg',
        amount: 1500,
        date: DateTime.now(),
      ),
    );

    expect(
      (await DatabaseHelper.instance.getCustomer('c1'))?.outstanding,
      6000,
    );

    await DatabaseHelper.instance.deleteCreditSale(insertedId);

    expect(
      (await DatabaseHelper.instance.getCustomer('c1'))?.outstanding,
      4500,
    );
  });

  test('payments reduce the balance and reject overpayments', () async {
    final saved = await DatabaseHelper.instance.recordPayment(
      Payment(
        customerId: 'c2',
        customerName: 'Sunita Sharma',
        amount: 500,
        date: DateTime.now(),
      ),
    );

    expect(saved, isTrue);
    expect(
      (await DatabaseHelper.instance.getCustomer('c2'))?.outstanding,
      1500,
    );

    final rejected = await DatabaseHelper.instance.recordPayment(
      Payment(
        customerId: 'c2',
        customerName: 'Sunita Sharma',
        amount: 5000,
        date: DateTime.now(),
      ),
    );

    expect(rejected, isFalse);
    expect(
      (await DatabaseHelper.instance.getCustomer('c2'))?.outstanding,
      1500,
    );

    final payment = (await DatabaseHelper.instance.getPayments()).firstWhere(
      (entry) => entry.amount == 500 && entry.customerId == 'c2',
    );

    await DatabaseHelper.instance.updatePayment(
      Payment(
        id: payment.id,
        customerId: 'c2',
        customerName: 'Sunita Sharma',
        amount: 700,
        date: payment.date,
      ),
    );

    expect(
      (await DatabaseHelper.instance.getCustomer('c2'))?.outstanding,
      1300,
    );

    await DatabaseHelper.instance.deletePayment(payment.id!);

    expect(
      (await DatabaseHelper.instance.getCustomer('c2'))?.outstanding,
      2000,
    );
  });
}
