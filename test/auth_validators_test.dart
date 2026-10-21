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

  group('passwordRegisterProblem(登録。dev の Supabase Auth の設定に合わせる)', () {
    test('足りないことをまとめて案内する', () {
      expect(passwordRegisterProblem(''), 'パスワードを入力してください。');
      expect(passwordRegisterProblem('a'), 'あと9文字・英大文字・数字が必要です。');
      expect(passwordRegisterProblem('abcdefghij'), '英大文字・数字が必要です。');
      expect(passwordRegisterProblem('ABCDEFGHIJ1'), '英小文字が必要です。');
      expect(passwordRegisterProblem('Abcdefghij'), '数字が必要です。');
      expect(passwordRegisterProblem('Abc12'), 'あと5文字が必要です。');
    });

    test('条件を満たせば問題なし', () {
      expect(passwordRegisterProblem('Password1234'), isNull);
      expect(passwordRegisterProblem('Abcdefghi1'), isNull);
    });
  });

  group('passwordConfirmProblem', () {
    test('空・不一致は案内し、一致すれば問題なし', () {
      expect(passwordConfirmProblem('Password1234', ''), '確認のため、もう一度入力してください。');
      expect(
        passwordConfirmProblem('Password1234', 'Password123'),
        'パスワードが一致しません。',
      );
      expect(passwordConfirmProblem('Password1234', 'Password1234'), isNull);
    });
  });

  test('passwordProblem(ログイン)は空欄だけを見る', () {
    expect(passwordProblem(''), 'パスワードを入力してください。');
    expect(passwordProblem('a'), isNull);
  });
}
