# iOSリリース手順

App Store(iOS)に出すための手順と、決めたこと。姉妹アプリ(burari-date・tekushare-app)が2026-11-10に初回の審査に出したときの手順を、ひと息に合わせて書いた。アップデートのときは「4. ビルドとアップロード」以降を繰り返す。
Google Playは[リリース手順(Android)](リリース手順.md)を参照。

> `.p8`(Sign in with Apple のキー・APNs のキー)・審査用アカウントのパスワードは、**リポジトリ・Issueに書かない**。

## 固定値

| 項目 | 値 |
|---|---|
| Team ID | `4N5F9L6BC2`(`ios/Runner.xcodeproj`の`DEVELOPMENT_TEAM`。姉妹アプリと同じ) |
| Bundle ID | prod `com.kosodatehitoiki` / dev `com.kosodatehitoiki.dev`(**App Store Connectでアプリを作ると、変えられない**) |
| App Store ID | (アプリを作ったら書く) |
| SKU | `kosodate-hitoiki-ios`(案) |
| 対応端末 | iPhone専用・iOS 15.0以上(iPadのスクリーンショット・審査が不要)。画面の向きは固定しない |
| Firebase のiOSアプリ | (プッシュ通知を入れるときに登録する。プロジェクトは`kosodate-hitoiki-f0036`) |

## 1. 初回だけ行う設定

