import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/themes.dart';

final firstRunProvider = FutureProvider<bool>((ref) async {
  final p = await SharedPreferences.getInstance();
  return !(p.getBool('first_run_complete') ?? false);
});

final markOnboardingDoneProvider = Provider((ref) {
  return () async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('first_run_complete', true);
  };
});

final themeControllerProvider = ChangeNotifierProvider<ThemeController>((ref) => ThemeController());
