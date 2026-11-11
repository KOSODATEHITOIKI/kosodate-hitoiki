#!/bin/zsh
# iOSのシミュレーターで、結合テスト(integration_test/)を動かし、「SNAP:<名前>」の合図ごとに撮る。
# 使い方: tool/ios_screenshots/shoot.sh <シミュレーターのUDID> <出力先>
# 本物のサーバーにはつながない(画面の確認用のデータを使う)。ステータスバーは9:41・電池満タンに整える。
# 手順は docs/iOSリリース手順.md の「スクリーンショット」を参照。burari-dateの同名のスクリプトと同じ作り。
U=$1; OUT=$2
if [[ -z $U || -z $OUT ]]; then echo "使い方: $0 <UDID> <出力先>" >&2; exit 2; fi
mkdir -p $OUT; OUT=$(cd $OUT && pwd); LOG=$OUT/run.log; : > $LOG
xcrun simctl boot $U 2>/dev/null
xcrun simctl status_bar $U override --time 9:41 --batteryState discharging --batteryLevel 100 --cellularBars 4 --wifiBars 3 --dataNetwork wifi
cd "$(dirname "$0")/../.."
flutter test integration_test/store_screenshots_test.dart --flavor prod -d $U > $LOG 2>&1 &
PID=$!
seen=""
while kill -0 $PID 2>/dev/null; do
  for name in $(grep -o 'SNAP:[0-9a-z_]*' $LOG | cut -d: -f2); do
    if [[ " $seen " != *" $name "* ]]; then
      xcrun simctl io $U screenshot --mask=black $OUT/$name.png >/dev/null 2>&1
      seen="$seen $name"
      echo "shot $name"
    fi
  done
  sleep 0.1
done
wait $PID; code=$?
xcrun simctl status_bar $U clear
tail -5 $LOG
exit $code
