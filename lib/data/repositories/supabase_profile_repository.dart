import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/child_age_range.dart';
import '../../domain/models/picked_avatar.dart';
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
    ChildAgeRange? childAgeRange,
    bool clearChildAgeRange = false,
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
          clearChildAgeRange: clearChildAgeRange,
          confirmed: confirmed,
        ),
      );
    } on FunctionException catch (error) {
      throw ApiException.fromFunction(error);
    }
  }

  /// アカウント画像のアップロード(`PUT /functions/v1/profile-avatar`)。
  @override
  Future<void> uploadAvatar(PickedAvatar avatar) async {
    try {
      await _client.functions.invoke(
        'profile-avatar',
        method: HttpMethod.put,
        headers: {'Content-Type': avatar.contentType},
        body: avatar.bytes,
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
    ChildAgeRange? childAgeRange,
    bool clearChildAgeRange = false,
    bool confirmed = false,
  }) {
    if (childAgeRange != null && clearChildAgeRange) {
      throw ArgumentError('年齢帯の設定と解除は、同時に指定できません');
    }
    return {
      'bio': ?bio?.trim(),
      'icon_key': ?iconKey,
      // 解除は、nullを送る(送らないと「変えない」になる)。
      if (childAgeRange != null) 'child_age_range': childAgeRange.code,
      if (clearChildAgeRange) 'child_age_range': null,
      if (confirmed) 'confirmed': true,
    };
  }

  @override
  Future<UserProfile?> fetchProfile(String userId) async {
    final mine = _client.auth.currentUser?.id == userId;
    final row = mine
        ? await _client
              .from('profiles')
              .select('id,nickname,bio,child_age_range,icon_key,avatar_path')
              .eq('id', userId)
              .maybeSingle()
        : await _client
              .from('public_profiles')
              .select('id,nickname,icon_key,avatar_path')
              .eq('id', userId)
              .maybeSingle();
    return row == null ? null : profileFromRow(row);
  }

  /// APIの行をプロフィールにする。アップロード画像(`avatar_path`)があれば、その公開URLを表示に使う。
  static UserProfile profileFromRow(Map<String, dynamic> row) => UserProfile(
    id: row['id'] as String,
    nickname: row['nickname'] as String? ?? '',
    avatarAsset: AppAvatars.forRow(
      iconKey: row['icon_key'] as String?,
      avatarPath: row['avatar_path'] as String?,
    ),
    bio: row['bio'] as String? ?? '',
    childAgeBand: row['child_age_range'] as String?,
  );
}
