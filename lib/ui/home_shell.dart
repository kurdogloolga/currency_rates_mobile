import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'converter_screen.dart';
import 'rates_controller.dart';
import 'widgets/common.dart';

/// Корневой экран: состояние загрузки/ошибки и вкладки приложения.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.controller});

  final RatesController controller;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Scaffold(
          body: switch (controller.status) {
            LoadStatus.loading => const LoadingView(),
            LoadStatus.error => ErrorView(
                message: controller.errorMessage ?? 'Неизвестная ошибка',
                onRetry: controller.load,
                busy: controller.refreshing,
              ),
            LoadStatus.ready => ConverterScreen(controller: controller, onOpenWeek: () {}),
          },
        ),
      ),
    );
  }
}
