import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_brand.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../data/mock/mock_notifications.dart';
import '../../widgets/comfort_page.dart';

/// S-06。通知取得・認証による表示分岐はIssue #11で接続する。
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _unreadOnly = false;
  final Set<String> _readIds = {
    for (final item in mockNotifications)
      if (item.initiallyRead) item.id,
  };

  void _open(MockNotification item) {
    setState(() => _readIds.add(item.id));
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.body),
              const SizedBox(height: 16),
              const Text(
                'サンプルのお知らせです。投稿への移動は準備中です。',
                style: TextStyle(fontSize: 12, height: 1.6),
              ),
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

  Widget _notificationCard(MockNotification item) {
    final unread = !_readIds.contains(item.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('notification-${item.id}'),
          onTap: () => _open(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    item.asset,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (unread)
                            Semantics(
                              label: '未読',
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          Text(
                            item.ageLabel,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, height: 1.7),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ComfortPage(
    title: 'お知らせ',
    titleImage: AppBrand.titleNotifications,
    titleImageScale: 1.15,
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
          textStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'サンプルのお知らせです。既読状態はアプリ終了時にリセットされます。',
        style: TextStyle(fontSize: 11, height: 1.6),
      ),
      const SizedBox(height: 12),
      if (_unreadOnly &&
          mockNotifications.every((item) => _readIds.contains(item.id)))
        const ComfortNotice(
          asset: AppIllustrations.emptyNotifications,
          title: '未読のお知らせはありません',
          message: '自分のペースで、ひと息。',
        )
      else
        for (final item in mockNotifications)
          if (!_unreadOnly || !_readIds.contains(item.id))
            _notificationCard(item),
    ],
  );
}
