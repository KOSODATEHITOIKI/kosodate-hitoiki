import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/child_age_range.dart';

void main() {
  test('サーバーが受け付ける5つのコードと、画面の名前', () {
    expect(
      {for (final range in ChildAgeRange.values) range.code: range.label},
      {
        'age_0_1': '0〜1歳',
        'age_2_3': '2〜3歳',
        'age_4_6': '4〜6歳(未就学)',
        'elementary': '小学生',
        'junior_high_plus': '中学生以上',
      },
    );
  });

  test('コードから求める。決まった値以外は、未設定', () {
    expect(ChildAgeRange.fromCode('elementary'), ChildAgeRange.elementary);
    expect(ChildAgeRange.fromCode('乳児'), isNull);
    expect(ChildAgeRange.fromCode(null), isNull);
    expect(ChildAgeRange.labelFor('age_2_3'), '2〜3歳');
    expect(ChildAgeRange.labelFor('???'), '未設定');
    expect(ChildAgeRange.labelFor(null), '未設定');
  });
}
