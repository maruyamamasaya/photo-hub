# コード探索の入口

| Feature | Primary paths | Search keywords / Key entry points | Related tests |
| --- | --- | --- | --- |
| アプリ入口・画面 | `ios/PhotoHub/PhotoHubApp.swift`, `Views.swift` | `PhotoHubApp`, `RootView`, `PhotoGrid`, `PhotoDetail`, `SettingsView` | シミュレータ手動、実機チェックリスト |
| 原本取り込み・派生 | `ios/PhotoHub/PhotoImporter.swift` | `importAsset`, `PHAssetResource`, `derivatives` | `IntegrationTests`、実写真手動 |
| 写真モデル・SQLite | `Sources/PhotoHubCore/Models.swift`, `Repository.swift` | `Photo`, `UploadState`, `photos`, `albums`, `memberships`, `recoverInterruptedUploads` | `Tests/PhotoHubCoreTests/CoreTests.swift` |
| アップロードと再試行 | `Sources/PhotoHubCore/PhotoTransfer.swift`, `ios/PhotoHub/LibraryModel.swift` | `PhotoTransfer.upload`, `uploadPending`, `head`, `checksum` | `testPartialUploadThenRetryKeepsStableID`, `testFailedUploadPreservesPendingOriginalAndRecovers` |
| 本人認証・S3通信 | `ios/PhotoHub/Cloud.swift` | `Authentication`, `ASWebAuthenticationSession`, `S3ObjectStore`, `token`, `/objects` | 実AWS結合は未実施 |
| 署名API | `backend/app.py` | `handler`, `validate_key`, `OWNER_SUB`, `BUCKET`, `tombstone` | `backend/tests/test_api.py` |
| ローカル保存・キャッシュ | `Sources/PhotoHubCore/ObjectStore.swift`, `LibraryModel.swift` | `LocalObjectStore`, `DevelopmentObjects`, `DiskCache`, `trim`, `image` | `CoreTests`, `IntegrationTests` |
| 整理・削除・原本保存 | `LibraryModel.swift`, `Views.swift` | `toggleMembership`, `setFavorite`, `requestDelete`, `finishDelete`, `saveOriginal` | `IntegrationTests`, `CoreTests` |
| JSONバックアップ・復元 | `Models.swift`, `Repository.swift`, `LibraryModel.swift` | `Backup.validate`, `snapshot`, `restore`, `schemaVersion`, `latest.json` | `CoreTests`, `IntegrationTests` |
| デプロイ | `infrastructure/auth.yaml`, `service.yaml` | `OwnerJWT`, `OwnerSub`, `BlockPublicAccess`, `BucketPolicy` | YAML構文、SAM/実AWSは未実施 |
| 検証入口 | `scripts/verify.sh`, `verify.py` | `--fast`, `REQUIRED`, `local_links` | 文書verifyの異常系確認 |

パスの短縮表記は表内の同じ領域にあるファイルを指す。領域固有のルールは `ios/AGENTS.md`、`backend/AGENTS.md` を変更前に読む。

## 検索の使い分け
| 分かっていること | 手段 |
| --- | --- |
| 概念だけ | 利用可能ならsemantic/repository search。なければ本書から語彙を選ぶ |
| 関数・クラス・コンポーネント名 | symbol / exact search |
| APIパス・テーブル名・環境変数・エラー文字列 | `rg -n -F '文字列' 対象ディレクトリ` |
| 呼び出し元と変更影響 | references search、名前の検索、関連テスト検索 |
| TODO / FIXME | `rg -n 'TODO|FIXME' Sources ios backend` |

`rg --files`で配置を確認し、検索範囲を絞る。追跡済みコードは `git grep -n '語句'` でも検索できるが、未追跡ファイルは `rg` を使う。入口 → 処理 → データアクセス → 外部依存 → テストの順に必要な部分だけ読む。

semantic indexやlanguage serverの設定は存在しない。将来利用可能になった場合も、検索結果の定義・参照を実コードで確認する。
