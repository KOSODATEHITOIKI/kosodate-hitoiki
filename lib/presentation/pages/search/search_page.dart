import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../widgets/comfort_page.dart';

/// S-05。検索APIの接続はIssue #10で行う。
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  String _postType = 'すべて';
  String _query = '';
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ComfortPage(
    title: 'ひと息',
    message: '子育ての毎日に、\nひと息つける場所を。',
    useBrandLogo: true,
    headerIllustration: AppIllustrations.welcome,
    horizontalPadding: 12,
    children: [
      TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        onChanged: (value) => setState(() => _query = value.trim()),
        onSubmitted: (_) => FocusScope.of(context).unfocus(),
        decoration: InputDecoration(
          hintText: '気になる言葉で検索',
          labelText: 'キーワード',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: '検索語を消す',
                  onPressed: () {
                    _controller.clear();
                    setState(() => _query = '');
                  },
                  icon: const Icon(Icons.cancel_outlined),
                ),
        ),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final type in ['すべて', 'ぐち', '相談', 'コツ・体験談'])
            ChoiceChip(
              label: Text(type, maxLines: 1, softWrap: false),
              labelStyle: const TextStyle(fontSize: 12),
              labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              selected: _postType == type,
              onSelected: (_) => setState(() => _postType = type),
              showCheckmark: false,
              selectedColor: AppColors.secondary,
              backgroundColor: AppColors.white,
              shape: const StadiumBorder(),
              side: BorderSide(
                color: _postType == type
                    ? Colors.transparent
                    : AppColors.divider,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            ),
        ],
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              AppDecorations.leavesSprout,
              width: 36,
              height: 36,
              excludeFromSemantics: true,
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('話題を選ぶ')),
            const Text('準備中', style: TextStyle(fontSize: 11)),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const Wrap(
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '検索結果',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          Text('・ 新着順', style: TextStyle(fontSize: 12.5)),
        ],
      ),
      const SizedBox(height: 16),
      ComfortNotice(
        asset: AppIllustrations.emptySearch,
        title: _query.isEmpty ? '気になる言葉を入れてみてください' : '検索機能は準備中です',
        message: _query.isEmpty
            ? '同じ気持ちや、子育てのコツに\n出会える場所を準備しています。'
            : '投稿の検索はまだご利用いただけません。\n検索語を変えたり、消したりできます。',
      ),
    ],
  );
}
