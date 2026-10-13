import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/flavor.dart';
import 'core/config/supabase_config.dart';
import 'core/widgets/startup_error_app.dart';

/// dev環境のエントリーポイント
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.setFlavor(Flavor.dev);

  try {
    await SupabaseConfig.initialize();
  } catch (error) {
    runApp(StartupErrorApp(error: error));
    return;
  }

  runApp(const ProviderScope(child: App()));
}
