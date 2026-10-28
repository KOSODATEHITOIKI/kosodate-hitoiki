import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// 外部のページを開く処理。テストでは差し替える。開けたら`true`。
final externalLinkOpenerProvider = Provider<Future<bool> Function(Uri url)>(
  (ref) =>
      (url) => launchUrl(url, mode: LaunchMode.externalApplication),
);

/// 外部のブラウザで、ページを開く。開けなければ、アドレスを出して、控えられるようにする。
Future<void> openExternalLink(
  BuildContext context,
  WidgetRef ref,
  Uri url, {
  required String title,
}) async {
  // 入力中の欄からフォーカスを外してから開く(戻ったときに、キーボードが出ないように)。
  FocusManager.instance.primaryFocus?.unfocus();
  try {
    if (await ref.read(externalLinkOpenerProvider)(url)) return;
  } catch (_) {
    // 下の案内を出す。
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('$titleを開けませんでした'),
      content: SelectableText(
        'ブラウザで、次のアドレスを開いてください。\n\n$url',
        style: const TextStyle(height: 1.7),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    ),
  );
  FocusManager.instance.primaryFocus?.unfocus();
}
