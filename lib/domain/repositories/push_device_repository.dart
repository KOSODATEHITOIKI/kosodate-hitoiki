/// この端末を、プッシュ通知の送り先として登録・解除する。
abstract class PushDeviceRepository {
  /// 端末を、ログイン中の利用者の送り先として登録する(同じ端末で別の人がログインしたら、
  /// 持ち主が新しい人に移る)。
  Future<void> register(String token);

  /// 端末の登録を外す(ログアウトの前に呼ぶ。ログイン中でないと、外せない)。
  Future<void> unregister(String token);
}

/// 何もしない(サンプル・テスト)。
class NoopPushDeviceRepository implements PushDeviceRepository {
  const NoopPushDeviceRepository();

  @override
  Future<void> register(String token) async {}

  @override
  Future<void> unregister(String token) async {}
}
