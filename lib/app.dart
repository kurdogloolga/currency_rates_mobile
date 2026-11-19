import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ui/home_shell.dart';
import 'ui/rates_controller.dart';
import 'ui/theme.dart';

class CurrencyApp extends StatelessWidget {
  const CurrencyApp({super.key, required this.controller});

  final RatesController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Курсы НБМ',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: HomeShell(controller: controller),
    );
  }
}
