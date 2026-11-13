/// A lightweight customer record used by sale and payment screens.
class CustomerAccount {
  const CustomerAccount({required this.name, required this.outstanding});

  final String name;
  final double outstanding;
}

/// Sample customer accounts shared by the customer-facing features.
const List<CustomerAccount> sampleCustomerAccounts = [
  CustomerAccount(name: 'Ravi Kumar', outstanding: 4500),
  CustomerAccount(name: 'Sunita Sharma', outstanding: 2000),
  CustomerAccount(name: 'Ganesh Stores', outstanding: 6250),
  CustomerAccount(name: 'Meena Patel', outstanding: 0),
  CustomerAccount(name: 'Arjun Verma', outstanding: 3800),
];
