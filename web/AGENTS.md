# Web素材ライブラリ
React/TypeScript/Vite。永続データはAPIを正本とし、localStorageへ素材情報を保存しない。
contractsから生成した型を使い、手書きの並行モデルを作らない。
検証: `npm run build`（TypeScript含む）。ブラウザで追加・整理・取得のデータ経路を確認する。
ローカルAPIは同じoriginの/apiを通す。個人素材、node_modules、distをGitへ追加しない。
