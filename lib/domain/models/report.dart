/// 通報の理由(6種。`reason`の値はAPIの値。バックエンド docs/API契約.md 7節)。
enum ReportReason {
  harassment('harassment', '誹謗中傷・攻撃的'),
  personalInfo('personal_info', '名前や個人情報'),
  spam('spam', '勧誘・宣伝・スパム'),
  copyright('copyright', '他人の文章や画像の転載'),
  danger('danger', '危険を感じる内容'),
  other('other', 'その他');

  const ReportReason(this.code, this.label);

  /// APIに送る値。
  final String code;

  /// 画面に出す文言。
  final String label;
}

/// 通報の結果。同じ人が同じ対象を通報し直したときは[duplicate]がtrueで、
/// 件数は増えず、最初の理由が残る。
class ReportResult {
  const ReportResult({required this.id, this.duplicate = false});

  final String id;
  final bool duplicate;
}
