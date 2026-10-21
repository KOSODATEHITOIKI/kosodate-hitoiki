import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/presentation/pages/auth/auth_validators.dart';

void main() {
  group('nicknameProblem', () {
    test('空・1文字・範囲外は、足りないことを案内する', () {
      expect(nicknameProblem(''), 'ニックネームを入力してください。');
      expect(nicknameProblem('  '), 'ニックネームを入力してください。');
      expect(nicknameProblem('あ'), 'あと1文字必要です。(2〜12文字)');
      expect(nicknameProblem('あ' * 13), '12文字以内にしてください。');
    });

    test('2〜12文字は問題なし(絵文字は見た目の1文字)', () {
      expect(nicknameProblem('はな'), isNull);
      expect(nicknameProblem('あ' * 12), isNull);
      expect(nicknameProblem('👨‍👩‍👧'), 'あと1文字必要です。(2〜12文字)');
      expect(nicknameProblem('👨‍👩‍👧a'), isNull);
    });
  });

  group('emailProblem', () {
    test('足りない部分を具体的に案内する', () {
      expect(emailProblem(''), 'メールアドレスを入力してください。');
      expect(emailProblem('abc'), contains('「@」を含めてください'));
      expect(emailProblem('@example.com'), contains('「@」の前'));
      expect(emailProblem('a@'), contains('ドメイン'));
      expect(emailProblem('a@example'), contains('「.」でつないで'));
      expect(emailProblem('a@b@c.com'), contains('1つだけ'));
      expect(emailProblem('a b@example.com'), '空白は使えません。');
    });

    test('正しい形式は問題なし(前後の空白は無視)', () {
      expect(emailProblem('a@example.com'), isNull);
      expect(emailProblem(' a@example.co.jp '), isNull);
    });
  });

  test('passwordProblem は空欄だけを見る(条件は未決定のため決めない)', () {
    expect(passwordProblem(''), 'パスワードを入力してください。');
    expect(passwordProblem('a'), isNull);
  });
}
