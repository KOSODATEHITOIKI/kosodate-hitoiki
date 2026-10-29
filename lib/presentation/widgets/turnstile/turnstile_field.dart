import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/turnstile_config.dart';
import '../../providers/captcha_provider.dart';
import 'turnstile_types.dart';
import 'turnstile_view.dart';

/// 確認の部品を表示する関数。通常は、環境に合ったもの(アプリ:WebView、Web:公式のスクリプト)。
/// テストでは差し替える。
final turnstileViewBuilderProvider = Provider<TurnstileViewBuilder>(
  (ref) => buildTurnstileView,
);

/// 登録・ログイン・パスワード再設定の画面に置く、確認の部品(Cloudflare Turnstile)の枠。
///
/// - 確認が済むと、トークンを[captchaTokenProvider]に置く(認証のリポジトリが、使う瞬間に
///   取り出す)。トークンは1回限りなので、使ったあとは[TurnstileFieldState.reset]で、
///   新しい確認をやり直す。
/// - 部品を読み込めないとき(通信の失敗・ブロック)は、トークンを置かず、再試行を案内する
///   (トークンなしでは、先へ進めない)。
class TurnstileField extends ConsumerStatefulWidget {
  const TurnstileField({super.key});

  @override
  ConsumerState<TurnstileField> createState() => TurnstileFieldState();
}

class TurnstileFieldState extends ConsumerState<TurnstileField> {
  /// 作り直すたびに増やす(部品を最初から表示し直すため)。
  int _attempt = 0;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // 前の画面で残った、古いトークンは使わない。
    Future<void>(() {
      if (mounted) ref.read(captchaTokenProvider.notifier).state = null;
    });
  }

  void _setToken(String? token) {
    if (!mounted) return;
    ref.read(captchaTokenProvider.notifier).state = token;
  }

  /// 使い終わったトークンを消して、新しい確認をやり直す。
  void reset() {
    if (!mounted) return;
    _setToken(null);
    setState(() {
      _attempt++;
      _failed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Column(
        key: const ValueKey('turnstile-failed'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '確認の部品を読み込めませんでした。通信を確認して、もう一度お試しください。',
            style: TextStyle(fontSize: 13, height: 1.6),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey('turnstile-retry'),
              onPressed: reset,
              child: const Text('もう一度読み込む'),
            ),
          ),
        ],
      );
    }
    final builder = ref.watch(turnstileViewBuilderProvider);
    return SizedBox(
      key: const ValueKey('turnstile-field'),
      height: 72,
      child: builder(
        key: ValueKey(_attempt),
        siteKey: TurnstileConfig.siteKey,
        onToken: _setToken,
        onExpired: () => _setToken(null),
        onError: () {
          if (!mounted) return;
          _setToken(null);
          setState(() => _failed = true);
        },
      ),
    );
  }
}
