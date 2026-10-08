# 0002: ネイティブ写真管理と端末内SQLite
Date: 2026-10-07
Status: accepted

将来の対象範囲は [0004](0004-local-web-asset-library.md) で拡張。以下は現在のiOS実装に関する判断として残す。

## Context
個人のiPhone一台で、自然な閲覧・整理と端末容量の抑制、機種変更時の復元を求められた。S3未設定の間はローカルでの検証が許可された。

## Decision
SwiftUIとOS標準SQLite3を使用し、原本はPhotoKitから無加工で取得、派生JPEGだけをキャッシュする。本番は東京の非公開S3と本人Cognito JWT API、復元はバージョン付きJSON。開発用LocalObjectStoreは本番とは独立する。クラウドDBは導入しない。

## Reason
一台利用ではクラウド同期DBが不要。標準SQLite3を小さなRepositoryで包み、依存更新の負担を抑え、永続状態とトランザクションを明示する。署名URLと長期秘密鍵は永続メタデータに入れない。

## Alternatives
GRDBはSQL運用の抽象化に有用だが初期規模では追加依存を避ける。SwiftDataは指定SQLiteモデルと復元トランザクションを直接制御する観点で採用しない。クラウドDB・複数端末同期は初期範囲外。

## Consequences
SQLiteのスキーマ管理とSQLは自前で保守する。前景アップロードの中断はファイル単位で再試行。開発用保存は端末内だけで、機種変更時の復元を保証しない。実AWS結合と実機性能は別途検証する。
