const List<String> _monthNames = [
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

/// Formats [date] as `08 Nov 2026`.
String formatShortDate(DateTime date) {
  final month = _monthNames[date.month - 1];
  return '${date.day.toString().padLeft(2, '0')} $month ${date.year}';
}

/// Formats [date] as `Today`, `Yesterday`, or `08 Nov 2026`.
String formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final value = DateTime(date.year, date.month, date.day);
  final difference = today.difference(value).inDays;

  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  return formatShortDate(date);
}
