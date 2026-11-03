import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/config/flavor.dart';
import 'package:kosodate_hitoiki/core/config/supabase_config.dart';

/// 接続先は、環境ごとに、別のプロジェクトを指す(devのデータを、本番のアプリが触らない)。
void main() {
  tearDown(() => AppConfig.setFlavor(Flavor.dev));

  test('アカウント画像の公開URLは、その環境のプロジェクトの Storage を指す', () {
    AppConfig.setFlavor(Flavor.dev);
    final dev = SupabaseConfig.avatarUrl('u-1/a.png');
    AppConfig.setFlavor(Flavor.prod);
    final prod = SupabaseConfig.avatarUrl('u-1/a.png');

    expect(dev, startsWith('https://djbizophhqtlqmlabhdo.supabase.co/'));
    expect(prod, startsWith('https://yaggicrvzykkfcdhsjlm.supabase.co/'));
    expect(prod, endsWith('/storage/v1/object/public/avatars/u-1/a.png'));
    expect(prod, isNot(equals(dev)));
  });

  test('本番の接続先は、仮の値のままではない', () {
    AppConfig.setFlavor(Flavor.prod);
    final url = SupabaseConfig.avatarUrl('x');
    expect(url, isNot(contains('your-project')));
    expect(url, startsWith('https://'));
  });
}