- [ ] App Store Connectでアプリを作る(名前「ひと息」、プライマリ言語は日本語、Bundle ID `com.kosodatehitoiki`。EUのDSAは「トレーダーではない(EUで配信しない)」)
- [x] Appleでサインイン(Issue #182・バックエンドのIssue)。2026-11-10に、devの実機で、Appleで登録・ログイン・退会(Appleとの連携の解除)まで確かめた
  - Apple Developer → Identifiers で、`com.kosodatehitoiki`(と`.dev`)の「Sign in with Apple」がオンか確かめる(Xcodeの自動署名で、App IDと一緒に作られていることがある)
  - Supabase(dev・本番)→ Authentication → Providers → Apple を有効にし、Client IDsに`com.kosodatehitoiki`・`com.kosodatehitoiki.dev`を入れる
  - 退会のときの連携の解除のため、Apple Developer → Keys で「Sign in with Apple」のキーを作り、Edge Functionsのシークレットに入れる(バックエンドのIssue)
- [ ] プッシュ通知(任意。なくてもアプリは動き、通知だけが使えない。Androidの初回と同じ)
  - Firebaseの`kosodate-hitoiki-f0036`に、iOSアプリ(`com.kosodatehitoiki`)を足し、`GoogleService-Info.plist`を置く
  - APNsの認証キーを作り、Firebase → Cloud Messaging → Appleアプリの構成に上げる
  - `Runner.entitlements`に`aps-environment`を足す
- [ ] 公開サイトの規約・プライバシーポリシーに、Apple(App Store・Appleでサインイン)を書く

## 2. App Store Connect の掲載情報

### バージョンのページ

| 項目 | 値・注意 |
|---|---|
| プロモーション用テキスト | 170文字以内。審査なしで、いつでも変更できる |
| サブタイトル | 30文字以内(アプリ情報のページ)。アプリ名と一緒に、検索の対象になる |
| 概要 | 4000文字以内。Google Play・Androidに触れない。利用規約・プライバシーポリシーのURLを、最後に書く |
| キーワード | 100文字以内・カンマ区切り・スペースなし。アプリ名・サブタイトルの言葉・他社のアプリ名は入れない(アプリ名・サブタイトルは、自動で検索の対象になる) |
| サポートURL | `https://www.kosodate-hitoiki.com/`(お問い合わせ `contact@kosodate-hitoiki.com` が分かるページ) |
| バージョン | `pubspec.yaml`の`version`の前半と同じ(例: `1.0.0`。初期値の`1.0`のままにしない) |
| 著作権 | `2026 CenterRiverStudio`(公開サイトと同じ名義) |

1.0.0で入れる文面(案。2026-11-10。公開サイトの文面に合わせた。提出の前に、運営が見直す):

- サブタイトル(18文字): 「子育ての気持ちを、安心して書ける場所」
- プロモーション用テキスト(91文字): 「言いづらいことも、ここでひと息。子育てのぐち・相談・コツや体験談を、ニックネームで気軽に書けます。投稿の前に自動で確認し、通報・ブロック・ミュートで、安心して過ごせる場所を守ります。」
- キーワード(81文字): `育児,ママ,パパ,愚痴,ぐち,悩み,相談,共感,つぶやき,ストレス,息抜き,ワンオペ,イヤイヤ期,夜泣き,寝かしつけ,離乳食,保育園,体験談,コミュニティ,掲示板`(「子育て」は、サブタイトルにあるので入れない)
- 概要(928文字):

```text
言いづらいことも、ここでひと息。
「ひと息」は、子育ての気持ちを、安心して書ける場所です。

寝てくれない夜のこと、思いどおりにいかない毎日のこと、誰かに聞いてほしいけれど、身近な人には言いづらいこと。
ここでは、ニックネームで、そっと書き出せます。同じように子育てをしている人が、共感やコメントで受けとめてくれます。

■ こんな方に
・子育ての気持ちを、誰かに聞いてほしい
・身近な人には相談しにくいことがある
・ほかの家庭のコツや体験談を知りたい
・読むだけでも、少し気持ちを軽くしたい

■ できること
・3つの種類で投稿:「ぐち」「相談」「コツ・体験談」
・コメント・返信で、コツや体験談を共有
・共感:ことばを選んで、気持ちを伝えられます
・気になる投稿を保存して、あとで読み返す
・キーワードで、投稿を探す
・困ったときの相談先(公的な窓口など)への案内

■ 安心して使うために
・名前や個人情報は書かない、気持ちを否定しない、を大切にしています
・投稿・コメントの前に、内容を自動で確認します
・通報・ブロックで、合わない相手や内容から離れられます
・ミュート:見たくない話題や言葉を含む投稿を、自分にだけ非表示にできます
・運営が通報を確認し、必要に応じて対応します

■ 自分のペースで
登録しなくても、投稿を読めます。書くのは、気が向いたときで大丈夫です。
ブラウザ版(https://app.kosodate-hitoiki.com/)でも、同じアカウントで使えます。

■ ご利用について
・18歳以上の方がご利用いただけます
・投稿・コメント・共感には、アカウント(メール・Apple・Google)が必要です
・無料でご利用いただけます。広告はありません
・医療や専門的な助言の代わりにはなりません。急ぎのときや、心配なときは、専門の窓口にご相談ください

利用規約:https://www.kosodate-hitoiki.com/terms/
プライバシーポリシー:https://www.kosodate-hitoiki.com/privacy/
お問い合わせ:contact@kosodate-hitoiki.com
```

- 書いていないこと: プッシュ通知(iOSは、まだ入れていない)。入れたら、概要に足す

### スクリーンショット

- 「Dynamic Island搭載iPhone(中型ディスプレイ)」に **1206×2622px**(iPhone 18 Proのシミュレーター)を最大10枚。iPadは不要(iPhone専用)
- Google Play用の画像は、Androidの画面が写っているので**そのまま使えない**(ガイドライン2.3.10)。同じ見出し・デザインで、中の画面だけiPhoneに差し替える
- 本番のSupabaseにつないで撮ると、実際のデータになる。撮影用の投稿は、撮ったあとに消す(Web版の公開のときと同じ)

### App Review に関する情報

- **連絡先情報**(姓・名・電話番号・メール)は必須。電話番号は`+81`から(先頭の0を取る)。公開されない
- **サインイン情報**: 投稿・コメントにはログインが要るので、**本番でメール確認まで済ませた審査用アカウント**を用意し、メール・パスワードを入れる。審査中は、削除・パスワード変更をしない
- **メモ**(英語)の基本:

```
Thank you for reviewing Hitoiki.

[What the app does]
Hitoiki is a small community for parents. Users post their parenting frustrations, questions and tips, and others reply with comments and empathy reactions.

[Sign in]
Reading posts works without signing in. Posting, commenting and reacting need an account.
Please use the demo account above. Sign in with Apple, Google and email are supported.
Registration requires agreeing to the Terms of Use and Privacy Policy, and confirming the user is 18 or older.

[User-generated content (Guideline 1.2)]
- Before a post or comment is sent, the server checks it automatically and blocks inappropriate content.
- Report: on any post or comment, tap the menu (...) > 通報する, then choose a reason.
- Block: on any post, comment or profile, tap the menu (...) > ブロックする. Blocked users' content is hidden.
- Mute: Settings > ミュート hides posts with chosen topics or words.
- Posts reported by several users are hidden automatically, and the operators review reports and can remove content or suspend users.
- Contact: contact@kosodate-hitoiki.com

[Account deletion]
Settings > 退会 deletes the account and its data immediately. For accounts registered with Sign in with Apple, the app asks the user to confirm with Apple once more, and the server revokes the Apple token before deleting.
```

- メモの操作の場所(メニューの名前)は、提出の前に、実際の画面と合わせる
- **リリース方法**: 「このバージョンを手動でリリースする」

### アプリ情報

| 項目 | 値 |
|---|---|
| カテゴリ | プライマリ: ライフスタイル(セカンダリ: ソーシャルネットワーキング)(案) |
| コンテンツ配信権 | いいえ(他社のコンテンツを表示しない)。表示するものが増えたら見直す |
| 年齢制限 | 「ユーザ生成コンテンツ」「ソーシャルメディア」は**はい**(投稿・コメント)。「メッセージ」はいいえ(DMはない)。広告・ウェブアクセス・ギャンブル等は、いいえ・なし。利用規約で18歳以上としている |
| 暗号化 | `Info.plist`の`ITSAppUsesNonExemptEncryption=false`で申告済み |

### アプリのプライバシー

- プライバシーポリシーURL: `https://www.kosodate-hitoiki.com/privacy/`
- 収集するデータ(`ios/Runner/PrivacyInfo.xcprivacy`と揃える)

| 分類 | 項目 | 内容 |
|---|---|---|
| 連絡先情報 | メールアドレス | アカウント登録(メール・Google・Apple) |
| ユーザコンテンツ | 写真またはビデオ | プロフィールのアイコン画像(ライブラリから選んだもの) |
| ユーザコンテンツ | その他のユーザコンテンツ | ニックネーム・プロフィール・投稿・コメント・返信・通報の内容 |
| ID | ユーザID | Supabaseの利用者ID |
| ID | デバイスID | プッシュ通知の送り先(FCMのトークン) |
| 使用状況データ | 製品の操作 | 共感・保存・ミュート・ブロック・既読 |

- 各項目: 用途「アプリの機能」のみ/ユーザに関連付け「はい」/トラッキング「いいえ」
- 本名・住所・電話番号・位置情報・診断・分析は**収集しない**(解析・クラッシュ収集・広告のツールは入れていない。入れたら申告を足す)
- 共有する外部サービスは、Androidのデータセーフティと同じ(Supabase・OpenAI(投稿前の自動チェック)・Google・Resend)
- 最後に右上の「**公開**」を押す(押さないと審査に出せない)

### 価格および配信状況

- 価格: 「価格スケジュール」で、基準を日本・**¥0(無料)**。未設定だと「価格帯を選択する必要があります」で提出できない
- **アプリの配信状況**: 「配信状況の設定」で**日本**を選んで保存する(価格の設定とは別。**選ばないと、承認されても、どこにも出ない**。burari-dateで、承認のあとに気づいた)
- 「Appleシリコン搭載のMac」「Apple Vision Pro」での配信は、確かめていないので、チェックを外す(推奨)

## 3. 提出前の確認

- [ ] `pubspec.yaml`の`version`のビルド番号が、App Store Connectにアップロード済みのものより大きい
- [ ] TestFlightで、本番版を実機で確かめる: 起動・閲覧、メールで登録(確認メール)・ログイン・パスワード再設定、Appleで登録・ログイン・退会、Googleで登録・ログイン、投稿・コメント・共感、通報・ブロック・ミュート、アイコンの変更

## 4. ビルドとアップロード

```bash
flutter build ipa --flavor prod -t lib/main_prod.dart
```

- 出力: `build/ios/archive/Runner.xcarchive`、`build/ios/ipa/kosodate_hitoiki.ipa`(App Store配布用の証明書で署名済み。Xcodeの自動署名)
- 2026-11-10に、`1.0.0(3)`で、配布用のIPAができることを確かめた(Appleでサインインの権限・Privacy Manifest入り)
- アップロードは、どちらか
  1. **Xcode の Organizer**: `open build/ios/archive/Runner.xcarchive` → Distribute App → App Store Connect → Upload(Xcode 27.2では、先に Validate App を実行しないと、押せないことがある)
  2. **Transporter**(Mac App Store): `build/ios/ipa/kosodate_hitoiki.ipa`をドラッグして「配信」
- 10〜30分で、TestFlightのビルドが「提出準備完了」になる

## 5. 審査への提出

1. 配信タブ → バージョンのページ → 「ビルド」でビルドを選ぶ
2. 「審査用に追加」→「審査へ提出」
   - 足りない項目は、一覧で出る(初回は: 連絡先情報・プライバシーポリシーURL・アプリのプライバシーの公開・年齢制限・コンテンツ配信権・カテゴリ・価格)
3. 結果は24〜48時間が目安。質問は App Review のメッセージに届く

## 6. 承認後

1. 「このバージョンをリリース」で公開する
2. App Storeから入れて、起動・ログイン・投稿を確かめる
3. Gitで、`develop`を`main`にマージして、`vX.Y.Z`のタグを打つ(`docs/環境とブランチ運用.md`)。Android・Webと同じコードのときは、同じタグにそろえる
