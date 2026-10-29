import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/config/turnstile_config.dart';

/// アプリ(Android・iOS)で、確認の部品を表示する。小さなWebViewに、公式のスクリプトを
/// 読み込む。WebViewは、確認の部品のためだけに使い、ほかのページへは移れないようにする。
Widget buildTurnstileView({
  Key? key,
  required String siteKey,
  required ValueChanged<String> onToken,
  required VoidCallback onExpired,
  required VoidCallback onError,
}) => _MobileTurnstile(
  key: key,
  siteKey: siteKey,
  onToken: onToken,
  onExpired: onExpired,
  onError: onError,
);

/// 部品を読み込めたと言えるまでの、待ち時間の上限(通信がつながらないときの再試行の案内用)。
const _loadTimeout = Duration(seconds: 20);

class _MobileTurnstile extends StatefulWidget {
  const _MobileTurnstile({
    super.key,
    required this.siteKey,
    required this.onToken,
    required this.onExpired,
    required this.onError,
  });

  final String siteKey;
  final ValueChanged<String> onToken;
  final VoidCallback onExpired;
  final VoidCallback onError;

  @override
  State<_MobileTurnstile> createState() => _MobileTurnstileState();
}

class _MobileTurnstileState extends State<_MobileTurnstile> {
  late final WebViewController _controller;
  Timer? _timeout;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          // 確認の部品以外には、移らない(部品は、公式のドメインの枠を内側に出す)。
          onNavigationRequest: (request) => _allowed(request)
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) _fail();
          },
        ),
      )
      ..addJavaScriptChannel('TurnstileBridge', onMessageReceived: _onMessage)
      ..loadHtmlString(
        _html(widget.siteKey),
        baseUrl: TurnstileConfig.appBaseUrl,
      );
    // 読み込めない(通信の失敗・ブロック)まま、動かなくならないようにする。
    _timeout = Timer(_loadTimeout, () {
      if (!_ready) _fail();
    });
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  bool _allowed(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return false;
    if (uri.scheme == 'about' || request.url == 'data:text/html') return true;
    if (request.url.startsWith(TurnstileConfig.appBaseUrl)) return true;
    // 枠(iframe)は、公式のドメインだけ。メインのページは、ほかへ移さない。
    return !request.isMainFrame &&
        uri.scheme == 'https' &&
        uri.host == TurnstileConfig.allowedHost;
  }

  void _fail() {
    if (_failed || !mounted) return;
    _failed = true;
    widget.onError();
  }

  void _onMessage(JavaScriptMessage message) {
    if (!mounted) return;
    try {
      final data = jsonDecode(message.message);
      if (data is! Map) return;
      switch (data['t']) {
        case 'ready':
          _ready = true;
        case 'token':
          final token = data['v'];
          if (token is String && token.isNotEmpty) {
            _ready = true;
            widget.onToken(token);
          }
        case 'expired':
          widget.onExpired();
        case 'error':
          _fail();
      }
    } catch (_) {
      // 想定外の内容は、無視する(内容は、ログに出さない)。
    }
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}

/// 確認の部品を表示する、小さなページ。Site Keyは、公開してよい定数だけを入れる。
String _html(String siteKey) =>
    '''
<!doctype html>
<html lang="ja"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>html,body{margin:0;padding:0;background:transparent;overflow:hidden}#w{display:flex;justify-content:center}</style>
<script src="${TurnstileConfig.scriptUrl}" async defer
  onerror="TurnstileBridge.postMessage(JSON.stringify({t:'error'}))"></script>
</head><body><div id="w"></div>
<script>
function send(o){TurnstileBridge.postMessage(JSON.stringify(o));}
var tries=0;
function init(){
  if(!window.turnstile){ if(++tries>150){send({t:'error'});return;} setTimeout(init,100); return; }
  send({t:'ready'});
  turnstile.render('#w',{
    sitekey:'$siteKey', theme:'light', language:'ja',
    callback:function(t){send({t:'token',v:t});},
    'expired-callback':function(){send({t:'expired'});},
    'error-callback':function(){send({t:'error'});}
  });
}
init();
</script></body></html>
''';
