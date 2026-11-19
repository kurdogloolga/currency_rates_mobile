import 'package:currency_rates/domain/input_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AmountValidator', () {
    const v = AmountValidator();

    test('целое число', () => expect(v.validate('100').value, 100));
    test('десятичная точка', () => expect(v.validate('99.5').value, 99.5));
    test('десятичная запятая', () => expect(v.validate('99,50').value, 99.5));
    test(
      'пробелы по краям и разделители разрядов',
      () => expect(v.validate('  1 000,25 ').value, 1000.25),
    );
    test(
      'неразрывный пробел как разделитель разрядов',
      () => expect(v.validate('1 000').value, 1000),
    );

    void expectError(String? input, String fragment) {
      final r = v.validate(input);
      expect(r.isValid, isFalse, reason: 'input: $input');
      expect(r.error, contains(fragment));
    }

    test('пустой ввод', () => expectError('', 'Введите сумму'));
    test('null', () => expectError(null, 'Введите сумму'));
    test('только пробелы', () => expectError('   ', 'Введите сумму'));
    test('ноль', () => expectError('0', 'больше нуля'));
    test('0,00', () => expectError('0,00', 'больше нуля'));
    test('отрицательное', () => expectError('-5', 'отрицательной'));
    test('буквы', () => expectError('abc', 'Введите число'));
    test('две запятые', () => expectError('1,2,3', 'Введите число'));
    test('экспонента', () => expectError('1e5', 'Введите число'));
    test(
      'запятая без дробной части',
      () => expectError('10,', 'Введите число'),
    );
    test(
      'слишком много знаков после запятой',
      () => expectError('1.12345', 'знаков'),
    );
    test(
      'слишком большая сумма',
      () => expectError('10000000000000', 'большая'),
    );
  });

  group('PairValidator', () {
    const v = PairValidator();
    const available = {'MDL', 'EUR', 'USD'};

    test(
      'корректная пара',
      () => expect(v.validate('EUR', 'MDL', available).value, ('EUR', 'MDL')),
    );
    test(
      'одинаковые валюты',
      () =>
          expect(v.validate('EUR', 'EUR', available).error, contains('разные')),
    );
    test(
      'не выбрана валюта',
      () => expect(v.validate(null, 'EUR', available).error, contains('обе')),
    );
    test(
      'неизвестная валюта',
      () => expect(
        v.validate('XYZ', 'EUR', available).error,
        contains('отсутствует'),
      ),
    );
  });
}
