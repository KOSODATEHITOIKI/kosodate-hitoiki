import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_notification_repository.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// お知らせの取得先。バックエンド接続時は、main_dev/prodでSupabase実装に差し替える。
/// 利用者が変わったときは、lib/app.dartが作り直す。
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => MockNotificationRepository(),
);

/// 画面にサンプルのお知らせの注記を出すか。
final notificationsAreSampleProvider = Provider<bool>(
  (ref) => ref.watch(notificationRepositoryProvider).isSample,
);

/// 自分宛てのお知らせ(新しい順)。
final notificationsProvider = FutureProvider<List<AppNotification>>(
  (ref) => ref.watch(notificationRepositoryProvider).fetchNotifications(),
);
