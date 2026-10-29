import 'package:flutter/material.dart';
import '../../../core/widgets/centered_page_transitions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/report.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_providers.dart';
import '../../widgets/comfort_page.dart';
import '../auth/auth_page.dart';
import '../compose/post_messages.dart';
import '../support/support_resources_page.dart';

enum ReportTargetType { post, comment, user }

/// S-13。投稿・コメントの通報を、通報API(`POST /functions/v1/reports`)へ送る。
/// 通報したことは、通報された側にも、ほかの利用者にも知らせない。
/// 利用者の通報は、APIが未対応(投稿・コメントのみ)のため、送らずに案内する。
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
  final _note = TextEditingController();
  ReportReason? _reason;
  bool _busy = false;
  String? _error;

  /// 送れたあとの結果。nullの間は、入力の画面を出す。
  ReportResult? _result;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _supported => widget.targetType != ReportTargetType.user;

  Future<void> _confirm() async {
    if (!ref.read(isLoggedInProvider) || _reason == null || !_supported) {
      return;
    }
    FocusScope.of(context).unfocus();
    final reason = _reason!;
    final note = reason == ReportReason.other ? _note.text.trim() : '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('この内容で通報しますか？'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('理由：${reason.label}'),
              if (note.isNotEmpty) ...[const SizedBox(height: 12), Text(note)],
              const SizedBox(height: 16),
              const Text(
                '通報したことは、相手に通知されません。対応には数日かかる場合があります。',
                style: TextStyle(fontSize: 13, height: 1.7),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('やめる'),
          ),
          FilledButton(
            key: const ValueKey('report-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('通報する'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _submit(reason, note);
  }

  Future<void> _submit(ReportReason reason, String note) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(reportRepositoryProvider)
          .submitReport(
            targetType: widget.targetType == ReportTargetType.comment
                ? 'comment'
                : 'post',
            targetId: widget.targetId,
            reason: reason,
            detail: note,
          );
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) setState(() => _error = postFailureMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(isLoggedInProvider);
    ref.listen<bool>(isLoggedInProvider, (previous, next) {
      if (!next) {
        _note.clear();
        setState(() {
          _reason = null;
          _result = null;
          _error = null;
        });
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text('通報する')),
      body: !loggedIn
          ? ComfortPage(
              title: 'ログインして、\nひと息',
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
          : (_result != null ? _done(_result!) : _form()),
    );
  }

  /// 送れたあとの画面。通報し直し(`duplicate`)のときは、前の通報のまま運営が確認すると伝える。
  Widget _done(ReportResult result) => ComfortPage(
    title: result.duplicate ? 'すでに通報しています' : '通報を受け付けました',
    message: result.duplicate
        ? '前の通報の内容のまま、\n運営が確認します。'
        : '知らせてくれて、ありがとう。\n運営が確認します。',
    children: [
      const Text(
        '対応には数日かかる場合があります。通報したことは、相手に通知されません。',
        key: ValueKey('report-done'),
        style: TextStyle(fontSize: 13, height: 1.7),
      ),
      const SizedBox(height: 16),
      FilledButton(
        key: const ValueKey('report-back'),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('戻る'),
      ),
    ],
  );

  Widget _form() => ComfortPage(
    title: '通報する',
    message: '通報したことは、相手に通知されません。',
    children: [
      Text(switch (widget.targetType) {
        ReportTargetType.post => 'この投稿について',
        ReportTargetType.comment => 'このコメントについて',
        ReportTargetType.user => 'この利用者について',
      }, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      if (!_supported) ...[
        const Text(
          '利用者の通報は、準備中です。問題のある投稿やコメントは、その投稿・コメントから通報してください。',
          key: ValueKey('report-user-unsupported'),
          style: TextStyle(fontSize: 14, height: 1.7),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('戻る'),
        ),
      ] else ...[
        const Text(
          '通報の理由を選んでください',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        RadioGroup<ReportReason>(
          groupValue: _reason,
          onChanged: (value) => setState(() => _reason = value),
          child: Column(
            children: [
              for (final reason in ReportReason.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RadioListTile<ReportReason>(
                    value: reason,
                    title: Text(
                      reason.label,
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
        if (_reason == ReportReason.danger) ...[
          const SizedBox(height: 4),
          Container(
            key: const ValueKey('report-danger-note'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ご自身や身近な方が、つらい状況にあるときは、相談先もあります。',
                  style: TextStyle(fontSize: 12, height: 1.7),
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
        if (_reason == ReportReason.other) ...[
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('report-note'),
            controller: _note,
            enabled: !_busy,
            minLines: 3,
            maxLines: 6,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: '補足（任意）',
              hintText: '具体的な内容があればご記入ください。',
            ),
          ),
        ],
        const SizedBox(height: 16),
        const Text(
          '対応に数日かかる場合があります。',
          style: TextStyle(fontSize: 12, height: 1.7),
        ),
        if (ref.watch(reportRepositoryProvider).isSample)
          const Text(
            'サンプルです。実際には送信されません。',
            style: TextStyle(fontSize: 12, height: 1.7),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              key: const ValueKey('report-error'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('report-submit'),
          onPressed: _reason == null || _busy ? null : _confirm,
          child: Text(_busy ? '送信しています…' : '通報内容を確認'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
      ],
    ],
  );

  void _auth(AuthMode mode) => Navigator.of(context).push<void>(
    fullWidthRoute<void>(builder: (_) => AuthPage(initialMode: mode)),
  );
}
