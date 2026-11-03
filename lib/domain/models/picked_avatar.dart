import 'dart:typed_data';

/// 選んだアカウント画像が、送れないものだったとき([message]は利用者向け)。
class AvatarPickException implements Exception {
  const AvatarPickException(this.message);
  final String message;

  @override
  String toString() => 'AvatarPickException: $message';
}

/// アップロードするアカウント画像。形式はJPEG・PNG・WebP、サーバーの受付は2MBまで
/// (kosodate-hitoiki-backend docs/API契約.md 2節。縮小はアプリ側で済ませる)。
class PickedAvatar {
  const PickedAvatar._(this.bytes, this.contentType);

  final Uint8List bytes;
  final String contentType;

  static const maxBytes = 2 * 1024 * 1024;

  /// 画像のバイト列から作る。形式は先頭のバイト列で判定する(サーバーも、Content-Typeと
  /// 中身が合わないものは断る)。対応外の形式・大きすぎる画像は[AvatarPickException]。
  factory PickedAvatar.fromBytes(Uint8List bytes) {
    final type = detectContentType(bytes);
    if (type == null) {
      throw const AvatarPickException(
        'この形式の画像は使えません。JPEG・PNG・WebPの画像を選んでください。',
      );
    }
    if (bytes.length > maxBytes) {
      throw const AvatarPickException('画像が大きすぎます。2MB以下の画像を選んでください。');
    }
    return PickedAvatar._(bytes, type);
  }

  /// JPEG・PNG・WebPのどれかなら、そのContent-Type。それ以外は`null`。
  static String? detectContentType(Uint8List b) {
    bool starts(List<int> sig, [int offset = 0]) {
      if (b.length < offset + sig.length) return false;
      for (var i = 0; i < sig.length; i++) {
        if (b[offset + i] != sig[i]) return false;
      }
      return true;
    }

    if (starts([0xFF, 0xD8, 0xFF])) return 'image/jpeg';
    if (starts([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
      return 'image/png';
    }
    // WebP: "RIFF" + サイズ(4バイト) + "WEBP"
    if (starts([0x52, 0x49, 0x46, 0x46]) &&
        starts([0x57, 0x45, 0x42, 0x50], 8)) {
      return 'image/webp';
    }
    return null;
  }
}
