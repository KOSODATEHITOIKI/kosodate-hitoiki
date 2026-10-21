import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/api/api_exception.dart';
import 'package:kosodate_hitoiki/domain/models/post.dart';
import 'package:kosodate_hitoiki/presentation/pages/compose/compose_review_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/support/support_resources_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/post_providers.dart';

import 'helpers/scripted_post_repository.dart';

const _body = '今日は少し疲れた。';

/// 確認画面を、別の画面から開いて、閉じたときの戻り値を[result]に入れる。
Future<void> pumpReview(
  WidgetTester tester,
  ScriptedPostRepository repository, {
  List<bool?>? result,
  double scale = 1,
  Size size = const Size(390, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [postRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  final posted = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => const ComposeReviewPage(
                        body: _body,
                        postType: PostType.consult,
                        responseMode: ResponseMode.advice,
                      ),
                    ),
                  );
                  result?.add(posted);
                },
                child: const Text('開く'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('開く'));
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  // 画面外のボタンは遅延構築されるので、見えるまでスクロールしてから押す。
  await tester.scrollUntilVisible(
    find.byKey(ValueKey(key)),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('投稿できたら、内容をAPIへ送り、成功画面から「ホームへ」で閉じる', (tester) async {
    final repository = ScriptedPostRepository([created()]);
    final result = <bool?>[];
    await pumpReview(tester, repository, result: result);

    expect(find.text(_body), findsOneWidget);
    expect(find.text('相談'), findsOneWidget);
    await tapKey(tester, 'compose-send');

    expect(repository.calls, hasLength(1));
    final call = repository.calls.single;
    expect(call.type, PostType.consult);
    expect(call.responseMode, ResponseMode.advice);
    expect(call.body, _body);
    expect(call.confirmed, isFalse);
    expect(call.key, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(find.text('投稿しました。'), findsOneWidget);
    expect(find.byKey(const ValueKey('support-notice')), findsNothing);

    await tapKey(tester, 'compose-done');
    expect(result, [true]);
  });

  testWidgets('成功後に戻る操作をしても「投稿できた」を返す', (tester) async {
    final repository = ScriptedPostRepository([created()]);
    final result = <bool?>[];
    await pumpReview(tester, repository, result: result);
    await tapKey(tester, 'compose-send');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(result, [true]);
  });

  testWidgets('相談先の案内(support_notice)は、本人にだけ出し、投稿は止めない', (tester) async {
    final repository = ScriptedPostRepository([created(supportNotice: true)]);
    await pumpReview(tester, repository);
    await tapKey(tester, 'compose-send');

    expect(find.byKey(const ValueKey('support-notice')), findsOneWidget);
    expect(find.text('投稿しました。'), findsOneWidget);
    await tester.tap(find.text('困ったときの相談先'));
    await tester.pumpAndSettle();
    expect(find.byType(SupportResourcesPage), findsOneWidget);
  });

  testWidgets('確認が必要なときは確認を出し、「そのまま投稿する」で confirmed:true・新しいキーで再送する', (
    tester,
  ) async {
    final repository = ScriptedPostRepository([
      const ApiException(
        code: 'MODERATION_CONFIRM_REQUIRED',
        message: '強い言葉が含まれています。',
        status: 409,
      ),
      created(),
    ]);
    await pumpReview(tester, repository);
    await tapKey(tester, 'compose-send');

    expect(find.byKey(const ValueKey('compose-confirm')), findsOneWidget);
    expect(find.text('強い言葉が含まれています。'), findsOneWidget);
    expect(find.text('そのまま投稿する'), findsOneWidget);
    expect(find.text('投稿しました。'), findsNothing);

    await tapKey(tester, 'compose-send');
    expect(repository.calls, hasLength(2));
    expect(repository.calls[0].confirmed, isFalse);
    expect(repository.calls[1].confirmed, isTrue);
    expect(repository.calls[1].key, isNot(repository.calls[0].key));
    expect(find.text('投稿しました。'), findsOneWidget);
  });

  testWidgets('確認後の送信が通信の失敗になっても、再試行は同じキーで送る(二重投稿を防ぐ)', (tester) async {
    final repository = ScriptedPostRepository([
      const ApiException(
        code: 'MODERATION_CONFIRM_REQUIRED',
        message: '確認してください。',
        status: 409,
      ),
      Exception('network'),
      Exception('network again'),
      created(),
    ]);
    await pumpReview(tester, repository);
    await tapKey(tester, 'compose-send'); // 確認が出る
    await tapKey(tester, 'compose-send'); // そのまま投稿 → 通信の失敗
    expect(find.byKey(const ValueKey('compose-error')), findsOneWidget);
    await tapKey(tester, 'compose-send'); // 再試行 → また失敗
    await tapKey(tester, 'compose-send'); // 再試行 → 成功

    expect(repository.calls, hasLength(4));
    final confirmedKeys = repository.calls.skip(1).map((c) => c.key).toSet();
    // 確認後の3回は、すべて同じキー。確認前のキーとは別。
    expect(confirmedKeys, hasLength(1));
    expect(confirmedKeys.single, isNot(repository.calls.first.key));
    expect(repository.calls.skip(1).every((c) => c.confirmed), isTrue);
    expect(find.text('投稿しました。'), findsOneWidget);
  });

  testWidgets('送信中は戻れず、終わると結果(成功画面)が出る', (tester) async {
    final completer = Completer<CreatedPost>();
    final repository = ScriptedPostRepository([() => completer.future]);
    final result = <bool?>[];
    await pumpReview(tester, repository, result: result);

    await tester.tap(find.byKey(const ValueKey('compose-send')));
    await tester.pump();
    expect(find.text('送信しています…'), findsOneWidget);

    // 送信中に戻る操作をしても、画面は閉じない。
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ComposeReviewPage), findsOneWidget);
    expect(result, isEmpty);

    completer.complete(created());
    await tester.pumpAndSettle();
    expect(find.text('投稿しました。'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(result, [true]);
  });

  testWidgets('送信不可のときは理由を出し、送るボタンはなく、書き直せる', (tester) async {
    final repository = ScriptedPostRepository([
      const ApiException(
        code: 'MODERATION_REJECTED',
        message: '',
        status: 422,
        details: {
          'reasons': ['pii_phone'],
        },
      ),
    ]);
    await pumpReview(tester, repository);
    await tapKey(tester, 'compose-send');

    expect(find.text('この内容では送信できません。'), findsOneWidget);
    expect(find.textContaining('個人が特定される情報'), findsOneWidget);
    expect(find.byKey(const ValueKey('compose-send')), findsNothing);
    await tapKey(tester, 'compose-rewrite');
    expect(find.byType(ComposeReviewPage), findsNothing);
  });

  testWidgets('通信の失敗は表示し、再送は同じキーで行う(二重投稿を防ぐ)', (tester) async {
    final repository = ScriptedPostRepository([
      Exception('network'),
      created(),
    ]);
    await pumpReview(tester, repository);
    await tapKey(tester, 'compose-send');
    expect(find.byKey(const ValueKey('compose-error')), findsOneWidget);
    expect(find.text('投稿しました。'), findsNothing);

    await tapKey(tester, 'compose-send');
    expect(repository.calls, hasLength(2));
    expect(repository.calls[1].key, repository.calls[0].key);
    expect(find.text('投稿しました。'), findsOneWidget);
  });

  for (final item in <(String, ApiException, String)>[
    (
      '503',
      const ApiException(
        code: 'MODERATION_UNAVAILABLE',
        message: '',
        status: 503,
      ),
      '確認の仕組みが一時的に使えません。しばらくしてから、もう一度お試しください。',
    ),
    (
      'プロフィール未登録',
      const ApiException(
        code: 'FORBIDDEN',
        message: '',
        status: 403,
        details: {'reason': 'profile_required'},
      ),
      'プロフィールの登録が必要です。ログインし直して、ニックネームを登録してください。',
    ),
    (
      '利用停止中',
      const ApiException(
        code: 'FORBIDDEN',
        message: '',
        status: 403,
        details: {'reason': 'restricted'},
      ),
      '現在、投稿やコメントができません。',
    ),
  ]) {
    testWidgets('${item.$1}のときは、案内を出し、確認や成功の画面にはならない', (tester) async {
      final repository = ScriptedPostRepository([item.$2]);
      await pumpReview(tester, repository);
      await tapKey(tester, 'compose-send');
      expect(find.text(item.$3), findsOneWidget);
      expect(find.byKey(const ValueKey('compose-confirm')), findsNothing);
      expect(find.text('投稿しました。'), findsNothing);
    });
  }

  testWidgets('投稿の回数制限は、解除の目安の時刻を出す', (tester) async {
    final repository = ScriptedPostRepository([
      const ApiException(
        code: 'RATE_LIMITED',
        message: '',
        status: 429,
        details: {
          'reason': 'new_user_limit',
          'retry_at': '2030-01-02T03:04:00',
        },
      ),
    ]);
    await pumpReview(tester, repository);
    await tapKey(tester, 'compose-send');
    expect(find.textContaining('1月2日 3:04ごろまでお待ちください'), findsOneWidget);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('320px文字$scale倍でも、投稿の流れを最後まで操作できる', (tester) async {
      final repository = ScriptedPostRepository([created(supportNotice: true)]);
      await pumpReview(
        tester,
        repository,
        scale: scale,
        size: const Size(320, 700),
      );
      await tapKey(tester, 'compose-send');
      expect(find.byKey(const ValueKey('support-notice')), findsOneWidget);
      await tapKey(tester, 'compose-done');
      expect(tester.takeException(), isNull);
    });
  }
}
