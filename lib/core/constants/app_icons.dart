/// SVGアセットのパス定数(docs/design/svg-assets/README.md参照、2026-09-29確定)。
/// 表示には`AppAsset`を使う(.svgは`flutter_svg`、重い画像は.png)。
library;

/// アイコン(24×24、線幅2)。
class AppIcons {
  AppIcons._();

  static const _base = 'assets/icons';

  // ナビゲーション
  static const navHome = '$_base/icon-nav-home.svg';
  static const navSearch = '$_base/icon-nav-search.svg';
  static const navCompose = '$_base/icon-nav-compose.svg';
  static const navNotifications = '$_base/icon-nav-notifications.svg';
  static const navMyPage = '$_base/icon-nav-my-page.svg';

  // 操作
  static const bookmark = '$_base/icon-action-bookmark.svg';
  static const bookmarkSaved = '$_base/icon-action-bookmark-saved.svg';
  static const comment = '$_base/icon-action-comment.svg';
  static const reply = '$_base/icon-action-reply.svg';
  static const heart = '$_base/icon-action-heart.svg';
  static const send = '$_base/icon-action-send.svg';
  static const back = '$_base/icon-action-back.svg';
  static const next = '$_base/icon-action-next.svg';
  static const close = '$_base/icon-action-close.svg';
  static const add = '$_base/icon-action-add.svg';
  static const check = '$_base/icon-action-check.svg';
  static const edit = '$_base/icon-action-edit.svg';
  static const delete = '$_base/icon-action-delete.svg';
  static const refresh = '$_base/icon-action-refresh.svg';
  static const filter = '$_base/icon-action-filter.svg';
  static const chevronDown = '$_base/icon-action-chevron-down.svg';
  static const externalLink = '$_base/icon-action-external-link.svg';
  static const more = '$_base/icon-action-more.svg';

  // アカウント
  static const accountImage = '$_base/icon-account-image.svg';
  static const accountUpload = '$_base/icon-account-upload.svg';
  static const accountCrop = '$_base/icon-account-crop.svg';
  static const accountMail = '$_base/icon-account-mail.svg';
  static const accountLock = '$_base/icon-account-lock.svg';
  static const accountEye = '$_base/icon-account-eye.svg';
  static const accountEyeOff = '$_base/icon-account-eye-off.svg';
  static const accountLogout = '$_base/icon-account-logout.svg';
  static const accountDocument = '$_base/icon-account-document.svg';

  // 安全・安心
  static const safetyReport = '$_base/icon-safety-report.svg';
  static const safetyBlock = '$_base/icon-safety-block.svg';
  static const safetyMute = '$_base/icon-safety-mute.svg';
  static const safetyShield = '$_base/icon-safety-shield.svg';
  static const safetySupport = '$_base/icon-safety-support.svg';

  // ステータス・設定
  static const statusInfo = '$_base/icon-status-info.svg';
  static const statusWarning = '$_base/icon-status-warning.svg';
  static const statusLightbulb = '$_base/icon-status-lightbulb.svg';
  static const settingsNotificationsOff =
      '$_base/icon-settings-notifications-off.svg';
  static const settingsSliders = '$_base/icon-settings-sliders.svg';
  static const settingsGear = '$_base/icon-settings-gear.svg';
  static const settingsDevice = '$_base/icon-settings-device.svg';

  // ガイド・お知らせ
  static const guideBook = '$_base/icon-guide-book.svg';
  static const noticeMegaphone = '$_base/icon-notice-megaphone.svg';
}

/// 装飾モチーフ(240×240)。
class AppDecorations {
  AppDecorations._();

  static const _base = 'assets/decorations';

