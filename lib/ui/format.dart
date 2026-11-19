import 'package:intl/intl.dart';

import '../domain/models.dart';

final _money = NumberFormat.decimalPatternDigits(locale: 'ru', decimalDigits: 2);
final _rate4 = NumberFormat.decimalPatternDigits(locale: 'ru', decimalDigits: 4);
final _rate6 = NumberFormat.decimalPatternDigits(locale: 'ru', decimalDigits: 6);
final _percent = NumberFormat.decimalPatternDigits(locale: 'ru', decimalDigits: 2);

/// Денежная сумма: «2 014,11».
String formatMoney(double value) => _money.format(value);

/// Курс: 4 знака, для очень малых значений — 6 («0,000123»).
String formatRate(double value) =>
    value.abs() < 0.01 && value != 0 ? _rate6.format(value) : _rate4.format(value);

/// Курс со знаком: «+0,0905», «−0,0120».
String formatSignedRate(double value) {
  if (value == 0) return formatRate(0);
  final sign = value > 0 ? '+' : '−';
  return '$sign${formatRate(value.abs())}';
}

/// Процент со знаком: «+0,45 %».
String formatPercent(double value) {
  final rounded = double.parse(value.toStringAsFixed(2));
  if (rounded == 0) return '0,00 %';
  final sign = rounded > 0 ? '+' : '−';
  return '$sign${_percent.format(rounded.abs())} %';
}

/// «19.11»
String formatDayMonth(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';

String _time(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// «сегодня в 15:02», «вчера в 09:10», «12.11.2026 в 18:00».
String formatMoment(DateTime moment, DateTime now) {
  final day = dateOnly(moment);
  final today = dateOnly(now);
  if (day == today) return 'сегодня в ${_time(moment)}';
  if (day == today.subtract(const Duration(days: 1))) return 'вчера в ${_time(moment)}';
  return '${formatDate(moment)} в ${_time(moment)}';
}

/// «7 дней», «1 день», «3 дня».
String pluralDays(int n) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  final word = (mod10 == 1 && mod100 != 11)
      ? 'день'
      : (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14))
          ? 'дня'
          : 'дней';
  return '$n $word';
}
