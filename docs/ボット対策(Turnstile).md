# ボット対策（Cloudflare Turnstile）

登録・ログイン・パスワード再設定（メール）で、ボットによる自動の操作を防ぐ。決定の経緯と順番は、Issue #141 の運営のコメント（2026-10-29）を参照する。

## 方針

- 確認の部品は、`TurnstileConfig.enabled`が`true`のときだけ出す。**既定は`true`**（普通にビルドすれば出る。2026-10-30に変更）。サーバーのCAPTCHA保護が無い環境で出したくないときだけ、`--dart-define=TURNSTILE=false`でビルドする。
- **v1.0（内部テストまで）は、ボット対策なしの、すでに作ったビルド**。ストアに出す最初の版は、v1.1（運営の決定）。
- **v1.1 で、アプリにも確認の部品（WebView）を入れる。Web版にも、同じ対応を入れる。**（実装は、この資料の対応で、済み。）
- 両方が出そろってから、バックエンドで、SupabaseのCAPTCHA保護を有効にし、Web版を公開する。**有効にすると、確認のトークンが無い古いアプリ（v1.0）は、メールの登録・ログイン・再設定に失敗する**（Googleログインには掛からない）。有効にするタイミングは、運営と合わせる。

## 仕組み

1. 登録・ログイン・再設定の画面に、確認の部品（`TurnstileField`）を出す。確認が済むまで、ボタンは押せない。
2. 確認が済むと、トークンが`captchaTokenProvider`に置かれる。
3. 認証のリポジトリ（`AuthRepository`）が、`signUp` / `signInWithPassword` / `resend` / `resetPasswordForEmail`を呼ぶ瞬間に、トークンを取り出して、`captchaToken`として渡す。**トークンは1回限り**。取り出したら消し、そのあと、確認をやり直す。
4. 部品を読み込めないとき（通信の失敗・ブロック・20秒たっても読み込めない）は、トークンなしでは進めない。「もう一度読み込む」を案内する。

| 環境 | 表示の方法 |
| --- | --- |
| アプリ（Android・iOS） | 小さなWebView（`webview_flutter`）に、公式のスクリプトを読み込む。WebViewは、この部品のためだけに使い、ほかのページへは移れない。 |
| Web | 公式のスクリプト（`challenges.cloudflare.com`）を、必要になったときだけ読み込み、ページの中の枠に表示する。 |

## 鍵

- Site Key（公開してよい）は、`lib/core/config/turnstile_config.dart`に書く。開発用は`localhost`、本番用は`app.kosodate-hitoiki.com`だけで使える。**開発のWebは、`http://localhost:ポート/`で開く**（`127.0.0.1`では、Cloudflareに断られ、確認の部品が出ない。エラー`110200`。2026-10-30に確認）。
- **Secret Keyは、このリポジトリに置かない。** 運営がSupabaseの画面に直接入れる。
- アプリ（WebView）は、部品を、Site Keyが許可しているホスト名の「ページの出どころ」で開く（開発: `http://localhost/`、本番: `https://app.kosodate-hitoiki.com/`）。

## 有効にする手順（運営と合わせる）

1. v1.1のアプリのビルドと、Web版の公開が、準備できていること。
2. 既定が`true`なので、普通にビルドする（付けなくてよい）。アプリ・Webの、ログイン・登録・再設定が、確認つきで通ることを確認する。
3. バックエンドで、SupabaseのCAPTCHA保護を有効にする（古いアプリは、このときから、メールの登録・ログインに失敗する）。
4. 本番で、メールの登録・ログイン・パスワード再設定を、アプリとWebで確認する。

開発のSupabaseは、CAPTCHA保護が有効。**確認の部品なし（`TURNSTILE=false`）のビルドは、メールの登録・ログイン・再設定が、`no captcha_token found`で失敗する**（Googleログインは影響なし）。

## Web版の公開先で必要な設定（CSP）

公開先（Cloudflare Pages）の、安全のヘッダー（Content-Security-Policy）に、次を足す。

- `script-src`: `https://challenges.cloudflare.com`
- `frame-src`: `https://challenges.cloudflare.com`
- `connect-src`: `https://challenges.cloudflare.com`

## 安全の注意

- トークンは、ログに出さない。使い回さない（1回限り）。
- 確認の部品が読み込めないときは、トークンなしで進めない。
- アプリのWebViewは、確認の部品以外のページへ移らない（メインのページの移動は止め、枠は`challenges.cloudflare.com`だけ許す）。
