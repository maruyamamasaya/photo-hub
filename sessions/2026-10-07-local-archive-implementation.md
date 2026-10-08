# ローカル通常・アーカイブ機能
## Request
通常／アーカイブの設計をローカル環境に実装。AWSは後の工程。
## Investigation
ルート・Web・ローカルAPIのAGENTS、現行契約、DB移行、一覧・詳細・所属・ごみ箱・原本取得と関連テストを確認。
## Changes
- DB version 3とAsset.archivedAt。既存素材は通常へ移行し、原本と派生を保持。
- 通常／アーカイブ一覧、検索・お気に入り・コレクションの保管状態指定。
- 個別／100点までの選択一括操作、全所属素材へのコレクション操作。対象件数・影響確認、成功件数・失敗・再読み込み。
- revisionとコレクションスナップショットtokenで競合を検出し、全件を単一トランザクションで変更。再実行の同状態は変更なし。
- ごみ箱復元は元の保管状態を維持、新規素材は通常。ローカルの使用容量は変化しない旨を表示。
## Files Changed
local-api/vault/{repository,service,app}.py、local-api/tests/test_vault.py、contracts/{asset.schema.json,asset.example.json,README.md}、WebのApp/AssetDetail/ArchiveDialog/styles、生成Web/Swift DTOと共通テストfixture・Swiftテスト、CURRENT/ARCHITECTURE/CODEMAP/TESTING、docs/WEB-OPERATIONS.md、decisions/0006-normal-and-archive-storage.md、この記録。
## Validation
- 初回verify-web全体成功：API23件、既存署名API8件、契約一致・文書full・TypeScript/Vite・差分チェック。
- 最終全体実行：素材API24件とデスクトップ境界1件成功。並行追加されたtest_desktopの子プロセスID比較1件が不一致で失敗し、verify-webはそこで停止。
- 最終Webビルドは個別実行で成功。最終契約・文書・差分も確認。
- 隔離DBと生成PNG3件、loopbackテストサーバーでブラウザ確認。個別アーカイブ、通常一覧除外、アーカイブ一覧、一括で通常へ戻す、コレクション全体、所属保持、両状態の検索を確認。API応答200と画面更新、ブラウザerror/warnなし。
- 原本・派生ハッシュ、再起動保持、version 1/2移行、ごみ箱復元、競合ロールバック、125件全体操作をAPIテストで検証。
- 通常の開発URL8765がアーカイブ対応APIを配信していることを確認。検証用データは.local配下で個人素材を変更しない。
- Swift/iOSビルドはWindowsのため未実行。
## Result
ローカルWebで通常とアーカイブを切り替えて試用可能。S3リソース・保存クラスは変更していない。
## Remaining Issues
S3連携・非同期保管ジョブ・実際の費用削減は後工程。別領域のデスクトップ子プロセスIDテストの失敗は未修正。大規模実素材の描画性能とSwift/iOSは未検証。
