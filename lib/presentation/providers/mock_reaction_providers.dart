import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

/// サンプルの共感状態。実送信・永続化はIssue #22で接続する。
final mockEmpathyProvider = StateProvider<Set<String>>((ref) => {});

/// 最初の共感操作から認証状態を監視し、ログアウト時にサンプルを消す。
final mockReactionAuthGuardProvider = Provider<void>((ref) {
  ref.listen<bool>(isLoggedInProvider, (_, loggedIn) {
    if (!loggedIn) ref.read(mockEmpathyProvider.notifier).state = {};
  });
});
