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

/// 登録の途中の処理(許可・トークンの取得・登録)。ログアウトの前の解除は、これが終わって
/// から行う(登録の応答を待つ間にログアウトして、解除が空振りするのを防ぐ)。
final pushPendingProvider = StateProvider<Future<void>?>((ref) => null);

/// ログインしたら、通知の許可を求め、端末を登録する。トークンが変わったら登録し直す。
/// ログアウトの前の解除は、[unregisterPushDevice]で行う。許可されなかったり、登録に
/// 失敗したりしても、アプリの利用は止めない(プッシュが届かないだけ)。
final pushRegistrationProvider = Provider<void>((ref) {
  final messaging = ref.watch(pushMessagingProvider);
  if (!messaging.isAvailable) return;
  StreamSubscription<String>? refresh;

  // 利用者が変わるたびに増やす。古い利用者のための処理が、あとから登録・監視を始めないように
  // するための印(許可の確認・トークンの取得・登録は、時間がかかる)。
  var generation = 0;

  Future<void> register(String token, int mine) async {
    if (mine != generation) return;
    try {
      await ref.read(pushDeviceRepositoryProvider).register(token);
      // 登録の応答を待つ間に、利用者が変わった。この登録は、前の利用者のもの。
      if (mine != generation) return;
      ref.read(registeredPushTokenProvider.notifier).state = token;
    } catch (_) {
      // 次にログインしたとき、またはトークンが変わったとき、登録し直す。
    }
  }

  Future<void> start(int mine) async {
    try {
      if (!await messaging.requestPermission() || mine != generation) return;
      final token = await messaging.getToken();
      if (mine != generation) return;
      if (token != null) await register(token, mine);
      if (mine != generation) return;
      refresh = messaging.onTokenRefresh.listen((token) {
        final pending = register(token, mine);
        ref.read(pushPendingProvider.notifier).state = pending;
      });
    } catch (_) {
      // 許可・トークンの取得に失敗しても、アプリは使える。
    }
  }

  ref.listen<String?>(currentUserIdProvider, (previous, next) {
    if (previous == next) return;
    generation++;
    unawaited(refresh?.cancel());
    refresh = null;
    ref.read(registeredPushTokenProvider.notifier).state = null;
    if (next != null) {
      final pending = start(generation);
      ref.read(pushPendingProvider.notifier).state = pending;
    }
  }, fireImmediately: true);
  ref.onDispose(() {
    generation++;
    unawaited(refresh?.cancel());
  });
});

/// ログアウトの前に、この端末の登録を外す(外したあとの通知が、この人に届かないように)。
/// 失敗しても、ログアウトは進める(サーバーは、次にこの端末でログインした人へ持ち主を移す)。
Future<void> unregisterPushDevice(ProviderContainer container) async {
  // 登録の途中なら、終わるのを待つ(終わる前に外そうとすると、空振りして、あとで登録が残る)。
  final pending = container.read(pushPendingProvider);
  if (pending != null) {
    try {
      await pending.timeout(const Duration(seconds: 10));
    } catch (_) {
      // 待ちきれなくても、いま分かっているトークンで、外す。
    }
  }
  final token = container.read(registeredPushTokenProvider);
  if (token == null) return;
  try {
    await container.read(pushDeviceRepositoryProvider).unregister(token);
  } catch (_) {
    // ログアウトを止めない。
  }
  container.read(registeredPushTokenProvider.notifier).state = null;
}
