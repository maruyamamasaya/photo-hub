# ローカル素材API
Python/FastAPI、標準SQLite、Pillow。原本を無加工で保持し、既存backendのAWS署名APIと混在させない。
contracts/asset.schema.jsonをDTOの正本にする。変更後は型生成と契約検証を実行。
検証入口: リポジトリルートで `python -m unittest discover -s local-api/tests -v`。
テストはTemporaryDirectoryを使用し、開発DBや入力素材を消さない。実データとDBをGitに追加しない。
