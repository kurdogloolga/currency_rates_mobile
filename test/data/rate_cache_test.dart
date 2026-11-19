import 'package:currency_rates/data/rate_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';

void main() {
  test('сохранённые курсы читаются новым экземпляром (имитация перезапуска)', () async {
    SharedPreferences.setMockInitialValues({});
    final first = SharedPrefsRateCache(await SharedPreferences.getInstance());
    await first.saveAll([day(DateTime.utc(2026, 11, 18), eur: 20.1)]);
    await first.setLastSync(DateTime(2026, 11, 18, 14, 30));

    final restarted = SharedPrefsRateCache(await SharedPreferences.getInstance());
    final loaded = await restarted.loadAll();
    expect(loaded.keys, [DateTime.utc(2026, 11, 18)]);
    expect(loaded.values.single.rateFor('EUR')!.value, 20.1);
    expect(await restarted.lastSync(), DateTime(2026, 11, 18, 14, 30));
  });

  test('повреждённый JSON в кэше не роняет приложение', () async {
    SharedPreferences.setMockInitialValues({'bnm_rates_v1': '{not json'});
    final cache = SharedPrefsRateCache(await SharedPreferences.getInstance());
    expect(await cache.loadAll(), isEmpty);
  });

  test('удаляет записи старше границы хранения', () async {
    SharedPreferences.setMockInitialValues({});
    final cache = SharedPrefsRateCache(await SharedPreferences.getInstance());
    await cache.saveAll([day(DateTime.utc(2026, 1, 1)), day(DateTime.utc(2026, 11, 1))]);
    await cache.saveAll([day(DateTime.utc(2026, 11, 2))],
        retainSince: DateTime.utc(2026, 10, 1));
    expect((await cache.loadAll()).keys.toSet(),
        {DateTime.utc(2026, 11, 1), DateTime.utc(2026, 11, 2)});
  });
}
