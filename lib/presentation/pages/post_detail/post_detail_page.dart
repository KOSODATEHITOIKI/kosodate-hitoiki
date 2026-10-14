import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_providers.dart';
import '../../widgets/post_card.dart';
import '../auth/auth_page.dart';
import '../report/report_page.dart';

/// S-03。本文と認証導線のUI。コメント・共感のAPIは未接続。
class PostDetailPage extends ConsumerStatefulWidget {
  const PostDetailPage({
    super.key,
    required this.post,
    this.focusComments = false,
  });
  final Post post;
  final bool focusComments;
  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  final _commentsKey = GlobalKey();
  Post get post => widget.post;

  @override
  void initState() {
    super.initState();
    if (widget.focusComments) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openComments());
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
    // 一覧側で保存を切り替えた後も、詳細を開いた時点の状態を反映する。
    final items = ref.watch(feedPostsProvider).valueOrNull;
    final current =
        items?.where((item) => item.id == post.id).firstOrNull ?? post;
    return Scaffold(
      appBar: AppBar(
        title: const Text('投稿の詳細'),
        actions: [
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
                              ? (post.responseMode == ResponseMode.listening
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
                              ? (post.responseMode == ResponseMode.listening
                                    ? 'この投稿にはコメントを送れません。定型文で気持ちを届ける機能は準備中です。'
                                    : 'コメントと返信を読む・送る機能は準備中です。')
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

  void _openAuth(BuildContext context, AuthMode mode) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => AuthPage(initialMode: mode)),
    );
  }
}
