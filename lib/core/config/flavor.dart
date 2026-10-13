/// アプリの実行環境。
enum Flavor { dev, prod }

/// main_dev/prod.dartが起動時にsetFlavor()で確定させる。
class AppConfig {
  AppConfig._();

  static Flavor? _flavor;

  static Flavor get flavor {
    final flavor = _flavor;
    assert(flavor != null, 'AppConfig.setFlavor() が呼ばれていません');
    return flavor ?? Flavor.dev;
  }

  static void setFlavor(Flavor flavor) => _flavor = flavor;

  static String get appName {
    switch (flavor) {
      case Flavor.dev:
        return 'ひと息(dev)';
      case Flavor.prod:
        return 'ひと息';
    }
  }
}
