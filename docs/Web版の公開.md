# Web版の公開（フロント側）

Web版（Flutter Web）を、Cloudflare Pagesに公開するための、フロント側の決めごと。公開の順番・CORS・ログインの設定などの、バックエンド側の方針は、[kosodate-hitoiki-backend](https://github.com/KOSODATEHITOIKI/kosodate-hitoiki-backend)の`docs/Web版の公開.md`を参照する。Issue #141・#142。

## 公開の順番（運営の決定）

1. 開発のSupabaseに向けた確認用のWeb（`pages.dev`）だけを、先に作る。CSP・ログイン・ボット対策を確かめる。
2. そのあとに、本番の`app.kosodate-hitoiki.com`を公開する。**公開した（2026-11-05）。** 下の「公開の記録」を参照。

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

バックエンドの`docs/Web版の公開.md`の案を、実際のビルドで動かして、次の変更をした（2026-11-02、Chrome・手元で確認）。

| 変更 | 理由 |
| --- | --- |
| `base-uri 'none'` → `base-uri 'self'` | Flutter Webの`index.html`に`<base href>`があるため。`'none'`だと、ブラウザーが`<base>`を認めない。 |
| `connect-src`に`blob:`を足す（2026-11-05） | アイコン画像を選ぶと、Flutter Webが、選んだ画像を`blob:`のアドレスから読み出す（`fetch`／`XMLHttpRequest`）。`connect-src`に無いと、止められて、アイコンを変えられない。`blob:`は、そのページ自身が作った、一時的なアドレスだけを指す（外部へは出ない）。`img-src`・`worker-src`には、もとからある。 |

**`fonts.gstatic.com`は、`connect-src`に足さない**（運営の決定、2026-11-03）。外部のサーバーへ、フォントを取りに行かない。次の「フォント」の節のとおり、必要なフォントは、同じサイトに置く。

### 確認したこと（開発用のビルド、手元、Chrome）

- CSPをつけて開いて、画面が出る。コンソールに、CSP違反が出ない。
- Networkに、外部のドメインが出ない（出るのは、同じサイトと、開発のSupabaseだけ）。`fonts.gstatic.com`は、許可していない（2026-11-03）。
- ログインの画面で、確認の部品（Turnstile）が、スクリプトの読み込みも含めて、止められずに出る。
- 公開先（`pages.dev`、開発用）で、運営と一緒に確認した（2026-11-02）: 登録・ログイン・再設定・Googleログイン・画像の表示。フォントを同梱したあと（2026-11-03）も、公開先で確認した（外部のドメインへの通信なし、CSP違反なし、絵文字が色つきで出る）。

## フォント（外部へ取りに行かない）

Flutter Webは、画面の文字が、同梱のフォントに無いとき、予備のフォントを`fonts.gstatic.com`から取りに行く（起動時には、Robotoも必ず取る）。CSPで外部を許可しないので、次のとおり、同じサイトに置く。

| フォント | 置き場所 | 内容 |
| --- | --- | --- |
| 日本語（M PLUS Rounded 1c） | アプリに同梱（`assets/fonts/`） | 4本。これまでどおり。 |
| 絵文字（Noto Color Emoji） | `web/fonts/NotoColorEmoji-subset.woff2`（約715KB。Webだけ。アプリには入らない） | 使う絵文字だけに絞ってある（顔・ハート・手・人・天気・食べ物・記号・キーキャップ）。起動時に、`lib/core/web/web_emoji_font.dart`が読み込む。 |
| Roboto（起動時に必ず取る） | `web/fallback-fonts/roboto/v32/` | 約63KB。取得先を、`web/flutter_bootstrap.js`の`fontFallbackBaseUrl`で、同じサイトに向けた。 |

- どちらも、SIL Open Font License 1.1（原文は、同じ場所の`OFL-*.txt`）。
- 絵文字の範囲を変えるときは、`scripts/web/make_emoji_font.py`のCODE_POINTSを直して、作り直す（手順は、スクリプトの先頭）。動物を足すと、約1.1MBになる。
- 絵文字のフォントの`FE0F`（絵文字として出す印）は、空の字形を足してある。足さないと、`1️⃣`などで、Flutterが外部のフォントを取りに行き続ける。
- **範囲外の文字**（フォントに無い絵文字、珍しい漢字）は、□で出る。このとき、Flutterは、予備のフォントの取得を、表示のたびにやり直すので、同じサイトへの取得（404）がくり返される。画面は崩れず、外部へは出ない。範囲外の絵文字が多いと分かったら、フォントの範囲を広げる。

## 公開の記録

| 日付 | できごと |
| --- | --- |
| 2026-11-02 | 開発用のWeb（`pages.dev`）で、CSP・登録・ログイン・再設定・Googleログイン・画像を確認 |
| 2026-11-03 | フォントを同梱（外部のフォント配信を使わない）。ボタンの日本語が豆腐になる不具合を直した（#174） |
| 2026-11-03 | `main`を、`v1.0.0`にそろえた |
| 2026-11-05 | `main`を、`v1.0.1`（アプリ1.0.0+3と同じコード）にそろえた。`Deploy Web (prod)`（`web-prod`の承認つき）で、本番Webを配備し、`app.kosodate-hitoiki.com`で公開 |

### 本番を公開したときの確認（2026-11-05）

- 外から（手元のChrome）: 通信先は、同じサイトと、本番のSupabaseだけ。CSP違反・通信エラーなし。日本語のフォント・ボタンの文字が、正しく出る。
- 運営が、本番で確認した: 新規登録と確認メール、ログイン、パスワード再設定、Googleログイン、同じアカウントでのアプリとWebの両方へのログイン、投稿とコメント。すべて問題なし。

### 公開の手順で気をつけたこと

- 配備先（Pagesのプロジェクト）を作ったあと、**公開するドメインを足す**。ボット対策の確認（Turnstile）は、公開するドメインでだけ通るので、登録・ログインの確認は、足したあとに行う。`pages.dev`のアドレスでは、確認できない。
- 公開の前に、`main`を、ストアに出した版にそろえる（本番Webは、`main`からだけ配備できる）。
- 本番での確認は、実際のデータになる。テストの投稿・コメントは、確認のあとに、削除する。

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
