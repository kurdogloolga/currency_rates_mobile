/// Базовые модели предметной области: курсы НБМ за конкретную дату.
library;

/// Код национальной валюты Молдовы. НБМ публикует курсы всех валют в MDL,
/// поэтому для MDL курс всегда равен 1 и в XML он не приходит.
const String baseCurrency = 'MDL';
const String baseCurrencyName = 'Молдавский лей';

/// Отбрасывает время, оставляя только календарную дату (в UTC, чтобы
/// переходы на летнее время не сдвигали дни при вычитании).
DateTime dateOnly(DateTime value) => DateTime.utc(value.year, value.month, value.day);

/// Ключ даты для хранения: `yyyy-MM-dd`.
String dateKey(DateTime date) {
  final d = dateOnly(date);
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

/// Дата для пользователя: `dd.MM.yyyy`.
String formatDate(DateTime date) {
  final d = dateOnly(date);
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '$dd.$mm.${d.year}';
}

/// Курс одной валюты: [value] MDL за [nominal] единиц валюты.
class CurrencyRate {
  const CurrencyRate({
    required this.code,
    required this.name,
    required this.nominal,
    required this.value,
  });

  final String code;
  final String name;
  final double nominal;
  final double value;

  /// Сколько MDL стоит одна единица валюты.
  double get mdlPerUnit => value / nominal;

  Map<String, Object> toJson() => {
        'code': code,
        'name': name,
        'nominal': nominal,
        'value': value,
      };

  factory CurrencyRate.fromJson(Map<String, dynamic> json) => CurrencyRate(
        code: json['code'] as String,
        name: json['name'] as String,
        nominal: (json['nominal'] as num).toDouble(),
        value: (json['value'] as num).toDouble(),
      );
}

/// Полный набор официальных курсов на одну дату.
class DailyRates {
  DailyRates({required DateTime date, required List<CurrencyRate> rates})
      : date = dateOnly(date),
        rates = List.unmodifiable(rates);

  final DateTime date;
  final List<CurrencyRate> rates;

  CurrencyRate? rateFor(String code) {
    for (final r in rates) {
      if (r.code == code) return r;
    }
    return null;
  }

  /// MDL за единицу валюты [code]; `null`, если валюты нет в публикации.
  double? mdlPerUnit(String code) {
    if (code == baseCurrency) return 1;
    return rateFor(code)?.mdlPerUnit;
  }

  /// Кросс-курс: сколько единиц [to] стоит одна единица [from].
  double? crossRate(String from, String to) {
    final fromMdl = mdlPerUnit(from);
    final toMdl = mdlPerUnit(to);
    if (fromMdl == null || toMdl == null) return null;
    return fromMdl / toMdl;
  }

  Map<String, Object> toJson() => {
        'date': dateKey(date),
        'rates': rates.map((r) => r.toJson()).toList(),
      };

  factory DailyRates.fromJson(Map<String, dynamic> json) => DailyRates(
        date: DateTime.parse(json['date'] as String),
        rates: (json['rates'] as List)
            .map((e) => CurrencyRate.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Точка временного ряда для графиков и статистики.
class RatePoint {
  const RatePoint(this.date, this.value);

  final DateTime date;
  final double value;

  @override
  String toString() => 'RatePoint(${dateKey(date)}, $value)';
}
