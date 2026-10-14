import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/comfort_page.dart';
import '../auth/auth_page.dart';

enum ReportTargetType { post, comment, user }

/// S-13のUI。実送信・記録はIssue #24で接続する。
class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({
    super.key,
    required this.targetId,
    required this.targetType,
  });
  final String targetId;
  final ReportTargetType targetType;
  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  static const _reasons = [
    '誹謗中傷・攻撃的',
    '名前や個人情報',
    '勧誘・宣伝・スパム',
    '他人の文章や画像の転載',
    '危険を感じる内容',
    'その他',
  ];
  final _note = TextEditingController();
  String? _reason;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!ref.read(isLoggedInProvider) || _reason == null) return;
    FocusScope.of(context).unfocus();
    showDialog<void>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, dialogRef, _) {
          if (!dialogRef.watch(isLoggedInProvider)) {
            return AlertDialog(
              title: const Text('ログインが必要です'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('閉じる'),
                ),
              ],
            );
          }
          return AlertDialog(
            title: const Text('通報内容の確認'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('理由：$_reason'),
                  if (_reason == 'その他' && _note.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(_note.text.trim()),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    '送信機能は準備中です。現在は送信・記録されません。\n\n機能公開後は、送信した内容が運営の確認対象として記録されます。対応には数日かかる場合があります。',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('入力に戻る'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(isLoggedInProvider);
    ref.listen<bool>(isLoggedInProvider, (previous, next) {
      if (!next) {
        _note.clear();
        setState(() => _reason = null);
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text('通報する')),
      body: !loggedIn
          ? ComfortPage(
              title: 'ログインして、ひと息',
              message: '通報するには、\n登録・ログインが必要です。',
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
            )
          : ComfortPage(
              title: '通報する',
              message: '通報したことは、相手に通知されません。',
              children: [
                Text(
                  switch (widget.targetType) {
                    ReportTargetType.post => 'この投稿について',
                    ReportTargetType.comment => 'このコメントについて',
                    ReportTargetType.user => 'この利用者について',
                  },
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '通報の理由を選んでください',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                RadioGroup<String>(
                  groupValue: _reason,
                  onChanged: (value) => setState(() => _reason = value),
                  child: Column(
                    children: [
                      for (final reason in _reasons)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: RadioListTile<String>(
                            value: reason,
                            title: Text(
                              reason,
                              style: const TextStyle(fontSize: 14),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            tileColor: Theme.of(context).colorScheme.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_reason == 'その他') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _note,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: '補足（任意）',
                      hintText: '具体的な内容があればご記入ください。',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  '対応に数日かかる場合があります。\n送信機能は準備中です。入力内容は保存されません。',
                  style: TextStyle(fontSize: 12, height: 1.7),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _reason == null ? null : _confirm,
                  child: const Text('通報内容を確認'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
              ],
            ),
    );
  }

  void _auth(AuthMode mode) => Navigator.of(
    context,
  ).push<void>(MaterialPageRoute(builder: (_) => AuthPage(initialMode: mode)));
}
