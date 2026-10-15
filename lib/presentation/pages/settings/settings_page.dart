import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../widgets/comfort_page.dart';
import 'withdrawal_page.dart';
import 'notification_settings_page.dart';

/// S-11。未接続の設定操作は案内だけを表示する。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showNotice(BuildContext context, String title) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$titleは準備中です'),
        content: const Text('この機能はまだご利用いただけません。設定やアカウントは変更されません。'),
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
    appBar: AppBar(title: const Text('設定')),
    body: ComfortPage(
      title: '設定',
      message: 'あなたが安心して使えるように、\n各種設定ができます。',
      children: [
        for (final group in const [
          [
            (AppIcons.navNotifications, '通知'),
            (AppIcons.safetyMute, 'ミュート管理'),
            (AppIcons.safetyBlock, 'ブロック管理'),
          ],
          [
            (AppIcons.statusInfo, '利用ガイド'),
            (AppIcons.safetySupport, '困ったときの相談先'),
          ],
          [
            (AppIcons.safetyShield, '利用規約'),
            (AppIcons.safetyShield, 'プライバシーポリシー'),
          ],
          [(AppIcons.accountMail, 'お問い合わせ')],
          [(AppIcons.accountLogout, 'ログアウト'), (AppIcons.navMyPage, '退会')],
        ]) ...[
          Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var index = 0; index < group.length; index++) ...[
                  if (index > 0)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: SvgPicture.asset(
                      group[index].$1,
                      width: 28,
                      height: 28,
                      excludeFromSemantics: true,
                    ),
                    title: Text(
                      group[index].$2,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: ['利用ガイド', '退会', '通知'].contains(group[index].$2)
                        ? null
                        : const Text('準備中', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      if (group[index].$2 == '利用ガイド') {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const UsageGuidePage(),
                          ),
                        );
                      } else if (group[index].$2 == '退会') {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => const WithdrawalPage(),
                          ),
                        );
                      } else if (group[index].$2 == '通知') {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => const NotificationSettingsPage(),
                          ),
                        );
                      } else {
                        _showNotice(context, group[index].$2);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    ),
  );
}

class UsageGuidePage extends StatelessWidget {
  const UsageGuidePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('利用ガイド')),
    body: ComfortPage(
      title: '利用ガイド',
      message: '安心して気持ちを話せるように、\n大切にしたいこと。',
      children: [
        for (final item in const [
          (
            '名前や個人情報は書かない',
            '本人や子ども、家族、知人の名前、学校や園、勤務先、住んでいる場所など、個人が特定される情報は書かないでください。「長男」「夫」など続柄で伝えましょう。',
          ),
          (
            '気持ちを否定しない',
            'どんな気持ちも、否定せずに受けとめ合いましょう。コツや体験談は「うちの場合は」の形で、押しつけずに伝えましょう。',
          ),
          ('自分のペースで大丈夫', '見るだけでも、書くのは後でも。あなたのペースで使えます。'),
          (
            '反応の希望を選べます',
            '「ただ聞いてほしい」は共感ボタン・定型文のみ。「話を聞きたい」は自由コメントを受け付けます。投稿時の初期選択は「ただ聞いてほしい」です。',
          ),
        ]) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item.$1,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.$2,
                  style: const TextStyle(fontSize: 13.5, height: 1.8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    ),
  );
}
