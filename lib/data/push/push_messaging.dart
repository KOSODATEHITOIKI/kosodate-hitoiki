import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// 通知をタップしてアプリを開いたときの内容。プッシュには、種類と通知IDだけが入る
/// (本文などは含まない。kosodate-hitoiki-backend docs/API契約.md 8節)。
class PushTap {
  const PushTap({this.notificationId, this.type});

  final String? notificationId;
  final String? type;
}

/// プッシュ通知の端末側(FCM)の窓口。設定ファイルがなく使えないときは、[NoopPushMessaging]。
abstract class PushMessaging {
  /// 使えるか(Firebaseの設定が入っているか)。
  bool get isAvailable;

  /// 通知の許可を求める。許可されたら`true`。
  Future<bool> requestPermission();

  /// この端末のFCMトークン。取得できなければ`null`。
  Future<String?> getToken();

  /// トークンが変わったとき。
  Stream<String> get onTokenRefresh;

  /// 通知をタップして、アプリを開いたとき(起動中・背景から)。
  Stream<PushTap> get onTap;

  /// アプリが前面にあるときに、通知が届いたとき(端末の通知欄には、出ない)。
  Stream<PushTap> get onForeground;

  /// 通知をタップして、アプリを起動したとき(その1回)。なければ`null`。
  Future<PushTap?> getInitialTap();
}

/// 使えないとき(設定ファイルがない、テスト)。何もしない。
class NoopPushMessaging implements PushMessaging {
  const NoopPushMessaging();

  @override
  bool get isAvailable => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<PushTap> get onTap => const Stream.empty();

  @override
  Stream<PushTap> get onForeground => const Stream.empty();

  @override
  Future<PushTap?> getInitialTap() async => null;
}

/// Firebase Cloud Messagingを使う実装。
class FirebasePushMessaging implements PushMessaging {
  FirebasePushMessaging({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  /// Firebaseを初期化し、使えれば[FirebasePushMessaging]、使えなければ[NoopPushMessaging]。
  /// 設定ファイル(google-services.json)がないと失敗する。そのときも、アプリは動かす。
  static Future<PushMessaging> initialize() async {
    try {
      await Firebase.initializeApp();
      return FirebasePushMessaging();
    } catch (_) {
      return const NoopPushMessaging();
    }
  }

  @override
  bool get isAvailable => true;

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<PushTap> get onTap => FirebaseMessaging.onMessageOpenedApp.map(_tapOf);

  @override
  Stream<PushTap> get onForeground => FirebaseMessaging.onMessage.map(_tapOf);

  @override
  Future<PushTap?> getInitialTap() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _tapOf(message);
  }

  static PushTap _tapOf(RemoteMessage message) => PushTap(
    notificationId: message.data['notification_id'] as String?,
    type: message.data['type'] as String?,
  );
}
