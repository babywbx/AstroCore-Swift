#!/usr/bin/env bash

set -euo pipefail

swift test -c release
ASTROCORE_ENABLE_BASELINE_VERIFICATION=1 swift test -c release --filter Baseline

derived_data_path="$(mktemp -d "${TMPDIR:-/tmp}/astrocore-release-ios.XXXXXX")"
trap 'rm -rf "$derived_data_path"' EXIT

xcodebuild \
  -scheme AstroCore-Package \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$derived_data_path" \
  build

if command -v swiftformat >/dev/null 2>&1; then
  swiftformat . --config .swiftformat --lint
else
  echo "swiftformat not found; skipping format lint" >&2
fi

if command -v swiftlint >/dev/null 2>&1; then
  swiftlint lint . --config .swiftlint.yml --strict --force-exclude
else
  echo "swiftlint not found; skipping SwiftLint" >&2
fi
