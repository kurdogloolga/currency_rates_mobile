import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import '../domain/models.dart';
import 'bnm_xml_parser.dart';

enum SourceErrorKind { network, timeout, httpStatus, invalidData }

/// Ошибка при обращении к источнику; [message] предназначено пользователю.
class SourceException implements Exception {
  const SourceException(this.kind, this.message);

  final SourceErrorKind kind;
  final String message;

  @override
  String toString() => 'SourceException($kind): $message';
}

/// HTTP-клиент официальных курсов НБМ. Один запрос — одна календарная дата.
class BnmClient {
  BnmClient({
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 10),
    this.parser = const BnmXmlParser(),
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final Duration timeout;
  final BnmXmlParser parser;

  static Uri uriFor(DateTime date) => Uri.https(
        'www.bnm.md',
        '/ru/official_exchange_rates',
        {'get_xml': '1', 'date': formatDate(date)},
      );

  /// Курсы на [date].
  ///
  /// Возвращает `null`, если на эту дату НБМ ничего не опубликовал
  /// (HTTP 404 для будущих дат или корректный пустой ValCurs).
  /// Бросает [SourceException] при сетевых ошибках и некорректных данных.
  Future<DailyRates?> fetch(DateTime date) async {
    final requested = dateOnly(date);
    final http.Response response;
    try {
      response = await _http.get(uriFor(requested)).timeout(timeout);
    } on TimeoutException {
      throw const SourceException(
          SourceErrorKind.timeout, 'Источник курсов не ответил вовремя');
    } on SocketException {
      throw const SourceException(
          SourceErrorKind.network, 'Нет подключения к интернету или источник недоступен');
    } on http.ClientException {
      throw const SourceException(
          SourceErrorKind.network, 'Нет подключения к интернету или источник недоступен');
    }

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw SourceException(SourceErrorKind.httpStatus,
          'Источник курсов временно недоступен (HTTP ${response.statusCode})');
    }

    final String body;
    try {
      body = utf8.decode(response.bodyBytes);
    } on FormatException {
      throw const SourceException(
          SourceErrorKind.invalidData, 'Источник вернул данные в неверной кодировке');
    }

    final DailyRates rates;
    try {
      rates = parser.parse(body);
    } on RateParseException catch (e) {
      throw SourceException(SourceErrorKind.invalidData, e.message);
    }

    if (rates.date.isAfter(requested)) {
      throw SourceException(SourceErrorKind.invalidData,
          'Источник вернул курс на ${formatDate(rates.date)} вместо ${formatDate(requested)}');
    }
    if (rates.rates.isEmpty) return null;
    return rates;
  }

  void close() => _http.close();
}
