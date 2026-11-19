import '../domain/models.dart';
import 'bnm_client.dart';
import 'rate_cache.dart';

/// Результат загрузки истории курсов.
class RatesHistory {
  const RatesHistory({
    required this.days,
    required this.requestedDays,
    required this.offline,
    this.lastSync,
    this.warning,
  });

  /// Дни с данными, по возрастанию даты.
  final List<DailyRates> days;

  /// Сколько календарных дней запрашивалось.
  final int requestedDays;

  /// `true`, если источник был недоступен и часть или все данные взяты из кэша.
  final bool offline;

  /// Когда в последний раз удалось получить данные из источника.
  final DateTime? lastSync;

  /// Сообщение о последней ошибке источника (если данные всё же есть).
  final String? warning;

  DailyRates get latest => days.last;

  /// Дни за последние [count] календарных дней, заканчивая [today].
  List<DailyRates> lastDays(int count, DateTime today) {
    final from = dateOnly(today).subtract(Duration(days: count - 1));
    return days.where((d) => !d.date.isBefore(from)).toList();
  }
}

/// Данных нет ни в источнике, ни в кэше.
class RatesUnavailableException implements Exception {
  const RatesUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'RatesUnavailableException: $message';
}

/// Объединяет источник и кэш.
///
/// Стратегия: курсы прошедших дат неизменны, поэтому каждый день запрашивается
/// у НБМ один раз и далее берётся из кэша. Сегодняшний день запрашивается при
/// каждой загрузке — это и есть проверка связи с источником.
class RateRepository {
  RateRepository({
    required this.client,
    required this.cache,
    DateTime Function()? now,
    this.parallelRequests = 6,
  }) : _now = now ?? DateTime.now;

  final BnmClient client;
  final RateCache cache;
  final DateTime Function() _now;
  final int parallelRequests;

  /// Сколько дней хранить в кэше сверх запрошенного периода.
  static const retentionDays = 60;

  Future<RatesHistory> loadHistory({int days = 30}) async {
    final today = dateOnly(_now());
    final dates = [
      for (var i = days - 1; i >= 0; i--) today.subtract(Duration(days: i)),
    ];

    Map<DateTime, DailyRates> cached;
    try {
      cached = await cache.loadAll();
    } catch (_) {
      cached = {};
    }
    final toFetch = dates.where((d) => d == today || !cached.containsKey(d)).toList();

    final fetched = <DailyRates>[];
    SourceException? lastError;
    var failures = 0;

    for (var i = 0; i < toFetch.length; i += parallelRequests) {
      final chunk = toFetch.skip(i).take(parallelRequests);
      final results = await Future.wait(chunk.map((date) async {
        try {
          return await client.fetch(date);
        } on SourceException catch (e) {
          failures++;
          lastError = e;
          return null;
        }
      }));
      fetched.addAll(results.whereType<DailyRates>());
      // Нет сети — нет смысла перебирать оставшиеся 30 дат по тайм-ауту.
      if (lastError != null &&
          (lastError!.kind == SourceErrorKind.network ||
              lastError!.kind == SourceErrorKind.timeout)) {
        break;
      }
    }

    final merged = {...cached};
    for (final day in fetched) {
      merged[day.date] = day;
    }

    try {
      if (fetched.isNotEmpty) {
        await cache.saveAll(fetched,
            retainSince: today.subtract(const Duration(days: retentionDays)));
      }
      if (failures == 0) await cache.setLastSync(_now());
    } catch (_) {
      // Ошибка записи кэша не должна мешать показать свежие данные.
    }

    final first = dates.first;
    final result = merged.values
        .where((d) => !d.date.isBefore(first) && !d.date.isAfter(today))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (result.isEmpty) {
      throw RatesUnavailableException(lastError == null
          ? 'Источник не опубликовал курсы за выбранный период'
          : '${lastError!.message}. Сохранённых данных пока нет — '
              'подключитесь к интернету и повторите попытку.');
    }

    return RatesHistory(
      days: result,
      requestedDays: days,
      offline: lastError != null,
      lastSync: await _safeLastSync(),
      warning: lastError?.message,
    );
  }

  Future<DateTime?> _safeLastSync() async {
    try {
      return await cache.lastSync();
    } catch (_) {
      return null;
    }
  }
}
