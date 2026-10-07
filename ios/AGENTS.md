# iOS領域
ルートAGENTS.mdに加えて適用する。SwiftUI / PhotoKit / SQLiteを使用する。
- 原本はPHAssetResource `.photo` を書き出す。派生画像と原本を混同しない。
- 写真ライブラリの削除APIを使わない。
- UIとRepository更新はMainActor。画像変換はバックグラウンドで行う。
- pending原本はキャッシュ削除対象にしない。
- 本番クラウドはログイン必須。LocalObjectStoreは明示的な開発専用モード。
- ビルドと実機の検証方法はTESTING.md、導入はOPERATIONS.md。
