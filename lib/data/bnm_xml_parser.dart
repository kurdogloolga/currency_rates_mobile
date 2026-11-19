import 'package:xml/xml.dart';

import '../domain/models.dart';

/// Ответ источника нельзя использовать: пустой, не XML или с некорректными
/// значениями. Частичный результат в этом случае не возвращается.
class RateParseException implements Exception {
  const RateParseException(this.message);

  final String message;

  @override
  String toString() => 'RateParseException: $message';
}

/// Разбор XML официальных курсов Национального банка Молдовы.
///
/// Формат:
/// ```xml
/// <ValCurs Date="19.11.2026" name="...">
///   <Valute ID="47"><NumCode>978</NumCode><CharCode>EUR</CharCode>
///     <Nominal>1</Nominal><Name>Евро</Name><Value>20.1411</Value></Valute>
/// </ValCurs>
/// ```
class BnmXmlParser {
  const BnmXmlParser();

  static final _datePattern = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$');
  static final _codePattern = RegExp(r'^[A-Z]{3}$');
  // Только запись с точкой: без экспоненты, NaN, Infinity, запятых и знаков.
  static final _numberPattern = RegExp(r'^\d+(\.\d+)?$');

  DailyRates parse(String body) {
    if (body.trim().isEmpty) {
      throw const RateParseException('Источник вернул пустой ответ');
    }

    final XmlDocument document;
    try {
      document = XmlDocument.parse(body);
    } on XmlException {
      throw const RateParseException('Ответ источника не является корректным XML');
    }

    final root = document.rootElement;
    if (root.name.local != 'ValCurs') {
      throw const RateParseException('В ответе нет элемента ValCurs');
    }

    final date = parseDate(root.getAttribute('Date'));

    final rates = <CurrencyRate>[];
    final seen = <String>{};
    for (final valute in root.findElements('Valute')) {
      final code = _text(valute, 'CharCode');
      if (!_codePattern.hasMatch(code)) {
        throw RateParseException('Некорректный код валюты: "$code"');
      }
      if (!seen.add(code)) {
        throw RateParseException('Валюта $code встречается дважды');
      }
      final name = _text(valute, 'Name');
      if (name.isEmpty) {
        throw RateParseException('Пустое название валюты $code');
      }
      rates.add(CurrencyRate(
        code: code,
        name: name,
        nominal: _positiveNumber(valute, 'Nominal', code),
        value: _positiveNumber(valute, 'Value', code),
      ));
    }

    return DailyRates(date: date, rates: rates);
  }

  /// Разбор даты `dd.MM.yyyy` с проверкой существования дня (31.02 — ошибка).
  static DateTime parseDate(String? raw) {
    final match = _datePattern.firstMatch(raw?.trim() ?? '');
    if (match == null) {
      throw RateParseException('Некорректная дата публикации: "${raw ?? ''}"');
    }
    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    final date = DateTime.utc(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      throw RateParseException('Несуществующая дата публикации: "$raw"');
    }
    return date;
  }

  static String _text(XmlElement parent, String tag) {
    final element = parent.getElement(tag);
    return element?.innerText.trim() ?? '';
  }

  static double _positiveNumber(XmlElement parent, String tag, String code) {
    final raw = _text(parent, tag);
    if (!_numberPattern.hasMatch(raw)) {
      throw RateParseException('Некорректное значение $tag для $code: "$raw"');
    }
    final value = double.parse(raw);
    if (value <= 0) {
      throw RateParseException('Значение $tag для $code должно быть больше нуля');
    }
    return value;
  }
}
