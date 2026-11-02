# Web版の公開（フロント側）

Web版（Flutter Web）を、Cloudflare Pagesに公開するための、フロント側の決めごと。公開の順番・CORS・ログインの設定などの、バックエンド側の方針は、[kosodate-hitoiki-backend](https://github.com/KOSODATEHITOIKI/kosodate-hitoiki-backend)の`docs/Web版の公開.md`を参照する。Issue #141・#142。

## 公開の順番（運営の決定）

1. 開発のSupabaseに向けた確認用のWeb（`pages.dev`）だけを、先に作る。CSP・ログイン・ボット対策を確かめる。
2. そのあとに、本番の`app.kosodate-hitoiki.com`を公開する。

## ビルド

```bash
# 開発用(pages.dev。開発のSupabase)
flutter build web -t lib/main_dev.dart --release --no-web-resources-cdn
# 本番用(app.kosodate-hitoiki.com。本番のSupabase)
flutter build web -t lib/main_prod.dart --release --no-web-resources-cdn
```

- **`--no-web-resources-cdn`を付ける。** 付けないと、描画のCanvasKitを`www.gstatic.com`から読み込む。CSPでは、そこを許可しないので、画面が出ない。付けると、`build/web/canvaskit/`に同梱される。
- 開発用と本番用で、向け先のSupabaseとTurnstileのSite Keyが変わる（`lib/main_dev.dart` / `lib/main_prod.dart`が、環境を決める）。

## 安全のヘッダー（`_headers`）

- ひな形: [deploy/web/_headers.template](../deploy/web/_headers.template)。CSPなどの安全のヘッダーが入っている。
- 作り方: `scripts/web/make_headers.sh <dev|prod>`が、ひな形の`__SUPABASE_HOST__`を、向け先のSupabaseのホスト名にして、`build/web/_headers`に置く。**開発用には開発のSupabaseだけ、本番用には本番のSupabaseだけ**が入る。取り違えると、スクリプトが止まる。
- Cloudflare Pagesは、公開するフォルダ直下の`_headers`を、そのまま使う。

### バックエンドの案から変えた点

バックエンドの`docs/Web版の公開.md`の案を、実際のビルドで動かして、次の2点を変えた（2026-11-02、Chrome・手元で確認）。

| 変更 | 理由 |
| --- | --- |
| `base-uri 'none'` → `base-uri 'self'` | Flutter Webの`index.html`に`<base href>`があるため。`'none'`だと、ブラウザーが`<base>`を認めない。 |
| `connect-src`に`https://fonts.gstatic.com`を足した | Flutterが、持っているフォントに無い文字（絵文字など）の予備のフォントを、ここから取るため。止めると、投稿の絵文字が「□」になる。取るのは、フォントのファイルだけ。**運営に、足してよいかの確認を取る**。 |

### 確認したこと（開発用のビルド、手元、Chrome）

- CSPをつけて開いて、画面が出る。コンソールに、CSP違反が出ない（`fonts.gstatic.com`を足したあと）。
- ログインの画面で、確認の部品（Turnstile）が、スクリプトの読み込みも含めて、止められずに出る。
- まだ確認していないこと: Supabaseへの通信（ログイン・投稿の取得）、Googleログイン、アカウント画像の表示。公開先（`pages.dev`）で、運営と一緒に確認する。

## 公開用のワークフロー

Cloudflare Pagesへの公開は、GitHub Actionsで行う。開発用と本番用を分ける。

| ワークフロー | 向け先 | 動かし方 | 出せるブランチ | GitHubのEnvironment |
| --- | --- | --- | --- | --- |
| `deploy-web-dev.yml` | 開発のSupabase（`pages.dev`の確認用） | 手動（`workflow_dispatch`） | `develop` | `web-dev` |
| `deploy-web-prod.yml` | 本番のSupabase（`app.kosodate-hitoiki.com`） | 手動（`workflow_dispatch`） | `main` | `web-prod` |

どちらも、ビルド（`--no-web-resources-cdn`）→ `scripts/web/make_headers.sh`で`_headers`を作る → `wrangler pages deploy`の順に動く。

### 運営が用意するもの（値は、ここにも、Issueにも書かない）

GitHubのEnvironment（`web-dev`・`web-prod`）ごとに、同じ名前で入れる。

| 種類 | 名前 | 中身 |
| --- | --- | --- |
| Secret | `CLOUDFLARE_API_TOKEN` | Pagesの配備だけの権限のAPIトークン |
| Secret | `CLOUDFLARE_ACCOUNT_ID` | CloudflareのアカウントID |
| Variable | `CLOUDFLARE_PAGES_PROJECT` | Pagesのプロジェクト名（開発用と本番用で別） |

- 設定が足りないときは、公開の前に、足りない**名前だけ**を知らせて止まる（値は出さない）。
- `web-prod`には、運営の承認（Required reviewers）を付ける。
- フォークや外部のPRからは、Secretsは使えない。ワークフローは、PRでは動かさず、手動だけにしている。
- 公開先の準備が済んで、動くことを確かめたら、開発用を、`develop`へのpushでも動かすかを、運営と決める。
- 使うアクションは、コミットを固定して指定している（`wrangler-action` v4.1.3、`flutter-action` v2.23.0、`checkout` v4.2.2）。更新するときは、コミットも更新する。
