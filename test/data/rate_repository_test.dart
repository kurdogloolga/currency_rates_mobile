import 'dart:convert';
import 'dart:io';

import 'package:currency_rates/data/bnm_client.dart';
import 'package:currency_rates/data/rate_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/fakes.dart';

void main() {
  final now = DateTime(2026, 11, 19, 15, 0);
  final today = DateTime.utc(2026, 11, 19);

  DateTime parseDate(Uri uri) {
    final p = uri.queryParameters['date']!.split('.');
    return DateTime.utc(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
  }

  /// Источник, отдающий EUR = 20 + номер дня месяца / 100.
  MockClient onlineSource(List<DateTime> requested) => MockClient((req) async {
        final date = parseDate(req.url);
        requested.add(date);
        return http.Response.bytes(
            utf8.encode(bnmXml(date, eur: 20 + date.day / 100)), 200);
      });

  final offlineSource =
      MockClient((_) async => throw const SocketException('Failed host lookup'));

  RateRepository repo(http.Client source, InMemoryRateCache cache) =>
      RateRepository(client: BnmClient(httpClient: source), cache: cache, now: () => now);

  test('онлайн: загружает 30 дней, сохраняет их в кэш', () async {
    final requested = <DateTime>[];
    final cache = InMemoryRateCache();
    final history = await repo(onlineSource(requested), cache).loadHistory(days: 30);

    expect(history.days, hasLength(30));
    expect(history.days.first.date, DateTime.utc(2026, 10, 21));
    expect(history.latest.date, today);
    expect(history.offline, isFalse);
    expect(requested, hasLength(30));
    expect(cache.store, hasLength(30));
    expect(cache.sync, now);
  });

  test('повторная загрузка запрашивает только сегодняшний день', () async {
    final cache = InMemoryRateCache();
    await repo(onlineSource([]), cache).loadHistory(days: 30);

    final requested = <DateTime>[];
    final history = await repo(onlineSource(requested), cache).loadHistory(days: 30);
    expect(requested, [today]);
    expect(history.days, hasLength(30));
  });

  test('офлайн с кэшем: данные из кэша и признак offline', () async {
    final cache = InMemoryRateCache();
    await repo(onlineSource([]), cache).loadHistory(days: 7);

    final history = await repo(offlineSource, cache).loadHistory(days: 7);
    expect(history.offline, isTrue);
    expect(history.days, hasLength(7));
    expect(history.lastSync, now);
    expect(history.warning, contains('Нет подключения'));
  });

  test('офлайн без кэша: понятная ошибка, а не падение', () async {
    await expectLater(
      repo(offlineSource, InMemoryRateCache()).loadHistory(days: 7),
      throwsA(isA<RatesUnavailableException>()
          .having((e) => e.message, 'message', contains('Сохранённых данных пока нет'))),
    );
  });

  test('офлайн: после первой сетевой ошибки остальные даты не перебираются', () async {
    var calls = 0;
    final source = MockClient((_) async {
      calls++;
      throw const SocketException('down');
    });
    await expectLater(repo(source, InMemoryRateCache()).loadHistory(days: 30),
        throwsA(isA<RatesUnavailableException>()));
    expect(calls, lessThanOrEqualTo(6));
  });

  test('некорректные данные за один день не мешают остальным', () async {
    final source = MockClient((req) async {
      final date = parseDate(req.url);
      if (date.day == 15) return http.Response('<broken', 200);
      return http.Response.bytes(utf8.encode(bnmXml(date)), 200);
    });
    final history = await repo(source, InMemoryRateCache()).loadHistory(days: 7);
    expect(history.days, hasLength(6));
    expect(history.days.any((d) => d.date.day == 15), isFalse);
    expect(history.warning, isNotNull);
  });

  test('источник ничего не опубликовал: сообщение без падения', () async {
    final source = MockClient((_) async => http.Response('', 404));
    await expectLater(repo(source, InMemoryRateCache()).loadHistory(days: 7),
        throwsA(isA<RatesUnavailableException>()));
  });

  test('lastDays выбирает последние N календарных дней', () async {
    final history = await repo(onlineSource([]), InMemoryRateCache()).loadHistory(days: 30);
    final week = history.lastDays(7, today);
    expect(week, hasLength(7));
    expect(week.first.date, DateTime.utc(2026, 11, 13));
  });
}
