# メタデータフィルターと複数選択
## Request
種別・タグ・拡張子のフィルター、日時・タイトル・サイズ順、複数選択と一括取得・整理を追加。
## Investigation
日時・原本容量・所属は既存DBに存在。拡張子検索用項目を追加し、一覧APIとページング条件を拡張。
## Changes
DB version 2へ移行して原本拡張子を補完。複数タグAND・拡張子ORと5項目の昇降順に対応。最大100点の複数選択、タグ/コレクション追加・置換を単一トランザクションで実装。原本ZIPは最大1GB、一時ファイルは応答後削除。新規一括APIの型は共通契約からWeb/Swiftへ生成。
## Files Changed
- local-api/vault/repository.py, service.py, app.py
- local-api/tests/test_vault.py
- web/src/App.tsx, styles.css, generated/contracts.ts
- contracts/asset.schema.json, README.md
- Sources/AssetLibraryContract/Models.swift
- CURRENT.md, ARCHITECTURE.md
## Validation
API18テスト成功。旧DB移行、複合条件、全並び順のページング、競合時の全件維持、ZIP内原本一致・同名ファイルを検証。Web型チェック/ビルド、共通型一致、文書verify、git diff --check成功。実ブラウザーでフィルター・解除・2点選択・一括タグ保存を確認し、タグ検索2件で照合。
## Result
DB側で一覧を検索・整列し、選んだ複数素材をまとめて整理・取得できる状態。
## Remaining Issues
撮影日時のEXIF抽出は未実装。日時不明は昇順先頭・降順末尾。ブラウザー自動検証ではZIPダウンロード完了イベントを取得できず、端末への保存完了は未確認（APIのZIP生成と原本一致は成功）。Swift/Xcodeがなく生成Swift型のビルドとiOS実機は未検証。
