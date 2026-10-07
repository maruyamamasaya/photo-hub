# ネイティブ写真管理: ローカル検証まで

## Request
7段階ロードマップに沿って、個人iPhone向けSwiftUI写真管理を実装・検証する。各段階のプロンプトを文書化する。S3未設定ならローカルでテストし、設定方法を残す。

## Investigation
空のGitから開始。Xcode 26.6 / Swift 6.3.3 / XcodeGenを利用可能。AWS CLIとSAM CLIは未導入。iOS 17.4・26.5シミュレータを利用。複数の実機iPhoneが認識されており、インストール先と署名Teamをユーザーへ照会した。秘密値や既存写真ライブラリを探索していない。

## Changes
| 段階 | 実装内容 | 検証と残る制限 |
| --- | --- | --- |
| 1 設計 | 画面、モデル、キー、認証、JSON、形式、費用、実機手順 | Apple/AWS一次資料を確認。AWS実利用量は未測定 |
| 2 端末内 | 複数原本取込、SQLite、日時順グリッド、詳細 | シミュレータのHEIC/JPEG各1枚を実際に取り込んだ。PhotosPickerの資産ID未取得問題を修正 |
| 3 保存 | PKCE、JWT署名API、PUT/HEAD照合、永続状態、再試行、ローカル保存 | 原本の改変検出・部分保存後の同一ID再試行をテスト。本番AWS結合は未実施 |
| 4 閲覧 | 派生512/2048px、遅延グリッド、ページ送り、ズーム、512MB LRU、原本解放条件 | 詳細HEIC表示とLRUテスト。実機ピンチ・容量不足・一覧性能は未確認 |
| 5 整理 | アルバム、お気に入り、原本写真ライブラリ保存、確認付き削除、削除再試行 | お気に入りを手動確認。所属と削除の整合性を統合テスト。AWS削除はtombstoneと6分猶予 |
| 6 復元 | version 1 JSON、正常版保持、latest、空DB復元、所有者/キー検証 | 2回のバックアップを手動確認。空DB復元と再閲覧・削除を統合テスト。機種変更の実AWS検証は未実施 |
| 7 仕上げ | 標準verify、実機チェックリスト、AWSセットアップ、制限の整理 | iOS 17.4/26.5で統合テスト成功。実機インストール・AWSデプロイは未実施 |

## Files Changed
- アプリ: ios/PhotoHub/、ios/PhotoHubTests/、ios/project.yml、生成済みPhotoHub.xcodeproj。
- 共有: Package.swift、Sources/PhotoHubCore/、Tests/PhotoHubCoreTests/。
- クラウド: backend/app.pyとtests、infrastructure/auth.yamlとservice.yaml。
- 文書: docs/DESIGN.md、phases/01–07-prompt.md、AWS-SETUP.md、DEVICE-CHECKLIST.md、decisions/0002と0003。
- 導線: ルートの役割別文書、ios/backend AGENTS、scripts/verify.sh、.gitignoreを更新。

## Validation
- 標準 `sh scripts/verify.sh` 成功: 文書、Python API 8テスト、Swift共有9テスト、AWS YAML構文、署名なしiOS Build。
- iOS統合: iOS 17.4と26.5で保存→バックアップ→空DB復元→画像再取得→削除、派生欠損→再試行の2ケース成功。iOS 17.4の最終版はさらに本番設定不足でローカルへフォールバックしないケースを含む。
- シミュレータ手動: 2枚取込、HEIC詳細、お気に入り、ローカル全3オブジェクト保存、JSONバックアップ2回成功。
- メタデータ1万件: Macのテスト環境でinsert約0.98秒、全件load約0.065秒。実機の画像スクロール性能とは別の測定。
- CloudFormation/SAMの意味的検証、実AWS、実機写真権限・原本保存・ネットワーク中断・容量不足・大量画像スクロールは未実施。

## Result
ローカル開発モードで動作するアプリと、認証必須の本番コード・非公開S3テンプレート・設定手順を用意。開発モードは端末内のみで、S3や機種変更バックアップの代替ではない。現在地と未確認事項をCURRENTに残した。

## Remaining Issues
実機端末と署名Team指定待ち。ユーザーの追加指示に従いAWSは仮ローカルで保留。有料リソース作成時は構成・費用を確認する。前景ファイル単位再送のみ、原本100MB上限、Live Photo静止画のみ、RAW/動画非対応。開発データのAWS自動移行とCI/CDは未実装。
