import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../../core/constants/app_icons.dart';

/// デザイン素材に沿った画面確認用の文言。最終文言は別途確定する。
enum MockReaction {
  empathy('わかる', AppReactions.empathy),
  breakTime('おつかれさま', AppReactions.takeABreak),
  listening('聞いているよ', AppReactions.listening),
  cheer('そっと応援', AppReactions.gentleCheer),
  applause('がんばってるね', AppReactions.applause);

  const MockReaction(this.label, this.asset);
  final String label;
  final String asset;
}

/// サンプルの共感状態。実送信・永続化はIssue #22で接続する。
final mockReactionsProvider = StateProvider<Map<String, MockReaction>>(
  (ref) => {},
);
final mockEmpathyProvider = Provider<Set<String>>(
  (ref) => ref
      .watch(mockReactionsProvider)
      .entries
      .where((entry) => entry.value == MockReaction.empathy)
      .map((entry) => entry.key)
      .toSet(),
);

/// 最初の共感操作から認証状態を監視し、ログアウト時にサンプルを消す。
final mockReactionAuthGuardProvider = Provider<void>((ref) {
  ref.listen<bool>(isLoggedInProvider, (_, loggedIn) {
    if (!loggedIn) ref.read(mockReactionsProvider.notifier).state = {};
  });
});
