import 'package:kosodate_hitoiki/domain/models/app_notification.dart';
import 'package:kosodate_hitoiki/domain/repositories/notification_repository.dart';

/// お知らせの一覧を固定し、既読の呼び出しを記録する偽のリポジトリ。
class ScriptedNotificationRepository implements NotificationRepository {
  ScriptedNotificationRepository({
    this.items = const [],
    this.sample = false,
    this.markError,
    List<Object>? fetchErrors,
  }) : fetchErrors = fetchErrors ?? [];

  final List<AppNotification> items;
  final bool sample;

  /// 既読で投げるエラー(nullなら成功)。
  final Object? markError;

  /// 取得の呼び出しごとに1つ使う(なくなったら成功)。投げる。
  final List<Object> fetchErrors;
  final markCalls = <String>[];
  var fetchCount = 0;

  @override
  bool get isSample => sample;

  @override
  Future<List<AppNotification>> fetchNotifications() async {
    fetchCount++;
    if (fetchErrors.isNotEmpty) throw fetchErrors.removeAt(0);
    return items;
  }

  @override
  Future<void> markRead(String id) async {
    markCalls.add(id);
    if (markError != null) throw markError!;
  }
}

AppNotification notification(
  String id,
  NotificationType type, {
  String? actorName,
  String? postId,
  int reactionCount = 0,
  bool isRead = false,
}) => AppNotification(
  id: id,
  type: type,
  createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
  actorName: actorName,
  postId: postId,
  reactionCount: reactionCount,
  isRead: isRead,
);
