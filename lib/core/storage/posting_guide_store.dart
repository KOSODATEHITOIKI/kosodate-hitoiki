import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 「はじめて投稿する前に」の案内を、確認済みかどうかを、端末に残す。
/// 最初の1回だけ出して、確認したあとは出さない(端末・ブラウザーごと)。
class PostingGuideStore {
  const PostingGuideStore();

  static const _key = 'posting_guide_seen';

  /// 読めなかったとき(保存先が使えないなど)は、未確認として扱う。案内が出るだけで、
  /// 投稿は止めない。
  Future<bool> isSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (_) {
      // 残せなくても、今回の投稿は進める。
    }
  }
}

final postingGuideStoreProvider = Provider<PostingGuideStore>(
  (ref) => const PostingGuideStore(),
);
