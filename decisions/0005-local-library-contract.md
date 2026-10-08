# 0005: ローカルWebと共通素材契約
Date: 2026-10-07
Status: accepted

## Context
ユーザーは実装プロンプトを順番に実施し、Web版をローカルで動かすことを希望した。iOS実機は使えないため、Webに合わせて将来構築できる共通仕様と未実行の検証条件が必要になった。

## Decision
React/TypeScript/Vite、Python/FastAPI/SQLite/Pillowを採用。素材メタデータはAPIの正本、保存は専用ローカルフォルダ。Assetと複数のAssetFileを分ける。JSON SchemaからWeb型とSwift Codable DTOを生成し、共通JSON例と生成一致テストを持つ。既存iOSは接続せず独立したSwift契約モジュールを追加する。

原本保存が完了すれば素材登録を成立させ、派生失敗は別に再試行する。原本ハッシュで重複を防ぎ、整理はrevision競合を検出。削除はごみ箱と完全削除を分離する。

## Reason
ローカルで操作を検証でき、iOS/Web間でモデルを別々に手書きしてずれることを防ぐ。既存Photoと旧バックアップを不用意に書き換えず、移行を別工程にできる。Pythonの原本・画像処理とWeb UIを独立させる。

## Alternatives
ブラウザ内DBを正本にするとファイル保存と将来の共有APIへの移行が複雑になる。既存iOSの固定3ファイルモデルの流用はプレビュー非対応素材を扱いづらい。クラウドやAIの先行導入は今回の目的に不要。

## Consequences
新規依存とローカルAPIの運用が増える。HEICは原本のみ、EXIF撮影日時抽出は未実装。共通型生成だけでiOS実動作の一致は保証できず、Macでのビルド・デコード・API接続・実機操作は [確認待ち](../docs/IOS-WEB-CONTRACT.md) に残す。クラウドDB・認証・同期は別設計。

選定時に [Vite公式](https://vite.dev/guide/)、[FastAPIのファイル取り込み](https://fastapi.tiangolo.com/tutorial/request-files/)、[Pillow対応形式](https://pillow.readthedocs.io/en/stable/handbook/image-file-formats.html) を確認した。今回のWindows環境で実際の依存取得・ビルド・画像処理を検証。
