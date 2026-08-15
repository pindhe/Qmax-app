import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class Validators {
  static String? requiredField(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return l10n.requiredField;
    return null;
  }

  static String? email(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return l10n.requiredField;
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value.trim())) return l10n.invalidEmail;
    return null;
  }

  static String? phone(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return l10n.requiredField;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final valid = RegExp(r'^(252)?6[3-9]\d{7}$').hasMatch(digits) ||
        RegExp(r'^0?6[3-9]\d{7}$').hasMatch(digits);
    if (!valid) return l10n.invalidPhone;
    return null;
  }

  static String? phoneOrEmail(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return l10n.requiredField;
    if (value.contains('@')) return email(value, l10n);
    return phone(value, l10n);
  }

  static String? password(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.requiredField;
    final strong = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$').hasMatch(value);
    if (!strong) return l10n.passwordTooWeak;
    return null;
  }

  static String? confirmPassword(
    String? value,
    String original,
    AppLocalizations l10n,
  ) {
    if (value == null || value.isEmpty) return l10n.requiredField;
    if (value != original) return l10n.passwordsDoNotMatch;
    return null;
  }

  static String? otp(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().length != 6) return l10n.requiredField;
    return null;
  }
}

class Formatters {
  static String money(num value, {String symbol = r'$'}) {
    return '$symbol${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}';
  }

  static String orderNumber(String value) => value.startsWith('QMAX-')
      ? value
      : 'QMAX-$value';

  static String greeting(TimeOfDay time, AppLocalizations l10n) {
    if (time.hour < 12) return l10n.goodMorning;
    if (time.hour < 17) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }

  static String phoneDisplay(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 9) {
      return '+${digits.substring(0, digits.length - 9)} ${digits.substring(digits.length - 9, digits.length - 7)} ${digits.substring(digits.length - 7, digits.length - 4)} ${digits.substring(digits.length - 4)}'
          .trim();
    }
    return raw;
  }
}

class Helpers {
  static int crossAxisCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 4;
    if (width >= 840) return 3;
    return 2;
  }

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= 600;
}
