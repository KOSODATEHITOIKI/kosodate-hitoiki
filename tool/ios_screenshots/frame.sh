#!/bin/zsh
# shoot.shで撮ったiPhoneの画面に、Google Play用の画像と同じ見出し・背景を付けて、
# App Store用の画像(1206×2622px・JPEG)にする。Google Chromeで描いて撮る。
# 使い方: tool/ios_screenshots/frame.sh <shoot.shの出力先> <仕上がりの出力先>
# 見出しと順番は、Google Play用の画像(01-start〜07-mypage)と同じ。変えるときは、両方をそろえる。
IN=$1; OUT=$2
if [[ -z $IN || -z $OUT ]]; then echo "使い方: $0 <撮った画面のフォルダ> <出力先>" >&2; exit 2; fi
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
IN=$(cd $IN && pwd); mkdir -p $OUT; OUT=$(cd $OUT && pwd)
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
WORK=$(mktemp -d)
# 画面のファイル名|見出し1行目|見出し2行目|小見出し|背景の色|出力名
items=(
  "01_welcome|言いづらいことも、|ここでひと息。|子育ての気持ちを、安心して書ける場所。|#FBE8C0|01-start"
  "02_home|今日の気持ち、|ひとりで抱えなくていい。|ぐちも相談も、あなたのペースで。|#FBE7DF|02-home"
  "08_feed|「わかる」で、|気持ちがつながる。|同じ毎日を過ごす誰かの声に、ひと息。|#EFF0E8|03-feed"
  "05_search|同じ悩みの声を、|見つけよう。|キーワードや話題から、気になる投稿へ。|#FBE8C0|04-search"
  "04_compose|ただ聞いてほしい日も、|書いていい。|ほしい反応を選んで、気持ちを投稿。|#FBE7DF|05-write"
  "09_notifications|あなたの言葉に、|反応が届く。|共感やコメントを、お知らせで確認。|#EFF0E8|06-notifications"
  "10_mypage|あなたのペースで、|つながろう。|プロフィールや投稿を、マイページで。|#FBE8C0|07-mypage"
)
for item in $items; do
  IFS='|' read -r img h1 h2 sub blob name <<< "$item"
  sed -e "s|FONTDIR|$ROOT/assets/fonts|g" -e "s|{IMG}|$IN/$img.png|" -e "s|{H1}|$h1|" \
      -e "s|{H2}|$h2|" -e "s|{SUB}|$sub|" -e "s|{BLOB}|$blob|g" \
      "$ROOT/tool/ios_screenshots/frame.html" > $WORK/$name.html
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files \
    --force-device-scale-factor=1 --window-size=1206,2622 \
    --screenshot=$WORK/$name.png file://$WORK/$name.html >/dev/null 2>&1
  sips -s format jpeg -s formatOptions 95 $WORK/$name.png --out $OUT/$name-1206x2622.jpg >/dev/null
  echo "made $name"
done
rm -rf $WORK
