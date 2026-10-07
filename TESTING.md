# 検証方法

## Test Strategy
SQLite・キー・バックアップ・転送・キャッシュはSwift Packageのユニットテスト。署名APIはPythonのmock S3テスト。iOS統合テストは実際のPNG生成・派生生成・保存・復元・削除をローカルオブジェクト保存で確認する。AWS結合と実機特有の挙動は [DEVICE-CHECKLIST.md](docs/DEVICE-CHECKLIST.md)。

## Fast Validation
```sh
sh scripts/verify.sh --fast
```
文書verifyとPython APIテストを実行。Swift変更では関連するSwiftテストも実行する。

## Full Validation / 標準Verify
```sh
sh scripts/verify.sh
```
文書・Python APIテスト・Swift全テスト・AWS YAML構文・署名なしiOSビルドを実行。Xcode、Swift、Python 3、Rubyが必要。外部依存の取得は不要。`--disable-sandbox` はSwiftPMのビルド実行環境だけの設定で、API認証を無効化するものではない。

iOS統合テストは実行先シミュレータを選んで追加する（重い環境依存処理のため標準verifyと分離）:
```sh
xcodebuild -project ios/PhotoHub.xcodeproj -scheme PhotoHub -destination 'platform=iOS Simulator,id=YOUR_SIMULATOR_ID' -derivedDataPath /tmp/photo-hub-xcode CODE_SIGNING_ALLOWED=NO test
```

## Lint / Format / Typecheck / Unit / Integration / E2E / Build
| 対象 | 実在する入口 |
| --- | --- |
| 文書の必要項目・ローカルリンク・肥大化 | `python3 scripts/verify.py`（軽量は `--fast`） |
| SwiftのTypecheck / Build | Fullのxcodebuild |
| Swift Unit | `swift test --disable-sandbox --scratch-path /tmp/photo-hub-swift-build` |
| Python API Unit | `python3 -m unittest discover -s backend/tests -v` |
| iOS Integration | 上記xcodebuild test、`ios/PhotoHubTests/IntegrationTests.swift` |
| E2E | シミュレータで手動操作、実機チェックリスト |
| AWS | CLI導入後 `sam validate --lint` と実AWS結合検証 |

SwiftLint、独立したformat/typecheckコマンド、CI/CD、UI自動テストは未導入。YAML構文検証はCloudFormationの意味的検証を代替しない。

## 変更別の検証
| 変更 | 必要な検証 |
| --- | --- |
| 文書 | 文書verifyと実コードとの照合 |
| Swift共有モデル・SQL・転送 | Swift Unit + iOS Build、復元・保存変更はIntegration |
| SwiftUI / PhotoKit / 画像生成 | iOS Build + Integration + 関連画面の操作確認 |
| API / IAM / 認証 | Python API Unit + YAML構文 + SAM検証・実AWS検証（可能な場合） |
| 全体構成 | Full + iOS Integration |

## 文書Verify自体の限界
必須文書・必要項目・README導線・ローカルリンク先・文書の行数を確認する。外部URLの到達性、アンカー、文章とコードの意味的一致は判定しない。詳細を分割する時は役割ごとの正本へリンクする。
