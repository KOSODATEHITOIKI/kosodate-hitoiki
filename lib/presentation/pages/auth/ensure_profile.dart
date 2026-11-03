import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/profile_registration_repository.dart';
import 'profile_creation.dart';
import 'profile_setup_page.dart';

/// ログインした利用者に、プロフィールがなければ作る(登録時に控えたニックネームと同意が
/// あれば自動で、なければ入力画面で)。プロフィールがある・作れたら`true`、利用者が途中で
/// やめたら`false`(呼び出し側で、ログアウトする)。
///
/// 認証は済んでいても、プロフィールがない状態は、ホームに進ませない
/// (メール確認・Googleのリンクから、アプリを新しく起動した場合も含む)。
Future<bool> ensureProfile({
  required BuildContext context,
  required ProfileRegistrationRepository profiles,
  required User user,
}) async {
  if (await profiles.hasProfile(user.id)) return true;
  if (!context.mounted) return false;
  final metadata = user.userMetadata ?? const <String, dynamic>{};
  final nickname = (metadata['nickname'] as String?)?.trim() ?? '';
  final agreed = metadata['terms_agreed'] == true;
  String? failure = 'ニックネームを決めてください。';
  if (nickname.isNotEmpty && agreed) {
    failure = await createProfileWithConfirmation(
      context: context,
      repository: profiles,
      nickname: nickname,
    );
  }
  if (failure == null) return true;
  if (!context.mounted) return false;
  final created = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => ProfileSetupPage(initialNickname: nickname),
    ),
  );
  return created == true;
}
