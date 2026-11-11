import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import '../config/apple_sign_in_config.dart';

Future<void>? _loading;

/// Apple JSを、もう読み込んだか(`AppleID`がある)。
bool get appleJsLoaded => globalContext.has('AppleID');

/// Apple JSを、1回だけ読み込む。読み込めなかったときは、次の呼び出しで、やり直す。
Future<void> preloadAppleJs() {
  if (appleJsLoaded) return Future<void>.value();
  final existing = _loading;
  if (existing != null) return existing;
  final completer = Completer<void>();
  _loading = completer.future;
  final script = web.HTMLScriptElement()
    ..src = AppleSignInConfig.scriptUrl
    ..async = true;
  script.onload = ((web.Event _) => completer.complete()).toJS;
  script.onerror = ((web.Event _) {
    _loading = null;
    script.remove();
    completer.completeError(StateError('apple js failed'));
  }).toJS;
  web.document.head!.append(script);
  return completer.future;
}
