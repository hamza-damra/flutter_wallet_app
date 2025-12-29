import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Helper class for locale-aware formatting of dates, numbers, and currencies
class FormatHelper {
  /// Private constructor to prevent instantiation
  FormatHelper._();

  // ============ CURRENCY FORMATTING ============

  /// Format amount as currency (ILS - Israeli Shekel)
  static String formatCurrency(double amount, {Locale? locale}) {
    final loc = locale?.toString() ?? 'en';
    final format = NumberFormat.currency(
      locale: loc,
      symbol: '₪',
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  /// Format amount as compact currency for large numbers
  static String formatCompactCurrency(double amount, {Locale? locale}) {
    final loc = locale?.toString() ?? 'en';
    final format = NumberFormat.compactCurrency(
      locale: loc,
      symbol: '₪',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  /// Format amount with sign (+ for positive/income, - for negative/expense)
  static String formatSignedCurrency(
    double amount, {
    required bool isIncome,
    Locale? locale,
  }) {
    final formatted = formatCurrency(amount.abs(), locale: locale);
    return isIncome ? '+$formatted' : formatted;
  }

  // ============ NUMBER FORMATTING ============

  /// Format number with locale-specific grouping
  static String formatNumber(num number, {Locale? locale, int? decimalDigits}) {
    final loc = locale?.toString() ?? 'en';
    final format = NumberFormat.decimalPattern(loc);
    if (decimalDigits != null) {
      format.minimumFractionDigits = decimalDigits;
      format.maximumFractionDigits = decimalDigits;
    }
    return format.format(number);
  }

  /// Format percentage
  static String formatPercent(
    double value, {
    Locale? locale,
    int decimalDigits = 1,
  }) {
    final loc = locale?.toString() ?? 'en';
    final format = NumberFormat.percentPattern(loc);
    format.maximumFractionDigits = decimalDigits;
    return format.format(value);
  }

  /// Format as compact number (e.g., 1.2K, 3.4M)
  static String formatCompact(num number, {Locale? locale}) {
    final loc = locale?.toString() ?? 'en';
    return NumberFormat.compact(locale: loc).format(number);
  }

  // ============ DATE FORMATTING ============

  /// Format date as full (e.g., "December 29, 2025" or "29 ديسمبر 2025")
  static String formatDateFull(DateTime date, {Locale? locale}) {
    final loc = locale?.toString() ?? 'en';
    return DateFormat.yMMMMd(loc).format(date);
  }

  /// Format date as medium (e.g., "Dec 29, 2025")
  static String formatDateMedium(DateTime date, {Locale? locale}) {
    final loc = locale?.toString() ?? 'en';
    return DateFormat.yMMMd(loc).format(date);
  }

  /// Format date as short (e.g., "12/29/25")
  static String formatDateShort(DateTime date, {Locale? locale}) {
    final loc = locale?.toString() ?? 'en';
    return DateFormat.yMd(loc).format(date);
  }

  /// Format time (e.g., "3:45 PM")
  static String formatTime(DateTime date, {Locale? locale}) {
    final loc = locale?.toString() ?? 'en';
    return DateFormat.jm(loc).format(date);
  }

  /// Format date and time
  static String formatDateTime(DateTime date, {Locale? locale}) {
    final loc = locale?.toString() ?? 'en';
    return DateFormat.yMd(loc).add_jm().format(date);
  }

  /// Format as relative time (Today, Yesterday, or date)
  static String formatRelativeDate(DateTime date, {Locale? locale}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;

    // For relative dates, we'd need localized strings
    // This is a simplified version - full implementation uses l10n
    if (difference == 0) {
      return formatTime(date, locale: locale); // Show time for today
    } else if (difference == 1) {
      return formatDateMedium(date, locale: locale);
    } else if (difference < 7) {
      final loc = locale?.toString() ?? 'en';
      return DateFormat.EEEE(loc).format(date); // Day name
    } else {
      return formatDateMedium(date, locale: locale);
    }
  }

  /// Format month and year (e.g., "December 2025")
  static String formatMonthYear(DateTime date, {Locale? locale}) {
    final loc = locale?.toString() ?? 'en';
    return DateFormat.yMMMM(loc).format(date);
  }

  /// Format day of week (e.g., "Sunday")
  static String formatDayOfWeek(DateTime date, {Locale? locale}) {
    final loc = locale?.toString() ?? 'en';
    return DateFormat.EEEE(loc).format(date);
  }

  // ============ CONTEXT-AWARE FORMATTING ============

  /// Get locale from BuildContext
  static Locale getLocale(BuildContext context) {
    return Localizations.localeOf(context);
  }

  /// Format currency using context locale
  static String currencyFromContext(BuildContext context, double amount) {
    return formatCurrency(amount, locale: getLocale(context));
  }

  /// Format date using context locale
  static String dateFromContext(BuildContext context, DateTime date) {
    return formatDateMedium(date, locale: getLocale(context));
  }

  /// Format number using context locale
  static String numberFromContext(BuildContext context, num number) {
    return formatNumber(number, locale: getLocale(context));
  }
}

/// Extension on num for easy formatting
extension NumFormatExtension on num {
  /// Format as currency
  String toCurrency({Locale? locale}) =>
      FormatHelper.formatCurrency(toDouble(), locale: locale);

  /// Format as compact number
  String toCompact({Locale? locale}) =>
      FormatHelper.formatCompact(this, locale: locale);

  /// Format with locale grouping
  String toLocaleString({Locale? locale}) =>
      FormatHelper.formatNumber(this, locale: locale);
}

/// Extension on DateTime for easy formatting
extension DateTimeFormatExtension on DateTime {
  /// Format as full date
  String toFullDate({Locale? locale}) =>
      FormatHelper.formatDateFull(this, locale: locale);

  /// Format as medium date
  String toMediumDate({Locale? locale}) =>
      FormatHelper.formatDateMedium(this, locale: locale);

  /// Format as short date
  String toShortDate({Locale? locale}) =>
      FormatHelper.formatDateShort(this, locale: locale);

  /// Format time only
  String toTimeString({Locale? locale}) =>
      FormatHelper.formatTime(this, locale: locale);

  /// Format as date and time
  String toDateTimeString({Locale? locale}) =>
      FormatHelper.formatDateTime(this, locale: locale);
}
