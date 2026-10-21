/// いちばん下のお子さんの年齢帯。サーバーに送る値(コード)は、決まった5つだけで、
/// それ以外は`422`(kosodate-hitoiki-backend docs/API契約.md 2節。2026-10-21確定)。
/// 画面に出す名前はアプリが持つ。
enum ChildAgeRange {
  age01('age_0_1', '0〜1歳'),
  age23('age_2_3', '2〜3歳'),
  age46('age_4_6', '4〜6歳(未就学)'),
  elementary('elementary', '小学生'),
  juniorHighPlus('junior_high_plus', '中学生以上');

  const ChildAgeRange(this.code, this.label);

  /// サーバーに送る値。
  final String code;

  /// 画面に出す名前。
  final String label;

  /// コードから求める。決まった値でなければ`null`。
  static ChildAgeRange? fromCode(String? code) {
    for (final range in values) {
      if (range.code == code) return range;
    }
    return null;
  }

  /// コードの画面表示。未設定・未知のコードは「未設定」。
  static String labelFor(String? code) => fromCode(code)?.label ?? '未設定';
}
