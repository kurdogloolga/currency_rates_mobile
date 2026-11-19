import '../domain/models.dart';

/// Аккуратные русские названия валют для интерфейса. В XML НБМ встречаются
/// разный регистр («Российский Рубль») и латинские буквы вместо кириллических
/// («доллаp», «pупия»), поэтому показываем свои названия, а название из
/// источника используем, только если валюты нет в справочнике.
const Map<String, String> _names = {
  'MDL': 'Молдавский лей',
  'EUR': 'Евро',
  'USD': 'Доллар США',
  'RUB': 'Российский рубль',
  'RON': 'Румынский лей',
  'UAH': 'Украинская гривна',
  'AED': 'Дирхам ОАЭ',
  'ALL': 'Албанский лек',
  'AMD': 'Армянский драм',
  'AUD': 'Австралийский доллар',
  'AZN': 'Азербайджанский манат',
  'BGN': 'Болгарский лев',
  'BYN': 'Белорусский рубль',
  'CAD': 'Канадский доллар',
  'CHF': 'Швейцарский франк',
  'CNY': 'Китайский юань',
  'CZK': 'Чешская крона',
  'DKK': 'Датская крона',
  'GBP': 'Фунт стерлингов',
  'GEL': 'Грузинский лари',
  'HKD': 'Гонконгский доллар',
  'HUF': 'Венгерский форинт',
  'ILS': 'Израильский шекель',
  'INR': 'Индийская рупия',
  'ISK': 'Исландская крона',
  'JPY': 'Японская иена',
  'KGS': 'Киргизский сом',
  'KRW': 'Южнокорейская вона',
  'KWD': 'Кувейтский динар',
  'KZT': 'Казахстанский тенге',
  'MKD': 'Македонский денар',
  'MYR': 'Малайзийский ринггит',
  'NOK': 'Норвежская крона',
  'NZD': 'Новозеландский доллар',
  'PLN': 'Польский злотый',
  'RSD': 'Сербский динар',
  'SEK': 'Шведская крона',
  'TJS': 'Таджикский сомони',
  'TMT': 'Туркменский манат',
  'TRY': 'Турецкая лира',
  'UZS': 'Узбекский сум',
  'XDR': 'Специальные права заимствования',
};

/// Валюты, которые показываются первыми в списках.
const List<String> popularCurrencies = ['MDL', 'EUR', 'USD', 'RON', 'UAH', 'RUB', 'GBP'];

String currencyName(String code, {String? fallback}) =>
    _names[code] ?? fallback ?? code;

/// Флаг-эмодзи: первые две буквы кода ISO 4217 — это код страны.
String currencyFlag(String code) {
  if (code == 'EUR') return '🇪🇺';
  if (code.startsWith('X') || code.length != 3) return '🌐';
  const base = 0x1F1E6;
  final a = code.codeUnitAt(0) - 0x41;
  final b = code.codeUnitAt(1) - 0x41;
  return String.fromCharCodes([base + a, base + b]);
}

class CurrencyOption {
  const CurrencyOption(this.code, this.name, this.mdlPerUnit);

  final String code;
  final String name;
  final double mdlPerUnit;

  String get flag => currencyFlag(code);
}

/// Все валюты дня + MDL; популярные сверху, остальные по коду.
List<CurrencyOption> currencyOptions(DailyRates day) {
  final options = <CurrencyOption>[
    const CurrencyOption(baseCurrency, 'Молдавский лей', 1),
    for (final r in day.rates)
      CurrencyOption(r.code, currencyName(r.code, fallback: r.name), r.mdlPerUnit),
  ];
  int rank(String code) {
    final i = popularCurrencies.indexOf(code);
    return i < 0 ? popularCurrencies.length : i;
  }

  options.sort((a, b) {
    final byRank = rank(a.code).compareTo(rank(b.code));
    return byRank != 0 ? byRank : a.code.compareTo(b.code);
  });
  return options;
}
