#!/usr/bin/env bash

set -euo pipefail

missing_tools=()
for tool in swiftformat swiftlint; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    missing_tools+=("$tool")
  fi
done

if ((${#missing_tools[@]} > 0)); then
  printf 'Missing required release verification tool(s): %s\n' "${missing_tools[*]}" >&2
  echo "Install them with: brew install swiftformat swiftlint" >&2
  exit 1
fi

swift test -c release
ASTROCORE_ENABLE_BASELINE_VERIFICATION=1 swift test -c release --filter Baseline

derived_data_path="$(mktemp -d "${TMPDIR:-/tmp}/astrocore-release-ios.XXXXXX")"
trap 'rm -rf "$derived_data_path"' EXIT

xcodebuild \
  -scheme AstroCore-Package \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$derived_data_path" \
  build

swiftformat . --config .swiftformat --lint
swiftlint lint . --config .swiftlint.yml --strict --force-exclude
