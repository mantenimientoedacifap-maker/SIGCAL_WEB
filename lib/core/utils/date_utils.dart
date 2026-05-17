import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart' as date_symbols;
import 'package:intl/intl.dart';

class SigecalDateUtils {
  SigecalDateUtils._();

  static bool _localesInitialized = false;

  static Future<void> ensureLocales() async {
    if (_localesInitialized) return;
    await date_symbols.initializeDateFormatting('es', null);
    _localesInitialized = true;
  }

  static DateTime calculateExpirationDate(
    DateTime calibrationDate,
    int validityMonths,
  ) {
    return DateTime(
      calibrationDate.year,
      calibrationDate.month + validityMonths,
      calibrationDate.day,
    );
  }

  static int daysRemaining(DateTime expirationDate, [DateTime? currentDate]) {
    final today = DateUtils.dateOnly(currentDate ?? DateTime.now());
    final expiration = DateUtils.dateOnly(expirationDate);
    return expiration.difference(today).inDays;
  }

  /// "12 de mayo 2026" – for detail views and full dates
  static String formatDateFull(DateTime? date) {
    if (date == null || date.millisecondsSinceEpoch == 0) return '-';
    return DateFormat("d 'de' MMMM yyyy", 'es').format(date);
  }

  /// "12 may 2026" – for dashboards and compact spaces
  static String formatDateCompact(DateTime? date) {
    if (date == null || date.millisecondsSinceEpoch == 0) return '-';
    return DateFormat('d MMM yyyy', 'es').format(date);
  }

  /// "12/05/2026" – for tables and data grids
  static String formatDateShort(DateTime? date) {
    if (date == null || date.millisecondsSinceEpoch == 0) return '-';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Legacy alias – uses short format for backward compat
  static String formatDate(DateTime? date) => formatDateShort(date);
}
