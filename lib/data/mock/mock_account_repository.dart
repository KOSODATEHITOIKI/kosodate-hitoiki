import '../../domain/repositories/account_repository.dart';

/// 画面確認・テスト用のモック実装。何も削除しない。
class MockAccountRepository implements AccountRepository {
  @override
  bool get isSample => true;

  @override
  Future<void> deleteAccount() async {}
}
