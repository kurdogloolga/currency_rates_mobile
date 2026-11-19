import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

/// Локальное хранилище курсов, переживающее перезапуск приложения.
abstract class RateCache {
  /// Все сохранённые дни. Повреждённое содержимое не должно ронять приложение —
  /// в этом случае возвращается пустая карта.
  Future<Map<DateTime, DailyRates>> loadAll();

  /// Добавляет/перезаписывает дни и удаляет записи старше [retainSince].
  Future<void> saveAll(Iterable<DailyRates> days, {DateTime? retainSince});

  /// Момент последнего успешного обращения к источнику.
  Future<DateTime?> lastSync();

  Future<void> setLastSync(DateTime moment);
}

/// Реализация на SharedPreferences: один JSON-документ с картой
/// `yyyy-MM-dd → курсы дня`. Объём — около 40 валют × 30–60 дней, что
/// укладывается в десятки килобайт.
class SharedPrefsRateCache implements RateCache {
  SharedPrefsRateCache(this._prefs);

  static const _ratesKey = 'bnm_rates_v1';
  static const _syncKey = 'bnm_last_sync_v1';

  final SharedPreferences _prefs;

  @override
  Future<Map<DateTime, DailyRates>> loadAll() async {
    final raw = _prefs.getString(_ratesKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final result = <DateTime, DailyRates>{};
      for (final entry in decoded.values) {
        final day = DailyRates.fromJson(entry as Map<String, dynamic>);
        result[day.date] = day;
      }
      return result;
    } catch (_) {
      // Повреждённый кэш (ручное редактирование, смена формата) — начинаем заново.
      await _prefs.remove(_ratesKey);
      return {};
    }
  }

  @override
  Future<void> saveAll(
    Iterable<DailyRates> days, {
    DateTime? retainSince,
  }) async {
    final all = await loadAll();
    for (final day in days) {
      all[day.date] = day;
    }
    if (retainSince != null) {
      final limit = dateOnly(retainSince);
      all.removeWhere((date, _) => date.isBefore(limit));
    }
    final encoded = {for (final d in all.values) dateKey(d.date): d.toJson()};
    await _prefs.setString(_ratesKey, jsonEncode(encoded));
  }

  @override
  Future<DateTime?> lastSync() async {
    final raw = _prefs.getString(_syncKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  @override
  Future<void> setLastSync(DateTime moment) =>
      _prefs.setString(_syncKey, moment.toIso8601String());
}
