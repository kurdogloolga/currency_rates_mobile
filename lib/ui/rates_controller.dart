import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/rate_repository.dart';
import '../domain/models.dart';
import 'currency_meta.dart';

enum LoadStatus { loading, ready, error }

/// Состояние приложения: история курсов и выбранная валютная пара.
class RatesController extends ChangeNotifier {
  RatesController({
    required this.repository,
    this.prefs,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    from = prefs?.getString(_fromKey) ?? 'EUR';
    to = prefs?.getString(_toKey) ?? baseCurrency;
  }

  static const historyDays = 30;
  static const _fromKey = 'pair_from';
  static const _toKey = 'pair_to';

  final RateRepository repository;
  final SharedPreferences? prefs;
  final DateTime Function() _now;

  LoadStatus status = LoadStatus.loading;
  RatesHistory? history;
  String? errorMessage;
  bool refreshing = false;

  late String from;
  late String to;

  DateTime get now => _now();
  DateTime get today => dateOnly(_now());

  List<CurrencyOption> get currencies =>
      history == null ? const [] : currencyOptions(history!.latest);

  Set<String> get availableCodes => currencies.map((c) => c.code).toSet();

  CurrencyOption? option(String code) {
    for (final c in currencies) {
      if (c.code == code) return c;
    }
    return null;
  }

  Future<void> load() async {
    if (refreshing) return;
    refreshing = true;
    if (history == null) status = LoadStatus.loading;
    notifyListeners();
    try {
      history = await repository.loadHistory(days: historyDays);
      status = LoadStatus.ready;
      errorMessage = null;
      _ensurePairAvailable();
    } on RatesUnavailableException catch (e) {
      errorMessage = e.message;
      if (history == null) status = LoadStatus.error;
    } catch (e) {
      errorMessage = 'Не удалось загрузить курсы. Повторите попытку позже.';
      if (history == null) status = LoadStatus.error;
    } finally {
      refreshing = false;
      notifyListeners();
    }
  }

  void setFrom(String code) {
    if (code == to) to = from; // выбор той же валюты меняет пару местами
    from = code;
    _persist();
  }

  void setTo(String code) {
    if (code == from) from = to;
    to = code;
    _persist();
  }

  void swap() {
    final t = from;
    from = to;
    to = t;
    _persist();
  }

  void _ensurePairAvailable() {
    final codes = availableCodes;
    if (!codes.contains(from)) {
      from = codes.contains('EUR') ? 'EUR' : codes.first;
    }
    if (!codes.contains(to) || to == from) {
      to = from == baseCurrency
          ? (codes.contains('EUR') ? 'EUR' : codes.last)
          : baseCurrency;
    }
  }

  void _persist() {
    prefs?.setString(_fromKey, from);
    prefs?.setString(_toKey, to);
    notifyListeners();
  }
}
