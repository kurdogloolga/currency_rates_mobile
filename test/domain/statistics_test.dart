import 'package:currency_rates/domain/models.dart';
import 'package:currency_rates/domain/statistics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

List<RatePoint> series(List<double> values) => [
  for (var i = 0; i < values.length; i++)
    RatePoint(DateTime.utc(2026, 11, 1 + i), values[i]),
];

void main() {
  const calc = StatisticsCalculator();

  group('StatisticsCalculator', () {
    test('минимум, максимум, среднее и даты экстремумов', () {
      final stats = calc.compute(series([20, 22, 19, 21]))!;
      expect(stats.min.value, 19);
      expect(stats.min.date, DateTime.utc(2026, 11, 3));
      expect(stats.max.value, 22);
      expect(stats.max.date, DateTime.utc(2026, 11, 2));
      expect(stats.average, closeTo(20.5, 1e-12));
      expect(stats.count, 4);
    });

    test('абсолютное и процентное изменение: рост', () {
      final stats = calc.compute(series([20, 19, 21, 22]))!;
      expect(stats.absoluteChange, closeTo(2, 1e-12));
      expect(stats.percentChange, closeTo(10, 1e-12));
      expect(stats.trend, Trend.up);
    });

    test('падение', () {
      final stats = calc.compute(series([25, 20]))!;
      expect(stats.absoluteChange, closeTo(-5, 1e-12));
      expect(stats.percentChange, closeTo(-20, 1e-12));
      expect(stats.trend, Trend.down);
    });

    test('без изменений: первое и последнее значения равны', () {
      final stats = calc.compute(series([20, 21, 19, 20]))!;
      expect(stats.absoluteChange, 0);
      expect(stats.percentChange, 0);
      expect(stats.trend, Trend.flat);
    });

    test('изменение меньше порога считается отсутствием изменений', () {
      // 20.0000 → 20.0010: +0,005 % < 0,01 %
      expect(calc.compute(series([20, 20.001]))!.trend, Trend.flat);
      // 20.0000 → 20.0100: +0,05 % — уже рост
      expect(calc.compute(series([20, 20.01]))!.trend, Trend.up);
    });

    test('точки сортируются по дате независимо от порядка во входе', () {
      final points = series([20, 21, 22]).reversed.toList();
      final stats = calc.compute(points)!;
      expect(stats.first.value, 20);
      expect(stats.last.value, 22);
      expect(stats.trend, Trend.up);
    });

    test('пустой набор — null, без исключений и деления на ноль', () {
      expect(calc.compute(const []), isNull);
    });

    test('одна точка: min = max = avg, изменение 0, без изменений', () {
      final stats = calc.compute(series([20.1411]))!;
      expect(stats.min.value, 20.1411);
      expect(stats.max.value, 20.1411);
      expect(stats.average, 20.1411);
      expect(stats.absoluteChange, 0);
      expect(stats.percentChange, 0);
      expect(stats.trend, Trend.flat);
    });
  });

  group('pairSeries', () {
    test('строит кросс-курс по дням', () {
      final days = [
        day(DateTime.utc(2026, 11, 1), eur: 20, usd: 16),
        day(DateTime.utc(2026, 11, 2), eur: 21, usd: 16.8),
      ];
      final eurUsd = pairSeries(days, 'EUR', 'USD');
      expect(eurUsd.map((p) => p.value), [
        closeTo(1.25, 1e-12),
        closeTo(1.25, 1e-12),
      ]);
      expect(pairSeries(days, 'EUR', 'MDL').map((p) => p.value), [20, 21]);
    });

    test('пропускает дни без нужной валюты', () {
      final days = [
        day(DateTime.utc(2026, 11, 1)),
        DailyRates(date: DateTime.utc(2026, 11, 2), rates: const []),
      ];
      expect(pairSeries(days, 'EUR', 'MDL'), hasLength(1));
    });

    test('пустая история даёт пустой ряд и пустую статистику', () {
      final points = pairSeries(const [], 'EUR', 'MDL');
      expect(points, isEmpty);
      expect(calc.compute(points), isNull);
    });
  });
}
