import 'package:flutter/material.dart';
import 'package:kosodate_hitoiki/presentation/widgets/app_asset.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../widgets/comfort_page.dart';

/// S-09。プロフィール取得・保存・送信前チェックは未接続。
class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});
  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _form = GlobalKey<FormState>();
  final _nickname = TextEditingController();
  final _bio = TextEditingController();
  String _avatar = AppAvatars.defaultSprout;
  String? _nameError;
  String _ageBand = '';

  // 年齢帯の区分は未確定。画面確認用のサンプルとして扱う。
  static const _sampleAgeBands = ['', '乳児', '未就学児', '小学生', '中学生以上'];

  @override
  void dispose() {
    _nickname.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _save() {
    final length = _nickname.text.trim().characters.length;
    setState(
      () => _nameError = length < 2 || length > 12
          ? 'ニックネームは2〜12文字で入力してください。'
          : null,
    );
    if (_nameError != null) return;
    FocusScope.of(context).unfocus();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プロフィールの保存は準備中です'),
        content: const Text('入力内容は保存されません。プロフィールの編集にはログインが必要です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('編集に戻る'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('プロフィール編集')),
    body: Form(
      key: _form,
      child: ComfortPage(
        title: 'プロフィール',
        message: 'あなたのことを、ひとこと。',
        children: [
          _section(
            'アイコンを選ぶ',
            Column(
              children: [
                AppAsset(
                  _avatar,
                  width: 96,
                  height: 96,
                  semanticsLabel: '選択中のアイコン',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    for (final item in const [
                      (AppAvatars.defaultSprout, '芽'),
                      (AppAvatars.defaultYellowFlower, '花'),
                      (AppAvatars.defaultTulip, 'チューリップ'),
                      (AppAvatars.defaultLittleBird, '鳥'),
                    ])
                      Semantics(
                        button: true,
                        selected: _avatar == item.$1,
                        label: '${item.$2}のアイコン',
                        child: Tooltip(
                          message: '${item.$2}のアイコン',
                          child: InkWell(
                            onTap: () => setState(() => _avatar = item.$1),
                            borderRadius: BorderRadius.circular(40),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surface,
                                border: Border.all(
                                  color: _avatar == item.$1
                                      ? AppColors.primary
                                      : AppColors.divider,
                                  width: 2,
                                ),
                              ),
                              child: AppAsset(
                                item.$1,
                                width: 56,
                                height: 56,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section(
            'ニックネーム（必須）',
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const ValueKey('profile-nickname'),
                  controller: _nickname,
                  forceErrorText: _nameError,
                  onChanged: (_) {
                    if (_nameError != null) setState(() => _nameError = null);
                  },
                  maxLength: 12,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'ニックネーム',
                    hintText: 'あなたの呼び名',
                  ),
                  validator: (value) =>
                      (value ?? '').trim().characters.length < 2
                      ? 'ニックネームは2〜12文字で入力してください。'
                      : null,
                ),
                const Text(
                  '2〜12文字・変更は30日に1回です。\n本名やお子さんの名前は使わないでください。',
                  style: TextStyle(fontSize: 12, height: 1.7),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section(
            '自己紹介（任意）',
            TextFormField(
              key: const ValueKey('profile-bio'),
              controller: _bio,
              maxLength: 100,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: '自己紹介',
                hintText: 'あなたのことを、ひとこと',
                alignLabelWithHint: true,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _section(
            '子どもの年齢帯（任意）',
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InputDecorator(
                  decoration: const InputDecoration(labelText: '年齢帯'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      key: const ValueKey('profile-age-band'),
                      value: _ageBand,
                      isExpanded: true,
                      itemHeight: null,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontSize: 14),
                      items: [
                        for (final age in _sampleAgeBands)
                          DropdownMenuItem(
                            value: age,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(age.isEmpty ? '未選択' : age),
                            ),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _ageBand = value ?? ''),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '選ばなくても構いません。選択肢は画面確認用のサンプルです。',
                  style: TextStyle(fontSize: 12, height: 1.7),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const ValueKey('profile-save'),
            onPressed: _save,
            child: const Text('保存する'),
          ),
          const SizedBox(height: 12),
          const Text(
            '保存機能は準備中です。\nこの画面を閉じると入力内容は消えます。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, height: 1.7),
          ),
        ],
      ),
    ),
  );

  Widget _section(String title, Widget child) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}
