#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
if [ ! -x .venv/bin/python ] || [ ! -f desktop/node_modules/electron/package.json ]; then
  echo 'Run sh scripts/setup-desktop.sh first.' >&2
  exit 1
fi
npm run build --prefix web
exec npm start --prefix desktop -- "$@"
