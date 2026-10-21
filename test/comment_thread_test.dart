import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/api/api_exception.dart';
import 'package:kosodate_hitoiki/data/mock/mock_post_repository.dart';
import 'package:kosodate_hitoiki/domain/models/comment.dart';
import 'package:kosodate_hitoiki/presentation/pages/post_detail/post_detail_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/support/support_resources_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/comment_providers.dart';
import 'package:kosodate_hitoiki/presentation/widgets/comment_thread.dart';

import 'helpers/scripted_comment_repository.dart';

Future<void> pumpThread(
  WidgetTester tester,
  ScriptedCommentRepository repository, {
  bool accepting = true,
}) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        isLoggedInProvider.overrideWithValue(true),
        commentRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: CommentThread(postId: 'p-1', accepting: accepting),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> typeComment(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('320px・文字$scale倍でコメント・返信を送り、一覧に出る', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final post = (await MockPostRepository().fetchFeed()).firstWhere(
        (post) => post.id == 'p2',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [isLoggedInProvider.overrideWithValue(true)],
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: PostDetailPage(post: post, focusComments: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ありがとう、試してみます。'), findsOneWidget);
      expect(find.text('はなさんに返信'), findsNothing);
      await tester.ensureVisible(find.text('こもれびさんに返信'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('こもれびさんに返信'));
      await tester.pumpAndSettle();
      expect(find.text('こもれびさんへの返信'), findsOneWidget);
      await tester.ensureVisible(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '送信'))
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextField), 'うちの場合は');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('送信'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('送信'));
      await tester.pumpAndSettle();
      // 送れたら、入力は空になり、一覧に自分のコメントが増える。
      expect(find.text('うちの場合は'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.text('コメントを書く'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).maxLength, 500);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('コメントと返信を、親の下に並べる。削除済み・編集済みも表示する', (tester) async {
    final repository = ScriptedCommentRepository(
      comments: [
        comment('c1', 'はな', 'こんにちは'),
        comment('r1', 'みみ', '返信です', parentId: 'c1'),
        comment('c2', 'ゆき', null, isDeleted: true),
        comment('c3', 'さくら', '直しました', isEdited: true),
        comment('o1', 'もも', '親が見えない返信', parentId: 'hidden'),
      ],
    );
    await pumpThread(tester, repository);

    expect(find.text('こんにちは'), findsOneWidget);
    expect(find.text('返信です'), findsOneWidget);
    expect(find.text('削除済み'), findsOneWidget);
    expect(find.text('編集済み'), findsOneWidget);
    expect(find.text('親が見えない返信'), findsOneWidget);
    // 返信への返信は不可。削除済みには、返信ボタンも通報も出ない。
    expect(find.text('みみさんに返信'), findsNothing);
    expect(find.text('ゆきさんに返信'), findsNothing);
    expect(find.byTooltip('ゆきさんのコメントを通報'), findsNothing);
    expect(find.text('はなさんに返信'), findsOneWidget);
  });

  testWidgets('送れたら、内容と返信先をAPIへ送り、入力を空にする', (tester) async {
    final repository = ScriptedCommentRepository(
      comments: [comment('c1', 'はな', 'こんにちは')],
      script: [createdComment()],
    );
    await pumpThread(tester, repository);
    await tester.tap(find.text('はなさんに返信'));
    await tester.pumpAndSettle();
    await typeComment(tester, '  わかります  ');
    await tapKey(tester, 'comment-send');

    expect(repository.calls, hasLength(1));
    final call = repository.calls.single;
    expect(call.postId, 'p-1');
    expect(call.parentId, 'c1');
    expect(call.body.trim(), 'わかります');
    expect(call.confirmed, isFalse);
    expect(call.key, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.text('はなさんへの返信'), findsNothing);
  });

  testWidgets('確認が必要なときは確認を出し、「そのまま送る」で同じキー・confirmed:trueで再送する', (
    tester,
  ) async {
    final repository = ScriptedCommentRepository(
      script: [
        const ApiException(
          code: 'MODERATION_CONFIRM_REQUIRED',
          message: '強い言葉が含まれています。',
          status: 409,
        ),
        createdComment(),
      ],
    );
    await pumpThread(tester, repository);
    await typeComment(tester, 'ありえない');
    await tapKey(tester, 'comment-send');

    expect(find.byKey(const ValueKey('comment-confirm')), findsOneWidget);
    expect(find.text('強い言葉が含まれています。'), findsOneWidget);
    // 確認中も、入力は残っている。
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'ありえない',
    );

    await tapKey(tester, 'comment-send-anyway');
    expect(repository.calls, hasLength(2));
    expect(repository.calls[0].confirmed, isFalse);
    expect(repository.calls[1].confirmed, isTrue);
    expect(repository.calls[1].key, repository.calls[0].key);
    expect(find.byKey(const ValueKey('comment-confirm')), findsNothing);
  });

  testWidgets('送信不可のときは理由を出し、送るボタンはなく、入力を直すと送れる', (tester) async {
    final repository = ScriptedCommentRepository(
      script: [
        const ApiException(
          code: 'MODERATION_REJECTED',
          message: '',
          status: 422,
          details: {
            'reasons': ['pii_phone'],
          },
        ),
        createdComment(),
      ],
    );
    await pumpThread(tester, repository);
    await typeComment(tester, '090-0000-0000');
    await tapKey(tester, 'comment-send');

    expect(find.text('この内容では送信できません。'), findsOneWidget);
    expect(find.textContaining('個人が特定される情報'), findsOneWidget);
    expect(find.byKey(const ValueKey('comment-send')), findsNothing);

    // 書き直すと、新しい送信として、送れる(キーも新しい)。
    await typeComment(tester, 'ご連絡ください');
    await tapKey(tester, 'comment-send');
    expect(repository.calls, hasLength(2));
    expect(repository.calls[1].key, isNot(repository.calls[0].key));
  });

  testWidgets('通信の失敗は表示し、再試行は同じキーで送る(二重投稿を防ぐ)', (tester) async {
    final repository = ScriptedCommentRepository(
      script: [Exception('network'), createdComment()],
    );
    await pumpThread(tester, repository);
    await typeComment(tester, 'こんにちは');
    await tapKey(tester, 'comment-send');
    expect(find.byKey(const ValueKey('comment-error')), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'こんにちは',
    );

    await tapKey(tester, 'comment-send');
    expect(repository.calls, hasLength(2));
    expect(repository.calls[1].key, repository.calls[0].key);
    expect(find.byKey(const ValueKey('comment-error')), findsNothing);
  });

  testWidgets('相談先の案内(support_notice)は、本人にだけ出し、コメントは止めない', (tester) async {
    final repository = ScriptedCommentRepository(
      script: [createdComment(supportNotice: true)],
    );
    await pumpThread(tester, repository);
    await typeComment(tester, 'つらい');
    await tapKey(tester, 'comment-send');

    expect(
      find.byKey(const ValueKey('comment-support-notice')),
      findsOneWidget,
    );
    await tester.tap(find.text('困ったときの相談先'));
    await tester.pumpAndSettle();
    expect(find.byType(SupportResourcesPage), findsOneWidget);
  });

  for (final item in <(String, ApiException, String)>[
    (
      '受付終了',
      const ApiException(
        code: 'FORBIDDEN',
        message: '',
        status: 403,
        details: {'reason': 'comments_closed'},
      ),
      'この投稿は、コメントの受付を終了しています。',
    ),
    (
      'ブロック(理由を推測させない)',
      const ApiException(
        code: 'FORBIDDEN',
        message: '',
        status: 403,
        details: {'reason': 'unavailable'},
      ),
      '送れませんでした。しばらくしてから、もう一度お試しください。',
    ),
  ]) {
    testWidgets('${item.$1}のときは、案内を出す', (tester) async {
      final repository = ScriptedCommentRepository(script: [item.$2]);
      await pumpThread(tester, repository);
      await typeComment(tester, 'こんにちは');
      await tapKey(tester, 'comment-send');
      expect(find.text(item.$3), findsOneWidget);
      expect(find.textContaining('ブロック'), findsNothing);
    });
  }

  testWidgets('送信中は、二重に送れない', (tester) async {
    final completer = Completer<CreatedComment>();
    final repository = ScriptedCommentRepository(
      script: [() => completer.future],
    );
    await pumpThread(tester, repository);
    await typeComment(tester, 'こんにちは');

    await tester.tap(find.byKey(const ValueKey('comment-send')));
    await tester.pump();
    expect(find.text('送信しています…'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('comment-send')))
          .onPressed,
      isNull,
    );

    completer.complete(createdComment());
    await tester.pumpAndSettle();
    expect(repository.calls, hasLength(1));
  });

  testWidgets('受付を終了した投稿は、入力欄と返信ボタンを出さない(既存コメントは残る)', (tester) async {
    final repository = ScriptedCommentRepository(
      comments: [comment('c1', 'はな', 'こんにちは')],
    );
    await pumpThread(tester, repository, accepting: false);
    expect(find.text('こんにちは'), findsOneWidget);
    expect(find.text('コメントの受付は終了しています。'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('はなさんに返信'), findsNothing);
  });
}