  static const sunSmiling = '$_base/decoration-sun-smiling.png';
  static const sunSimple = '$_base/decoration-sun-simple.png';
  static const leavesSprout = '$_base/decoration-leaves-sprout.svg';
  static const heartWarm = '$_base/decoration-heart-warm.svg';
  static const cloudSoft = '$_base/decoration-cloud-soft.svg';
  static const flowerCoral = '$_base/decoration-flower-coral.svg';
  static const sparkles = '$_base/decoration-sparkles.svg';
  static const tulip = '$_base/decoration-tulip.svg';
  static const cornerLeavesLeft = '$_base/decoration-corner-leaves-left.png';
  static const cornerLeavesRight = '$_base/decoration-corner-leaves-right.png';
  static const cloudsBottom = '$_base/decoration-clouds-bottom.svg';
  static const cloudsLeft = '$_base/decoration-clouds-left.svg';
  static const cloudsRight = '$_base/decoration-clouds-right.svg';
  static const leavesTall = '$_base/decoration-leaves-tall.svg';
  static const logoGoldenLeaves = '$_base/decoration-logo-golden-leaves.svg';
  static const watercolorWash = '$_base/decoration-watercolor-wash.svg';
}

/// 画面ごとのイラスト(240×240)。
class AppIllustrations {
  AppIllustrations._();

  static const _base = 'assets/illustrations';

  static const welcome = '$_base/illustration-welcome.png';
  static const emptyFeed = '$_base/illustration-empty-feed.svg';
  static const emptySearch = '$_base/illustration-empty-search.svg';
  static const emptyBookmarks = '$_base/illustration-empty-bookmarks.svg';
  static const emptyNotifications =
      '$_base/illustration-empty-notifications.svg';
  static const emptyMyPosts = '$_base/illustration-empty-my-posts.svg';
  static const postPublished = '$_base/illustration-post-published.png';
  static const passwordResetSent =
      '$_base/illustration-password-reset-sent.png';
  static const passwordResetComplete =
      '$_base/illustration-password-reset-complete.svg';
  static const reportReceived = '$_base/illustration-report-received.svg';
  static const connectionRetry = '$_base/illustration-connection-retry.svg';
  static const supportResources = '$_base/illustration-support-resources.png';
  static const firstPostGuide = '$_base/illustration-first-post-guide.png';
  static const loginRequired = '$_base/illustration-login-required.png';
  static const supportHeartHands =
      '$_base/illustration-support-heart-hands.png';
  static const supportHomeFamily =
      '$_base/illustration-support-home-family.png';
  static const supportParentChild =
      '$_base/illustration-support-parent-child.png';
}

/// 既定アカウント画像(240×240)。
class AppAvatars {
  AppAvatars._();

  static const _base = 'assets/avatars';

  static const defaultSun = '$_base/avatar-default-sun.png';
  static const defaultSprout = '$_base/avatar-default-sprout.png';
  static const defaultLittleBird = '$_base/avatar-little-bird.png';
  static const defaultYellowFlower = '$_base/avatar-yellow-flower.png';
  static const defaultTulip = '$_base/avatar-tulip.png';
  static const defaultBlueFlowers = '$_base/avatar-blue-flowers.png';

  /// アカウント画像から、プロフィールの`icon_key`を求める([forIconKey]の逆)。
  static String keyFor(String asset) => switch (asset) {
    defaultSun => 'sun',
    defaultLittleBird => 'little_bird',
    defaultYellowFlower => 'yellow_flower',
    defaultTulip => 'tulip',
    defaultBlueFlowers => 'blue_flowers',
    _ => 'sprout',
  };

  /// プロフィールの`icon_key`に対応するアカウント画像。
  /// icon_keyのマスタは未決定(バックエンド 未決事項)のため、いまは画像のファイル名に
  /// 合わせた仮のkeyを使う。未設定・未知のkeyは既定(芽)にする。
  static String forIconKey(String? key) => switch (key) {
    'sun' => defaultSun,
    'little_bird' => defaultLittleBird,
    'yellow_flower' => defaultYellowFlower,
    'tulip' => defaultTulip,
    'blue_flowers' => defaultBlueFlowers,
    'sprout' => defaultSprout,
    _ => defaultSprout,
  };
}

/// 共感リアクションの定型文アイコン(240×240)。
class AppReactions {
  AppReactions._();

  static const _base = 'assets/reactions';

  static const empathy = '$_base/reaction-empathy.svg';
  static const takeABreak = '$_base/reaction-take-a-break.svg';
  static const listening = '$_base/reaction-listening.svg';
  static const gentleCheer = '$_base/reaction-gentle-cheer.png';
  static const applause = '$_base/reaction-applause.svg';
}
