import 'package:flutter/services.dart';

class ValidationUtils {
  /// Input formatters to strictly reject numbers and special characters (letters and spaces only)
  static final List<TextInputFormatter> lettersOnlyFormatter = [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
  ];

  /// Input formatters to strictly reject non-numeric characters (numbers and single decimal point only)
  static final List<TextInputFormatter> decimalNumberFormatter = [
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
  ];

  /// Input formatters for whole numbers only (e.g., Phone, Stock bags)
  static final List<TextInputFormatter> digitsOnlyFormatter = [
    FilteringTextInputFormatter.digitsOnly,
  ];

  /// Input formatters for 10-digit phone numbers
  static final List<TextInputFormatter> phoneFormatter = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(10),
  ];

  /// Validates that name fields contain ONLY letters/characters, not numbers
  static String? validateName(String? value, {String fieldName = 'Member Name'}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    final trimmed = value.trim();
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(trimmed)) {
      return '$fieldName must only contain letters, not numbers';
    }
    if (trimmed.length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    return null;
  }

  /// Validates that quantity fields contain ONLY valid positive numbers, not characters
  static String? validateQuantity(String? value, {String fieldName = 'Milk quantity'}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    final trimmed = value.trim();
    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      return '$fieldName must only contain numbers, not characters';
    }
    if (parsed <= 0) {
      return '$fieldName must be greater than 0';
    }
    return null;
  }

  /// Validates FAT percentage (typically 2.0% - 15.0%)
  static String? validateFat(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter FAT %';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'FAT must be a valid number';
    }
    if (parsed < 1.0 || parsed > 15.0) {
      return 'FAT must be between 1.0% and 15.0%';
    }
    return null;
  }

  /// Validates SNF percentage (typically 5.0% - 12.0%)
  static String? validateSnf(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter SNF %';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'SNF must be a valid number';
    }
    if (parsed < 5.0 || parsed > 13.0) {
      return 'SNF must be between 5.0% and 13.0%';
    }
    return null;
  }

  /// Validates monetary amounts (must be positive numbers only)
  static String? validateAmount(String? value, {String fieldName = 'Amount'}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return '$fieldName must only contain numbers';
    }
    if (parsed <= 0) {
      return '$fieldName must be greater than 0';
    }
    return null;
  }

  /// Validates Indian 10-digit mobile phone number
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter phone number';
    }
    final trimmed = value.trim();
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(trimmed)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }
}
