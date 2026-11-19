import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'comparison_screen.dart';
import 'converter_screen.dart';
import 'rates_controller.dart';
import 'widgets/common.dart';

/// Корневой экран: состояние загрузки/ошибки и три вкладки.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final RatesController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          final ready = c.status == LoadStatus.ready;
          return Scaffold(
            body: switch (c.status) {
              LoadStatus.loading => const LoadingView(),
              LoadStatus.error => ErrorView(
                message: c.errorMessage ?? 'Неизвестная ошибка',
                onRetry: c.load,
                busy: c.refreshing,
              ),
              LoadStatus.ready => IndexedStack(
                index: _tab,
                children: [
                  ConverterScreen(
                    controller: c,
                    onOpenWeek: () => setState(() => _tab = 1),
                  ),
                  ComparisonScreen(controller: c, days: 7),
                  ComparisonScreen(controller: c, days: 30),
                ],
              ),
            },
            bottomNavigationBar: ready
                ? NavigationBar(
                    selectedIndex: _tab,
                    onDestinationSelected: (i) => setState(() => _tab = i),
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.currency_exchange_outlined),
                        selectedIcon: Icon(Icons.currency_exchange_rounded),
                        label: 'Конвертер',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.date_range_outlined),
                        selectedIcon: Icon(Icons.date_range_rounded),
                        label: 'Неделя',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.calendar_month_outlined),
                        selectedIcon: Icon(Icons.calendar_month_rounded),
                        label: 'Месяц',
                      ),
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }
}
