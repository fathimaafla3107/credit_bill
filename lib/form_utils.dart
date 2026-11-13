import 'package:flutter/material.dart';

import 'app_theme.dart';

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Returns true when [value] looks like a valid email address.
bool isValidEmail(String value) => _emailPattern.hasMatch(value);

/// Returns true when [value] contains between 7 and 15 digits.
///
/// Spaces, dashes and a leading "+" are allowed so common local formats work.
bool isValidPhoneNumber(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.length >= 7 && digits.length <= 15;
}

OutlineInputBorder _fieldBorder(Color color, [double width = 1]) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color, width: width),
  );
}

/// The text-field styling used across the app's forms.
InputDecoration appFieldDecoration({
  required String label,
  required String hint,
  required IconData icon,
  Widget? suffixIcon,
  String? errorText,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    errorText: errorText,
    prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.fieldFill,
    hintStyle: TextStyle(
      color: AppColors.muted.withValues(alpha: 0.65),
      fontSize: 14,
    ),
    labelStyle: const TextStyle(
      color: AppColors.muted,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    floatingLabelStyle: const TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    border: _fieldBorder(AppColors.border),
    enabledBorder: _fieldBorder(AppColors.border),
    focusedBorder: _fieldBorder(AppColors.primary, 1.6),
    errorBorder: _fieldBorder(AppColors.danger, 1.2),
    focusedErrorBorder: _fieldBorder(AppColors.danger, 1.6),
    errorStyle: const TextStyle(color: AppColors.danger, fontSize: 12),
  );
}
