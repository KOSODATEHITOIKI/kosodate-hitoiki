import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../widgets/comfort_page.dart';

/// S-06。通知取得・認証による表示分岐はIssue #11で接続する。
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _unreadOnly = false;
  @override
  Widget build(BuildContext context) => ComfortPage(
    title: 'お知らせ',
    message: 'ひと息のつながりから、\nうれしいお知らせをお届けします。',
    children: [
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, label: Text('すべて')),
          ButtonSegment(value: true, label: Text('未読')),
        ],
        selected: {_unreadOnly},
        showSelectedIcon: false,
        onSelectionChanged: (selection) =>
            setState(() => _unreadOnly = selection.single),
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.white,
          selectedBackgroundColor: AppColors.secondary,
          selectedForegroundColor: AppColors.textPrimary,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(48, 52),
          side: const BorderSide(color: AppColors.divider),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      const SizedBox(height: 24),
      ComfortNotice(
        asset: AppIllustrations.emptyNotifications,
        title: 'お知らせ機能は準備中です',
        message: _unreadOnly
            ? '未読のお知らせを確認できるようになります。\nコメントや共感の通知をお待ちください。'
            : 'コメントや共感、運営からのお知らせを\nここで確認できるようになります。',
      ),
    ],
  );
}
