import '../../core/constants/app_icons.dart';

/// 共感の定型文(運営が用意した少数の種類。1人が1つの投稿に1つ選ぶ)。
/// 「共感ボタン」は、`empathy`(わかる)をそのまま押す形(バックエンド docs/API契約.md 3節)。
class ReactionType {
  const ReactionType({
    required this.id,
    required this.code,
    required this.label,
  });

  final int id;

  /// 画面のアイコンと結びつける固定の名前(文言を直しても変わらない)。
  final String code;

  /// 画面に出す文言(運営が直せる)。
  final String label;

  /// 共感ボタンに当たる定型文か。
  bool get isEmpathy => code == empathyCode;

  /// 画面に出すアイコン。
  String get asset => AppReactions.forCode(code);

  static const empathyCode = 'empathy';
}
