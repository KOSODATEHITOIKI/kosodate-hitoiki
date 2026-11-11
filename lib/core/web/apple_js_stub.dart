/// アプリでは、使わない。いつでも読み込み済みとして扱う。
bool get appleJsLoaded => true;

/// アプリでは、何もしない。
Future<void> preloadAppleJs() async {}
