import 'package:kosodate_hitoiki/domain/models/user_profile.dart';
import 'package:kosodate_hitoiki/domain/repositories/profile_repository.dart';

/// プロフィールの取得結果を固定し、ニックネーム変更・更新の呼び出しを記録して、
/// 決めた順に結果(成功・失敗)を返す偽のリポジトリ。
class ScriptedProfileRepository implements ProfileRepository {
  ScriptedProfileRepository({
    this.profile,
    this.sample = false,
    List<Object?>? nicknameScript,
    List<Object?>? updateScript,
  }) : nicknameScript = nicknameScript ?? [],
       updateScript = updateScript ?? [];

  final UserProfile? profile;
  final bool sample;

  /// 呼び出しごとに1つ使う。nullなら成功、それ以外は投げる。
  final List<Object?> nicknameScript;
  final List<Object?> updateScript;
  final nicknameCalls = <({String nickname, bool confirmed})>[];
  final updateCalls =
      <({String? bio, String? iconKey, String? age, bool confirmed})>[];

  @override
  bool get isSample => sample;

  @override
  Future<UserProfile?> fetchProfile(String userId) async => profile;

  @override
  Future<void> changeNickname({
    required String nickname,
    bool confirmed = false,
  }) async {
    nicknameCalls.add((nickname: nickname, confirmed: confirmed));
    final next = nicknameScript.removeAt(0);
    if (next != null) throw next;
  }

  @override
  Future<void> updateProfile({
    String? bio,
    String? iconKey,
    String? childAgeRange,
    bool confirmed = false,
  }) async {
    updateCalls.add((
      bio: bio,
      iconKey: iconKey,
      age: childAgeRange,
      confirmed: confirmed,
    ));
    final next = updateScript.removeAt(0);
    if (next != null) throw next;
  }
}
