import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kosodate_hitoiki/presentation/widgets/app_asset.dart';
import '../../core/constants/app_colors.dart';
import '../../data/api/api_exception.dart';
import '../../data/api/idempotency_key.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/post.dart' show EditResult;
import '../pages/compose/post_messages.dart';
import '../pages/report/report_page.dart';
import '../pages/support/support_resources_page.dart';
import '../providers/auth_provider.dart';
import '../providers/comment_providers.dart';
import '../providers/post_providers.dart';

/// S-03のコメント・返信。取得・作成はコメントAPIに接続している。
/// 送信前チェックはサーバー側で行われ、結果をここに表示する(API契約4節)。
class CommentThread extends ConsumerStatefulWidget {
  const CommentThread({super.key, required this.postId, this.accepting = true});
  final String postId;
  final bool accepting;
  @override
  ConsumerState<CommentThread> createState() => _CommentThreadState();
}

class _CommentThreadState extends ConsumerState<CommentThread> {
  final _draft = TextEditingController();
  final _inputKey = GlobalKey();
  String? _replyTo;
  String? _replyToId;

  bool _busy = false;
  bool _confirmed = false;
  bool _supportNotice = false;
  String? _confirmMessage;
  String? _rejectedMessage;
  String? _error;

  /// 1回の「送信」操作につき、キーを1つだけ作り、確認後の再送や通信失敗の再送でも
  /// 使い回す(409・422・503は保存もキーの消費もされない。二重投稿を防ぐ)。
  /// 入力や返信先を変えたら、新しい操作として、キーを作り直す。
  String? _key;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  /// 入力や返信先が変わった。前の送信の確認・結果・キーは、もう関係ない。
  void _startNewOperation() {
    _key = null;
    _confirmed = false;
    _confirmMessage = null;
    _rejectedMessage = null;
    _error = null;
    _supportNotice = false;
  }

