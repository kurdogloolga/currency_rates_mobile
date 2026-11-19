import 'package:currency_rates/data/rate_cache.dart';
import 'package:currency_rates/domain/models.dart';

/// Кэш в памяти для тестов репозитория.
class InMemoryRateCache implements RateCache {
  final Map<DateTime, DailyRates> store = {};
  DateTime? sync;

  @override
  Future<Map<DateTime, DailyRates>> loadAll() async => {...store};

  @override
  Future<void> saveAll(
    Iterable<DailyRates> days, {
    DateTime? retainSince,
  }) async {
    for (final d in days) {
      store[d.date] = d;
    }
    if (retainSince != null) {
      store.removeWhere((date, _) => date.isBefore(dateOnly(retainSince)));
    }
  }

  @override
  Future<DateTime?> lastSync() async => sync;

  @override
  Future<void> setLastSync(DateTime moment) async => sync = moment;
}

/// XML НБМ для даты [date] с курсами EUR и USD.
String bnmXml(DateTime date, {double eur = 20, double usd = 18}) =>
    '''
<?xml version="1.0" encoding="UTF-8"?>
<ValCurs Date="${formatDate(date)}" name="Обменные ставки">
  <Valute ID="47"><NumCode>978</NumCode><CharCode>EUR</CharCode><Nominal>1</Nominal><Name>Евро</Name><Value>$eur</Value></Valute>
  <Valute ID="44"><NumCode>840</NumCode><CharCode>USD</CharCode><Nominal>1</Nominal><Name>Доллар США</Name><Value>$usd</Value></Valute>
</ValCurs>''';

DailyRates day(DateTime date, {double eur = 20, double usd = 18}) => DailyRates(
  date: date,
  rates: [
    CurrencyRate(code: 'EUR', name: 'Евро', nominal: 1, value: eur),
    CurrencyRate(code: 'USD', name: 'Доллар США', nominal: 1, value: usd),
  ],
);
