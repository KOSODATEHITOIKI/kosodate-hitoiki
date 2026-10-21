import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// お知らせの取得(`notifications`)と既読(`PATCH notifications`)。読める・既読にできるのは
/// 受信者本人だけ。ブロックした相手が起こしたお知らせは、サーバーが除く
/// (kosodate-hitoiki-backend docs/API契約.md 8節)。
class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseNotificationRepository(this._client);

  final SupabaseClient _client;

  /// 1回に取得する件数。ページ送りは未実装。
  static const pageSize = 30;

  static const _columns =
      'id,notification_type,actor_id,post_id,comment_id,is_read,created_at,'
      'reaction_count';

  @override
  bool get isSample => false;

  @override
  Future<List<AppNotification>> fetchNotifications() async {
    final rows = await _client
        .from('notifications')
        .select(_columns)
        .order('created_at', ascending: false)
        .limit(pageSize);
    final actorIds = {
      for (final row in rows)
        if (row['actor_id'] != null) row['actor_id'] as String,
    }.toList();
    final names = await _nicknames(actorIds);
    return [
      for (final row in rows)
        notificationFromRow(row, actorName: names[row['actor_id']]),
    ];
  }

  /// 発生させた人のニックネーム(公開プロフィール)。取得できなかった人は、含まれない。
  Future<Map<String, String>> _nicknames(List<String> ids) async {
    if (ids.isEmpty) return const {};
    final rows = await _client
        .from('public_profiles')
        .select('id,nickname')
        .inFilter('id', ids);
    return {
      for (final row in rows) row['id'] as String: row['nickname'] as String,
    };
  }

  /// 自分の通知の設定(`notification_settings`。本人の行だけが見える)。まだ行がなければ、
  /// 既定(すべて受け取る)にする。
  @override
  Future<NotificationSettings> fetchSettings() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const NotificationSettings();
    final row = await _client
        .from('notification_settings')
        .select(
          'comments_enabled,replies_enabled,reactions_enabled,push_enabled',
        )
        .eq('user_id', userId)
        .maybeSingle();
    return row == null ? const NotificationSettings() : settingsFromRow(row);
  }

  /// 通知の設定の変更(`PATCH notification_settings`)。指定した項目だけ送る。
  @override
  Future<void> updateSettings({
    bool? comments,
    bool? replies,
    bool? reactions,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('ログインが必要です');
    final body = settingsBody(
      comments: comments,
      replies: replies,
      reactions: reactions,
    );
    if (body.isEmpty) return;
    await _client
        .from('notification_settings')
        .update(body)
        .eq('user_id', userId);
  }

  /// 設定の行を、通知の設定にする。
  static NotificationSettings settingsFromRow(Map<String, dynamic> row) =>
      NotificationSettings(
        comments: row['comments_enabled'] != false,
        replies: row['replies_enabled'] != false,
        reactions: row['reactions_enabled'] != false,
        push: row['push_enabled'] != false,
      );

  /// 設定の変更の本文。指定した項目だけを入れる。
  static Map<String, dynamic> settingsBody({
    bool? comments,
    bool? replies,
    bool? reactions,
  }) => {
    'comments_enabled': ?comments,
    'replies_enabled': ?replies,
    'reactions_enabled': ?reactions,
  };

  @override
  Future<void> markRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  /// APIの行をお知らせにする。
  static AppNotification notificationFromRow(
    Map<String, dynamic> row, {
    String? actorName,
  }) => AppNotification(
    id: row['id'] as String,
    type: NotificationType.fromCode(row['notification_type'] as String?),
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    actorName: actorName,
    postId: row['post_id'] as String?,
    commentId: row['comment_id'] as String?,
    reactionCount: (row['reaction_count'] as num?)?.toInt() ?? 0,
    isRead: row['is_read'] == true,
  );
}
