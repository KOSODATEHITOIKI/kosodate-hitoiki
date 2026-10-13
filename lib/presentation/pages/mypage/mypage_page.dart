import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../widgets/comfort_page.dart';
import '../settings/settings_page.dart';
import '../profile/profile_edit_page.dart';

/// S-07。プロフィール・投稿取得と認証分岐はIssue #12で接続する。
class MyPagePage extends StatefulWidget {
  const MyPagePage({super.key});

  @override
  State<MyPagePage> createState() => _MyPagePageState();
}

class _MyPagePageState extends State<MyPagePage> {
  bool _savedPosts = false;

  void _showNotice(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
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
  Widget build(BuildContext context) => ComfortPage(
    title: 'マイページ',
    message: 'あなたのペースで\nつながれる、ひと息の場所です。',
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const SettingsPage())),
          icon: const Icon(Icons.settings_outlined),
          label: const Text('設定'),
        ),
      ),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    AppAvatars.defaultSprout,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'あなたのプロフィール',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'マイページの利用には\nログインが必要です。',
                        style: TextStyle(fontSize: 14, height: 1.7),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ProfileEditPage(),
                ),
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('プロフィールを編集'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.divider),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () =>
                  _showNotice('登録・ログインは準備中です', '現在は登録せずに画面をご覧いただけます。'),
              child: const Text('登録・ログイン'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, label: Text('自分の投稿')),
          ButtonSegment(value: true, label: Text('保存した投稿')),
        ],
        selected: {_savedPosts},
        showSelectedIcon: false,
        onSelectionChanged: (selection) =>
            setState(() => _savedPosts = selection.single),
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.white,
          selectedBackgroundColor: AppColors.secondary,
          selectedForegroundColor: AppColors.textPrimary,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(48, 52),
          side: const BorderSide(color: AppColors.divider),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      const SizedBox(height: 24),
      if (_savedPosts) ...[
        const Text(
          'あとで読みたい投稿',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          '保存したことは相手に通知されません。',
          style: TextStyle(fontSize: 14, height: 1.7),
        ),
        const SizedBox(height: 16),
      ],
      ComfortNotice(
        asset: _savedPosts
            ? AppIllustrations.emptyBookmarks
            : AppIllustrations.emptyMyPosts,
        title: _savedPosts ? '保存した投稿は準備中です' : '自分の投稿は準備中です',
        message: _savedPosts
            ? 'あとで読み返したい投稿を\nここで確認できるようになります。'
            : 'あなたが書いた気持ちを\nここで振り返れるようになります。',
      ),
    ],
  );
}
