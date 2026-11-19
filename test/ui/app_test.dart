import 'package:currency_rates/app.dart';
import 'package:currency_rates/data/bnm_client.dart';
import 'package:currency_rates/data/rate_repository.dart';
import 'package:currency_rates/ui/rates_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

/// Репозиторий с заранее заданным результатом, без сети.
class FakeRepository extends RateRepository {
  FakeRepository(this.result)
    : super(client: BnmClient(), cache: InMemoryRateCache());

  final Future<RatesHistory> Function() result;

  @override
  Future<RatesHistory> loadHistory({int days = 30}) => result();
}

RatesHistory sampleHistory({bool offline = false}) => RatesHistory(
  days: [
    for (var i = 0; i < 30; i++)
      day(DateTime.utc(2026, 10, 21).add(Duration(days: i)), eur: 20 + i / 100),
  ],
  requestedDays: 30,
  offline: offline,
  lastSync: DateTime(2026, 11, 19, 12),
  warning: offline
      ? 'Нет подключения к интернету или источник недоступен'
      : null,
);

Future<RatesController> pumpApp(
  WidgetTester tester,
  FakeRepository repo,
) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  final controller = RatesController(
    repository: repo,
    now: () => DateTime(2026, 11, 19, 15),
  );
  await tester.pumpWidget(CurrencyApp(controller: controller));
  await controller.load();
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('конвертирует сумму по курсу последнего дня', (tester) async {
    await pumpApp(tester, FakeRepository(() async => sampleHistory()));
    // EUR на 19.11 = 20.29 → 100 EUR = 2 029,00 MDL
    expect(find.byKey(const Key('conversionResult')), findsOneWidget);
    final text = tester
        .widget<Text>(find.byKey(const Key('conversionResult')))
        .data!;
    expect(text.replaceAll(RegExp(r'\s'), ''), '2029,00MDL');
  });

  testWidgets('некорректная сумма показывает ошибку вместо результата', (
    tester,
  ) async {
    await pumpApp(tester, FakeRepository(() async => sampleHistory()));
    await tester.enterText(find.byKey(const Key('amountField')), 'abc');
    await tester.pump();
    expect(find.text('Введите число, например 100 или 99,50'), findsOneWidget);
    expect(find.byKey(const Key('conversionResult')), findsNothing);
  });

  testWidgets('офлайн: показана дата актуальности сохранённых данных', (
    tester,
  ) async {
    await pumpApp(
      tester,
      FakeRepository(() async => sampleHistory(offline: true)),
    );
    expect(
      find.textContaining('сохранённый курс на 19.11.2026'),
      findsOneWidget,
    );
    expect(find.text('Работа без сети'), findsOneWidget);
  });

  testWidgets(
    'нет данных совсем: экран ошибки с кнопкой повтора, без падения',
    (tester) async {
      await pumpApp(
        tester,
        FakeRepository(
          () async => throw const RatesUnavailableException(
            'Нет подключения к интернету',
          ),
        ),
      );
      expect(find.text('Курсы недоступны'), findsOneWidget);
      expect(find.text('Повторить'), findsOneWidget);
    },
  );

  testWidgets('вкладки недели и месяца показывают статистику и тенденцию', (
    tester,
  ) async {
    await pumpApp(tester, FakeRepository(() async => sampleHistory()));
    await tester.tap(find.text('Неделя'));
    await tester.pumpAndSettle();
    expect(find.text('Динамика за неделю'), findsOneWidget);
    expect(find.text('Минимум'), findsWidgets);
    expect(find.text('Максимум'), findsWidgets);

    await tester.tap(find.text('Месяц'));
    await tester.pumpAndSettle();
    expect(find.text('Динамика за месяц'), findsOneWidget);
    expect(find.textContaining('Рост'), findsWidgets);
  });
}
