import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/push/push_messaging.dart';
import '../../domain/repositories/push_device_repository.dart';
import 'auth_provider.dart';

/// 端末側のプッシュ通知(FCM)。使えないときは何もしない。main_dev/prodで差し替える。
final pushMessagingProvider = Provider<PushMessaging>(
  (ref) => const NoopPushMessaging(),
);

/// 端末の登録先。main_dev/prodで、Supabase実装に差し替える。
final pushDeviceRepositoryProvider = Provider<PushDeviceRepository>(
  (ref) => const NoopPushDeviceRepository(),
);

/// いま登録している端末のトークン(登録していなければ`null`)。
final registeredPushTokenProvider = StateProvider<String?>((ref) => null);

/// ログインしたら、通知の許可を求め、端末を登録する。トークンが変わったら登録し直す。
/// ログアウトの前の解除は、[unregisterPushDevice]で行う。許可されなかったり、登録に
/// 失敗したりしても、アプリの利用は止めない(プッシュが届かないだけ)。
final pushRegistrationProvider = Provider<void>((ref) {
  final messaging = ref.watch(pushMessagingProvider);
  if (!messaging.isAvailable) return;
  StreamSubscription<String>? refresh;

  Future<void> register(String token) async {
    try {
      await ref.read(pushDeviceRepositoryProvider).register(token);
      ref.read(registeredPushTokenProvider.notifier).state = token;
    } catch (_) {
      // 次にログインしたとき、またはトークンが変わったとき、登録し直す。
    }
  }

  Future<void> start() async {
    try {
      if (!await messaging.requestPermission()) return;
      final token = await messaging.getToken();
      if (token != null) await register(token);
      refresh = messaging.onTokenRefresh.listen(register);
    } catch (_) {
      // 許可・トークンの取得に失敗しても、アプリは使える。
    }
  }

  ref.listen<String?>(currentUserIdProvider, (previous, next) {
    if (previous == next) return;
    unawaited(refresh?.cancel());
    refresh = null;
    ref.read(registeredPushTokenProvider.notifier).state = null;
    if (next != null) unawaited(start());
  }, fireImmediately: true);
  ref.onDispose(() => unawaited(refresh?.cancel()));
});

/// ログアウトの前に、この端末の登録を外す(外したあとの通知が、この人に届かないように)。
/// 失敗しても、ログアウトは進める(サーバーは、次にこの端末でログインした人へ持ち主を移す)。
Future<void> unregisterPushDevice(ProviderContainer container) async {
  final token = container.read(registeredPushTokenProvider);
  if (token == null) return;
  try {
    await container.read(pushDeviceRepositoryProvider).unregister(token);
  } catch (_) {
    // ログアウトを止めない。
  }
  container.read(registeredPushTokenProvider.notifier).state = null;
}
