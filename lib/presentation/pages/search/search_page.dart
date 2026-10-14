import 'package:flutter/material.dart';
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
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final type in ['すべて', 'ぐち', '相談', 'コツ・体験談'])
            ChoiceChip(
              label: Text(type),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
        ],
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Row(
          children: [
            Icon(Icons.eco_outlined),
            SizedBox(width: 12),
            Expanded(child: Text('話題を選ぶ')),
            Text('準備中', style: TextStyle(fontSize: 11)),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Text('・ 新着順', style: TextStyle(fontSize: 12)),
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
