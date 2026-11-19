import 'package:flutter/material.dart';

import '../domain/input_validation.dart';
import '../domain/models.dart';
import '../domain/statistics.dart';
import 'format.dart';
import 'rates_controller.dart';
import 'theme.dart';
import 'widgets/common.dart';
import 'widgets/rate_chart.dart';

/// Экран сравнения за период: график, минимум, максимум, среднее,
/// изменение в единицах и процентах, направление тенденции.
class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({
    super.key,
    required this.controller,
    required this.days,
  });

  final RatesController controller;
  final int days;

  String get _title => days == 7 ? 'Динамика за неделю' : 'Динамика за месяц';

  Future<void> _pick(BuildContext context, {required bool isFrom}) async {
    final code = await showCurrencyPicker(
      context,
      options: controller.currencies,
      selected: isFrom ? controller.from : controller.to,
      title: isFrom ? 'Базовая валюта' : 'Валюта котировки',
    );
    if (code == null) return;
    isFrom ? controller.setFrom(code) : controller.setTo(code);
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final history = c.history!;
    final today = c.today;
    final periodStart = today.subtract(Duration(days: days - 1));

    final pair = const PairValidator().validate(c.from, c.to, c.availableCodes);
    final points = pair.isValid
        ? pairSeries(history.lastDays(days, today), c.from, c.to)
        : <RatePoint>[];
    final stats = const StatisticsCalculator().compute(points);
    final coverage = coverageNote(points.length, days);

    return RefreshIndicator(
      onRefresh: c.load,
      edgeOffset: MediaQuery.paddingOf(context).top,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          GradientHeader(
            title: _title,
            subtitle:
                '${formatDayMonth(periodStart)} — ${formatDate(today)} · ${pluralDays(days)}',
            status: DataStatusPill(
              history: history,
              now: c.now,
              onRetry: c.load,
            ),
            child: _PairHeroCard(
              from: c.from,
              to: c.to,
              stats: stats,
              pairError: pair.error,
              onPickFrom: () => _pick(context, isFrom: true),
              onPickTo: () => _pick(context, isFrom: false),
              onSwap: c.swap,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (history.offline) ...[
                  OfflineNotice(history: history, now: c.now),
                  const SizedBox(height: 16),
                ],
                if (stats == null)
                  SectionCard(
                    child: EmptyDataView(
                      message:
                          pair.error ??
                          'За выбранный период нет курсов для пары ${c.from}/${c.to}. '
                              'Подключитесь к интернету и потяните экран вниз, чтобы обновить.',
                    ),
                  )
                else ...[
                  SectionCard(
                    title: 'График курса',
                    subtitle: '1 ${c.from} в ${c.to} по дням · данные НБМ',
                    padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RateChart(
                          points: points,
                          stats: stats,
                          height: days == 7 ? 220 : 240,
                        ),
                        const SizedBox(height: 8),
                        const _ChartLegend(),
                      ],
                    ),
                  ),
                  if (coverage != null) ...[
                    const SizedBox(height: 12),
                    _InfoLine(icon: Icons.info_outline_rounded, text: coverage),
                  ],
                  const SizedBox(height: 16),
                  _StatsGrid(stats: stats, unit: c.to),
                  const SizedBox(height: 16),
                  _TrendSummary(
                    stats: stats,
                    from: c.from,
                    to: c.to,
                    days: days,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PairHeroCard extends StatelessWidget {
  const _PairHeroCard({
    required this.from,
    required this.to,
    required this.stats,
    required this.pairError,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onSwap,
  });

  final String from;
  final String to;
  final PeriodStats? stats;
  final String? pairError;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 6,
      shadowColor: Brand.sapphireDeep.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: CurrencyButton(
                    label: 'Из',
                    code: from,
                    onTap: onPickFrom,
                    compact: true,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: IconButton.filled(
                    tooltip: 'Поменять местами',
                    style: IconButton.styleFrom(
                      backgroundColor: Brand.gold,
                      foregroundColor: const Color(0xFF2B1F00),
                    ),
                    onPressed: onSwap,
                    icon: const Icon(Icons.swap_horiz_rounded),
                  ),
                ),
                Expanded(
                  child: CurrencyButton(
                    label: 'В',
                    code: to,
                    onTap: onPickTo,
                    compact: true,
                  ),
                ),
              ],
            ),
            if (stats != null) ...[
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Курс на ${formatDate(stats!.last.date)}',
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: formatRate(stats!.last.value),
                                    style: text.headlineMedium?.copyWith(
                                      color: scheme.primary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '  $to',
                                    style: text.titleMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            'за 1 $from',
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TrendBadge(
                      trend: stats!.trend,
                      percent: stats!.percentChange,
                      large: true,
                    ),
                  ],
                ),
              ),
            ] else if (pairError != null) ...[
              const SizedBox(height: 12),
              Text(pairError!, style: TextStyle(color: scheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    Widget item(Widget mark, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11.5, color: muted)),
      ],
    );
    Widget dot(Color color) => Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          item(Container(width: 16, height: 2.5, color: c.chartLine), 'курс'),
          item(Container(width: 16, height: 2, color: Brand.gold), 'среднее'),
          item(dot(c.trendUp), 'максимум'),
          item(dot(c.trendDown), 'минимум'),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats, required this.unit});

  final PeriodStats stats;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final changeColor = c.trend(stats.trend);
    final tiles = [
      _StatTile(
        icon: Icons.arrow_downward_rounded,
        accent: c.trendDown,
        label: 'Минимум',
        value: formatRate(stats.min.value),
        unit: unit,
        caption: formatDate(stats.min.date),
      ),
      _StatTile(
        icon: Icons.arrow_upward_rounded,
        accent: c.trendUp,
        label: 'Максимум',
        value: formatRate(stats.max.value),
        unit: unit,
        caption: formatDate(stats.max.date),
      ),
      _StatTile(
        icon: Icons.functions_rounded,
        accent: Brand.gold,
        label: 'Среднее',
        value: formatRate(stats.average),
        unit: unit,
        caption: 'по ${pluralDays(stats.count)}',
      ),
      _StatTile(
        icon: TrendBadge.iconFor(stats.trend),
        accent: changeColor,
        label: 'Изменение',
        value: formatSignedRate(stats.absoluteChange),
        unit: unit,
        caption: formatPercent(stats.percentChange),
        captionColor: changeColor,
      ),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final width = (box.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (final t in tiles) SizedBox(width: width, child: t)],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    required this.unit,
    required this.caption,
    this.captionColor,
  });

  final IconData icon;
  final Color accent;
  final String label;
  final String value;
  final String unit;
  final String caption;
  final Color? captionColor;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: accent),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: value, style: text.titleLarge),
                    TextSpan(
                      text: ' $unit',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              style: text.bodySmall?.copyWith(
                color: captionColor ?? scheme.onSurfaceVariant,
                fontWeight: captionColor != null ? FontWeight.w700 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendSummary extends StatelessWidget {
  const _TrendSummary({
    required this.stats,
    required this.from,
    required this.to,
    required this.days,
  });

  final PeriodStats stats;
  final String from;
  final String to;
  final int days;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.trend(stats.trend);
    final text = Theme.of(context).textTheme;
    final period =
        '${formatDate(stats.first.date)} по ${formatDate(stats.last.date)}';
    // Направление уже названо словами, поэтому в предложении — модули.
    final change =
        '${formatRate(stats.absoluteChange.abs())} $to '
        '(${formatPercent(stats.percentChange.abs()).replaceFirst('+', '')})';
    final signed =
        '${formatSignedRate(stats.absoluteChange)} $to (${formatPercent(stats.percentChange)})';
    final sentence = switch (stats.trend) {
      Trend.up =>
        '$from подорожал относительно $to: с $period курс вырос на $change.',
      Trend.down =>
        '$from подешевел относительно $to: с $period курс снизился на $change.',
      Trend.flat =>
        'С $period курс $from/$to практически не изменился: $signed.',
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.16),
            color.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              TrendBadge.iconFor(stats.trend),
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Тенденция за ${pluralDays(days)}',
                  style: text.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stats.trend.label,
                  style: text.headlineSmall?.copyWith(color: color),
                ),
                const SizedBox(height: 8),
                Text(sentence, style: text.bodyMedium?.copyWith(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 16, color: muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(color: muted, fontSize: 12.5)),
        ),
      ],
    );
  }
}
