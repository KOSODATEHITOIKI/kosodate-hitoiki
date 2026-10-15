import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/moderation_result.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/comfort_page.dart';
import '../support/support_resources_page.dart';

enum _Preview { normal, confirm, block, support }

/// 送信前チェック表示のモック。入力文の判定・送信・保存は行わない。
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
  final String postType;
  final String responseMode;
  final String? topic;
  final bool editing;
  @override
  ConsumerState<ComposeReviewPage> createState() => _ComposeReviewPageState();
}

class _ComposeReviewPageState extends ConsumerState<ComposeReviewPage> {
  _Preview _preview = _Preview.confirm;

  ModerationResult get _result => switch (_preview) {
    _Preview.normal => const ModerationResult(verdict: ModerationVerdict.allow),
    _Preview.confirm => const ModerationResult(
      verdict: ModerationVerdict.confirm,
    ),
    _Preview.block => const ModerationResult(
      verdict: ModerationVerdict.block,
      reason: '名前や個人情報、誰かを傷つける表現がないか確認して書き直してください。',
    ),
    _Preview.support => const ModerationResult(
      verdict: ModerationVerdict.allow,
      supportMessageRequired: true,
    ),
  };

  void _submit() {
    if (_result.verdict == ModerationVerdict.block) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('投稿機能は準備中です'),
        content: const Text('入力内容は送信・保存されません。投稿・編集にはログインと送信前チェックの接続が必要です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('確認に戻る'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ログアウト・利用者切り替え時は、表示中の本文が前の利用者のものに
    // なるため、確認画面ごと閉じて最新状態の書く画面へ戻す。
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous != next && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('投稿の確認')),
      body: ComfortPage(
        title: result.verdict == ModerationVerdict.block
            ? '内容を見直してみましょう'
            : '送信する前に、ひと確認。',
        message: '名前や個人情報、\n誰かを傷つける表現はありませんか？',
        children: [
          const Text(
            '表示確認用のサンプルです。入力した文章の判定は行っていません。',
            style: TextStyle(fontSize: 12, height: 1.7),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '投稿の内容',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text(widget.postType)),
                      Chip(label: Text(widget.responseMode)),
                      if (widget.topic != null)
                        Chip(label: Text(widget.topic!)),
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
          if (result.verdict == ModerationVerdict.confirm)
            const Text(
              '誰かを傷つける表現になっていませんか？\n家族や知人は「上の子」「夫」などに言い換えられます。',
              style: TextStyle(fontSize: 14, height: 1.7),
            ),
          if (result.verdict == ModerationVerdict.block) ...[
            const Text(
              'この内容では送信できません。（表示サンプル）',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              result.reason!,
              style: const TextStyle(fontSize: 14, height: 1.7),
            ),
          ],
          if (result.supportMessageRequired) ...[
            const Text(
              'つらい気持ちを、ひとりで抱えなくて大丈夫です。',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              '必要なときは相談先を頼ってください。この案内だけで投稿を止めることはありません。',
              style: TextStyle(fontSize: 14, height: 1.7),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const SupportResourcesPage()),
              ),
              child: const Text('困ったときの相談先'),
            ),
          ],
          const SizedBox(height: 16),
          if (result.verdict != ModerationVerdict.block)
            FilledButton(
              onPressed: _submit,
              child: Text(widget.editing ? 'この内容で変更する' : 'この内容で投稿する'),
            ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('書き直す'),
          ),
          const Text(
            '入力した文章は残っています。',
            style: TextStyle(fontSize: 12, height: 1.7),
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            key: const PageStorageKey('moderation-display-samples'),
            maintainState: true,
            title: const Text('チェック結果の表示サンプル', style: TextStyle(fontSize: 12)),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in const [
                    (_Preview.normal, '通常'),
                    (_Preview.confirm, '確認表示'),
                    (_Preview.block, '送信不可'),
                    (_Preview.support, '相談先案内'),
                  ])
                    ChoiceChip(
                      label: Text(item.$2),
                      selected: _preview == item.$1,
                      onSelected: (_) => setState(() => _preview = item.$1),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
