#!/usr/bin/env bash
# Web版の`_headers`を作る。ひな形の`__SUPABASE_HOST__`を、向け先のSupabaseのホスト名にする。
#
# 使い方: scripts/web/make_headers.sh <dev|prod> [出力先(既定: build/web/_headers)]
#   dev  = 開発のSupabase(pages.dev の確認用)
#   prod = 本番のSupabase(app.kosodate-hitoiki.com)
# 開発と本番は、ホスト名を取り違えないよう、ここにだけ書く(公開してよい値。lib/core/config/supabase_config.dart と同じ)。
set -euo pipefail

case "${1:-}" in
  dev) host="djbizophhqtlqmlabhdo.supabase.co" ;;
  prod) host="yaggicrvzykkfcdhsjlm.supabase.co" ;;
  *)
    echo "使い方: $0 <dev|prod> [出力先]" >&2
    exit 2
    ;;
esac

root="$(cd "$(dirname "$0")/../.." && pwd)"
out="${2:-$root/build/web/_headers}"

sed "s/__SUPABASE_HOST__/${host}/g" "$root/deploy/web/_headers.template" > "$out"

# 取り違え・置き換え漏れを防ぐ。
if grep -q "__SUPABASE_HOST__" "$out"; then
  echo "置き換え漏れがあります: $out" >&2
  exit 1
fi
if [ "$1" = "dev" ] && grep -q "yaggicrvzykkfcdhsjlm" "$out"; then
  echo "開発用のヘッダーに、本番のSupabaseが入っています" >&2
  exit 1
fi
if [ "$1" = "prod" ] && grep -q "djbizophhqtlqmlabhdo" "$out"; then
  echo "本番用のヘッダーに、開発のSupabaseが入っています" >&2
  exit 1
fi
echo "作りました: $out ($1)"
