/// The type of an entry in a customer's statement.
enum StatementEntryType { creditSale, payment }

/// A single credit sale or payment on a customer's account.
class StatementEntry {
  const StatementEntry({
    required this.customer,
    required this.date,
    required this.type,
    required this.details,
    required this.amount,
  });

  final String customer;
  final DateTime date;
  final StatementEntryType type;
  final String details;
  final double amount;

  bool get isPayment => type == StatementEntryType.payment;

  String get typeLabel => isPayment ? 'Payment' : 'Credit sale';
}

/// A statement entry together with the balance after it was recorded.
class StatementLine {
  const StatementLine({required this.entry, required this.balanceAfter});

  final StatementEntry entry;
  final double balanceAfter;
}

/// A customer's complete statement, ordered from oldest to newest.
class CustomerStatement {
  const CustomerStatement({required this.customer, required this.lines});

  final String customer;
  final List<StatementLine> lines;

  bool get isEmpty => lines.isEmpty;

  double get totalCredit => lines.fold(
    0,
    (total, line) => total + (line.entry.isPayment ? 0 : line.entry.amount),
  );

  double get totalPayments => lines.fold(
    0,
    (total, line) => total + (line.entry.isPayment ? line.entry.amount : 0),
  );

  double get remainingBalance => totalCredit - totalPayments;

  DateTime? get firstDate => lines.isEmpty ? null : lines.first.entry.date;

  DateTime? get lastDate => lines.isEmpty ? null : lines.last.entry.date;
}

/// Builds a statement for [customer] from the sample ledger.
CustomerStatement buildCustomerStatement(String customer) {
  final entries =
      sampleStatementEntries
          .where((entry) => entry.customer == customer)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  var balance = 0.0;
  final lines = <StatementLine>[];

  for (final entry in entries) {
    balance += entry.isPayment ? -entry.amount : entry.amount;
    lines.add(StatementLine(entry: entry, balanceAfter: balance));
  }

  return CustomerStatement(customer: customer, lines: lines);
}

/// Sample ledger entries used by the statement screen.
///
/// The net balance for each customer matches the sample customer accounts.
final List<StatementEntry> sampleStatementEntries = [
  StatementEntry(
    customer: 'Ravi Kumar',
    date: _daysAgo(18),
    type: StatementEntryType.creditSale,
    details: 'Basmati rice · 40 kg',
    amount: 4000,
  ),
  StatementEntry(
    customer: 'Ravi Kumar',
    date: _daysAgo(12),
    type: StatementEntryType.creditSale,
    details: 'Sunflower oil · 10 L',
    amount: 2500,
  ),
  StatementEntry(
    customer: 'Ravi Kumar',
    date: _daysAgo(6),
    type: StatementEntryType.payment,
    details: 'Payment received · UPI',
    amount: 2000,
  ),
  StatementEntry(
    customer: 'Sunita Sharma',
    date: _daysAgo(15),
    type: StatementEntryType.creditSale,
    details: 'Wheat flour · 25 kg',
    amount: 3000,
  ),
  StatementEntry(
    customer: 'Sunita Sharma',
    date: _daysAgo(5),
    type: StatementEntryType.payment,
    details: 'Payment received · Cash',
    amount: 1000,
  ),
  StatementEntry(
    customer: 'Ganesh Stores',
    date: _daysAgo(21),
    type: StatementEntryType.creditSale,
    details: 'Rice bags · 50 kg',
    amount: 5000,
  ),
  StatementEntry(
    customer: 'Ganesh Stores',
    date: _daysAgo(11),
    type: StatementEntryType.creditSale,
    details: 'Grocery staples · Restock',
    amount: 3250,
  ),
  StatementEntry(
    customer: 'Ganesh Stores',
    date: _daysAgo(3),
    type: StatementEntryType.payment,
    details: 'Payment received · Bank transfer',
    amount: 2000,
  ),
  StatementEntry(
    customer: 'Meena Patel',
    date: _daysAgo(22),
    type: StatementEntryType.creditSale,
    details: 'Monthly grocery pack',
    amount: 1500,
  ),
  StatementEntry(
    customer: 'Meena Patel',
    date: _daysAgo(9),
    type: StatementEntryType.payment,
    details: 'Payment received · UPI',
    amount: 1500,
  ),
  StatementEntry(
    customer: 'Arjun Verma',
    date: _daysAgo(7),
    type: StatementEntryType.creditSale,
    details: 'Cooking oil · 15 L',
    amount: 3800,
  ),
];

DateTime _daysAgo(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
}
