import 'package:flutter/material.dart';

import '../domain/input_validation.dart';
import '../domain/models.dart';
import '../domain/statistics.dart';
import 'currency_meta.dart';
import 'format.dart';
import 'rates_controller.dart';
import 'theme.dart';
import 'widgets/common.dart';
import 'widgets/rate_chart.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({
    super.key,
    required this.controller,
    required this.onOpenWeek,
  });

  final RatesController controller;
  final VoidCallback onOpenWeek;

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final _amount = TextEditingController(text: '100');
  static const _amountValidator = AmountValidator();
  static const _pairValidator = PairValidator();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  RatesController get c => widget.controller;

  Future<void> _pick({required bool isFrom}) async {
    final code = await showCurrencyPicker(
      context,
      options: c.currencies,
      selected: isFrom ? c.from : c.to,
      title: isFrom ? 'Конвертировать из' : 'Конвертировать в',
    );
    if (code == null) return;
    isFrom ? c.setFrom(code) : c.setTo(code);
  }

  @override
  Widget build(BuildContext context) {
    final history = c.history!;
    final latest = history.latest;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final amount = _amountValidator.validate(_amount.text);
    final pair = _pairValidator.validate(c.from, c.to, c.availableCodes);
    final rate = pair.isValid ? latest.crossRate(c.from, c.to) : null;
    final inverse = pair.isValid ? latest.crossRate(c.to, c.from) : null;

    final week = pair.isValid
        ? pairSeries(history.lastDays(7, c.today), c.from, c.to)
        : <RatePoint>[];
    final weekStats = const StatisticsCalculator().compute(week);

    return RefreshIndicator(
      onRefresh: c.load,
      edgeOffset: MediaQuery.paddingOf(context).top,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          GradientHeader(
            title: 'Конвертер валют',
            subtitle: 'Официальные курсы Национального банка Молдовы',
            status: DataStatusPill(
              history: history,
              now: c.now,
              onRetry: c.load,
            ),
            child: Card(
              elevation: 6,
              shadowColor: Brand.sapphireDeep.withValues(alpha: 0.25),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Сумма',
                      style: text.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('amountField'),
                      controller: _amount,
                      onChanged: (_) => setState(() {}),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: text.headlineSmall,
                      decoration: InputDecoration(
                        hintText: '0,00',
                        errorText: amount.error,
                        suffixText: c.from,
                        suffixStyle: text.titleMedium?.copyWith(
                          color: scheme.primary,
                        ),
                        prefixIcon: const Icon(Icons.payments_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          children: [
                            CurrencyButton(
                              label: 'Из',
                              code: c.from,
                              onTap: () => _pick(isFrom: true),
                            ),
                            const SizedBox(height: 10),
                            CurrencyButton(
                              label: 'В',
                              code: c.to,
                              onTap: () => _pick(isFrom: false),
                            ),
                          ],
                        ),
                        Positioned(
                          right: 52,
                          child: Material(
                            color: Brand.gold,
                            shape: CircleBorder(
                              side: BorderSide(color: scheme.surface, width: 4),
                            ),
                            elevation: 2,
                            child: IconButton(
                              tooltip: 'Поменять местами',
                              onPressed: c.swap,
                              icon: const Icon(
                                Icons.swap_vert_rounded,
                                color: Color(0xFF2B1F00),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _ResultBlock(
                      amountError: amount.error,
                      pairError: pair.error,
                      amount: amount.value,
                      rate: rate,
                      inverse: inverse,
                      from: c.from,
                      to: c.to,
                      date: latest.date,
                    ),
                  ],
                ),
              ),
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
                if (weekStats != null)
                  _WeekTeaser(
                    from: c.from,
                    to: c.to,
                    points: week,
                    stats: weekStats,
                    onOpen: widget.onOpenWeek,
                  ),
                const SizedBox(height: 16),
                _PopularRates(controller: c),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBlock extends StatelessWidget {
  const _ResultBlock({
    required this.amountError,
    required this.pairError,
    required this.amount,
    required this.rate,
    required this.inverse,
    required this.from,
    required this.to,
    required this.date,
  });

  final String? amountError;
  final String? pairError;
  final double? amount;
  final double? rate;
  final double? inverse;
  final String from;
  final String to;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    Widget body;
    if (pairError != null) {
      body = Row(
        children: [
          Icon(Icons.info_outline_rounded, color: scheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(pairError!, style: TextStyle(color: scheme.error)),
          ),
        ],
      );
    } else if (amountError != null || amount == null || rate == null) {
      body = Text(
        'Введите сумму, чтобы увидеть результат',
        style: TextStyle(color: scheme.onSurfaceVariant),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${formatMoney(amount!)} $from =',
            style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${formatMoney(amount! * rate!)} $to',
              key: const Key('conversionResult'),
              style: text.headlineMedium?.copyWith(
                color: scheme.primary,
                fontSize: 34,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RateChip(text: '1 $from = ${formatRate(rate!)} $to'),
              _RateChip(text: '1 $to = ${formatRate(inverse!)} $from'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.account_balance_rounded,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Официальный курс НБМ на ${formatDate(date)}',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: body,
      ),
    );
  }
}

class _RateChip extends StatelessWidget {
  const _RateChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _WeekTeaser extends StatelessWidget {
  const _WeekTeaser({
    required this.from,
    required this.to,
    required this.points,
    required this.stats,
    required this.onOpen,
  });

  final String from;
  final String to;
  final List<RatePoint> points;
  final PeriodStats stats;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.trend(stats.trend);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$from → $to за 7 дней',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${formatSignedRate(stats.absoluteChange)} $to',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TrendBadge(trend: stats.trend, percent: stats.percentChange),
                ],
              ),
              const SizedBox(height: 12),
              Sparkline(points: points, color: color),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Подробная аналитика →',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Курсы популярных валют к MDL с изменением за день.
class _PopularRates extends StatelessWidget {
  const _PopularRates({required this.controller});

  final RatesController controller;

  @override
  Widget build(BuildContext context) {
    final days = controller.history!.days;
    final latest = days.last;
    final previous = days.length > 1 ? days[days.length - 2] : null;
    final scheme = Theme.of(context).colorScheme;
    final codes = popularCurrencies.where(
      (c) => c != baseCurrency && latest.rateFor(c) != null,
    );

    return SectionCard(
      title: 'Популярные валюты',
      subtitle: 'Стоимость 1 единицы в MDL и изменение за день',
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        children: [
          for (final code in codes)
            Builder(
              builder: (context) {
                final now = latest.mdlPerUnit(code)!;
                final before = previous?.mdlPerUnit(code);
                final pct = before == null
                    ? 0.0
                    : (now - before) / before * 100;
                final trend = const StatisticsCalculator().trendFor(pct);
                final color = context.colors.trend(trend);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      FlagBadge(code: code, size: 38),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              code,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              currencyName(code),
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatRate(now),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                TrendBadge.iconFor(trend),
                                size: 15,
                                color: color,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                formatPercent(pct),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
