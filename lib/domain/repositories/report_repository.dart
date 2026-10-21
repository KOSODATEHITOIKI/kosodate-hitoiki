import '../models/report.dart';

/// 投稿・コメントの通報の抽象。バックエンド接続時はSupabase実装に差し替える。
abstract class ReportRepository {
  /// サンプルか。trueの間、画面に「サンプルです。送信されません」の注記を出す。
  bool get isSample;

  /// 通報を送る。[targetType]は`post`か`comment`。[detail]は、任意の補足(200文字まで)。
  /// 通報したことは、通報された側にも、ほかの利用者にも知らせない。
  Future<ReportResult> submitReport({
    required String targetType,
    required String targetId,
    required ReportReason reason,
    String detail = '',
  });
}
