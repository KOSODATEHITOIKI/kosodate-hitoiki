import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kosodate_hitoiki/presentation/widgets/app_asset.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../providers/auth_provider.dart';
import '../pages/report/report_page.dart';

/// S-03のサンプルコメント。取得・送信・保存はIssue #23で接続する。
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
  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _reply(String name) {
    setState(() => _replyTo = name);
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

  void _submit() {
    if (!ref.read(isLoggedInProvider) ||
        _draft.text.trim().isEmpty ||
        _draft.text.characters.length > 500) {
      return;
    }
    FocusScope.of(context).unfocus();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('コメント送信は準備中です'),
        content: const Text('入力内容は送信・保存されません。入力に戻って続けて編集できます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('入力に戻る'),
          ),
        ],
      ),
    );
  }

  Widget _comment(
    String id,
    String name,
    String avatar,
    String body, {
    bool reply = false,
  }) => Container(
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
            AppAsset(avatar, width: 32, height: 32, excludeFromSemantics: true),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: '$nameさんのコメントを通報',
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => ReportPage(
                    targetId: id,
                    targetType: ReportTargetType.comment,
                  ),
                ),
              ),
              icon: const Icon(Icons.flag_outlined, size: 20),
            ),
          ],
        ),
        Text(body, style: const TextStyle(fontSize: 14, height: 1.7)),
        if (!reply && widget.accepting)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _reply(name),
              icon: const Icon(Icons.reply, size: 18),
              label: Text('$nameさんに返信'),
            ),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(isLoggedInProvider, (_, next) {
      if (!next) {
        _draft.clear();
        setState(() => _replyTo = null);
      }
    });
    if (!ref.watch(isLoggedInProvider)) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'サンプルコメントです。入力はこの画面を閉じると消えます。',
          style: TextStyle(fontSize: 11, height: 1.6),
        ),
        const SizedBox(height: 12),
        if (widget.postId == 'p2') ...[
          _comment(
            'sample-c1',
            'こもれび',
            AppAvatars.defaultSprout,
            'うちの場合は、小さなおにぎりにしたら食べやすかったです。',
          ),
          _comment(
            'sample-r1',
            'はな',
            AppAvatars.defaultTulip,
            'ありがとう、試してみます。',
            reply: true,
          ),
          _comment(
            'sample-c2',
            'みみ',
            AppAvatars.defaultLittleBird,
            'うちも食べない日があります。無理せず、少しずつで大丈夫。',
          ),
        ] else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('まだサンプルコメントはありません。', style: TextStyle(fontSize: 14)),
          ),
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
                        onPressed: () => setState(() => _replyTo = null),
                        child: const Text('返信をやめる'),
                      ),
                    ],
                  ),
                TextField(
                  controller: _draft,
                  minLines: 2,
                  maxLines: 6,
                  maxLength: 500,
                  onChanged: (_) => setState(() {}),
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
                const SizedBox(height: 8),
                FilledButton(
                  onPressed:
                      _draft.text.trim().isEmpty ||
                          _draft.text.characters.length > 500
                      ? null
                      : _submit,
                  child: const Text('送信'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
