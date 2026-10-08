# 01: 共通仕様と起動基盤
## 実行プロンプト
ローカルWeb素材ライブラリの基盤を構築する。React/TypeScript/ViteとPython/FastAPI/SQLiteを使用し、依存と起動手順を固定する。APIは127.0.0.1のみ、開発用所有者のみでクラウド設定を要求しない。既存iOS/AWS実装は別に保持する。

contractsにJSON Schema、API仕様とサンプルを置く。Asset/AssetFile/Tag/Collectionを定義し、TypeScriptとSwift Codable DTOを生成する入口を作る。日時はUTC文字列、幅高さはnullable、素材種別は拡張可能な文字列、URL/絶対パスは永続データに含めない。Swift DTOは別モジュールとして既存Photoを上書きしない。
## 完了条件と検証
契約例を検証し、生成物が契約から再生成して一致する。新APIの起動設定に本番認証省略が混入しない。Windowsで依存準備が可能。Swiftのビルド・実機確認はこの環境では未実行と明記する。
