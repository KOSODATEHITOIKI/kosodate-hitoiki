import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// 話題(任意・1つ)のモック候補。F-06の分類が確定したら差し替える。
const List<String> kMockTopics = [
  '夜泣き',
  '寝かしつけ',
  '離乳食・食事',
  'イヤイヤ期',
  '保育園・幼稚園',
  '仕事復帰',
  '上の子・きょうだい',
  '体調・通院',
];

/// 話題選択のボトムシートを開き、選んだ話題(クリア時はnull)を返す。
Future<String?> showTopicPicker(BuildContext context, {String? current}) {
  return showModalBottomSheet<String?>(
    context: context,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '話題を選ぶ(任意・1つ)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final topic in kMockTopics)
                  ChoiceChip(
                    label: Text(topic),
                    selected: current == topic,
                    onSelected: (_) => Navigator.of(context).pop(topic),
                    showCheckmark: false,
                    selectedColor: AppColors.secondary,
                    backgroundColor: AppColors.white,
                    shape: const StadiumBorder(),
                    side: BorderSide(
                      color: current == topic
                          ? Colors.transparent
                          : AppColors.divider,
                    ),
                  ),
              ],
            ),
            if (current != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('選択をクリア'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
