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

# Version gate: every module version constant must be identical and carry no pre-release suffix.
module_versions="$(grep -hoE 'static let version = "[^"]+"' Sources/*/*.swift | sed -E 's/.*"([^"]+)".*/\1/' | sort -u)"
if [[ "$(printf '%s\n' "$module_versions" | grep -c .)" -ne 1 ]]; then
  echo "Module version constants are not identical:" >&2
  grep -rnE 'static let version = ' Sources >&2
  exit 1
fi
if [[ "$module_versions" == *-* ]]; then
  echo "Module version carries a pre-release suffix: $module_versions" >&2
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
