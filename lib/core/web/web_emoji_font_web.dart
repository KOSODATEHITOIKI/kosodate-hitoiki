import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

import '../constants/app_typography.dart';

/// 絵文字のフォントを、同じサイト(web/fonts/)から読み込んで、登録する。
/// 読み込めなくても、アプリは動く(絵文字が出ないだけ)。
Future<void> loadWebEmojiFont() async {
  try {
    final response = await web.window
        .fetch('fonts/NotoColorEmoji-subset.woff2'.toJS)
        .toDart
        .timeout(const Duration(seconds: 10));
    if (!response.ok) return;
    final buffer = await response.arrayBuffer().toDart;
    final bytes = buffer.toDart.asUint8List();
    final loader = FontLoader(AppTypography.emojiFontFamily)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  } catch (_) {
    // 絵文字が□になるだけで、投稿・閲覧は止めない。
  }
}
