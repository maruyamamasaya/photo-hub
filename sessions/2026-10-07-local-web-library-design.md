# ローカルWeb素材ライブラリの設計
## Request
合意したローカルWeb先行方針をMarkdownにまとめ、設計後に実装へ進める。
## Investigation
既存の現在地・構成・運用・検証・設計判断と、直前に確認した写真モデルとAPI制約を照合。
## Changes
素材ライブラリの初期範囲、画面、ローカル構成、データモデル、API案、整合性、検証、AWSとiOSへの移行を設計。合意済み方針と技術提案を区別した。現在地とREADMEの導線を更新し、判断0004を記録。
## Files Changed
docs/ASSET-LIBRARY-DESIGN.md、CURRENT.md、README.md、decisions/0002-native-photo-storage.md、decisions/0004-local-web-asset-library.md、本記録。
## Validation
python scripts/verify.pyで文書full検証成功。git diff --check成功。アプリコード変更なしのためSwift/iOS/APIテストは未実行。Webは未実装のため動作未検証。
## Result
設計文書を作成。実装・リソース作成・改名は行っていない。
## Remaining Issues
正式名称、初期形式、具体的なフレームワーク・依存と性能目標は未確定。既存iOSと新Webのデータ移行・同期は後工程。
