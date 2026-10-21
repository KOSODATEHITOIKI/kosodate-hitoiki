import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kosodate_hitoiki/presentation/widgets/app_asset.dart';
import '../../../core/constants/app_icons.dart';
import '../../../domain/models/app_notification.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_providers.dart';
import '../../widgets/comfort_page.dart';
import '../auth/auth_page.dart';

/// S-11通知設定。通知の設定(`notification_settings`)の取得・変更に接続している。
/// 止めた種類は、お知らせ自体が作られなくなる。運営からのお知らせは、止められない。
class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});
  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

enum _Kind { comments, replies, reactions }

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  /// いまの設定。読み込めたら入り、切り替えるとすぐ変わる(サーバーへは、続けて送る)。
  NotificationSettings? _settings;

  @override
  void initState() {
    super.initState();
    ref.listenManual(notificationSettingsProvider, (_, next) {
      final loaded = next.valueOrNull;
      // 切り替えの途中の値を、読み込みで上書きしない。
      if (loaded != null && _settings == null) {
        setState(() => _settings = loaded);
      }
    }, fireImmediately: true);
  }

  bool _value(_Kind kind) {
    final settings = _settings!;
    return switch (kind) {
      _Kind.comments => settings.comments,
      _Kind.replies => settings.replies,
      _Kind.reactions => settings.reactions,
    };
  }

  NotificationSettings _with(NotificationSettings s, _Kind kind, bool value) =>
      switch (kind) {
        _Kind.comments => s.copyWith(comments: value),
        _Kind.replies => s.copyWith(replies: value),
        _Kind.reactions => s.copyWith(reactions: value),
      };

  /// 切り替える。すぐ表示に反映し、サーバーへ送る。送れなかったときは、元に戻して案内する。
  Future<void> _toggle(_Kind kind, bool value) async {
    final before = _settings;
    if (before == null) return;
    setState(() => _settings = _with(before, kind, value));
    final repository = ref.read(notificationRepositoryProvider);
    try {
      await repository.updateSettings(
        comments: kind == _Kind.comments ? value : null,
        replies: kind == _Kind.replies ? value : null,
        reactions: kind == _Kind.reactions ? value : null,
      );
      // 開き直したとき、古い値が出ないようにする。
      if (mounted) ref.invalidate(notificationSettingsProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() => _settings = _with(_settings ?? before, kind, !value));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('設定を変更できませんでした')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(isLoggedInProvider);
    // 利用者が切り替わったら、この画面を閉じる(前の利用者の設定を、別の人に見せない・送らない)。
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous == next) return;
      final navigator = Navigator.of(context);
      final myRoute = ModalRoute.of(context);
      if (myRoute != null) {
        navigator.popUntil((route) => route == myRoute);
      }
      if (navigator.canPop()) navigator.pop();
    });
    final sample = ref.watch(notificationsAreSampleProvider);
    final loaded = ref.watch(notificationSettingsProvider);
    final failed = loaded.hasError && _settings == null;
    final loading = _settings == null && !failed;
    return Scaffold(
      appBar: AppBar(title: const Text('通知設定')),
      body: !loggedIn
          ? ComfortPage(
              title: 'ログインして、\nひと息',
              message: '通知設定には、\n登録・ログインが必要です。',
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
              title: '通知設定',
              useBrandLogo: true,
              message: 'お知らせも、\nあなたのペースで。',
              children: [
                if (sample) ...[
                  const Text(
                    '画面確認用のサンプル設定です。変更は保存されず、実際の通知には反映されません。',
                    style: TextStyle(fontSize: 12, height: 1.7),
                  ),
                  const SizedBox(height: 20),
                ],
                if (loading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      '設定を読み込んでいます…',
                      key: ValueKey('settings-loading'),
                      style: TextStyle(fontSize: 13, height: 1.7),
                    ),
                  ),
                if (failed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '設定を読み込めませんでした。読み込めるまで、変更できません。',
                          key: ValueKey('settings-load-failed'),
                          style: TextStyle(fontSize: 13, height: 1.7),
                        ),
                        TextButton(
                          key: const ValueKey('settings-retry'),
                          onPressed: () =>
                              ref.invalidate(notificationSettingsProvider),
                          child: const Text('再読み込み'),
                        ),
                      ],
                    ),
                  ),
                Card(
                  child: Column(
                    children: [
                      _switch(
                        _Kind.comments,
                        AppIcons.comment,
                        'コメント',
                        'あなたの投稿へのコメントをお知らせします。',
                        sample,
                      ),
                      const Divider(height: 1),
                      _switch(
                        _Kind.replies,
                        AppIcons.reply,
                        '返信',
                        'あなたのコメントへの返信をお知らせします。',
                        sample,
                      ),
                      const Divider(height: 1),
                      _switch(
                        _Kind.reactions,
                        AppIcons.heart,
                        '共感のまとめ',
                        '届いた共感をまとめてお知らせします。',
                        sample,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          '端末の通知設定',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '通知を受け取るには、端末側でも通知の許可が必要です。',
                          style: TextStyle(fontSize: 12, height: 1.6),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('端末設定への移動は準備中です'),
                              content: const Text(
                                '現在は端末の設定を開きません。端末連携の実装を準備しています。',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('閉じる'),
                                ),
                              ],
                            ),
                          ),
                          child: const Text('設定を開く'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '運営からの連絡は、この切り替えの対象には含みません。',
                  style: TextStyle(fontSize: 12, height: 1.7),
                ),
              ],
            ),
    );
  }

  Widget _switch(
    _Kind kind,
    String icon,
    String title,
    String description,
    bool sample,
  ) {
    final ready = _settings != null;
    final on = ready && _value(kind);
    return SwitchListTile(
      secondary: AppAsset(
        icon,
        width: 28,
        height: 28,
        excludeFromSemantics: true,
      ),
      value: on,
      onChanged: ready ? (value) => _toggle(kind, value) : null,
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '$description\n${on ? '受け取る' : '受け取らない'}${sample ? '（サンプル）' : ''}',
        style: const TextStyle(fontSize: 12, height: 1.6),
      ),
    );
  }

  void _auth(AuthMode mode) => Navigator.of(
    context,
  ).push<void>(MaterialPageRoute(builder: (_) => AuthPage(initialMode: mode)));
}