  void _reply(Comment comment) {
    setState(() {
      _replyTo = comment.authorName;
      _replyToId = comment.id;
      _startNewOperation();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _inputKey.currentContext;
      if (mounted && target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 250),
        );
      }
    });
  }

  bool get _canSend =>
      !_busy &&
      _draft.text.trim().isNotEmpty &&
      _draft.text.characters.length <= 500;

  Future<void> _send() async {
    if (!ref.read(isLoggedInProvider) || !_canSend) return;
    FocusScope.of(context).unfocus();
    _key ??= newIdempotencyKey();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final created = await ref
          .read(commentRepositoryProvider)
          .createComment(
            postId: widget.postId,
            body: _draft.text,
            idempotencyKey: _key!,
            parentId: _replyToId,
            confirmed: _confirmed,
          );
      if (!mounted) return;
      // コメント一覧と、投稿のコメント件数を、取り直す。
      ref
        ..invalidate(commentsProvider(widget.postId))
        ..invalidate(postDetailProvider)
        ..invalidate(feedPostsProvider)
        ..invalidate(searchResultsProvider);
      setState(() {
        _draft.clear();
        _replyTo = null;
        _replyToId = null;
        _startNewOperation();
        _supportNotice = created.supportNotice;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        if (error.isConfirmRequired && !_confirmed) {
          _confirmMessage = confirmMessage(error);
        } else if (error.isRejected) {
          _confirmMessage = null;
          _rejectedMessage = rejectionMessage(error);
        } else {
          _error = postFailureMessage(error);
        }
      });
    } catch (error) {
      if (mounted) setState(() => _error = postFailureMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 確認表示のあと、「そのまま送る」。同じキーで、確認済みとして再送する。
  void _confirmAndSend() {
    _confirmed = true;
    _send();
  }

  /// 自分のコメントの編集。受付を終了した投稿でも、編集できる。
  Future<void> _editComment(Comment comment) async {
    final result = await showDialog<EditResult>(
      context: context,
      builder: (context) => _CommentEditDialog(comment: comment),
    );
    if (result == null || !mounted) return;
    ref.invalidate(commentsProvider(widget.postId));
    if (result.supportNotice) setState(() => _supportNotice = true);
  }

  /// 自分のコメントの削除。本文は消えて、返信は残る。取り消せないので、確認する。
  Future<void> _deleteComment(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('コメントを削除しますか？'),
        content: const Text('削除すると、本文が消えて「削除済み」になります。返信は残ります。元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('やめる'),
          ),
          FilledButton(
            key: const ValueKey('comment-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(commentRepositoryProvider).deleteComment(comment.id);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(postFailureMessage(error))),
      );
      return;
    }
    ref
      ..invalidate(commentsProvider(widget.postId))
      ..invalidate(postDetailProvider)
      ..invalidate(feedPostsProvider)
      ..invalidate(searchResultsProvider);
  }

  Widget _comment(Comment comment, {bool reply = false}) {
    final body = comment.isDeleted ? '削除済み' : (comment.body ?? '');
    return Container(
      margin: EdgeInsets.only(left: reply ? 16 : 0, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: reply
            ? const Border(left: BorderSide(color: AppColors.divider, width: 2))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipOval(
                child: AppAsset(
                  comment.authorAvatarAsset,
                  width: 32,
                  height: 32,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  comment.authorName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!comment.isDeleted && !comment.isMine)
                IconButton(
                  tooltip: '${comment.authorName}さんのコメントを通報',
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => ReportPage(
                        targetId: comment.id,
                        targetType: ReportTargetType.comment,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.flag_outlined, size: 20),
                ),
            ],
          ),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: comment.isDeleted ? AppColors.textSecondary : null,
            ),
          ),
          if (comment.isEdited && !comment.isDeleted)
            const Text('編集済み', style: TextStyle(fontSize: 11, height: 1.6)),
          if (comment.isMine && !comment.isDeleted)
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                children: [
                  TextButton.icon(
                    key: ValueKey('comment-edit-${comment.id}'),
                    onPressed: () => _editComment(comment),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('編集'),
                  ),
                  TextButton.icon(
                    key: ValueKey('comment-delete-${comment.id}'),
                    onPressed: () => _deleteComment(comment),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('削除'),
                  ),
                ],
              ),
            ),
          if (!reply && !comment.isDeleted && widget.accepting)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _reply(comment),
                icon: const Icon(Icons.reply, size: 18),
                label: Text('${comment.authorName}さんに返信'),
              ),
            ),
        ],
      ),
    );
  }

  /// 親コメントの下に、返信を並べる。親が見えない返信(ブロックなどで除外)は、
  /// 返信として、最後に並べる。
  List<Widget> _threads(List<Comment> comments) {
    final topLevel = comments.where((c) => !c.isReply).toList();
    final topIds = {for (final c in topLevel) c.id};
    final widgets = <Widget>[];
    for (final parent in topLevel) {
      widgets.add(_comment(parent));
      for (final reply in comments.where((c) => c.parentId == parent.id)) {
        widgets.add(_comment(reply, reply: true));
      }
    }
    for (final orphan in comments.where(
      (c) => c.isReply && !topIds.contains(c.parentId),
    )) {
      widgets.add(_comment(orphan, reply: true));
    }
    return widgets;
  }

  Widget _list() {
    final comments = ref.watch(commentsProvider(widget.postId));
    return comments.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Column(
        children: [
          const Text('コメントを読み込めませんでした。', style: TextStyle(fontSize: 14)),
          TextButton(
            onPressed: () => ref.invalidate(commentsProvider(widget.postId)),
            child: const Text('再読み込み'),
          ),
        ],
      ),
      data: (items) => items.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                ref.watch(commentsAreSampleProvider)
                    ? 'まだサンプルコメントはありません。'
                    : 'まだコメントはありません。',
                style: const TextStyle(fontSize: 14),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _threads(items),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(isLoggedInProvider, (_, next) {
      if (!next) {
        _draft.clear();
        setState(() {
          _replyTo = null;
          _replyToId = null;
          _startNewOperation();
        });
      }
    });
    if (!ref.watch(isLoggedInProvider)) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ref.watch(commentsAreSampleProvider)) ...[
          const Text(
            'サンプルコメントです。入力はこの画面を閉じると消えます。',
            style: TextStyle(fontSize: 11, height: 1.6),
          ),
          const SizedBox(height: 12),
        ],
        _list(),
        if (!widget.accepting)
          const Text('コメントの受付は終了しています。', style: TextStyle(fontSize: 14)),
        if (widget.accepting)
          Container(
            key: _inputKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_replyTo != null)
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '$_replyToさんへの返信',
                        style: const TextStyle(fontSize: 13),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                _replyTo = null;
                                _replyToId = null;
                                _startNewOperation();
                              }),
                        child: const Text('返信をやめる'),
                      ),
                    ],
                  ),
                TextField(
                  controller: _draft,
                  enabled: !_busy,
                  minLines: 2,
                  maxLines: 6,
                  maxLength: 500,
                  onChanged: (_) => setState(_startNewOperation),
                  decoration: InputDecoration(
                    labelText: _replyTo == null ? 'コメントを書く' : '返信を書く',
                    hintText: 'あなたの経験を、やさしく',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '名前や個人情報は書かないでください。',
                  style: TextStyle(fontSize: 12, height: 1.6),
                ),
                if (_confirmMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _confirmMessage!,
                    key: const ValueKey('comment-confirm'),
                    style: const TextStyle(fontSize: 13, height: 1.7),
                  ),
                ],
                if (_rejectedMessage != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'この内容では送信できません。',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    _rejectedMessage!,
                    key: const ValueKey('comment-rejected'),
                    style: const TextStyle(fontSize: 13, height: 1.7),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    key: const ValueKey('comment-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ],
                if (_supportNotice) ...[
                  const SizedBox(height: 8),
                  Container(
                    key: const ValueKey('comment-support-notice'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'つらい気持ちを、ひとりで抱えなくて大丈夫です。',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'この案内は、あなたにだけ表示しています。',
                          style: TextStyle(fontSize: 12, height: 1.6),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => const SupportResourcesPage(),
                            ),
                          ),
                          child: const Text('困ったときの相談先'),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                if (_confirmMessage != null)
                  FilledButton(
                    key: const ValueKey('comment-send-anyway'),
                    onPressed: _busy ? null : _confirmAndSend,
                    child: Text(_busy ? '送信しています…' : 'そのまま送る'),
                  )
                else if (_rejectedMessage == null)
                  FilledButton(
                    key: const ValueKey('comment-send'),
                    onPressed: _canSend ? _send : null,
                    child: Text(_busy ? '送信しています…' : '送信'),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// コメントの編集ダイアログ。送信前チェックは、作成と同じ(確認→「そのまま保存」、
/// 送信不可→書き直し)。保存できたら[EditResult]を返す。
class _CommentEditDialog extends ConsumerStatefulWidget {
  const _CommentEditDialog({required this.comment});
  final Comment comment;

  @override
  ConsumerState<_CommentEditDialog> createState() => _CommentEditDialogState();
}

class _CommentEditDialogState extends ConsumerState<_CommentEditDialog> {
  late final _controller = TextEditingController(text: widget.comment.body);
  bool _busy = false;
  bool _confirmed = false;
  String? _confirmMessage;
  String? _rejectedMessage;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSave =>
      !_busy &&
      _controller.text.trim().isNotEmpty &&
      _controller.text.characters.length <= 500;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(commentRepositoryProvider)
          .editComment(
            commentId: widget.comment.id,
            body: _controller.text,
            confirmed: _confirmed,
          );
      if (mounted) Navigator.of(context).pop(result);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        if (error.isConfirmRequired && !_confirmed) {
          _confirmMessage = confirmMessage(error);
        } else if (error.isRejected) {
          _confirmMessage = null;
          _rejectedMessage = rejectionMessage(error);
        } else {
          _error = postFailureMessage(error);
        }
      });
    } catch (error) {
      if (mounted) setState(() => _error = postFailureMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('コメントを編集'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('comment-edit-field'),
          controller: _controller,
          enabled: !_busy,
          minLines: 2,
          maxLines: 6,
          maxLength: 500,
          onChanged: (_) => setState(() {
            // 直したら、前の確認・結果は関係ない。
            _confirmed = false;
            _confirmMessage = null;
            _rejectedMessage = null;
            _error = null;
          }),
        ),
        if (_confirmMessage != null)
          Text(
            _confirmMessage!,
            key: const ValueKey('comment-edit-confirm'),
            style: const TextStyle(fontSize: 13, height: 1.7),
          ),
        if (_rejectedMessage != null) ...[
          const Text(
            'この内容では保存できません。',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          Text(
            _rejectedMessage!,
            key: const ValueKey('comment-edit-rejected'),
            style: const TextStyle(fontSize: 13, height: 1.7),
          ),
        ],
        if (_error != null)
          Text(
            _error!,
            key: const ValueKey('comment-edit-error'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 13,
              height: 1.6,
            ),
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.of(context).pop(),
        child: const Text('キャンセル'),
      ),
      if (_rejectedMessage == null)
        FilledButton(
          key: const ValueKey('comment-edit-save'),
          onPressed: _canSave
              ? () {
                  if (_confirmMessage != null) _confirmed = true;
                  _save();
                }
              : null,
          child: Text(
            _busy ? '保存しています…' : (_confirmMessage != null ? 'そのまま保存' : '保存'),
          ),
        ),
    ],
  );
}
