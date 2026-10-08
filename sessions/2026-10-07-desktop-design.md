# Mac・Windowsアプリ設計
## Request
現UIを踏襲したMac・Windowsアプリ設計を進め、開発状況をキャッチアップする。
## Investigation
CURRENT、構成、探索入口、Web UI/API/保存処理、既存iOS共通仕様、検証・運用と判断記録を確認。Electron公式の安全境界・配布・署名資料を参照。既存の未コミット変更は保持。
## Changes
React UI共有とElectron＋Python APIを第一候補とする設計案、OS操作、APIライフサイクル、原本保全、D1〜D5の完了条件を追加。現在地のアーカイブ未着手表記を実コードに合わせ、S3未実装を区別。
## Files Changed
docs/DESKTOP-DESIGN.md、decisions/0007-shared-desktop-ui.md、CURRENT.md、README.md、本記録。
## Validation
文書full verifyと対象差分の空白チェックを実施。アプリ実装変更なし。デスクトップビルド・Mac/Windowsアプリ実機検証は未実行。
## Result
両OSで同じUIを維持する設計と、次のWindows技術試作の受け入れ条件を記録。
## Remaining Issues
Electron採用は試作後に確定。Python同梱、署名、最低OS、正式名、Mac実機検証は今後の工程。
