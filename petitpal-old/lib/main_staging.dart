import 'package:flutter/material.dart';
import 'config/api_config.dart';
import 'main_common.dart';
import 'src/analytics/analytics.dart';
import 'src/analytics/sentry_boot.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiConfig.setEnvironment(ApiEnvironment.staging);
  await bootSentry();
  await AnalyticsService().initIfNeeded();
  runApp(const PetitPalApp());
}
