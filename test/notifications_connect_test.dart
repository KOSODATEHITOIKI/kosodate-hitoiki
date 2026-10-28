import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/repositories/supabase_notification_repository.dart';
import 'package:kosodate_hitoiki/domain/models/app_notification.dart';
import 'package:kosodate_hitoiki/domain/models/post.dart';
import 'package:kosodate_hitoiki/presentation/pages/notifications/notifications_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/post_detail/post_detail_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/notification_providers.dart';
import 'package:kosodate_hitoiki/presentation/providers/post_providers.dart';

import 'helpers/scripted_notification_repository.dart';
import 'helpers/scripted_post_repository.dart';

Post _post(String id) => Post(
  id: id,
  authorId: 'me',
  authorName: 'こもれび',
  authorAvatarAsset: 'assets/avatars/avatar-default-sprout.png',
  createdAt: DateTime(2026, 10, 21),
  type: PostType.consult,
  responseMode: ResponseMode.advice,
  body: 'お知らせの投稿です。',
  empathyCount: 0,
  commentCount: 0,
  isMine: true,
);

Future<void> pumpNotifications(
  WidgetTester tester,
  ScriptedNotificationRepository notifications, {
  ScriptedPostRepository? posts,
}) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        isLoggedInProvider.overrideWithValue(true),
        notificationRepositoryProvider.overrideWithValue(notifications),
        postRepositoryProvider.overrideWithValue(
          posts ?? ScriptedPostRepository([]),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: NotificationsPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapCard(WidgetTester tester, String id) async {
  final card = find.byKey(ValueKey('notification-$id'));
  await tester.scrollUntilVisible(
    card,
    150,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(card);
  await tester.pumpAndSettle();
}

/// 未読の印(8×8の丸)。「未読」の切り替えボタンの文字とは別に数える。
final _unreadDots = find.byWidgetPredicate(
  (widget) =>
      widget is Container &&
      widget.constraints == const BoxConstraints.tightFor(width: 8, height: 8),
);

void main() {
  testWidgets('種類ごとの定型文で表示する(本文・共感した人は出さない)。サンプルの注記は出さない', (tester) async {
    await pumpNotifications(
      tester,
      ScriptedNotificationRepository(
        items: [
          notification(
            'n1',
            NotificationType.comment,
            actorName: 'はな',
            postId: 'p1',
          ),
          notification('n2', NotificationType.reply, postId: 'p1'),
          notification(
            'n3',
            NotificationType.reactionDigest,
            postId: 'p1',
            reactionCount: 8,
          ),
          notification('n4', NotificationType.moderation, isRead: true),
        ],
      ),
    );
    expect(find.text('はなさんがコメントしました'), findsOneWidget);
    expect(find.text('あなたの投稿にコメントが届いています。'), findsOneWidget);
    expect(find.text('返信が届きました'), findsOneWidget);
    expect(find.text('共感が届きました'), findsOneWidget);
    expect(find.text('あなたの投稿に8件の共感が届いています。'), findsOneWidget);
    expect(find.text('運営からのお知らせ'), findsOneWidget);
    expect(find.textContaining('サンプル'), findsNothing);
    // 未読は3件、既読の運営のお知らせには未読の印がない。
    expect(_unreadDots, findsNWidgets(3));
  });

  testWidgets('投稿に結び付くお知らせは、既読にして、その投稿の詳細を開く', (tester) async {
    final notifications = ScriptedNotificationRepository(
      items: [
        notification(
          'n1',
          NotificationType.comment,
          actorName: 'はな',
          postId: 'p1',
        ),
      ],
    );
    final posts = ScriptedPostRepository([])..fetchedPosts['p1'] = _post('p1');
    await pumpNotifications(tester, notifications, posts: posts);
    await tapCard(tester, 'n1');

    expect(notifications.markCalls, ['n1']);
    expect(find.byType(PostDetailPage), findsOneWidget);
    expect(
      tester.widget<PostDetailPage>(find.byType(PostDetailPage)).post.id,
      'p1',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(_unreadDots, findsNothing);
  });

  testWidgets('見えない投稿(削除・ブロックなど)は、「投稿が見つかりません」と案内する', (tester) async {
    final notifications = ScriptedNotificationRepository(
      items: [notification('n1', NotificationType.comment, postId: 'gone')],
    );
    final posts = ScriptedPostRepository([])..missingPostIds.add('gone');
    await pumpNotifications(tester, notifications, posts: posts);
    await tapCard(tester, 'n1');
    expect(find.text('投稿が見つかりません'), findsOneWidget);
    expect(find.byType(PostDetailPage), findsNothing);
  });

  testWidgets('投稿に結び付かない運営からのお知らせは、内容を表示して、既読にする', (tester) async {
    final notifications = ScriptedNotificationRepository(
      items: [notification('n4', NotificationType.moderation)],
    );
    await pumpNotifications(tester, notifications);
    await tapCard(tester, 'n4');

    expect(notifications.markCalls, ['n4']);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('運営から、お知らせがあります。利用ガイドもご確認ください。'), findsWidgets);
    expect(find.text('投稿を見る'), findsNothing);
  });

  testWidgets('既読にできなかったときは、未読のままにする', (tester) async {
    final notifications = ScriptedNotificationRepository(
      items: [notification('n4', NotificationType.moderation)],
      markError: Exception('network'),
    );
    await pumpNotifications(tester, notifications);
    await tapCard(tester, 'n4');
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    expect(notifications.markCalls, ['n4']);
    expect(_unreadDots, findsOneWidget);
  });

  testWidgets('「未読」では、既読にしたお知らせが消える。0件のときの文言も出し分ける', (tester) async {
    await pumpNotifications(
      tester,
      ScriptedNotificationRepository(
        items: [notification('n4', NotificationType.moderation)],
      ),
    );
    await tester.tap(find.text('未読'));
    await tester.pumpAndSettle();
    await tapCard(tester, 'n4');
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notification-n4')), findsNothing);
    expect(find.text('未読のお知らせはありません'), findsOneWidget);

    await tester.tap(find.text('すべて'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notification-n4')), findsOneWidget);
  });

  testWidgets('お知らせが1件もないときは、「お知らせは、まだありません」', (tester) async {
    await pumpNotifications(tester, ScriptedNotificationRepository());
    expect(find.text('お知らせは、まだありません'), findsOneWidget);
  });

  testWidgets('読み込めなかったときは、再読み込みできる', (tester) async {
    final notifications = ScriptedNotificationRepository(
      items: [notification('n4', NotificationType.moderation)],
      fetchErrors: [Exception('network')],
    );
    await pumpNotifications(tester, notifications);
    expect(find.text('お知らせを読み込めませんでした。'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('notifications-retry')));
    await tester.pumpAndSettle();
    expect(find.text('運営からのお知らせ'), findsOneWidget);
    expect(notifications.fetchCount, 2);
  });

  group('行の読み取り', () {
    Map<String, dynamic> row(String type, {bool isRead = false}) => {
      'id': 'n-1',
      'notification_type': type,
      'actor_id': 'a-1',
      'post_id': 'p-1',
      'comment_id': 'c-1',
      'is_read': isRead,
      'created_at': '2026-10-21T01:02:03Z',
      'reaction_count': type == 'reaction_digest' ? 5 : null,
    };

    test('通知の行を、お知らせにする', () {
      final item = SupabaseNotificationRepository.notificationFromRow(
        row('comment'),
        actorName: 'はな',
      );
      expect(item.type, NotificationType.comment);
      expect(item.actorName, 'はな');
      expect(item.postId, 'p-1');
      expect(item.commentId, 'c-1');
      expect(item.isRead, isFalse);
      expect(item.createdAt.toUtc(), DateTime.utc(2026, 10, 21, 1, 2, 3));
    });

    test('共感のまとめは、件数を持つ。知らない種類は運営のお知らせにする', () {
      expect(
        SupabaseNotificationRepository.notificationFromRow(
          row('reaction_digest'),
        ).reactionCount,
        5,
      );
      expect(NotificationType.fromCode('reply'), NotificationType.reply);
      expect(NotificationType.fromCode('unknown'), NotificationType.moderation);
      expect(NotificationType.fromCode(null), NotificationType.moderation);
    });
  });
}
