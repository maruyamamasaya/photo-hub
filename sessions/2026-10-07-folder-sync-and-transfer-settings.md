# フォルダ同期と素材設定の転送
## Request
使用頻度の低いアップロード／ローカルダウンロードを設定内へ追加。Finderで配置した画像を指定フォルダとの同期で表示し、フォルダ移動・画像一致とユニークキーを整理。
## Investigation
既存の素材UUID・原本SHA-256を維持し、所在のパスと固定IDを分離する。SQLite v6でフォルダ対応・模擬リモート保持・未完了整理を記録。
## Changes
素材詳細の歯車から転送。原本照合、ダウンロード時のリモート保持、アップロード後のローカル整理と失敗時の明示再試行。設定に任意フォルダの手動同期・移動先再指定・一致／移動／変更／欠損結果。外部原本はコピーせず参照。Electronの限定IPCでOSフォルダ選択を追加。
## Files Changed
local-api/vaultとテスト、Web App／AssetDetail／CSS、contractsと生成DTO、desktop/main／preload／package.json、CURRENT・ARCHITECTURE・CODEMAP、保管設計・運用文書、判断0009。
## Validation
API34件、既存API8件、Node3件（フォルダ選択の送信元検証を含む）、Electron描画smoke、Web型チェック／ビルド、共通契約一致・文書full、差分の空白を検証。隔離ブラウザで素材設定→アップロード→ローカルダウンロードの表示切り替えを確認。指定フォルダの新規同期→フォルダ移動のエラー→移動先再指定で一致1件の回復をブラウザで確認。実素材の転送・削除は行わない。
## Result
固定UUID＋SHA-256による手動同期と模擬転送を実装。既存DBを退避してWindowsアプリを更新・起動。実素材24件のハッシュ保持とDB整合性を確認。画面確認記録は.local/folder-sync-proof.jpg。
## Remaining Issues
AWS／共有DBは未接続で、模擬転送はPC全体の容量削減にはならない。改訂履歴・類似画像一致・常時監視は未実装。MacのFinder選択は実機未確認。転送中に外部ファイルを編集しない運用が必要。
