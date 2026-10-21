import 'package:supabase_flutter/supabase_flutter.dart';

import '../api/api_exception.dart';

/// 登録直後のプロフィール作成(`profile-create`)と、作成済みかの確認。
/// 認証はSupabase Auth、プロフィールの作成はEdge Functionの担当
/// (kosodate-hitoiki-backend docs/認証設定.md 1・2節)。
class ProfileRegistrationRepository {
  ProfileRegistrationRepository(this._client);

  final SupabaseClient _client;

  /// 自分のプロフィールが作成済みか。RLSにより自分の行だけが見える。
  Future<bool> hasProfile(String userId) async {
    final rows = await _client
        .from('profiles')
        .select('id')
        .eq('id', userId)
        .limit(1);
    return rows.isNotEmpty;
  }

  /// プロフィールと利用規約同意を作る。同じ内容の再送は成功扱い(冪等)。
  /// 確認が必要な場合は[ApiException.isConfirmRequired]で失敗するので、
  /// 確認後に[confirmed]をtrueにして再送する。
  Future<void> create({
    required String nickname,
    required String termsVersion,
    bool confirmed = false,
  }) async {
    try {
      await _client.functions.invoke(
        'profile-create',
        body: {
          'nickname': nickname,
          'terms_version': termsVersion,
          'confirmed': confirmed,
        },
      );
    } on FunctionException catch (error) {
      throw ApiException.fromFunction(error);
    }
  }
}
