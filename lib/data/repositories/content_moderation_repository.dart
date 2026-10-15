import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/moderation_result.dart';

/// 誹謗中傷・個人情報の送信前チェック(必須要件、docs/全体設計書.md 5章)。
/// 未接続・要再設計: バックエンドの決定事項(docs/バックエンド設計.md 4章)ではチェックを
/// 投稿・コメント作成APIと同一経路で行う設計のため、独立Edge Function(check-content)を
/// 呼ぶ本クラスの構成とは整合しない。verdict等のパース処理のみ参考実装として残す。
class ContentModerationRepository {
  ContentModerationRepository(this._client);

  final SupabaseClient _client;

  static const _functionName = 'check-content';

  Future<ModerationResult> check(String text) async {
    final response = await _client.functions.invoke(
      _functionName,
      body: {'text': text},
    );

    return ModerationResult.fromJson(response.data as Map<String, dynamic>);
  }
}
