/// 送信前チェックの判定結果(docs/全体設計書.md 5章)。
///
/// - allow: そのまま送信
/// - confirm: 「誰かを傷つける表現になっていませんか？」の確認表示
/// - block: 送信不可(理由を表示し書き直しを促す)
enum ModerationVerdict { allow, confirm, block }

/// [supportMessageRequired]は、自分や子どもへの危害をほのめかす内容を検出した場合に
/// trueになる(送信自体は止めず、本人にだけ相談先を案内するために使う)。
class ModerationResult {
  const ModerationResult({
    required this.verdict,
    this.reason,
    this.supportMessageRequired = false,
  });

  factory ModerationResult.fromJson(Map<String, dynamic> json) {
    return ModerationResult(
      verdict: ModerationVerdict.values.byName(json['verdict'] as String),
      reason: json['reason'] as String?,
      supportMessageRequired: json['supportMessageRequired'] as bool? ?? false,
    );
  }

  final ModerationVerdict verdict;
  final String? reason;
  final bool supportMessageRequired;
}
