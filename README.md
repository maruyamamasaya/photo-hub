# Photo Hub

iPhone一台で使う、個人向けのネイティブ写真管理アプリです。SwiftUIとSQLiteで写真を整理し、原本・派生画像・JSONバックアップを非公開S3へ保存する構成です。

現在は開発用ローカル保存で試せます。AWSリソースはまだ作成していません。

## 試す
1. `ios/PhotoHub.xcodeproj` をXcodeで開く。
2. PhotoHub schemeとiPhoneシミュレータを選んで実行する。
3. 写真タブの＋から取り込む。
4. 設定で未完了アップロードを実行し、ローカル保存とJSONバックアップを試す。

実機へのインストール・起動・運用は [OPERATIONS.md](OPERATIONS.md)、AWS設定は [セットアップ手順](docs/AWS-SETUP.md)。ローカル保存は同じ端末内のため、アプリ削除や機種変更では失われます。

## 開発情報
- [AI作業ルール](AGENTS.md)
- [現在地](CURRENT.md)
- [システム構成](ARCHITECTURE.md)
- [コード探索の入口](CODEMAP.md)
- [検証方法](TESTING.md)
- [設計案と費用](docs/DESIGN.md)
- [設計判断](decisions/README.md)
- [作業記録](sessions/README.md)
- [実機チェックリストと制限](docs/DEVICE-CHECKLIST.md)
