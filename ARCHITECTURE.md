# 現在の構成

## System Overview / Technology Stack
個人向けiOS写真管理。SwiftUI / PhotoKit / ImageIO / CryptoKit / OS標準SQLite3、iOS 17以上。追加のSwift依存なし。共有ロジックはSwift Package。開発用保存はアプリ内ファイル。本番向けPython Lambda / S3 / Cognito / HTTP APIのコードとテンプレートは存在するが未デプロイ。

## Directory Structure / Main Components
```text
photo-hub/
├─ Sources/PhotoHubCore/   モデル・SQLite・オブジェクト保存・転送
├─ Tests/                 共有ユニットテスト
├─ ios/PhotoHub/          SwiftUI・PhotoKit・認証・状態管理
├─ ios/PhotoHubTests/     iOS統合テスト
├─ ios/PhotoHub.xcodeproj/ 生成済みプロジェクト
├─ backend/              署名API・テスト
├─ infrastructure/       認証とサービスのテンプレート
├─ docs/                 設計・AWS導入・実機検証・段階別プロンプト
├─ decisions/            設計判断
├─ sessions/             作業結果
└─ scripts/              Fast/Full verify
```
主要シンボルと検索語は [CODEMAP.md](CODEMAP.md)。

## Data Flow
```text
Photos Picker → PhotoKit原本 → Pendingファイル + JPEG派生 → SQLite
                                   ↓
                             PhotoTransfer
                                   ↓
                LocalObjectStore / 本人JWT API → 非公開S3
                                   ↓
                    HEADサイズ・SHA256照合 → uploaded
SQLite → LazyVGrid / 詳細 → 派生キャッシュ → 必要時GET
SQLite → JSON正常版 + latestポインター → 空SQLiteへの復元
```

## API Structure
POST `/objects`: head / put / get / delete。安定した本人キーだけを受け、URLは5分で失効。PUTはchecksum・サイズ・形式を署名、写真と正常JSONはIf-None-Matchで重複上書きを防ぐ。削除はS3 tombstoneで再署名を禁止し、6分後に既存署名の失効を待って完了する。

## Database
SQLite WAL + foreign_keys。`photos`はID・資産ID・SHA256・撮影日時・JSONメタデータBLOB（画像ではない）。`albums`と`memberships`で整理情報を持つ。状態・お気に入り・安定キーはメタデータに含む。復元は空DBだけ、検証後トランザクションで取り込む。スキーマはversion 1。

## Authentication
Cognito Hosted UI Code + PKCE S256。refresh tokenはKeychain、署名URLは保存しない。API Gateway JWT authorizer + LambdaのOwnerSubチェック。開発用ローカル保存は独立したテスト用経路。

## External Services / Deployment
東京S3 Standard（原本・派生・JSON）、Cognito、Lambda、HTTP API、CloudWatch。クラウドDBなし。実AWSは未作成。設定は [OPERATIONS.md](OPERATIONS.md)。

## Important Dependencies
標準Appleフレームワーク・SQLite・Python標準ライブラリ。LambdaはAWSランタイムboto3を使う。XcodeGenはプロジェクト再生成時のみ。verifyはPython、Swift、Ruby、Xcode。CI/CDとsemantic indexは未導入。

設計の理由・費用・未対応形式は [DESIGN.md](docs/DESIGN.md)、履歴はdecisionsとsessions。
