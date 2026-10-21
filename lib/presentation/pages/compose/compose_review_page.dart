import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/api/api_exception.dart';
import '../../../data/api/idempotency_key.dart';
import '../../../domain/models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_providers.dart';
import '../../widgets/comfort_page.dart';
import '../support/support_resources_page.dart';
import 'post_messages.dart';

/// 送信前チェックの段階。
/// - review: 送る前の確認(まだ送っていない)
/// - confirm: サーバーが「確認が必要」と返した(確認後に再送する)
/// - rejected: サーバーが「送信不可」と返した(書き直す)
/// - success: 投稿できた
enum _Stage { review, confirm, rejected, success }

/// S-04の確認画面。送信前チェックは、投稿作成API(サーバー側)が行い、その結果を表示する
/// (kosodate-hitoiki-backend docs/API契約.md 3節)。投稿できたら`true`を返して閉じる。
class ComposeReviewPage extends ConsumerStatefulWidget {
  const ComposeReviewPage({
    super.key,
    required this.body,
    required this.postType,
    required this.responseMode,
    this.topic,
    this.editing = false,
  });
  final String body;
  final PostType postType;
  final ResponseMode responseMode;
  final String? topic;
  final bool editing;
  @override
  ConsumerState<ComposeReviewPage> createState() => _ComposeReviewPageState();
}

class _ComposeReviewPageState extends ConsumerState<ComposeReviewPage> {
  _Stage _stage = _Stage.review;
  bool _busy = false;
  bool _confirmed = false;
  bool _supportNotice = false;
  String? _message;
  String? _error;

  /// 同じ送信の再送(通信の失敗など)では、同じキーを使う。確認を経て再送するときは、
  /// 新しい送信として、新しいキーにする。
  String _key = newIdempotencyKey();

  Future<void> _submit() async {
    if (_busy) return;
    if (widget.editing) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('投稿の編集は準備中です'),
          content: const Text('編集の内容は送信されません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('確認に戻る'),
            ),
          ],
        ),
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final created = await ref
          .read(postRepositoryProvider)
          .createPost(
            type: widget.postType,
            responseMode: widget.responseMode,
            body: widget.body,
            idempotencyKey: _key,
            confirmed: _confirmed,
          );
      if (!mounted) return;
      // 一覧・検索・マイページを、新しい投稿を含めて取り直す。
      ref
        ..invalidate(feedPostsProvider)
        ..invalidate(searchResultsProvider)
        ..invalidate(myPostsProvider);
      setState(() {
        _stage = _Stage.success;
        _supportNotice = created.supportNotice;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.isConfirmRequired && !_confirmed) {
        setState(() {
          _stage = _Stage.confirm;
          _message = confirmMessage(error);
        });
      } else if (error.isRejected) {
        setState(() {
          _stage = _Stage.rejected;
          _message = rejectionMessage(error);
        });
      } else {
        setState(() => _error = postFailureMessage(error));
      }
    } catch (error) {
      if (mounted) setState(() => _error = postFailureMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 確認表示のあと、「そのまま投稿する」。確認済みとして、新しい送信にする。
  void _confirmAndSubmit() {
    _confirmed = true;
    _key = newIdempotencyKey();
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    // 利用者切り替え時、上に乗ったダイアログ/相談先画面ごとこの画面を閉じる(pop1回だと取り残される)。
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous == next) return;
      final navigator = Navigator.of(context);
      final myRoute = ModalRoute.of(context);
      if (myRoute != null) {
        navigator.popUntil((route) => route == myRoute);
      }
      if (navigator.canPop()) {
        navigator.pop();
      }
    });
    return PopScope<bool>(
      // 投稿できたあとは、戻る操作でも「投稿できた」を返して閉じる。
      canPop: _stage != _Stage.success,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_stage == _Stage.success ? '投稿しました' : '投稿の確認'),
        ),
        body: _stage == _Stage.success ? _success() : _content(),
      ),
    );
  }

  Widget _success() => ComfortPage(
    title: '投稿しました。',
    message: 'ここに書いてくれて、ありがとう。\nあなたのペースで大丈夫です。',
    children: [
      if (_supportNotice) ...[
        const Text(
          'つらい気持ちを、ひとりで抱えなくて大丈夫です。',
          key: ValueKey('support-notice'),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          '必要なときは相談先を頼ってください。この案内は、あなたにだけ表示しています。',
          style: TextStyle(fontSize: 14, height: 1.7),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const SupportResourcesPage()),
          ),
          child: const Text('困ったときの相談先'),
        ),
        const SizedBox(height: 8),
      ],
      FilledButton(
        key: const ValueKey('compose-done'),
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('ホームへ'),
      ),
    ],
  );

  Widget _content() => ComfortPage(
    title: _stage == _Stage.rejected ? '内容を見直してみましょう' : '送信する前に、ひと確認。',
    message: '名前や個人情報、\n誰かを傷つける表現はありませんか？',
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '投稿の内容',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(widget.postType.label)),
                  Chip(label: Text(widget.responseMode.label)),
                  if (widget.topic != null) Chip(label: Text(widget.topic!)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.body,
                style: const TextStyle(fontSize: 14, height: 1.7),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      if (_stage == _Stage.confirm)
        Text(
          _message!,
          key: const ValueKey('compose-confirm'),
          style: const TextStyle(fontSize: 14, height: 1.7),
        ),
      if (_stage == _Stage.rejected) ...[
        const Text(
          'この内容では送信できません。',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          _message!,
          key: const ValueKey('compose-rejected'),
          style: const TextStyle(fontSize: 14, height: 1.7),
        ),
      ],
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            _error!,
            key: const ValueKey('compose-error'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ),
      const SizedBox(height: 16),
      if (_stage != _Stage.rejected)
        FilledButton(
          key: const ValueKey('compose-send'),
          onPressed: _busy
              ? null
              : (_stage == _Stage.confirm ? _confirmAndSubmit : _submit),
          child: Text(
            _busy
                ? '送信しています…'
                : (_stage == _Stage.confirm
                      ? 'そのまま投稿する'
                      : (widget.editing ? 'この内容で変更する' : 'この内容で投稿する')),
          ),
        ),
      OutlinedButton(
        key: const ValueKey('compose-rewrite'),
        onPressed: _busy ? null : () => Navigator.of(context).pop(),
        child: const Text('書き直す'),
      ),
      const SizedBox(height: 4),
      const Text(
        '入力した文章は残っています。',
        style: TextStyle(
          fontSize: 12,
          height: 1.7,
          color: AppColors.textPrimary,
        ),
      ),
    ],
  );
}
