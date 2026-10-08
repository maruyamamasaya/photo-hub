#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
.venv/bin/python scripts/generate-contracts.py --check
.venv/bin/python scripts/verify.py
.venv/bin/python -m unittest discover -s local-api/tests -v
.venv/bin/python -m unittest discover -s backend/tests -v
npm run build --prefix web
npm run check --prefix desktop
npm test --prefix desktop
npm run smoke --prefix desktop
git diff --check
