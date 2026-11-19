import 'models.dart';

/// Направление тенденции за период.
enum Trend {
  up('Рост'),
  down('Падение'),
  flat('Без изменений');

  const Trend(this.label);
  final String label;
}

/// Статистика показателя за период.
class PeriodStats {
  const PeriodStats({
    required this.count,
    required this.first,
    required this.last,
    required this.min,
    required this.max,
    required this.average,
    required this.absoluteChange,
    required this.percentChange,
    required this.trend,
  });

  final int count;
  final RatePoint first;
  final RatePoint last;
  final RatePoint min;
  final RatePoint max;
  final double average;

  /// `last − first` в единицах показателя.
  final double absoluteChange;

  /// `(last − first) / first × 100`.
  final double percentChange;
  final Trend trend;
}

/// Расчёт статистики для экранов сравнения.
class StatisticsCalculator {
  const StatisticsCalculator({this.flatThresholdPercent = 0.01});

  /// Изменение по модулю меньше этого порога (в процентах) считается
  /// отсутствием изменений. Курсы НБМ публикуются с 4 знаками, а кросс-курсы
  /// получаются делением, поэтому сравнение с нулём «в лоб» ловило бы шум
  /// округления. 0,01 % — это 0,002 MDL при курсе EUR ≈ 20.
  final double flatThresholdPercent;

  /// Возвращает `null` для пустого набора: на экране показывается
  /// «нет данных за период» вместо деления на ноль.
  PeriodStats? compute(List<RatePoint> points) {
    if (points.isEmpty) return null;
    final sorted = [...points]..sort((a, b) => a.date.compareTo(b.date));

    var min = sorted.first;
    var max = sorted.first;
    var sum = 0.0;
    for (final p in sorted) {
      if (p.value < min.value) min = p;
      if (p.value > max.value) max = p;
      sum += p.value;
    }

    final first = sorted.first;
    final last = sorted.last;
    final absolute = last.value - first.value;
    final percent = first.value == 0 ? 0.0 : absolute / first.value * 100;

    return PeriodStats(
      count: sorted.length,
      first: first,
      last: last,
      min: min,
      max: max,
      average: sum / sorted.length,
      absoluteChange: absolute,
      percentChange: percent,
      trend: trendFor(percent),
    );
  }

  Trend trendFor(double percentChange) {
    if (percentChange.abs() < flatThresholdPercent) return Trend.flat;
    return percentChange > 0 ? Trend.up : Trend.down;
  }
}

/// Ряд кросс-курса [from]→[to] по дням. Дни, где нет одной из валют,
/// пропускаются.
List<RatePoint> pairSeries(List<DailyRates> days, String from, String to) => [
  for (final d in days)
    if (d.crossRate(from, to) case final rate?) RatePoint(d.date, rate),
];
