import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/push_device_repository.dart';

/// 端末の登録は`register_push_device`だけ(表への直接の書き込みは拒否される)。
/// 解除は、自分の行を削除する(kosodate-hitoiki-backend docs/API契約.md 8節)。
class SupabasePushDeviceRepository implements PushDeviceRepository {
  SupabasePushDeviceRepository(this._client, {this.platform = 'android'});

  final SupabaseClient _client;

  /// 端末の種類(`android`・`ios`)。
  final String platform;

  @override
  Future<void> register(String token) async {
    await _client.rpc<void>(
      'register_push_device',
      params: registerParams(platform, token),
    );
  }

  @override
  Future<void> unregister(String token) async {
    await _client.from('push_devices').delete().eq('device_token', token);
  }

  /// 登録のリクエスト。
  static Map<String, dynamic> registerParams(String platform, String token) => {
    'p_platform': platform,
    'p_token': token,
  };
}
