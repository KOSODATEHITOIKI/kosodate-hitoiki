import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// 画面確認・テスト用のモック実装。既読の状態は、アプリを閉じるまでの間だけ持つ。
class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository() {
    final now = DateTime.now();
    _items = [
      AppNotification(
        id: 'comment',
        type: NotificationType.comment,
        postId: 'p2',
        actorName: 'はな',
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
      AppNotification(
        id: 'reply',
        type: NotificationType.reply,
        postId: 'p3',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      AppNotification(
        id: 'empathy',
        type: NotificationType.reactionDigest,
        postId: 'p1',
        reactionCount: 8,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      AppNotification(
        id: 'announcement',
        type: NotificationType.moderation,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  late final List<AppNotification> _items;

  /// サンプルの設定。共感のまとめは、初期は受け取らない(画面確認用)。
  var _settings = const NotificationSettings(reactions: false);

  @override
  Future<NotificationSettings> fetchSettings() async => _settings;

  @override
  Future<void> updateSettings({
    bool? comments,
    bool? replies,
    bool? reactions,
  }) async {
    _settings = _settings.copyWith(
      comments: comments,
      replies: replies,
      reactions: reactions,
    );
  }

  @override
  bool get isSample => true;

  @override
  Future<List<AppNotification>> fetchNotifications() async => List.of(_items);

  @override
  Future<void> markRead(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) _items[index] = _items[index].copyWith(isRead: true);
  }
}
