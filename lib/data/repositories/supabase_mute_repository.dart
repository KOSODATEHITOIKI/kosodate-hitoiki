import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/mute_repository.dart';
import '../api/api_exception.dart';

/// 言葉のミュート(`muted_words`。本人の行だけが読み書きできる)。
/// 上限(100件・1語100文字)はサーバーが検証する
/// (kosodate-hitoiki-backend docs/API契約.md 6節)。
class SupabaseMuteRepository implements MuteRepository {
  SupabaseMuteRepository(this._client);

  final SupabaseClient _client;

  @override
  bool get isSample => false;

  @override
  Future<List<String>> fetchWords() async {
    final rows = await _client
        .from('muted_words')
        .select('word')
        .order('created_at', ascending: false);
    return [for (final row in rows) row['word'] as String];
  }

  @override
  Future<void> addWord(String word) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('ログインが必要です');
    try {
      await _client.from('muted_words').insert(wordRow(userId, word));
    } on PostgrestException catch (error) {
      throw apiExceptionFor(error);
    }
  }

  @override
  Future<void> removeWord(String word) async {
    await _client.from('muted_words').delete().eq('word', word);
  }

  /// 追加する行。自分のIDが必要(表に既定値がなく、権限の条件が`user_id = auth.uid()`のため、
  /// 付けないと「row-level security policyに違反」で拒否される)。前後の空白は除く。
  static Map<String, dynamic> wordRow(String userId, String word) => {
    'user_id': userId,
    'word': word.trim(),
  };

  /// PostgRESTの失敗を、画面で扱える失敗にする。上限超過は`54000`(`LIMIT_EXCEEDED`)、
  /// 重複は一意制約違反(`23505`・HTTP 409)。
  static ApiException apiExceptionFor(PostgrestException error) {
    if (error.code == '54000' || error.message.contains('LIMIT_EXCEEDED')) {
      return ApiException(code: 'LIMIT_EXCEEDED', message: error.message);
    }
    if (error.code == '23505' || error.code == '409') {
      return ApiException(code: 'DUPLICATE', message: error.message);
    }
    return ApiException(code: 'UNKNOWN', message: error.message);
  }
}
