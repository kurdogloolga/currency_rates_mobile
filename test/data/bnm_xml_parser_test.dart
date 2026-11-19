import 'dart:io';

import 'package:currency_rates/data/bnm_xml_parser.dart';
import 'package:flutter_test/flutter_test.dart';

String valute(
  String code,
  String nominal,
  String value, {
  String name = 'Валюта',
}) =>
    '''
  <Valute ID="1">
    <NumCode>000</NumCode>
    <CharCode>$code</CharCode>
    <Nominal>$nominal</Nominal>
    <Name>$name</Name>
    <Value>$value</Value>
  </Valute>''';

String doc(String date, List<String> valutes) =>
    '<?xml version="1.0" encoding="UTF-8"?>\n'
    '<ValCurs Date="$date" name="Обменные ставки">${valutes.join()}</ValCurs>';

void main() {
  const parser = BnmXmlParser();

  group('BnmXmlParser — корректные ответы', () {
    test('разбирает реальный ответ НБМ (фикстура)', () {
      final body = File('test/fixtures/bnm_19_11_2026.xml').readAsStringSync();
      final result = parser.parse(body);

      expect(result.date, DateTime.utc(2026, 11, 19));
      expect(result.rates, hasLength(40));
      final eur = result.rateFor('EUR')!;
      expect(eur.name, 'Евро');
      expect(eur.mdlPerUnit, closeTo(20.1411, 1e-9));
      expect(result.rateFor('USD')!.value, closeTo(18.3744, 1e-9));
    });

    test('нормализует курс по номиналу: Value / Nominal', () {
      final result = parser.parse(
        doc('01.11.2026', [valute('JPY', '100', '12.5')]),
      );
      expect(result.rateFor('JPY')!.mdlPerUnit, closeTo(0.125, 1e-12));
    });

    test('корректная публикация без валют даёт пустой набор, а не ошибку', () {
      final result = parser.parse(doc('01.11.2026', []));
      expect(result.rates, isEmpty);
      expect(result.date, DateTime.utc(2026, 11, 1));
    });

    test('MDL всегда имеет курс 1 и участвует в кросс-курсе', () {
      final result = parser.parse(
        doc('01.11.2026', [valute('EUR', '1', '20'), valute('USD', '1', '16')]),
      );
      expect(result.mdlPerUnit('MDL'), 1);
      expect(result.crossRate('EUR', 'USD'), closeTo(1.25, 1e-12));
      expect(result.crossRate('MDL', 'EUR'), closeTo(0.05, 1e-12));
      expect(result.crossRate('EUR', 'XXX'), isNull);
    });
  });

  group('BnmXmlParser — некорректные ответы', () {
    void expectFailure(String body) =>
        expect(() => parser.parse(body), throwsA(isA<RateParseException>()));

    test('пустая строка', () => expectFailure(''));
    test('только пробелы', () => expectFailure('   \n '));
    test('HTML вместо XML', () => expectFailure('<html><body>Error</body>'));
    test(
      'другой корневой элемент',
      () => expectFailure('<Rates Date="01.11.2026"/>'),
    );
    test('нет даты', () => expectFailure('<ValCurs name="x"></ValCurs>'));
    test('дата в другом формате', () => expectFailure(doc('2026-11-01', [])));
    test('несуществующая дата', () => expectFailure(doc('31.02.2026', [])));
    test(
      'нулевой курс',
      () => expectFailure(doc('01.11.2026', [valute('EUR', '1', '0')])),
    );
    test(
      'отрицательный номинал',
      () => expectFailure(doc('01.11.2026', [valute('EUR', '-1', '20')])),
    );
    test(
      'запятая вместо точки',
      () => expectFailure(doc('01.11.2026', [valute('EUR', '1', '20,14')])),
    );
    test(
      'NaN',
      () => expectFailure(doc('01.11.2026', [valute('EUR', '1', 'NaN')])),
    );
    test(
      'пустое значение',
      () => expectFailure(doc('01.11.2026', [valute('EUR', '1', '')])),
    );
    test(
      'некорректный код валюты',
      () => expectFailure(doc('01.11.2026', [valute('eu', '1', '20')])),
    );
    test(
      'пустое название',
      () => expectFailure(
        doc('01.11.2026', [valute('EUR', '1', '20', name: ' ')]),
      ),
    );
    test(
      'дублирующаяся валюта',
      () => expectFailure(
        doc('01.11.2026', [valute('EUR', '1', '20'), valute('EUR', '1', '21')]),
      ),
    );
  });
}
