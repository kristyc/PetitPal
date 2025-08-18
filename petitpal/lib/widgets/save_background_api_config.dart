// lib/widgets/save_background_api_config.dart
import 'package:home_widget/home_widget.dart';

/// Save credentials so the Android Foreground Service (started from the widget)
/// can access them without opening the Flutter UI.
Future<void> saveBackgroundApiConfig({
  required String openAiKey,
  required String workerBase, // e.g. https://petitpal-api.kristyc.workers.dev
}) async {
  await HomeWidget.saveWidgetData<String>('pp_oai_key', openAiKey);
  await HomeWidget.saveWidgetData<String>('pp_worker_base', workerBase);
  await HomeWidget.updateWidget(name: 'MicWidgetProvider', iOSName: 'MicWidget');
}
