import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/data/models/moderation_result.dart';
import 'package:kosodate_hitoiki/data/repositories/content_moderation_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

void main() {
  late MockSupabaseClient client;
  late MockFunctionsClient functions;
  late ContentModerationRepository repository;

  setUp(() {
    client = MockSupabaseClient();
    functions = MockFunctionsClient();
    when(() => client.functions).thenReturn(functions);
    repository = ContentModerationRepository(client);

    registerFallbackValue(<String, dynamic>{});
  });

  test('allow判定を正しくパースする', () async {
    when(
      () => functions.invoke('check-content', body: any(named: 'body')),
    ).thenAnswer(
      (_) async =>
          const FunctionResponse(data: {'verdict': 'allow'}, status: 200),
    );

    final result = await repository.check('今日はいい天気');

    expect(result.verdict, ModerationVerdict.allow);
    expect(result.reason, isNull);
    expect(result.supportMessageRequired, isFalse);
  });

  test('confirm判定を正しくパースする', () async {
    when(
      () => functions.invoke('check-content', body: any(named: 'body')),
    ).thenAnswer(
      (_) async =>
          const FunctionResponse(data: {'verdict': 'confirm'}, status: 200),
    );

    final result = await repository.check('本当にありえない');

    expect(result.verdict, ModerationVerdict.confirm);
  });

  test('block判定はreasonも受け取る', () async {
    when(
      () => functions.invoke('check-content', body: any(named: 'body')),
    ).thenAnswer(
      (_) async => const FunctionResponse(
        data: {'verdict': 'block', 'reason': '名前など個人情報が含まれています'},
        status: 200,
      ),
    );

    final result = await repository.check('田中さんが言ってた');

    expect(result.verdict, ModerationVerdict.block);
    expect(result.reason, '名前など個人情報が含まれています');
  });

  test('危害をほのめかす内容はsupportMessageRequiredがtrueになる', () async {
    when(
      () => functions.invoke('check-content', body: any(named: 'body')),
    ).thenAnswer(
      (_) async => const FunctionResponse(
        data: {'verdict': 'allow', 'supportMessageRequired': true},
        status: 200,
      ),
    );

    final result = await repository.check('消えたい');

    expect(result.verdict, ModerationVerdict.allow);
    expect(result.supportMessageRequired, isTrue);
  });

  test('送信するテキストをそのままFunctionに渡す', () async {
    when(
      () => functions.invoke('check-content', body: any(named: 'body')),
    ).thenAnswer(
      (_) async =>
          const FunctionResponse(data: {'verdict': 'allow'}, status: 200),
    );

    await repository.check('寝かしつけがつらい');

    verify(
      () => functions.invoke('check-content', body: {'text': '寝かしつけがつらい'}),
    ).called(1);
  });
}
