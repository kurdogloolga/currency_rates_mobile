/// Результат проверки пользовательского ввода: либо значение, либо ошибка.
class ValidationResult<T> {
  const ValidationResult.ok(T this.value) : error = null;
  const ValidationResult.fail(String this.error) : value = null;

  final T? value;
  final String? error;

  bool get isValid => error == null;
}

/// Проверка суммы для конвертации.
class AmountValidator {
  const AmountValidator({this.maxAmount = 1e12, this.maxFractionDigits = 4});

  final double maxAmount;
  final int maxFractionDigits;

  static final _pattern = RegExp(r'^\d+([.,]\d+)?$');

  ValidationResult<double> validate(String? input) {
    // Пробелы допустимы как разделители разрядов: «1 000,50».
    final text = (input ?? '').trim().replaceAll(RegExp(r'[\s ]'), '');
    if (text.isEmpty) return const ValidationResult.fail('Введите сумму');
    if (text.startsWith('-')) {
      return const ValidationResult.fail('Сумма не может быть отрицательной');
    }
    if (!_pattern.hasMatch(text)) {
      return const ValidationResult.fail(
        'Введите число, например 100 или 99,50',
      );
    }
    final normalized = text.replaceAll(',', '.');
    final dot = normalized.indexOf('.');
    if (dot >= 0 && normalized.length - dot - 1 > maxFractionDigits) {
      return ValidationResult.fail(
        'Не больше $maxFractionDigits знаков после запятой',
      );
    }
    final value = double.parse(normalized);
    if (value == 0) {
      return const ValidationResult.fail('Сумма должна быть больше нуля');
    }
    if (value > maxAmount) {
      return const ValidationResult.fail('Слишком большая сумма');
    }
    return ValidationResult.ok(value);
  }
}

/// Проверка выбранной валютной пары.
class PairValidator {
  const PairValidator();

  ValidationResult<(String, String)> validate(
    String? from,
    String? to,
    Set<String> available,
  ) {
    if (from == null || to == null) {
      return const ValidationResult.fail('Выберите обе валюты');
    }
    if (!available.contains(from) || !available.contains(to)) {
      return const ValidationResult.fail('Валюта отсутствует в публикации НБМ');
    }
    if (from == to) {
      return const ValidationResult.fail('Выберите две разные валюты');
    }
    return ValidationResult.ok((from, to));
  }
}
