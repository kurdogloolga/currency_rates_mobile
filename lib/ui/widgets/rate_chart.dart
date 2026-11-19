import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/statistics.dart';
import '../format.dart';
import '../theme.dart';

/// Линейный график курса: одна линия 2 px, мягкая заливка, пунктир среднего,
/// отмеченные минимум и максимум, перекрестие с подсказкой при касании.
class RateChart extends StatelessWidget {
  const RateChart({
    super.key,
    required this.points,
    required this.stats,
    this.height = 240,
  });

  final List<RatePoint> points;
  final PeriodStats stats;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    final line = colors.chartLine;
    final muted = scheme.onSurfaceVariant;

    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].value),
    ];
    final range = stats.max.value - stats.min.value;
    final pad = range == 0 ? stats.average.abs() * 0.005 + 1e-6 : range * 0.18;
    final minY = stats.min.value - pad;
    final maxY = stats.max.value + pad;
    final minIndex = points.indexOf(stats.min);
    final maxIndex = points.indexOf(stats.max);
    final labelStep = math.max(1, (points.length / 6).ceil());
    final xPad = math.max(0.25, (points.length - 1) * 0.035);

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          // Поля по X, чтобы крайние точки и подписи дат не обрезались.
          minX: -xPad,
          maxX: math.max(1, spots.length - 1) + xPad,
          minY: minY,
          maxY: maxY,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: scheme.outlineVariant.withValues(alpha: 0.35),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 58,
                interval: (maxY - minY) / 4,
                minIncluded: false,
                maxIncluded: false,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    formatRate(value),
                    style: TextStyle(color: muted, fontSize: 10.5),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i != value || i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final isLast = i == points.length - 1;
                  if (!isLast &&
                      (i % labelStep != 0 ||
                          points.length - 1 - i < labelStep / 2)) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      formatDayMonth(points[i].date),
                      style: TextStyle(color: muted, fontSize: 10.5),
                    ),
                  );
                },
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: stats.average,
                color: Brand.gold,
                strokeWidth: 1.5,
                dashArray: const [6, 5],
              ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              preventCurveOverShooting: true,
              color: line,
              barWidth: 2,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    line.withValues(alpha: 0.28),
                    line.withValues(alpha: 0.0),
                  ],
                ),
              ),
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, _) {
                  final i = spot.x.round();
                  return i == minIndex ||
                      i == maxIndex ||
                      i == points.length - 1;
                },
                getDotPainter: (spot, _, _, _) {
                  final i = spot.x.round();
                  final color = i == maxIndex
                      ? colors.trendUp
                      : i == minIndex
                      ? colors.trendDown
                      : line;
                  return FlDotCirclePainter(
                    radius: 4.5,
                    color: color,
                    strokeWidth: 2,
                    strokeColor: scheme.surface,
                  );
                },
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            getTouchedSpotIndicator: (bar, indexes) => [
              for (final _ in indexes)
                TouchedSpotIndicatorData(
                  FlLine(
                    color: muted.withValues(alpha: 0.5),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                  FlDotData(
                    getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                      radius: 6,
                      color: line,
                      strokeWidth: 2.5,
                      strokeColor: scheme.surface,
                    ),
                  ),
                ),
            ],
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              tooltipBorderRadius: BorderRadius.circular(12),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              getTooltipColor: (_) => scheme.inverseSurface,
              getTooltipItems: (touched) => [
                for (final s in touched)
                  LineTooltipItem(
                    '${formatDate(points[s.x.round()].date)}\n',
                    TextStyle(
                      color: scheme.onInverseSurface.withValues(alpha: 0.75),
                      fontSize: 11,
                    ),
                    children: [
                      TextSpan(
                        text: formatRate(s.y),
                        style: TextStyle(
                          color: scheme.onInverseSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        duration: const Duration(milliseconds: 350),
      ),
    );
  }
}

/// Мини-график без осей для карточек.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.points,
    required this.color,
    this.height = 56,
  });

  final List<RatePoint> points;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return SizedBox(height: height);
    final values = points.map((p) => p.value);
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final pad = hi == lo ? lo.abs() * 0.005 + 1e-6 : (hi - lo) * 0.15;
    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: lo - pad,
          maxY: hi + pad,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].value),
              ],
              isCurved: true,
              preventCurveOverShooting: true,
              color: color,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.22),
                    color.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
