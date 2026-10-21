import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/models/post.dart';
import '../../../domain/repositories/post_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_providers.dart';
import '../../widgets/post_card.dart';
import '../../widgets/comment_thread.dart';
import '../auth/auth_page.dart';
import '../compose/post_messages.dart';
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

  /// 受付状態の、画面内での変更(サンプルのプレビュー、または変更できた直後)。
  /// nullなら、投稿が持っている状態に従う。
  bool? _closedOverride;
  bool _changingMode = false;

  /// 編集できたあとの本文。一覧に載っていない古い投稿でも、詳細にすぐ反映する。
  String? _editedBody;

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
          _closedOverride = null;
        });
      }
    });
    // 一覧側で保存を切り替えた後も、詳細を開いた時点の状態を反映する。
    final items = ref.watch(feedPostsProvider).valueOrNull;
    final current =
        (items?.where((item) => item.id == post.id).firstOrNull ?? post)
            .copyWith(responseMode: _previewMode, body: _editedBody);
    final commentsClosed = _closedOverride ?? !current.commentsOpen;
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
                  Text(
                    ref.watch(postsAreSampleProvider)
                        ? 'サンプル投稿です。共感は準備中です。'
                        : '共感は準備中です。',
                    style: const TextStyle(fontSize: 11, height: 1.6),
                  ),
                  const SizedBox(height: 12),
                  PostCard(
                    post: current,
                    showOpenButton: false,
                    showPresetReactions: true,
                    showMenuButton: false,
                    onOpenComments: _openComments,
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
                            accepting: !commentsClosed,
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
                  Text(
                    menuRef.watch(postsAreSampleProvider)
                        ? 'サンプル投稿の操作'
                        : '投稿の操作',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (menuRef.watch(postsAreSampleProvider)) ...[
                    const SizedBox(height: 8),
                    const Text(
                      '保存はモック内の変更です。その他の実処理は準備中です。',
                      style: TextStyle(fontSize: 12, height: 1.6),
                    ),
                  ],
                  for (final option in [
                    ('save', current.isSaved ? '保存を解除' : '保存する'),
                    // 自分の投稿は、非表示にもブロックにもしない。
                    if (!current.isMine) ...[
                      ('hide', 'この投稿を非表示'),
                      ('block', '投稿者をブロック'),
                    ],
                    ('report', '通報する'),
                    if (loggedIn && current.isMine) ...[
                      ('edit', '投稿を編集'),
                      ('delete', '投稿を削除'),
                      if (current.responseMode == ResponseMode.listening)
                        ('mode', '話を聞きたいに変更'),
                      if (current.responseMode == ResponseMode.advice)
                        (
                          'comments',
                          _closedOverride ?? !current.commentsOpen
                              ? 'コメント受付を再開'
                              : 'コメント受付を終了',
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
        await togglePostSaved(context, ref, post);
      case 'hide':
        await _hideOrBlock(
          title: 'この投稿を非表示にしますか？',
          message: 'この投稿は、あなたの画面にだけ表示されなくなります。相手には知らせません。',
          action: 'この投稿を非表示',
          done: '投稿を非表示にしました',
          run: (repository) => repository.hidePost(current.id),
        );
      case 'block':
        if (current.authorId.isEmpty) return;
        await _hideOrBlock(
          title: '投稿者をブロックしますか？',
          message:
              '相手の投稿・コメントが、あなたに表示されなくなります。相手は、あなたへのコメント・返信・共感ができなくなります。相手には知らせません。',
          action: 'ブロックする',
          done: '投稿者をブロックしました',
          run: (repository) => repository.blockUser(current.authorId),
        );
      case 'edit':
        if (!current.isMine) return;
        // 編集できたら、新しい本文が返る。
        final newBody = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('投稿を編集')),
              body: ComposePage(initialPost: current),
            ),
          ),
        );
        if (mounted && newBody != null) setState(() => _editedBody = newBody);
      case 'delete':
        if (!current.isMine) return;
        await _confirmDelete(current);
      case 'mode':
        if (!current.isMine) return;
        if (ref.read(postsAreSampleProvider)) {
          final accepted = await _previewConfirmation(
            '話を聞きたいに変更',
            'この画面のサンプルだけでコメント入力を開きます。変更は保存されません。',
          );
          if (mounted && accepted && ref.read(isLoggedInProvider)) {
            setState(() => _previewMode = ResponseMode.advice);
          }
          return;
        }
        await _changeMode(
          title: '話を聞きたいに変更しますか？',
          message: 'コメントを受け付けるようになります。あとから、受付を終了することもできます。',
          action: '変更する',
          done: '話を聞きたいに変更しました',
          mode: ResponseMode.advice,
          closedAfter: false,
        );
      case 'comments':
        if (!current.isMine) return;
        final closed = _closedOverride ?? !current.commentsOpen;
        if (ref.read(postsAreSampleProvider)) {
          final accepted = await _previewConfirmation(
            closed ? 'コメント受付を再開' : 'コメント受付を終了',
            'この画面のサンプルだけで受付状態を変更します。既存コメントは表示したままです。変更は保存されません。',
          );
          if (mounted && accepted && ref.read(isLoggedInProvider)) {
            setState(() => _closedOverride = !closed);
          }
          return;
        }
        await _changeMode(
          title: closed ? 'コメントの受付を再開しますか？' : 'コメントの受付を終了しますか？',
          message: closed
              ? '新しいコメントを、また受け付けます。'
              : '新しいコメントは受け付けなくなります。すでについたコメントは、表示したままです。',
          action: closed ? '再開する' : '終了する',
          done: closed ? 'コメントの受付を再開しました' : 'コメントの受付を終了しました',
          // 受付状態を変えられるのは「話を聞きたい」の投稿だけ。反応モードも添えて送る。
          mode: ResponseMode.advice,
          commentsOpen: closed,
          closedAfter: !closed,
        );
    }
  }

  /// 反応モード・コメント受付状態を変える。確認してから送り、変えられたら表示に反映して、
  /// 一覧を取り直す。失敗したときは、案内して、表示は変えない。
  Future<void> _changeMode({
    required String title,
    required String message,
    required String action,
    required String done,
    required ResponseMode mode,
    bool? commentsOpen,
    required bool closedAfter,
  }) async {
    if (_changingMode) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('やめる'),
          ),
          FilledButton(
            key: const ValueKey('post-action-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context);
    _changingMode = true;
    try {
      await ref
          .read(postRepositoryProvider)
          .updateReactionMode(
            postId: post.id,
            mode: mode,
            commentsOpen: commentsOpen,
          );
    } catch (error) {
      _changingMode = false;
      messenger.showSnackBar(
        SnackBar(content: Text(postFailureMessage(error))),
      );
      return;
    }
    _changingMode = false;
    container
      ..invalidate(feedPostsProvider)
      ..invalidate(searchResultsProvider)
      ..invalidate(myPostsProvider)
      ..invalidate(savedPostsProvider);
    messenger.showSnackBar(SnackBar(content: Text(done)));
    if (!mounted) return;
    setState(() {
      _previewMode = mode;
      _closedOverride = closedAfter;
    });
  }

  /// 投稿の非表示・投稿者のブロック。確認してから実行し、一覧を取り直して、詳細を閉じる。
  /// 失敗したときは、案内して、詳細は閉じない。
  Future<void> _hideOrBlock({
    required String title,
    required String message,
    required String action,
    required String done,
    required Future<void> Function(PostRepository repository) run,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('やめる'),
          ),
          FilledButton(
            key: const ValueKey('post-action-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await run(ref.read(postRepositoryProvider));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(postFailureMessage(error))),
      );
      return;
    }
    ref
      ..invalidate(feedPostsProvider)
      ..invalidate(searchResultsProvider)
      ..invalidate(myPostsProvider)
      ..invalidate(savedPostsProvider);
    messenger.showSnackBar(SnackBar(content: Text(done)));
    if (mounted) Navigator.of(context).pop();
  }

  /// 投稿の削除。取り消せないので、確認してから削除する。
  Future<void> _confirmDelete(Post current) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('投稿を削除しますか？'),
        content: const Text('削除すると、この投稿とコメント・返信・共感が消えます。元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('やめる'),
          ),
          FilledButton(
            key: const ValueKey('post-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(postRepositoryProvider).deletePost(current.id);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(postFailureMessage(error))),
      );
      return;
    }
    ref
      ..invalidate(feedPostsProvider)
      ..invalidate(searchResultsProvider)
      ..invalidate(myPostsProvider)
      ..invalidate(savedPostsProvider);
    messenger.showSnackBar(const SnackBar(content: Text('投稿を削除しました')));
    if (mounted) Navigator.of(context).pop();
  }

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
