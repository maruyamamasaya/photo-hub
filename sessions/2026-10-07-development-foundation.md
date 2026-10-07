# AI開発基盤の整備

## Request
実コードから現在地・設計・検索・検証・運用を理解できる土台を作り、検索優先・階層ルール・肥大化防止・Fast/Full verifyで強化する。

## Investigation
作業開始時は空のディレクトリ。ユーザーの許可によりmainのGitリポジトリを初期化。既存アプリ・設計文書・パッケージ・テスト・CI/CDは存在しなかった。

## Changes
第1段階で役割別の文書、設計判断と作業記録の形式を作成。第2段階で検索入口と使い分け、更新条件、文書のサイズ検証を追加。アプリ導入後にios/backendの責務境界だけに子AGENTSを追加し、アプリの実在する検証をverifyへ統合した。

## Files Changed
ルートAGENTS/CURRENT/ARCHITECTURE/CODEMAP/TESTING/OPERATIONS/README、.gitignore、decisions/、sessions/、scripts/verify.pyとverify.sh、ios/AGENTS.md、backend/AGENTS.md。

## Validation
文書verifyの正常系と、必須文書削除・リンク切れ・必要項目欠落・行数上限超過の4異常系を一時コピーで確認した。アプリ導入後の標準verifyは別セッションに結果を記録する。

## Result
AGENTS + CURRENT → 必要な構造とCODEMAP → 検索 → 対象と参照・テスト → 実装 → Fast/Full → 必要な文書更新 → sessionを推奨。全ファイル一覧や生ログを文書へコピーしない。

## Remaining Issues
semantic index、language server固有の参照検索、CI/CDは未導入。文書verifyは意味的一致を自動判定しない。実コードの追加に合わせて正本を更新する必要がある。
