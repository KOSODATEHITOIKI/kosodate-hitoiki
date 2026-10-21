import '../../domain/repositories/mute_repository.dart';
import '../api/api_exception.dart';

/// 画面確認・テスト用のモック実装。言葉は、アプリを閉じるまでの間だけ持つ(投稿には反映しない)。
class MockMuteRepository implements MuteRepository {
  final _words = <String>[];

  @override
  bool get isSample => true;

  @override
  Future<List<String>> fetchWords() async => List.of(_words);

  @override
  Future<void> addWord(String word) async {
    final trimmed = word.trim();
    if (_words.any((w) => w.toLowerCase() == trimmed.toLowerCase())) {
      throw const ApiException(code: 'DUPLICATE', message: '');
    }
    if (_words.length >= maxMutedWords) {
      throw const ApiException(code: 'LIMIT_EXCEEDED', message: '');
    }
    _words.insert(0, trimmed);
  }

  @override
  Future<void> removeWord(String word) async {
    _words.remove(word);
  }
}
