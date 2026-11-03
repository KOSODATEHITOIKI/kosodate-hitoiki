import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/account_repository.dart';
import '../api/api_exception.dart';

/// 退会(`POST /functions/v1/account-delete`)。取消期間はなく、即時に削除する。
/// アプリ側で「元に戻せません」と確認してから呼ぶ(バックエンド docs/API契約.md 2節)。
class SupabaseAccountRepository implements AccountRepository {
  SupabaseAccountRepository(this._client);

  final SupabaseClient _client;

  @override
  bool get isSample => false;

  @override
  Future<void> deleteAccount() async {
    try {
      await _client.functions.invoke(
        'account-delete',
        body: const {'confirm': true},
      );
    } on FunctionException catch (error) {
      throw ApiException.fromFunction(error);
    }
  }
}
