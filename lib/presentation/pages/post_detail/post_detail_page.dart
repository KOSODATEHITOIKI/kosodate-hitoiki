import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_providers.dart';
import '../../widgets/post_card.dart';
import '../../widgets/comment_thread.dart';
import '../auth/auth_page.dart';
import '../report/report_page.dart';
import '../compose/compose_page.dart';

/// S-03。本文と認証導線のUI。コメント・共感のAPIは未接続。
class PostDetailPage extends ConsumerStatefulWidget {
  const PostDetailPage({
    super.key,
    required this.post,
    this.focusComments = false,
    this.autoOpenMenu = false,
  });
  final Post post;
  final bool focusComments;
  final bool autoOpenMenu;
  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  final _commentsKey = GlobalKey();
  Post get post => widget.post;
  ResponseMode? _previewMode;
  bool _commentsClosed = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusComments) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openComments());
    }
    if (widget.autoOpenMenu) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _menu(post));
    }
  }

  void _openComments() {
    final target = _commentsKey.currentContext;
    if (mounted && target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 250),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(isLoggedInProvider);
    ref.listen<bool>(isLoggedInProvider, (_, next) {
      if (!next) {
        setState(() {
          _previewMode = null;
          _commentsClosed = false;
        });
      }
    });
    // 一覧側で保存を切り替えた後も、詳細を開いた時点の状態を反映する。
    final items = ref.watch(feedPostsProvider).valueOrNull;
    final current =
        (items?.where((item) => item.id == post.id).firstOrNull ?? post)
            .copyWith(responseMode: _previewMode);
    return Scaffold(
      appBar: AppBar(
        title: const Text('投稿の詳細'),
        actions: [
          IconButton(
            tooltip: '投稿メニュー',
            onPressed: () => _menu(current),
            icon: const Icon(Icons.more_horiz),
          ),
          IconButton(
            tooltip: '投稿を通報',
            icon: const Icon(Icons.flag_outlined),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => ReportPage(
                  targetId: post.id,
                  targetType: ReportTargetType.post,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'サンプル投稿です。コメント・共感は準備中です。',
                    style: TextStyle(fontSize: 11, height: 1.6),
                  ),
                  const SizedBox(height: 12),
                  PostCard(
                    post: current,
                    showOpenButton: false,
                    showPresetReactions: true,
                    showMenuButton: false,
                    onOpenComments: _openComments,
                    onToggleSaved: () async {
                      try {
                        await ref
                            .read(postRepositoryProvider)
                            .toggleSaved(post.id);
                        if (!context.mounted) return;
                        ref.invalidate(feedPostsProvider);
                        ref.invalidate(searchResultsProvider);
                        ref.invalidate(myPostsProvider);
                        ref.invalidate(savedPostsProvider);
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('保存状態を変更できませんでした')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Container(
                    key: _commentsKey,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          loggedIn
                              ? (current.responseMode == ResponseMode.listening
                                    ? 'ただ聞いてほしい気持ちです'
                                    : 'コメント')
                              : '続きは、ログインしてから',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          loggedIn
                              ? (current.responseMode == ResponseMode.listening
                                    ? 'この投稿にはコメントを送れません。定型文で気持ちを届ける機能は準備中です。'
                                    : 'あなたの経験を、やさしく。')
                              : 'コメント欄の閲覧や気持ちを届けるには、登録・ログインが必要です。',
                          style: const TextStyle(fontSize: 14, height: 1.7),
                        ),
                        if (!loggedIn) ...[
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: () =>
                                _openAuth(context, AuthMode.register),
                            child: const Text('会員登録'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () => _openAuth(context, AuthMode.login),
                            child: const Text('ログイン'),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '戻ると、この投稿を続けて読めます。',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (loggedIn &&
                            current.responseMode == ResponseMode.advice) ...[
                          const SizedBox(height: 12),
                          CommentThread(
                            postId: post.id,
                            accepting: !_commentsClosed,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _menu(Post current) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => Consumer(
        builder: (context, menuRef, _) {
          final loggedIn = menuRef.watch(isLoggedInProvider);
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'サンプル投稿の操作',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '保存はモック内の変更です。その他の実処理は準備中です。',
                    style: TextStyle(fontSize: 12, height: 1.6),
                  ),
                  for (final option in [
                    ('save', current.isSaved ? '保存を解除' : '保存する'),
                    ('hide', 'この投稿を非表示'),
                    ('block', '投稿者をブロック'),
                    ('report', '通報する'),
                    if (loggedIn && current.isMine) ...[
                      ('edit', '投稿を編集'),
                      ('delete', '投稿を削除'),
                      if (current.responseMode == ResponseMode.listening)
                        ('mode', '話を聞きたいに変更'),
                      if (current.responseMode == ResponseMode.advice)
                        (
                          'comments',
                          _commentsClosed ? 'コメント受付を再開' : 'コメント受付を終了',
                        ),
                    ],
                  ])
                    ListTile(
                      title: Text(
                        option.$2,
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () => Navigator.of(context).pop(option.$1),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('閉じる'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'report') {
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) =>
              ReportPage(targetId: post.id, targetType: ReportTargetType.post),
        ),
      );
      return;
    }
    if (!ref.read(isLoggedInProvider)) {
      _openAuth(context, AuthMode.login);
      return;
    }
    switch (action) {
      case 'save':
        try {
          await ref.read(postRepositoryProvider).toggleSaved(post.id);
          if (!mounted) return;
          ref.invalidate(feedPostsProvider);
          ref.invalidate(searchResultsProvider);
          ref.invalidate(myPostsProvider);
          ref.invalidate(savedPostsProvider);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('保存状態を変更できませんでした')));
          }
        }
      case 'hide':
        await _notice('非表示は準備中です', 'この投稿はまだ非表示になりません。非表示機能の接続を準備しています。');
      case 'block':
        await _notice('ブロックは準備中です', '投稿者はまだブロックされません。ブロック機能の接続を準備しています。');
      case 'edit':
        if (!current.isMine) return;
        Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('投稿を編集')),
              body: ComposePage(initialPost: current),
            ),
          ),
        );
      case 'delete':
        if (!current.isMine) return;
        await _notice(
          '投稿を削除する前に',
          '削除すると投稿とコメント・返信・共感が削除され、元に戻せません。\n\n削除機能は準備中です。現在は削除されません。',
        );
      case 'mode':
        if (!current.isMine) return;
        final accepted = await _previewConfirmation(
          '話を聞きたいに変更',
          'この画面のサンプルだけでコメント入力を開きます。変更は保存されません。',
        );
        if (mounted && accepted && ref.read(isLoggedInProvider)) {
          setState(() => _previewMode = ResponseMode.advice);
        }
      case 'comments':
        if (!current.isMine) return;
        final accepted = await _previewConfirmation(
          _commentsClosed ? 'コメント受付を再開' : 'コメント受付を終了',
          'この画面のサンプルだけで受付状態を変更します。既存コメントは表示したままです。変更は保存されません。',
        );
        if (mounted && accepted && ref.read(isLoggedInProvider)) {
          setState(() => _commentsClosed = !_commentsClosed);
        }
    }
  }

  Future<void> _notice(String title, String message) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('戻る'),
        ),
      ],
    ),
  );

  Future<bool> _previewConfirmation(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('プレビューで変更'),
            ),
          ],
        ),
      ) ??
      false;

  void _openAuth(BuildContext context, AuthMode mode) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => AuthPage(initialMode: mode)),
    );
  }
}
