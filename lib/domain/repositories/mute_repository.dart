/// 言葉のミュートの抽象。ミュートした言葉を含む投稿は、一覧・検索に出なくなる
/// (投稿の本文にだけ適用し、コメントには適用しない)。相手には知らせない。
abstract class MuteRepository {
  /// サンプルか。trueの間、画面に「サンプルです。実際には反映されません」の注記を出す。
  bool get isSample;

  /// ミュートしている言葉(新しく追加した順)。ログイン必須。
  Future<List<String>> fetchWords();

  /// 言葉を追加する。前後の空白は除かれる。1語100文字まで・100件まで。失敗は`ApiException`:
  /// - `LIMIT_EXCEEDED`: 100件を超える
  /// - `DUPLICATE`: すでに登録している(全角・半角、英字の大文字小文字は区別しない)
  Future<void> addWord(String word);

  /// 言葉を外す。登録していない言葉でも、エラーにならない。
  Future<void> removeWord(String word);

  /// ミュートしている話題のID。ミュートした話題の投稿は、一覧・検索に出なくなる。ログイン必須。
  Future<Set<int>> fetchTopicIds();

  /// 話題をミュートする。すでにミュートしていても、エラーにならない。
  Future<void> addTopic(int topicId);

  /// 話題のミュートを外す。ミュートしていなくても、エラーにならない。
  Future<void> removeTopic(int topicId);
}

/// 登録できる言葉の上限(件数)。サーバーの上限(暫定)と同じ。
const maxMutedWords = 100;

/// 1語の最大の長さ(文字数)。
const maxMutedWordLength = 100;
