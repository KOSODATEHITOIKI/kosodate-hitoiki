import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/core/constants/app_theme.dart';
import 'package:kosodate_hitoiki/data/api/api_exception.dart';
import 'package:kosodate_hitoiki/domain/models/report.dart';
import 'package:kosodate_hitoiki/presentation/pages/auth/auth_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/report/report_page.dart';
import 'package:kosodate_hitoiki/presentation/pages/support/support_resources_page.dart';
import 'package:kosodate_hitoiki/presentation/providers/auth_provider.dart';
import 'package:kosodate_hitoiki/presentation/providers/report_providers.dart';

import 'helpers/scripted_report_repository.dart';

Future<void> pumpReport(
  WidgetTester tester,
  ScriptedReportRepository repository, {
  ReportTargetType type = ReportTargetType.post,
  String targetId = 'p1',
  double scale = 1,
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        isLoggedInProvider.overrideWithValue(true),
        reportRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: ReportPage(targetId: targetId, targetType: type),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  await reveal(tester, find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await reveal(tester, find.byKey(ValueKey(key)));
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('通報フォーム幅$width・文字$scaleで、理由を選んで確認し、送れる', (tester) async {
        final repository = ScriptedReportRepository();
        await pumpReport(tester, repository, width: width, scale: scale);
        await reveal(tester, find.byKey(const ValueKey('report-submit')));
        // 理由を選ぶまでは、送れない。
        expect(
          tester
              .widget<FilledButton>(find.byKey(const ValueKey('report-submit')))
              .onPressed,
          isNull,
        );
        await tapText(tester, 'その他');
        await reveal(tester, find.byKey(const ValueKey('report-note')));
        await tester.enterText(
          find.byKey(const ValueKey('report-note')),
          '補足のサンプル',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tapKey(tester, 'report-submit');

        expect(find.text('この内容で通報しますか？'), findsOneWidget);
        expect(find.text('理由：その他'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('補足のサンプル'),
          ),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('report-confirm')));
        await tester.pumpAndSettle();

        expect(repository.calls, hasLength(1));
        expect(repository.calls.single.targetType, 'post');
        expect(repository.calls.single.targetId, 'p1');
        expect(repository.calls.single.reason, ReportReason.other);
        expect(repository.calls.single.detail, '補足のサンプル');
        expect(find.text('通報を受け付けました'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('コメントの通報は、target_type が comment。「その他」以外は補足を送らない', (tester) async {
    final repository = ScriptedReportRepository();
    await pumpReport(
      tester,
      repository,
      type: ReportTargetType.comment,
      targetId: 'c1',
    );
    await tapText(tester, '名前や個人情報');
    expect(find.byKey(const ValueKey('report-note')), findsNothing);
    await tapKey(tester, 'report-submit');
    await tester.tap(find.byKey(const ValueKey('report-confirm')));
    await tester.pumpAndSettle();

    final call = repository.calls.single;
    expect(call.targetType, 'comment');
    expect(call.targetId, 'c1');
    expect(call.reason, ReportReason.personalInfo);
    expect(call.detail, isEmpty);
  });

  testWidgets('確認で「やめる」と、送らない', (tester) async {
    final repository = ScriptedReportRepository();
    await pumpReport(tester, repository);
    await tapText(tester, '勧誘・宣伝・スパム');
    await tapKey(tester, 'report-submit');
    await tester.tap(find.text('やめる'));
    await tester.pumpAndSettle();
    expect(repository.calls, isEmpty);
    expect(find.text('通報する'), findsWidgets);
  });

  testWidgets('通報し直し(duplicate)は、「すでに通報しています」と伝える', (tester) async {
    final repository = ScriptedReportRepository(
      result: const ReportResult(id: 'r-1', duplicate: true),
    );
    await pumpReport(tester, repository);
    await tapText(tester, '誹謗中傷・攻撃的');
    await tapKey(tester, 'report-submit');
    await tester.tap(find.byKey(const ValueKey('report-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('すでに通報しています'), findsOneWidget);
    expect(find.textContaining('前の通報の内容のまま'), findsOneWidget);
    await tapKey(tester, 'report-back');
  });

  for (final item in <(String, ApiException, String)>[
    (
      '自分の投稿・コメント',
      const ApiException(
        code: 'FORBIDDEN',
        message: '',
        status: 403,
        details: {'reason': 'not_allowed'},
      ),
      '自分の投稿・コメントは、通報できません。',
    ),
    (
      '見つからない・見えない対象',
      const ApiException(code: 'NOT_FOUND', message: '', status: 404),
      '見つかりませんでした。すでに削除されているかもしれません。',
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
  ]) {
    testWidgets('${item.$1}の失敗は案内し、入力は残る', (tester) async {
      final repository = ScriptedReportRepository(error: item.$2);
      await pumpReport(tester, repository);
      await tapText(tester, '誹謗中傷・攻撃的');
      await tapKey(tester, 'report-submit');
      await tester.tap(find.byKey(const ValueKey('report-confirm')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const ValueKey('report-error')));
      expect(find.text(item.$3), findsOneWidget);
      expect(find.text('通報を受け付けました'), findsNothing);
      // 理由の選択は、そのまま残る(やり直せる)。
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('report-submit')))
            .onPressed,
        isNotNull,
      );
    });
  }

  testWidgets('「危険を感じる内容」を選ぶと、相談先を案内する(通報は止めない)', (tester) async {
    final repository = ScriptedReportRepository();
    await pumpReport(tester, repository);
    await tapText(tester, '危険を感じる内容');
    expect(find.byKey(const ValueKey('report-danger-note')), findsOneWidget);
    await tapText(tester, '困ったときの相談先');
    expect(find.byType(SupportResourcesPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapKey(tester, 'report-submit');
    await tester.tap(find.byKey(const ValueKey('report-confirm')));
    await tester.pumpAndSettle();
    expect(repository.calls.single.reason, ReportReason.danger);
  });

  testWidgets('利用者の通報は、APIが未対応なので、送らずに案内する', (tester) async {
    final repository = ScriptedReportRepository();
    await pumpReport(tester, repository, type: ReportTargetType.user);
    expect(
      find.byKey(const ValueKey('report-user-unsupported')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('report-submit')), findsNothing);
    expect(repository.calls, isEmpty);
  });

  testWidgets('サンプルのときだけ、「サンプルです」と注記する', (tester) async {
    await pumpReport(tester, ScriptedReportRepository(sample: true));
    await reveal(tester, find.byKey(const ValueKey('report-submit')));
    expect(find.text('サンプルです。実際には送信されません。'), findsOneWidget);
    await pumpReport(tester, ScriptedReportRepository());
    await reveal(tester, find.byKey(const ValueKey('report-submit')));
    expect(find.textContaining('サンプルです'), findsNothing);
  });

  testWidgets('直接開いてもゲストには通報理由や入力欄を出さない', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [isLoggedInProvider.overrideWithValue(false)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ReportPage(
            targetId: 'c1',
            targetType: ReportTargetType.comment,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RadioListTile<ReportReason>), findsNothing);
    expect(find.byType(TextField), findsNothing);
    await tester.ensureVisible(find.text('ログイン'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ログイン'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ReportPage), findsOneWidget);
  });
}
