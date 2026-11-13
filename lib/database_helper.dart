import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

/// Owns the local SQLite database used by the Credit Bill System.
///
/// The database stores customers, credit sales and payments on the device so
/// that data survives app restarts.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _databaseName = 'credit_bill_system.db';
  static const int _databaseVersion = 1;

  Database? _database;
  String? _activePath;
  bool _useInMemoryDatabase = false;

  /// Makes subsequent opens use a temporary in-memory database.
  ///
  /// Used by widget tests so they never touch the real device database.
  void useInMemoryDatabaseForTesting() {
    _useInMemoryDatabase = true;
  }

  /// Closes the open database and clears test data.
  Future<void> resetDatabaseForTesting() async {
    final database = _database;
    final path = _activePath;
    _database = null;
    _activePath = null;

    if (database != null) {
      await database.close();
    }
    if (!_useInMemoryDatabase && path != null) {
      await databaseFactory.deleteDatabase(path);
    }
  }

  Future<Database> get database async {
    return _database ??= await _openDatabase();
  }

  Future<String> _databasePath() async {
    if (_useInMemoryDatabase) return inMemoryDatabasePath;
    final directory = await databaseFactory.getDatabasesPath();
    return p.join(directory, _databaseName);
  }

  Future<Database> _openDatabase() async {
    final path = await _databasePath();
    _activePath = path;

    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _createSchema,
      ),
    );
  }

  Future<void> _createSchema(Database database, int version) async {
    await database.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL DEFAULT '',
        address TEXT NOT NULL DEFAULT '',
        outstanding REAL NOT NULL DEFAULT 0
      )
    ''');

    await database.execute('''
      CREATE TABLE credit_sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id TEXT NOT NULL,
        product TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    await database.execute(
      'CREATE INDEX credit_sales_customer_idx '
      'ON credit_sales (customer_id)',
    );
    await database.execute(
      'CREATE INDEX payments_customer_idx ON payments (customer_id)',
    );

    await _seedDatabase(database);
  }

  Future<void> _seedDatabase(Database database) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final customers = <Customer>[
      const Customer(
        id: 'c1',
        name: 'Ravi Kumar',
        phone: '98765 43210',
        email: 'ravi.kumar@example.com',
        address: '12 Market Road, Pune',
        outstanding: 4500,
      ),
      const Customer(
        id: 'c2',
        name: 'Sunita Sharma',
        phone: '98111 22334',
        email: 'sunita.sharma@example.com',
        address: '8 Gandhi Nagar, Nashik',
        outstanding: 2000,
      ),
      const Customer(
        id: 'c3',
        name: 'Ganesh Stores',
        phone: '99887 76655',
        email: 'ganesh.stores@example.com',
        address: 'Main Bazaar, Kolhapur',
        outstanding: 6250,
      ),
      const Customer(
        id: 'c4',
        name: 'Meena Patel',
        phone: '97654 32109',
        email: 'meena.patel@example.com',
        address: '21 Station Road, Surat',
        outstanding: 0,
      ),
      const Customer(
        id: 'c5',
        name: 'Arjun Verma',
        phone: '90987 65432',
        email: 'arjun.verma@example.com',
        address: '5 MG Road, Nagpur',
        outstanding: 3800,
      ),
    ];

    for (final customer in customers) {
      await database.insert('customers', customer.toMap());
    }

    final sales = <CreditSale>[
      CreditSale(
        customerId: 'c1',
        customerName: 'Ravi Kumar',
        product: 'Basmati rice · 25 kg',
        amount: 4500,
        date: today,
      ),
      CreditSale(
        customerId: 'c2',
        customerName: 'Sunita Sharma',
        product: 'Sunflower oil · 5 L',
        amount: 2000,
        date: today.subtract(const Duration(days: 1)),
      ),
      CreditSale(
        customerId: 'c3',
        customerName: 'Ganesh Stores',
        product: 'Wheat flour · 50 kg',
        amount: 6250,
        date: today.subtract(const Duration(days: 2)),
      ),
    ];

    for (final sale in sales) {
      await database.insert('credit_sales', sale.toMap());
    }

    final payments = <Payment>[
      Payment(
        customerId: 'c1',
        customerName: 'Ravi Kumar',
        amount: 2000,
        date: today,
      ),
      Payment(
        customerId: 'c4',
        customerName: 'Meena Patel',
        amount: 1500,
        date: today.subtract(const Duration(days: 1)),
      ),
      Payment(
        customerId: 'c2',
        customerName: 'Sunita Sharma',
        amount: 1000,
        date: today.subtract(const Duration(days: 2)),
      ),
    ];

    for (final payment in payments) {
      await database.insert('payments', payment.toMap());
    }
  }

  // ---------------------------------------------------------------- customers

  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final rows = await db.query('customers', orderBy: 'rowid ASC');
    return rows.map(Customer.fromMap).toList();
  }

  Future<Customer?> getCustomer(String id) async {
    final db = await database;
    final rows = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Customer.fromMap(rows.first);
  }

  Future<void> insertCustomer(Customer customer) async {
    final db = await database;
    await db.insert('customers', customer.toMap());
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await database;
    final updated = await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
    if (updated == 0) {
      throw StateError('Customer ${customer.id} was not found.');
    }
  }

  Future<void> deleteCustomer(String id) async {
    final db = await database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // -------------------------------------------------------------- credit sales

  Future<List<CreditSale>> getCreditSales({int limit = 100}) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT s.id, s.customer_id, c.name AS customer_name, s.product,
             s.amount, s.date
      FROM credit_sales s
      INNER JOIN customers c ON c.id = s.customer_id
      ORDER BY s.date DESC, s.id DESC
      LIMIT ?
      ''',
      [limit],
    );
    return rows.map(CreditSale.fromMap).toList();
  }

  /// Inserts a credit sale and adds its amount to the customer's balance.
  Future<int> insertCreditSale(CreditSale sale) async {
    final db = await database;

    return db.transaction((transaction) async {
      final id = await transaction.insert('credit_sales', sale.toMap());
      await transaction.rawUpdate(
        'UPDATE customers SET outstanding = outstanding + ? WHERE id = ?',
        [sale.amount, sale.customerId],
      );
      return id;
    });
  }

  /// Updates a credit sale and keeps customer balances in sync.
  Future<void> updateCreditSale(CreditSale sale) async {
    final id = sale.id;
    if (id == null) {
      throw ArgumentError('A credit sale id is required for an update.');
    }

    final db = await database;

    await db.transaction((transaction) async {
      final rows = await transaction.query(
        'credit_sales',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw StateError('Credit sale $id was not found.');
      }

      final previous = CreditSale.fromMap(rows.first);

      await transaction.update(
        'credit_sales',
        sale.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      if (previous.customerId == sale.customerId) {
        final difference = sale.amount - previous.amount;
        await transaction.rawUpdate(
          'UPDATE customers SET outstanding = MAX(0, outstanding + ?) '
          'WHERE id = ?',
          [difference, sale.customerId],
        );
      } else {
        await transaction.rawUpdate(
          'UPDATE customers SET outstanding = MAX(0, outstanding - ?) '
          'WHERE id = ?',
          [previous.amount, previous.customerId],
        );
        await transaction.rawUpdate(
          'UPDATE customers SET outstanding = outstanding + ? WHERE id = ?',
          [sale.amount, sale.customerId],
        );
      }
    });
  }

  /// Deletes a credit sale and removes its amount from the balance.
  Future<void> deleteCreditSale(int id) async {
    final db = await database;

    await db.transaction((transaction) async {
      final rows = await transaction.query(
        'credit_sales',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return;

      final sale = CreditSale.fromMap(rows.first);
      await transaction.delete(
        'credit_sales',
        where: 'id = ?',
        whereArgs: [id],
      );
      await transaction.rawUpdate(
        'UPDATE customers SET outstanding = MAX(0, outstanding - ?) '
        'WHERE id = ?',
        [sale.amount, sale.customerId],
      );
    });
  }

  // ----------------------------------------------------------------- payments

  Future<List<Payment>> getPayments({int limit = 100}) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT p.id, p.customer_id, c.name AS customer_name, p.amount, p.date
      FROM payments p
      INNER JOIN customers c ON c.id = p.customer_id
      ORDER BY p.date DESC, p.id DESC
      LIMIT ?
      ''',
      [limit],
    );
    return rows.map(Payment.fromMap).toList();
  }

  /// Records a payment and reduces the customer's outstanding balance.
  ///
  /// Returns `false` when the amount is invalid or exceeds the balance.
  Future<bool> recordPayment(Payment payment) async {
    final db = await database;

    return db.transaction((transaction) async {
      final rows = await transaction.query(
        'customers',
        columns: ['outstanding'],
        where: 'id = ?',
        whereArgs: [payment.customerId],
        limit: 1,
      );
      if (rows.isEmpty) return false;

      final outstanding = (rows.first['outstanding'] as num?)?.toDouble() ?? 0;
      if (payment.amount <= 0 || payment.amount > outstanding + 0.005) {
        return false;
      }

      await transaction.insert('payments', payment.toMap());

      final remaining = outstanding - payment.amount;
      await transaction.update(
        'customers',
        {'outstanding': remaining.abs() < 0.005 ? 0.0 : remaining},
        where: 'id = ?',
        whereArgs: [payment.customerId],
      );
      return true;
    });
  }

  /// Updates a payment and keeps customer balances in sync.
  Future<void> updatePayment(Payment payment) async {
    final id = payment.id;
    if (id == null) {
      throw ArgumentError('A payment id is required for an update.');
    }

    final db = await database;

    await db.transaction((transaction) async {
      final rows = await transaction.query(
        'payments',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw StateError('Payment $id was not found.');
      }

      final previous = Payment.fromMap(rows.first);

      await transaction.update(
        'payments',
        payment.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      if (previous.customerId == payment.customerId) {
        final difference = payment.amount - previous.amount;
        await transaction.rawUpdate(
          'UPDATE customers SET outstanding = MAX(0, outstanding - ?) '
          'WHERE id = ?',
          [difference, payment.customerId],
        );
      } else {
        await transaction.rawUpdate(
          'UPDATE customers SET outstanding = outstanding + ? WHERE id = ?',
          [previous.amount, previous.customerId],
        );
        await transaction.rawUpdate(
          'UPDATE customers SET outstanding = MAX(0, outstanding - ?) '
          'WHERE id = ?',
          [payment.amount, payment.customerId],
        );
      }
    });
  }

  /// Deletes a payment and adds its amount back to the balance.
  Future<void> deletePayment(int id) async {
    final db = await database;

    await db.transaction((transaction) async {
      final rows = await transaction.query(
        'payments',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return;

      final payment = Payment.fromMap(rows.first);
      await transaction.delete('payments', where: 'id = ?', whereArgs: [id]);
      await transaction.rawUpdate(
        'UPDATE customers SET outstanding = outstanding + ? WHERE id = ?',
        [payment.amount, payment.customerId],
      );
    });
  }
}
