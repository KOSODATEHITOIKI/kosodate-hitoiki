import 'package:kosodate_hitoiki/domain/models/picked_avatar.dart';
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
    List<Object?>? avatarScript,
    this.fetchGate,
    List<Object>? fetchErrors,
  }) : fetchErrors = fetchErrors ?? [],
       nicknameScript = nicknameScript ?? [],
       updateScript = updateScript ?? [],
       avatarScript = avatarScript ?? [];

  final UserProfile? profile;
  final bool sample;

  /// 取得を、これが終わるまで待たせる(読み込み中の状態を作る)。
  final Future<void>? fetchGate;

  /// 取得の呼び出しごとに1つ使う(なくなったら成功)。投げる。
  final List<Object> fetchErrors;
  var fetchCount = 0;

  /// 呼び出しごとに1つ使う。nullなら成功、`Future<void> Function()`ならその結果を待つ(ニックネーム変更)、
  /// それ以外は投げる。
  final List<Object?> nicknameScript;
  final List<Object?> updateScript;

  /// 画像のアップロードの呼び出しごとに1つ使う(なくなったら成功)。nullでなければ投げる。
  final List<Object?> avatarScript;
  final avatarCalls = <PickedAvatar>[];
  final nicknameCalls = <({String nickname, bool confirmed})>[];
  final updateCalls =
      <({String? bio, String? iconKey, String? age, bool confirmed})>[];

  @override
  bool get isSample => sample;

  @override
  Future<UserProfile?> fetchProfile(String userId) async {
    fetchCount++;
    if (fetchGate != null) await fetchGate;
    if (fetchErrors.isNotEmpty) throw fetchErrors.removeAt(0);
    return profile;
  }

  @override
  Future<void> uploadAvatar(PickedAvatar avatar) async {
    avatarCalls.add(avatar);
    if (avatarScript.isEmpty) return;
    final next = avatarScript.removeAt(0);
    if (next != null) throw next;
  }

  @override
  Future<void> changeNickname({
    required String nickname,
    bool confirmed = false,
  }) async {
    nicknameCalls.add((nickname: nickname, confirmed: confirmed));
    final next = nicknameScript.removeAt(0);
    if (next is Future<void> Function()) return next();
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
