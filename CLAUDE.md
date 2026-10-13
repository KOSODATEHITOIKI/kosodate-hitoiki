# CLAUDE.md

このリポジトリで作業するAIエージェント（Claude Code）向けのルール集約ファイル。個別ドキュメントに散らばる決定事項ではなく、**作業の進め方そのものに関するルール**をここにまとめる。姉妹リポジトリ（kosodate-hitoiki-backend、kumayokeru-app／kumayokeru-backend、burari-date、tekushare-app）と運用方針を揃えることを前提とする。

## このリポジトリについて

子育ての愚痴をこぼし、コメントでコツや体験談を共有できるSNSアプリ（Flutter + Supabase）。バックエンド（Supabaseのマイグレーション・RLSポリシー・Edge Functions）は別リポジトリ [kosodate-hitoiki-backend](https://github.com/naka328/kosodate-hitoiki-backend) で管理する。

## 一次情報と資料の優先順位

1. **[Notion要件定義書](https://app.notion.com/p/3e95b8f5ffee8171bf86f976d5d5b2ec)** が仕様の一次情報。決定ログ（9章）に確定事項が時系列で記録されている。
2. [docs/全体設計書.md](docs/全体設計書.md) が、Notionの決定事項をこのリポジトリのコードベースと対応づけて要点整理したもの。仕様の変更はまずNotion側を更新し、本書は実装への影響がある範囲で追従する。
3. バックエンド仕様（DBスキーマ・権限・API契約）は[kosodate-hitoiki-backend](https://github.com/naka328/kosodate-hitoiki-backend)の`docs/`を参照する。フロント側で新しいAPI呼び出しが必要になったら、まずバックエンド側のAPI契約を確認し、なければIssueで相談する。

全体設計書内の状態表記（決定・採用決定・詳細検討中・未決定 等）を確認し、**未決定の項目を確定事項として実装しない**。スコープ外の機能（1章参照：DM、画像・動画投稿、フォロー機能、人気ランキング、広告・課金、AI自動返信、Web一般公開）を提案・実装しない。

## ブランチ・PR・Issueの運用

[docs/環境とブランチ運用.md](docs/環境とブランチ運用.md)のとおり、姉妹プロジェクト（burari-date・kumayokeru-app・tekushare-app）の「main1本 + GitHub Flow」とは異なり、本プロジェクトは**Git Flow（develop運用）**を採用する（2026-09-29決定）。

```text
main                  ← リリース済み（本番公開済み）の状態のみ
  └─ develop          ← 開発中の最新コードを集約する統合ブランチ
       ├─ feature/xxx ← develop から分岐、develop 宛てにPR
       └─ fix/xxx      ← 同上
  └─ hotfix/xxx       ← 本番の緊急修正。main から分岐し、main と develop の両方へ反映
```

- 作業は必ず`develop`から作業ブランチを切る。`main`・`develop`へ直接コミット・pushしない。
- 全てのPRはレビュー必須（最低1名の承認）。CIで自動テスト・解析が実行される。
- リリース時に`develop`の内容を`main`にマージし、`vX.Y.Z`タグを打つ。
- PR本文は`.github/pull_request_template.md`の書式（📝説明／🔗関連Issue／📋変更内容／✅チェックリスト／📸スクリーンショット／🚀備考）に従う。Issue・PRテンプレートはBug・Logic・UIの3種。

## Flutterのビルドモードと環境

- Debug／Profile／Releaseの使い分けは[docs/環境とブランチ運用.md](docs/環境とブランチ運用.md)参照。
- 環境（Flavor: dev/prod。姉妹プロジェクトのdev/stg/prod 3種とは異なり2種のみ）は導入済み。エントリーポイントは`lib/main_dev.dart` / `lib/main_prod.dart`（`lib/main.dart`はdevへ委譲）。詳細は[docs/環境とブランチ運用.md](docs/環境とブランチ運用.md)参照。
- Supabaseの接続先は[lib/core/config/supabase_config.dart](lib/core/config/supabase_config.dart)に直接記載する。anon keyは公開情報のため`.env`での秘匿は不要（理由は同ファイルのコメント参照）。service_role相当の特権キーは絶対にこのリポジトリへ含めない。

## コミット・PRメッセージ

- 日本語で、変更の意図（なぜ）が分かるように書く。
- コミットメッセージ・PR説明の末尾に付ける attribution（Co-Authored-By等）は、呼び出し元（Claude Codeのシステム設定）の指示に従う。本ファイルでは固定しない。

## セットアップ・テスト

```bash
flutter pub get
flutter run
```

テスト方針・コード規約を定めた個別ドキュメント（コード規約.md・テスト方針.md）は現時点で未整備（姉妹アプリのkumayokeru-app等には存在するが、本リポジトリにはまだない）。実装を進める中で必要になった規約はこのファイルまたは新設のdocsへ追記する。
