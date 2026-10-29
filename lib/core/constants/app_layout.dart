/// パソコン向けの広い画面(幅1024px以上)の、3列の寸法。
/// 左メニュー・中央・右の補足のカード。狭い画面(スマホ)では使わない。
class AppLayout {
  AppLayout._();

  /// この幅以上を、パソコン向けにする。
  static const desktopBreakpoint = 1024.0;

  /// 左メニューの幅。
  static const sidebarWidth = 248.0;

  /// 中央(投稿や各画面)の最大の幅。
  static const centerMaxWidth = 720.0;

  /// 右の補足のカードの幅。
  static const rightPanelWidth = 320.0;

  /// 右の補足のカードを出す、いちばん狭い幅(これ未満は、左メニュー+中央だけ)。
  static const rightPanelMinWidth = 1280.0;

  static bool isDesktop(double width) => width >= desktopBreakpoint;
}
