/// アカウントの削除(退会)の抽象。バックエンド接続時はSupabase実装に差し替える。
abstract class AccountRepository {
  /// サンプルか。trueの間、削除せず「準備中」と案内する。
  bool get isSample;

  /// アカウントと関連データを、即時に削除する。取消期間はない。
  ///
  /// 何度実行しても安全(途中で失敗したときは、同じ操作を再実行する)。失敗は`ApiException`:
  /// - `403 reauth_required`: この操作に使うセッションが、5分より前に作られている。
  ///   再ログインを求める
  /// - `409 operator_registered`: 運営者として登録されている間は、退会できない
  /// - `400 apple_code_required`: Appleで登録したアカウントなのに、[appleAuthorizationCode]
  ///   がない(Appleとの連携を解除できないので、削除しない)
  /// - `502 apple_revoke_failed`: Appleとの連携の解除に失敗した(削除していない)
  ///
  /// [appleAuthorizationCode]は、Appleで登録したアカウントのとき、退会の直前に、もう一度
  /// Appleで確認して受け取ったコード。[appleClientId]は、そのときAppleに名乗ったID
  /// (iOSはBundle ID、WebはサービスID。コードは、このIDに対して発行される)。
  /// サーバーが、この2つで、Appleとの連携を解除する(審査ガイドライン5.1.1(v))。
  Future<void> deleteAccount({
    String? appleAuthorizationCode,
    String? appleClientId,
  });
}
