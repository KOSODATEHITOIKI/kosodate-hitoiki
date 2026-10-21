import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_icons.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../api/api_exception.dart';

/// プロフィールの取得。自分のプロフィールは`profiles`(自己紹介・年齢帯を含む)、
/// ほかの人は`public_profiles`(ニックネーム・アイコンだけ)から読む。
/// 自己紹介・年齢帯は、初期版では本人と運営者のみが読める
/// (バックエンド 決定ログ 2026-09-30)。`public_profiles`は、自分と、公開中の投稿・
/// コメントの投稿者に限られるため、それ以外のIDは`null`になる。
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  bool get isSample => false;

  /// プロフィールの更新(`PATCH /functions/v1/profile-update`)。指定した項目だけ送る。
  @override
  Future<void> updateProfile({
    String? bio,
    String? iconKey,
    String? childAgeRange,
    bool confirmed = false,
  }) async {
    try {
      await _client.functions.invoke(
        'profile-update',
        method: HttpMethod.patch,
        body: updateBody(
          bio: bio,
          iconKey: iconKey,
          childAgeRange: childAgeRange,
          confirmed: confirmed,
        ),
      );
    } on FunctionException catch (error) {
      throw ApiException.fromFunction(error);
    }
  }

  /// ニックネームの変更(`POST /functions/v1/profile-nickname`)。
  @override
  Future<void> changeNickname({
    required String nickname,
    bool confirmed = false,
  }) async {
    try {
      await _client.functions.invoke(
        'profile-nickname',
        body: {'nickname': nickname.trim(), if (confirmed) 'confirmed': true},
      );
    } on FunctionException catch (error) {
      throw ApiException.fromFunction(error);
    }
  }

  /// プロフィール更新APIのリクエスト本文。指定した項目だけを入れる。
  static Map<String, dynamic> updateBody({
    String? bio,
    String? iconKey,
    String? childAgeRange,
    bool confirmed = false,
  }) => {
    'bio': ?bio?.trim(),
    'icon_key': ?iconKey,
    'child_age_range': ?childAgeRange,
    if (confirmed) 'confirmed': true,
  };

  @override
  Future<UserProfile?> fetchProfile(String userId) async {
    final mine = _client.auth.currentUser?.id == userId;
    final row = mine
        ? await _client
              .from('profiles')
              .select('id,nickname,bio,child_age_range,icon_key')
              .eq('id', userId)
              .maybeSingle()
        : await _client
              .from('public_profiles')
              .select('id,nickname,icon_key')
              .eq('id', userId)
              .maybeSingle();
    return row == null ? null : profileFromRow(row);
  }

  /// APIの行をプロフィールにする。アップロード画像(`avatar_path`)は、段8で扱う。
  static UserProfile profileFromRow(Map<String, dynamic> row) => UserProfile(
    id: row['id'] as String,
    nickname: row['nickname'] as String? ?? '',
    avatarAsset: AppAvatars.forIconKey(row['icon_key'] as String?),
    bio: row['bio'] as String? ?? '',
    childAgeBand: row['child_age_range'] as String?,
  );
}
