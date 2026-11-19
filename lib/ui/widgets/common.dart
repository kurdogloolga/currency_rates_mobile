import 'package:flutter/material.dart';

import '../../data/rate_repository.dart';
import '../../domain/models.dart';
import '../../domain/statistics.dart';
import '../currency_meta.dart';
import '../format.dart';
import '../theme.dart';

/// Градиентная шапка экрана с декоративными кругами. Высота подстраивается
/// под текст (крупный системный шрифт не обрезается), а [child] — карточка,
/// которая на [overlap] пикселей «наезжает» на нижний край градиента.
class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.status,
    this.overlap = 56,
  });

  final String title;
  final String subtitle;
  final Widget? status;
  final Widget child;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final top = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: overlap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors.headerGradient,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -60,
                    top: -40,
                    child: _Bubble(size: 200, opacity: 0.08),
                  ),
                  Positioned(
                    right: 60,
                    top: top + 70,
                    child: _Bubble(size: 70, opacity: 0.07),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -50,
                    child: _Bubble(size: 140, opacity: 0.06),
                  ),
                  Positioned(
                    right: 24,
                    top: top + 22,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Brand.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24, top + 18, 24, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'КУРСЫ НБМ',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Brand.gold,
                      letterSpacing: 2.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.78)),
                  ),
                  if (status != null) ...[const SizedBox(height: 14), status!],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: child,
            ),
          ],
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: opacity),
    ),
  );
}

/// Плашка актуальности данных в шапке. В офлайне — заметная янтарная.
class DataStatusPill extends StatelessWidget {
  const DataStatusPill({
    super.key,
    required this.history,
    required this.now,
    this.onRetry,
  });

  final RatesHistory history;
  final DateTime now;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final latest = history.latest.date;
    final offline = history.offline;
    final sync = history.lastSync;

    final String text;
    final IconData icon;
    if (offline) {
      icon = Icons.cloud_off_rounded;
      text = 'Нет связи · сохранённый курс на ${formatDate(latest)}';
    } else {
      icon = Icons.verified_rounded;
      text =
          'Курс на ${formatDate(latest)}'
          '${sync != null ? ' · обновлено ${formatMoment(sync, now)}' : ''}';
    }

    final bg = offline
        ? const Color(0xFFFFE08A)
        : Colors.white.withValues(alpha: 0.14);
    final fg = offline ? const Color(0xFF4A3300) : Colors.white;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: offline ? onRetry : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (offline && onRetry != null) ...[
                const SizedBox(width: 6),
                Icon(Icons.refresh_rounded, size: 16, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Подробное предупреждение о работе из кэша (под шапкой).
class OfflineNotice extends StatelessWidget {
  const OfflineNotice({super.key, required this.history, required this.now});

  final RatesHistory history;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sync = history.lastSync;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.warningBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.wifi_off_rounded, color: c.warningFg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Работа без сети',
                  style: TextStyle(
                    color: c.warningFg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Показаны сохранённые курсы, актуальные на ${formatDate(history.latest.date)}.'
                  '${sync != null ? ' Последнее обновление — ${formatMoment(sync, now)}.' : ''}'
                  '${history.warning != null ? '\nПричина: ${history.warning}.' : ''}',
                  style: TextStyle(color: c.warningFg, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Кнопка выбора валюты: флаг, код и название.
class CurrencyButton extends StatelessWidget {
  const CurrencyButton({
    super.key,
    required this.label,
    required this.code,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final String code;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: compact ? 10 : 12,
          ),
          child: Row(
            children: [
              FlagBadge(code: code, size: compact ? 34 : 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(code, style: text.titleMedium),
                    if (!compact)
                      Text(
                        currencyName(code),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.expand_more_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class FlagBadge extends StatelessWidget {
  const FlagBadge({super.key, required this.code, this.size = 40});

  final String code;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Text(currencyFlag(code), style: TextStyle(fontSize: size * 0.52)),
    );
  }
}

/// Нижний лист выбора валюты с поиском по коду и названию.
Future<String?> showCurrencyPicker(
  BuildContext context, {
  required List<CurrencyOption> options,
  required String selected,
  required String title,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        _CurrencyPicker(options: options, selected: selected, title: title),
  );
}

class _CurrencyPicker extends StatefulWidget {
  const _CurrencyPicker({
    required this.options,
    required this.selected,
    required this.title,
  });

  final List<CurrencyOption> options;
  final String selected;
  final String title;

  @override
  State<_CurrencyPicker> createState() => _CurrencyPickerState();
}

class _CurrencyPickerState extends State<_CurrencyPicker> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final q = query.trim().toLowerCase();
    final filtered = widget.options
        .where(
          (o) =>
              q.isEmpty ||
              o.code.toLowerCase().contains(q) ||
              o.name.toLowerCase().contains(q),
        )
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  autofocus: false,
                  onChanged: (v) => setState(() => query = v),
                  decoration: const InputDecoration(
                    hintText: 'Поиск: код или название',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'Ничего не найдено',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    controller: scroll,
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final o = filtered[i];
                      final isSelected = o.code == widget.selected;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 2,
                        ),
                        leading: FlagBadge(code: o.code),
                        title: Text(
                          o.code,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          o.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: scheme.primary,
                              )
                            : Text(
                                o.code == baseCurrency
                                    ? 'базовая'
                                    : '${formatRate(o.mdlPerUnit)} MDL',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                        selected: isSelected,
                        onTap: () => Navigator.of(context).pop(o.code),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Значок тенденции: иконка + подпись + процент (цвет никогда не один).
class TrendBadge extends StatelessWidget {
  const TrendBadge({
    super.key,
    required this.trend,
    this.percent,
    this.large = false,
  });

  final Trend trend;
  final double? percent;
  final bool large;

  static IconData iconFor(Trend t) => switch (t) {
    Trend.up => Icons.trending_up_rounded,
    Trend.down => Icons.trending_down_rounded,
    Trend.flat => Icons.trending_flat_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final color = context.colors.trend(trend);
    final size = large ? 15.0 : 13.0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 10,
        vertical: large ? 7 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconFor(trend), size: size + 5, color: color),
          const SizedBox(width: 6),
          Text(
            percent == null
                ? trend.label
                : '${trend.label} · ${formatPercent(percent!)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: size,
            ),
          ),
        ],
      ),
    );
  }
}

/// Карточка-секция с заголовком.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title!, style: text.titleMedium),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 16),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(strokeWidth: 3.5),
          ),
          const SizedBox(height: 20),
          Text(
            'Загружаем курсы НБМ…',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Получаем историю за 30 дней',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.busy = false,
  });

  final String message;
  final VoidCallback onRetry;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 46,
                color: scheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Курсы недоступны',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: busy ? null : onRetry,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: const Text('Повторить'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Пустое состояние для экранов, где за период нет точек.
class EmptyDataView extends StatelessWidget {
  const EmptyDataView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.insert_chart_outlined_rounded,
            size: 56,
            color: scheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'Нет данных за период',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Доля дней с данными, если период заполнен не полностью.
String? coverageNote(int have, int want) => have >= want
    ? null
    : 'Данные есть за ${pluralDays(have)} из $want — часть дат не загрузилась';
