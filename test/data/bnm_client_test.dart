import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:currency_rates/data/bnm_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response xml(String body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(body), status);

void main() {
  final fixture = File('test/fixtures/bnm_19_11_2026.xml').readAsStringSync();
  final date = DateTime(2026, 11, 19);

  test('формирует адрес запроса с датой dd.MM.yyyy', () {
    final uri = BnmClient.uriFor(DateTime(2026, 3, 7));
    expect(uri.host, 'www.bnm.md');
    expect(uri.queryParameters['date'], '07.03.2026');
    expect(uri.queryParameters['get_xml'], '1');
  });

  test('успешный ответ разбирается в курсы', () async {
    late Uri requested;
    final client = BnmClient(httpClient: MockClient((req) async {
      requested = req.url;
      return xml(fixture);
    }));

    final result = await client.fetch(date);
    expect(requested.queryParameters['date'], '19.11.2026');
    expect(result!.rateFor('EUR')!.value, closeTo(20.1411, 1e-9));
  });

  test('HTTP 404 (дата ещё не опубликована) — null', () async {
    final client = BnmClient(httpClient: MockClient((_) async => http.Response('', 404)));
    expect(await client.fetch(date), isNull);
  });

  test('корректная пустая публикация — null', () async {
    final client = BnmClient(httpClient: MockClient(
        (_) async => xml('<ValCurs Date="19.11.2026" name="x"></ValCurs>')));
    expect(await client.fetch(date), isNull);
  });

  Future<void> expectKind(http.Client mock, SourceErrorKind kind,
      {Duration timeout = const Duration(seconds: 10)}) async {
    final client = BnmClient(httpClient: mock, timeout: timeout);
    await expectLater(
      client.fetch(date),
      throwsA(isA<SourceException>().having((e) => e.kind, 'kind', kind)),
    );
  }

  test('HTTP 500 — ошибка источника', () => expectKind(
      MockClient((_) async => http.Response('oops', 500)), SourceErrorKind.httpStatus));

  test('пустое тело при 200 — некорректные данные',
      () => expectKind(MockClient((_) async => xml('')), SourceErrorKind.invalidData));

  test('мусор вместо XML — некорректные данные', () => expectKind(
      MockClient((_) async => xml('<html>maintenance')), SourceErrorKind.invalidData));

  test('неверная кодировка — некорректные данные', () => expectKind(
      MockClient((_) async => http.Response.bytes([0xff, 0xfe, 0xfd], 200)),
      SourceErrorKind.invalidData));

  test('курс на будущую дату вместо запрошенной — некорректные данные', () => expectKind(
      MockClient((_) async => xml(fixture.replaceFirst('19.11.2026', '25.11.2026'))),
      SourceErrorKind.invalidData));

  test('нет сети — сетевая ошибка', () => expectKind(
      MockClient((_) async => throw const SocketException('Failed host lookup')),
      SourceErrorKind.network));

  test('ClientException — сетевая ошибка', () => expectKind(
      MockClient((_) async => throw http.ClientException('Connection closed')),
      SourceErrorKind.network));

  test('нет ответа дольше тайм-аута — timeout', () => expectKind(
      MockClient((_) => Completer<http.Response>().future),
      SourceErrorKind.timeout,
      timeout: const Duration(milliseconds: 20)));
}
