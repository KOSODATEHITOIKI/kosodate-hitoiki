import '../models/app_notification.dart';

/// お知らせの取得と既読の抽象。バックエンド接続時はSupabase実装に差し替える。
abstract class NotificationRepository {
  /// サンプルデータか。trueの間、画面に「サンプルのお知らせです」の注記を出す。
  bool get isSample;

  /// 自分宛てのお知らせ(新しい順)。ログイン必須。ブロックした相手が起こした
  /// お知らせは、サーバー側で除かれる。
  Future<List<AppNotification>> fetchNotifications();

  /// お知らせを既読にする(本人のみ。既読にできるのは`is_read`だけ)。
  Future<void> markRead(String id);
}
