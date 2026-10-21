import '../models/user_profile.dart';

abstract class ProfileRepository {
  /// サンプルデータか。trueの間、保存せず「準備中」と案内する。
  bool get isSample;

  Future<UserProfile?> fetchProfile(String userId);

  /// プロフィールを更新する(指定した項目だけ。何も指定しないと失敗する)。
  /// 自己紹介は送信前チェックを通る(確認が必要なときは`ApiException`。[confirmed]を
  /// trueにして再送する)。[iconKey]を指定すると、アップロード画像は外れる。
  Future<void> updateProfile({
    String? bio,
    String? iconKey,
    String? childAgeRange,
    bool confirmed = false,
  });

  /// ニックネームを変える。初回は制限なし、以降は前回の変更から30日空ける
  /// (違反は`ApiException`)。送信前チェックを通る。変更前の名前は30日、ほかの人が使えない。
  Future<void> changeNickname({
    required String nickname,
    bool confirmed = false,
  });
}
