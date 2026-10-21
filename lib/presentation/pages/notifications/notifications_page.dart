import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kosodate_hitoiki/presentation/widgets/app_asset.dart';
import '../../../core/constants/app_brand.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../domain/models/app_notification.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_providers.dart';
import '../../providers/post_providers.dart';
import '../../widgets/comfort_page.dart';
import '../auth/auth_page.dart';
import '../post_detail/post_detail_page.dart';

/// お知らせの見出し。本文はサーバーが持たないので、種類から定型文で作る。
String notificationTitle(AppNotification item) => switch (item.type) {
  NotificationType.comment =>
    item.actorName != null ? '${item.actorName}さんがコメントしました' : 'コメントが届きました',
  NotificationType.reply =>
    item.actorName != null ? '${item.actorName}さんから返信が届きました' : '返信が届きました',
  NotificationType.reactionDigest => '共感が届きました',
  NotificationType.moderation => '運営からのお知らせ',
};

/// お知らせの本文(定型文。コメント・返信の本文や、共感した人は出さない)。
String notificationBody(AppNotification item) => switch (item.type) {
  NotificationType.comment => 'あなたの投稿にコメントが届いています。',
  NotificationType.reply => 'あなたのコメントに返信が届いています。',
  NotificationType.reactionDigest => 'あなたの投稿に${item.reactionCount}件の共感が届いています。',
  NotificationType.moderation => '運営から、お知らせがあります。利用ガイドもご確認ください。',
};

String _ageLabel(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'たった今';
  if (diff.inHours < 1) return '${diff.inMinutes}分前';
  if (diff.inDays < 1) return '${diff.inHours}時間前';
  return '${diff.inDays}日前';
}

String _iconFor(NotificationType type) => switch (type) {
  NotificationType.comment => AppIcons.comment,
  NotificationType.reply => AppIcons.reply,
  NotificationType.reactionDigest => AppDecorations.heartWarm,
  NotificationType.moderation => AppIcons.noticeMegaphone,
};

/// S-06。お知らせの一覧・既読を、お知らせAPIに接続している。
/// ゲストには、登録・ログインの案内を出す。
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});
  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  bool _unreadOnly = false;

  /// 既読にしたお知らせ。サーバーへの反映と一覧の取り直しを待たずに、すぐ既読の表示にする。
  final Set<String> _readIds = {};

  bool _isRead(AppNotification item) =>
      item.isRead || _readIds.contains(item.id);

  /// 既読にする。すぐ表示に反映し、サーバーに送る。送れなかったときは、未読に戻す。
  Future<void> _markRead(AppNotification item) async {
    if (_isRead(item)) return;
    setState(() => _readIds.add(item.id));
    try {
      await ref.read(notificationRepositoryProvider).markRead(item.id);
    } catch (_) {
      if (mounted) setState(() => _readIds.remove(item.id));
    }
  }

  Future<void> _open(AppNotification item) async {
    await _markRead(item);
    if (!mounted) return;
    final sample = ref.read(notificationsAreSampleProvider);
    if (!sample && item.postId != null) {
      await _openPost(item.postId!);
      return;
    }
    // サンプル、または、投稿に結び付かないお知らせ(運営から)は、内容を表示する。
    _showDialog(item, sample: sample);
  }

  void _showDialog(AppNotification item, {required bool sample}) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, dialogRef, _) {
          if (!dialogRef.watch(isLoggedInProvider)) {
            return AlertDialog(
              title: const Text('ログインが必要です'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('閉じる'),
                ),
              ],
            );
          }
          return AlertDialog(
            title: Text(notificationTitle(item)),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(notificationBody(item)),
                  if (sample) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'サンプルのお知らせです。',
                      style: TextStyle(fontSize: 12, height: 1.6),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (item.postId != null)
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _openPost(item.postId!);
                  },
                  child: const Text('投稿を見る'),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _notificationCard(AppNotification item) {
    final unread = !_isRead(item);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('notification-${item.id}'),
          onTap: () => _open(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: AppAsset(
                    _iconFor(item.type),
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notificationTitle(item),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (unread)
                            Semantics(
                              label: '未読',
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          Text(
                            _ageLabel(item.createdAt),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notificationBody(item),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, height: 1.7),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _list(List<AppNotification> items) {
    final visible = [
      for (final item in items)
        if (!_unreadOnly || !_isRead(item)) item,
    ];
    if (visible.isEmpty) {
      return _unreadOnly
          ? const ComfortNotice(
              asset: AppIllustrations.emptyNotifications,
              title: '未読のお知らせはありません',
              message: '自分のペースで、ひと息。',
            )
          : const ComfortNotice(
              asset: AppIllustrations.emptyNotifications,
              title: 'お知らせは、まだありません',
              message: '自分のペースで、ひと息。',
            );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final item in visible) _notificationCard(item)],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(isLoggedInProvider, (_, next) {
      if (!next) {
        setState(() {
          _unreadOnly = false;
          _readIds.clear();
        });
      }
    });
    if (!ref.watch(isLoggedInProvider)) {
      return ComfortPage(
        title: 'ログインして、\nひと息',
        message: 'お知らせを見るには、\n登録・ログインが必要です。',
        children: [
          FilledButton(
            onPressed: () => _auth(AuthMode.register),
            child: const Text('会員登録'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _auth(AuthMode.login),
            child: const Text('ログイン'),
          ),
        ],
      );
    }
    final notifications = ref.watch(notificationsProvider);
    return ComfortPage(
      title: 'お知らせ',
      titleImage: AppBrand.titleNotifications,
      titleImageScale: 1.15,
      message: 'ひと息のつながりから、\nうれしいお知らせをお届けします。',
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('すべて')),
            ButtonSegment(value: true, label: Text('未読')),
          ],
          selected: {_unreadOnly},
          showSelectedIcon: false,
          onSelectionChanged: (selection) =>
              setState(() => _unreadOnly = selection.single),
          style: SegmentedButton.styleFrom(
            backgroundColor: AppColors.white,
            selectedBackgroundColor: AppColors.secondary,
            selectedForegroundColor: AppColors.textPrimary,
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size(48, 52),
            side: const BorderSide(color: AppColors.divider),
            textStyle: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (ref.watch(notificationsAreSampleProvider)) ...[
          const Text(
            'サンプルのお知らせです。既読状態はアプリ終了時にリセットされます。',
            style: TextStyle(fontSize: 11, height: 1.6),
          ),
          const SizedBox(height: 12),
        ],
        notifications.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Column(
            children: [
              const Text('お知らせを読み込めませんでした。', style: TextStyle(fontSize: 14)),
              TextButton(
                key: const ValueKey('notifications-retry'),
                onPressed: () => ref.invalidate(notificationsProvider),
                child: const Text('再読み込み'),
              ),
            ],
          ),
          data: _list,
        ),
      ],
    );
  }

  void _auth(AuthMode mode) => Navigator.of(
    context,
  ).push<void>(MaterialPageRoute(builder: (_) => AuthPage(initialMode: mode)));

  /// お知らせの投稿を、ID指定で取得して開く。見えない投稿(削除・ブロックなど)は、
  /// 「見つかりません」と案内する。
  Future<void> _openPost(String postId) async {
    try {
      final post = await ref.read(postRepositoryProvider).fetchPost(postId);
      if (!mounted || !ref.read(isLoggedInProvider)) return;
      if (post == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('投稿が見つかりません')));
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('投稿を読み込めませんでした')));
    }
  }
}
