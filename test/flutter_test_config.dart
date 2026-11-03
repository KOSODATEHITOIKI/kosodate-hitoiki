import 'dart:async';

import 'package:kosodate_hitoiki/core/config/flavor.dart';
import 'package:kosodate_hitoiki/core/config/turnstile_config.dart';

/// テスト実行ファイルごとに自動で呼ばれる(flutter_testの規約)。
/// AppConfig.flavor未設定のままAppを構築するテストがあるため、ここで設定する。
/// 確認の部品(Turnstile、本物のWebView)は、テストでは出さない(出すテストは、自分で上書きする)。
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppConfig.setFlavor(Flavor.dev);
  TurnstileConfig.enabledOverride = false;
  await testMain();
}
