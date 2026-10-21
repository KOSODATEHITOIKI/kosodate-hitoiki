import 'package:flutter_test/flutter_test.dart';
import 'package:kosodate_hitoiki/data/repositories/supabase_report_repository.dart';
import 'package:kosodate_hitoiki/domain/models/report.dart';

void main() {
  test('理由は6種で、APIの値になる', () {
    expect(
      {for (final reason in ReportReason.values) reason.code},
      {'harassment', 'personal_info', 'spam', 'copyright', 'danger', 'other'},
    );
  });

  group('requestBody', () {
    test('対象・理由・補足を、APIの形にする', () {
      expect(
        SupabaseReportRepository.requestBody(
          targetType: 'post',
          targetId: 'p-1',
          reason: ReportReason.personalInfo,
        ),
        {
          'target_type': 'post',
          'target_id': 'p-1',
          'reason': 'personal_info',
          'detail': '',
        },
      );
    });

    test('補足は、前後の空白を除き、200文字(絵文字は1文字)までにする', () {
      final body = SupabaseReportRepository.requestBody(
        targetType: 'comment',
        targetId: 'c-1',
        reason: ReportReason.other,
        detail: '  ${'あ' * 250}  ',
      );
      expect((body['detail'] as String).length, 200);
      final emoji = SupabaseReportRepository.requestBody(
        targetType: 'post',
        targetId: 'p-1',
        reason: ReportReason.other,
        detail: '👨‍👩‍👧' * 201,
      );
      expect(emoji['detail'], '👨‍👩‍👧' * 200);
    });
  });

  test('応答の duplicate を読む(なければ false)', () {
    expect(
      SupabaseReportRepository.resultFromResponse({
        'id': 'r-1',
        'duplicate': true,
      }).duplicate,
      isTrue,
    );
    final fresh = SupabaseReportRepository.resultFromResponse({
      'id': 'r-2',
      'duplicate': false,
    });
    expect(fresh.duplicate, isFalse);
    expect(fresh.id, 'r-2');
    expect(
      SupabaseReportRepository.resultFromResponse(null).duplicate,
      isFalse,
    );
  });
}
