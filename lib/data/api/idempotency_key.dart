import 'dart:math';

final _random = Random.secure();

/// 作成系API(`Idempotency-Key`)に付けるUUID(v4)。同じキーでの再送は、最初の結果が
/// 返り、投稿やコメントが二重にならない。再送のときは、同じキーを使う
/// (kosodate-hitoiki-backend docs/API契約.md 1節)。
String newIdempotencyKey() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant
  String hex(int from, int to) => bytes
      .sublist(from, to)
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}
