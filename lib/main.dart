import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/bnm_client.dart';
import 'data/rate_cache.dart';
import 'data/rate_repository.dart';
import 'ui/rates_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final controller = RatesController(
    repository: RateRepository(
      client: BnmClient(),
      cache: SharedPrefsRateCache(prefs),
    ),
    prefs: prefs,
  );
  runApp(CurrencyApp(controller: controller));
  controller.load();
}
