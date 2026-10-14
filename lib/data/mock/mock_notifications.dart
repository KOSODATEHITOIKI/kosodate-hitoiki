import '../../core/constants/app_icons.dart';

/// S-06の見た目と既読操作を確認するサンプル。サーバー通知ではない。
class MockNotification {
  const MockNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.asset,
    required this.ageLabel,
    this.initiallyRead = false,
    this.postId,
  });
  final String id;
  final String title;
  final String body;
  final String asset;
  final String ageLabel;
  final bool initiallyRead;
  final String? postId;
}

const mockNotifications = [
  MockNotification(
    id: 'comment',
    postId: 'p2',
    title: 'はなさんがコメントしました',
    body: '「わかります！うちも同じです。一緒にがんばりましょう。」',
    asset: AppAvatars.defaultTulip,
    ageLabel: '5分前',
  ),
  MockNotification(
    id: 'reply',
    postId: 'p3',
    title: '返信が届きました',
    body: '「そうなんですね！とても参考になりました。」',
    asset: AppIcons.reply,
    ageLabel: '1時間前',
  ),
  MockNotification(
    id: 'empathy',
    postId: 'p1',
    title: '共感が届きました',
    body: 'あなたの投稿に8件の共感が届いています。',
    asset: AppDecorations.heartWarm,
    ageLabel: '3時間前',
  ),
  MockNotification(
    id: 'announcement',
    title: '運営からのお知らせ',
    body: '利用ガイドをご確認ください。名前や個人情報を書かず、気持ちを否定せずに受けとめ合いましょう。',
    asset: AppIcons.noticeMegaphone,
    ageLabel: '1日前',
    initiallyRead: true,
  ),
];
