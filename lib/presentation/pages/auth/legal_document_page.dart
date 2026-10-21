import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'legal_documents.dart';

/// 利用規約・プライバシーポリシーを読む画面。最後までスクロールすると
/// 「同意する」を押せて、`true`を返して前の画面へ戻る。
/// 途中で戻ったときは`null`を返す(チェックはつかない)。
class LegalDocumentPage extends StatefulWidget {
  const LegalDocumentPage({super.key, required this.document});
  final LegalDocument document;

  @override
  State<LegalDocumentPage> createState() => _LegalDocumentPageState();
}

class _LegalDocumentPageState extends State<LegalDocumentPage> {
  final _scroll = ScrollController();
  bool _reachedEnd = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_checkEnd);
    // 短くて最初から全部見えている場合も、読み終えた扱いにする。
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkEnd());
  }

  void _checkEnd() {
    if (_reachedEnd || !_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 24) {
      setState(() => _reachedEnd = true);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Expanded(
                  child: Scrollbar(
                    controller: _scroll,
                    child: SingleChildScrollView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            key: const ValueKey('legal-draft-banner'),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '仮の文面です。正式な本文は、公開前に専門家の確認を受けて差し替えます。',
                              style: TextStyle(fontSize: 12, height: 1.6),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            document.summary,
                            style: const TextStyle(height: 1.7),
                          ),
                          for (final section in document.sections) ...[
                            const SizedBox(height: 20),
                            Text(
                              section.heading,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              section.body,
                              style: const TextStyle(height: 1.8),
                            ),
                          ],
                          const SizedBox(height: 24),
                          const Text(
                            '以上',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_reachedEnd)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            '最後までスクロールすると、「同意する」を押せます。',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, height: 1.6),
                          ),
                        ),
                      FilledButton(
                        key: const ValueKey('legal-done'),
                        onPressed: _reachedEnd
                            ? () => Navigator.of(context).pop(true)
                            : null,
                        child: const Text('同意する'),
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
}
