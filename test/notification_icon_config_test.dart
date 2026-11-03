import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// プッシュ通知の見た目の設定(Android)。指定が抜けると、通知のアイコンが、
/// Flutterの初期のアイコン(白い丸)に戻る。
void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();

  test('通知のアイコンと色を、指定している', () {
    expect(
      manifest,
      contains('com.google.firebase.messaging.default_notification_icon'),
    );
    expect(manifest, contains('@drawable/ic_stat_hitoiki'));
    expect(
      manifest,
      contains('com.google.firebase.messaging.default_notification_color'),
    );
    expect(manifest, contains('@color/ic_notification_color'));
  });

  test('指定したアイコン・色の資源が、ある。アイコンは、白一色(形だけが使われる)', () {
    final icon = File(
      'android/app/src/main/res/drawable/ic_stat_hitoiki.xml',
    ).readAsStringSync();
    expect(icon, contains('<vector'));
    // 白以外の色は、使っていない(通知のアイコンは、形だけが使われ、色は塗られる)。
    final colors = RegExp(
      r'#[0-9A-Fa-f]{8}',
    ).allMatches(icon).map((m) => m.group(0)!.toUpperCase()).toSet();
    expect(colors, {'#FFFFFFFF'});

    final color = File(
      'android/app/src/main/res/values/ic_notification_color.xml',
    ).readAsStringSync();
    expect(color, contains('name="ic_notification_color"'));
  });
}
