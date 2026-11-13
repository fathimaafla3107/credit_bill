/// Formats [value] as Indian rupees with grouping and no decimal places.
///
/// For example, `124500` becomes `₹1,24,500`.
String formatRupees(double value) {
  final isNegative = value < 0;
  final digits = value.abs().round().toString();
  final prefix = isNegative ? '-₹' : '₹';

  if (digits.length <= 3) return '$prefix$digits';

  final lastThree = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final groups = <String>[];

  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);

  return '$prefix${groups.join(',')},$lastThree';
}
