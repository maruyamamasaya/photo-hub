#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
python3 scripts/verify.py
python3 -m unittest discover -s backend/tests
if [ "${1:-}" = "--fast" ]; then
  exit 0
fi
export CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/photo-hub-clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="${TMPDIR:-/tmp}/photo-hub-swift-cache"
swift test --disable-sandbox --scratch-path "${TMPDIR:-/tmp}/photo-hub-swift-build"
ruby -rpsych -e 'ARGV.each { |path| Psych.parse_file(path); puts "YAML syntax OK: #{path}" }' infrastructure/auth.yaml infrastructure/service.yaml
xcodebuild -project ios/PhotoHub.xcodeproj -scheme PhotoHub -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath "${TMPDIR:-/tmp}/photo-hub-xcode" CODE_SIGNING_ALLOWED=NO build
