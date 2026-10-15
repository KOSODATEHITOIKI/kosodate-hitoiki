import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_icons.dart';
import '../../widgets/comfort_page.dart';

/// S-12。ログイン不要。確認済みの公的な案内ページを外部ブラウザで開く。
class SupportResourcesPage extends StatelessWidget {
  const SupportResourcesPage({super.key, this.openLink});
  final Future<bool> Function(Uri)? openLink;

  static final parentLineUrl = Uri.parse(
    'https://www.cfa.go.jp/policies/jidougyakutai/oyako-line/',
  );
  static final childSafetyUrl = Uri.parse(
    'https://www.cfa.go.jp/policies/jidougyakutai/gyakutai-taiou-dial/',
  );
  static final mentalSupportUrl = Uri.parse(
    'https://www.mhlw.go.jp/mamorouyokokoro/',
  );

  Future<void> _open(BuildContext context, Uri url) async {
    try {
      final opened =
          await (openLink?.call(url) ??
              launchUrl(url, mode: LaunchMode.externalApplication));
      if (opened || !context.mounted) return;
    } catch (_) {
      if (!context.mounted) return;
    }
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('公式ページを開けませんでした'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('接続環境を確認して再度お試しください。次のURLをコピーしてブラウザで開くこともできます。'),
              const SizedBox(height: 12),
              SelectableText(url.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('困ったときの相談先')),
    body: ComfortPage(
      title: 'ひとりで\n抱えなくて大丈夫。',
      message: 'あなたの状況に合う相談先を探せます。',
      children: [
        for (final item in [
          (
            '子育ての悩み',
            '親子のための相談LINE',
            'こども家庭庁',
            AppIllustrations.supportParentChild,
            parentLineUrl,
            '子育てや親子関係の相談窓口を案内しています。',
          ),
          (
            'こころの相談',
            'まもろうよ こころ',
            '厚生労働省',
            AppIllustrations.supportHeartHands,
            mentalSupportUrl,
            '電話・SNSなど、相談方法や窓口を探せます。',
          ),
          (
            '子どもの安全について',
            '児童相談所虐待対応ダイヤル 189',
            'こども家庭庁',
            AppIllustrations.supportHomeFamily,
            childSafetyUrl,
            '虐待かもと思ったときの相談・通告先です。全国共通の電話番号は189です。',
          ),
        ]) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SvgPicture.asset(
                        item.$4,
                        width: 64,
                        height: 64,
                        excludeFromSemantics: true,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.$1,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.$2,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(item.$3, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(
                    item.$6,
                    style: const TextStyle(fontSize: 14, height: 1.7),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _open(context, item.$5),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(
                      '${item.$2}の公式ページ',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        const Text(
          'リンク先で受付時間や対象地域をご確認ください。\n公式ページを外部ブラウザで開きます。',
          style: TextStyle(fontSize: 12, height: 1.7),
        ),
      ],
    ),
  );
}
