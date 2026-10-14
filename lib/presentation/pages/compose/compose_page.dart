import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../widgets/comfort_page.dart';

/// S-04。投稿API・送信前チェックとの接続はIssue #9で行う。
class ComposePage extends StatefulWidget {
  const ComposePage({super.key});
  @override
  State<ComposePage> createState() => _ComposePageState();
}

enum _ResponseMode { listening, advice }

class _ComposePageState extends State<ComposePage> {
  final _body = TextEditingController();
  String _postType = 'ぐち';
  _ResponseMode _mode = _ResponseMode.listening;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  void _showPostingNotice() {
    FocusScope.of(context).unfocus();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('投稿機能は準備中です'),
        content: const Text(
          '投稿にはログインが必要です。\n現在は入力画面をお試しいただけます。入力した内容は送信・保存されません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('書く画面に戻る'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ComfortPage(
    title: 'ひと息',
    useBrandLogo: true,
    message: 'いまの気持ちを、\nあなたのペースで。',
    headerIllustration: AppIllustrations.welcome,
    horizontalPadding: 12,
    messageFontSize: 12.5,
    children: [
      _section(
        '投稿の種類',
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final type in ['ぐち', '相談', 'コツ・体験談'])
              ChoiceChip(
                label: Text(type, maxLines: 1, softWrap: false),
                labelStyle: const TextStyle(fontSize: 12),
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                selected: _postType == type,
                onSelected: (_) => setState(() => _postType = type),
                showCheckmark: false,
                selectedColor: AppColors.secondary,
                backgroundColor: AppColors.background,
                shape: const StadiumBorder(),
                side: const BorderSide(color: AppColors.divider),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _section(
        '本文',
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _body,
              minLines: 4,
              maxLines: 10,
              maxLength: 1000,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'いまの気持ちを書いてみませんか。',
                labelText: '気持ちの本文',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '名前・学校や園・住んでいる場所は書かないでね。',
                      style: TextStyle(fontSize: 12.5, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _section(
        '反応の希望',
        LayoutBuilder(
          builder: (context, constraints) {
            final options = [
              _modeOption(_ResponseMode.listening, 'ただ聞いてほしい', '共感ボタン・定型文のみ'),
              _modeOption(_ResponseMode.advice, '話を聞きたい', '自由コメントを受け付ける'),
            ];
            final scale = MediaQuery.textScalerOf(context).scale(1);
            if (constraints.maxWidth / scale >= 400) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: options[0]),
                  const SizedBox(width: 12),
                  Expanded(child: options[1]),
                ],
              );
            }
            return Column(
              children: [options[0], const SizedBox(height: 12), options[1]],
            );
          },
        ),
      ),
      const SizedBox(height: 16),
      _section(
        '話題（任意・1つ）',
        const Text('話題の選択は準備中です。', style: TextStyle(fontSize: 12.5)),
      ),
      const SizedBox(height: 24),
      FilledButton.icon(
        key: const ValueKey('compose-submit'),
        onPressed: _body.text.trim().isEmpty ? null : _showPostingNotice,
        icon: SvgPicture.asset(
          AppIcons.navCompose,
          width: 24,
          height: 24,
          excludeFromSemantics: true,
          colorFilter: ColorFilter.mode(
            _body.text.trim().isEmpty
                ? AppColors.textSecondary
                : AppColors.white,
            BlendMode.srcIn,
          ),
        ),
        label: const Text('投稿する'),
      ),
      const SizedBox(height: 12),
      const Text(
        '入力内容はこの画面を開いている間だけ保持されます。\n投稿機能は準備中です。',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, height: 1.6),
      ),
    ],
  );

  Widget _modeOption(_ResponseMode value, String title, String description) {
    final selected = _mode == value;
    return Semantics(
      key: ValueKey('response-${value.name}'),
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? AppColors.accentPink.withValues(alpha: 0.35)
            : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _mode = value),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 12, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, Widget child) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}
