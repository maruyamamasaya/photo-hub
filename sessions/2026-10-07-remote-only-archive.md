# リモート専用アーカイブ
## Request
ローカルにはアーカイブを設けず、リモート独自機能にする。
## Investigation
UI・個別/一括/コレクションAPI・原本転送・DB移行の関連を確認。
## Changes
ローカルで入口・状態選択・詳細/一括操作を非表示。混在選択APIは400で全件拒否、コレクション操作はリモートのみ。ローカル転送・同期で分類解除。DB v7で既存ローカル分類を解除しrevision更新。
## Files Changed
WebのApp/AssetDetail/ArchiveDialog、APIのservice/repositoryとテスト、CURRENT、ARCHITECTURE、保管設計・契約・判断0010。
## Validation
API全35テスト、Web型チェック/ビルド、文書full、diff空白チェック成功。ブラウザで所在切り替え・一括操作・アーカイブからローカルへの遷移を確認。Reactスキルの関連チェックを適用。
## Result
リモート専用のアーカイブを実装。原本・タグ・所属を保持。
## Remaining Issues
iOS実機・Mac実機、実S3保存クラス変更は未検証/未実装。
