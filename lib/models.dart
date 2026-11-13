/// Domain models persisted in the local SQLite database.
library;

/// A customer account with an outstanding credit balance.
class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.address = '',
    this.outstanding = 0,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final double outstanding;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    final first = parts.first.substring(0, 1);
    final last = parts.last.substring(0, 1);
    return '$first$last'.toUpperCase();
  }

  factory Customer.fromMap(Map<String, Object?> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      email: (map['email'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      outstanding: (map['outstanding'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'outstanding': outstanding,
    };
  }
}

/// A credit sale recorded against a customer's account.
class CreditSale {
  const CreditSale({
    this.id,
    required this.customerId,
    required this.customerName,
    required this.product,
    required this.amount,
    required this.date,
  });

  final int? id;
  final String customerId;
  final String customerName;
  final String product;
  final double amount;
  final DateTime date;

  factory CreditSale.fromMap(Map<String, Object?> map) {
    return CreditSale(
      id: map['id'] as int?,
      customerId: map['customer_id'] as String,
      customerName: (map['customer_name'] as String?) ?? '',
      product: map['product'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'customer_id': customerId,
      'product': product,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }
}

/// A payment received from a customer.
class Payment {
  const Payment({
    this.id,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.date,
  });

  final int? id;
  final String customerId;
  final String customerName;
  final double amount;
  final DateTime date;

  factory Payment.fromMap(Map<String, Object?> map) {
    return Payment(
      id: map['id'] as int?,
      customerId: map['customer_id'] as String,
      customerName: (map['customer_name'] as String?) ?? '',
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'customer_id': customerId,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }
}
