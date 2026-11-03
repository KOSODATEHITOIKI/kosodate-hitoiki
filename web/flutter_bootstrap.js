{{flutter_js}}
{{flutter_build_config}}

// 同梱のフォントに無い文字の予備フォントを、外部(fonts.gstatic.com)ではなく、同じサイトから取る。
// CSPで外部のフォントを許可しないため。置いてあるのは、起動時に必ず取るRobotoだけ
// (web/fallback-fonts/)。絵文字は、アプリ側で読み込む(lib/core/web/web_emoji_font.dart)。
_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
  config: {
    fontFallbackBaseUrl: 'fallback-fonts/',
  },
});
