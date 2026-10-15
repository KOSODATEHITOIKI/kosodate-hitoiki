import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/moderation_result.dart';

/// 誹謗中傷・個人情報の送信前チェック(必須要件、docs/全体設計書.md 5章)。
///
/// 対象: 投稿本文・自由コメント・返信・ニックネーム・自己紹介。
/// 判定処理自体(禁止語リスト+AI判定)はバックエンド(kosodate-hitoiki-backend)側で行う。
///
/// **現状は未接続・要再設計**: kosodate-hitoiki-backendの
/// `docs/バックエンド設計.md`(4. 送信前チェック)の決定事項により、チェックは
/// 投稿・コメント作成/編集APIと同一経路内で実施し、クライアントが別途チェック結果を
/// 自己申告してDBへ書き込む経路は認めない設計。したがって本クラスのような
/// 独立した事前チェック用Edge Function(`check-content`)は実際のバックエンド契約とは
/// 整合しない可能性が高い。判定の閾値・個人情報検出方式・レスポンス形式は
/// バックエンド側で未決定のため、実装先のEdge Functionが用意され次第、
/// 呼び出し経路そのものを見直すこと。verdict/reason/supportMessageRequiredの
/// パース処理自体は参考実装として残すが、本番の呼び出し方法ではない。
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
