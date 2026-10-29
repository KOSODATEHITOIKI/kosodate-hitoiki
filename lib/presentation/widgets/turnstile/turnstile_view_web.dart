import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import '../../../core/config/turnstile_config.dart';

/// Webで、確認の部品を表示する。公式のスクリプト(challenges.cloudflare.com)を、
/// 必要になったときだけ読み込み、ページの中の小さな枠に、部品を出す。
Widget buildTurnstileView({
  Key? key,
  required String siteKey,
  required ValueChanged<String> onToken,
  required VoidCallback onExpired,
  required VoidCallback onError,
}) => _WebTurnstile(
  key: key,
  siteKey: siteKey,
  onToken: onToken,
  onExpired: onExpired,
  onError: onError,
);

/// 部品を読み込めたと言えるまでの、待ち時間の上限。
const _loadTimeout = Duration(seconds: 20);

Future<void>? _scriptLoading;

/// 公式のスクリプトを、1回だけ読み込む。読み込めなかったときは、次の呼び出しで、やり直す。
Future<void> _loadScript() {
  if (globalContext.has('turnstile')) return Future<void>.value();
  final existing = _scriptLoading;
  if (existing != null) return existing;
  final completer = Completer<void>();
  _scriptLoading = completer.future;
  final script = web.HTMLScriptElement()
    ..src = TurnstileConfig.scriptUrl
    ..async = true;
  script.onload = ((web.Event _) => completer.complete()).toJS;
  script.onerror = ((web.Event _) {
    _scriptLoading = null;
    script.remove();
    completer.completeError(StateError('turnstile script failed'));
  }).toJS;
  web.document.head!.append(script);
  return completer.future;
}

int _nextViewId = 0;

class _WebTurnstile extends StatefulWidget {
  const _WebTurnstile({
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
  State<_WebTurnstile> createState() => _WebTurnstileState();
}

class _WebTurnstileState extends State<_WebTurnstile> {
  late final String _viewType = 'turnstile-view-${_nextViewId++}';
  late final web.HTMLDivElement _container;
  JSAny? _widgetId;
  Timer? _timeout;
  bool _failed = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _container = web.HTMLDivElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.display = 'flex'
      ..style.justifyContent = 'center';
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _container,
    );
    _timeout = Timer(_loadTimeout, () {
      if (_widgetId == null) _fail();
    });
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      await _loadScript();
      // 枠が、ページに取り付けられるのを、1フレーム待つ。
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (_disposed) return;
      final turnstile = globalContext['turnstile'] as JSObject;
      final options = JSObject()
        ..['sitekey'] = widget.siteKey.toJS
        ..['theme'] = 'light'.toJS
        ..['language'] = 'ja'.toJS
        ..['callback'] = ((JSString token) {
          if (!_disposed) widget.onToken(token.toDart);
        }).toJS
        ..['expired-callback'] = (() {
          if (!_disposed) widget.onExpired();
        }).toJS
        ..['error-callback'] = (() {
          _fail();
        }).toJS;
      _widgetId = turnstile.callMethod<JSAny?>(
        'render'.toJS,
        _container,
        options,
      );
      if (_widgetId == null) _fail();
    } catch (_) {
      // 内容は、ログに出さない。
      _fail();
    }
  }

  void _fail() {
    if (_failed || _disposed) return;
    _failed = true;
    widget.onError();
  }

  @override
  void dispose() {
    _disposed = true;
    _timeout?.cancel();
    final id = _widgetId;
    if (id != null && globalContext.has('turnstile')) {
      try {
        (globalContext['turnstile'] as JSObject).callMethod<JSAny?>(
          'remove'.toJS,
          id,
        );
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
