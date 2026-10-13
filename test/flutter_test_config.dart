import 'dart:async';

import 'package:kosodate_hitoiki/core/config/flavor.dart';

/// テスト実行ファイルごとに自動で呼ばれる(flutter_testの規約)。
/// AppConfig.flavor未設定のままAppを構築するテストがあるため、ここで設定する。
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppConfig.setFlavor(Flavor.dev);
  await testMain();
}
