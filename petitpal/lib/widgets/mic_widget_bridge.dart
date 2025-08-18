import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

enum MicWidgetState { idle, listening, thinking }

class MicWidget {
  static const String _widgetProvider = 'MicWidgetProvider';
  static const String _iOSWidgetName = 'MicWidget';

  static Future<void> syncState(MicWidgetState state) async {
    await HomeWidget.saveWidgetData<String>('mic_widget_state', describeEnum(state));
    await HomeWidget.updateWidget(name: _widgetProvider, iOSName: _iOSWidgetName);
  }

  /// Save theme colors so the widget matches the in-app button exactly.
  static Future<void> syncPaletteFromTheme(ThemeData theme) async {
    final p  = theme.colorScheme.primary.value;
    final op = theme.colorScheme.onPrimary.value;
    final s  = theme.colorScheme.secondary.value;
    await HomeWidget.saveWidgetData<int>('pp_primary', p);
    await HomeWidget.saveWidgetData<int>('pp_onPrimary', op);
    await HomeWidget.saveWidgetData<int>('pp_secondary', s);
    await HomeWidget.updateWidget(name: _widgetProvider, iOSName: _iOSWidgetName);
  }

  static Future<void> initBackground() async {
    // no-op (service is started natively by the widget)
  }
}
