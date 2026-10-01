#!/usr/bin/env bash
set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failures=0

valid='{
  "version": 1,
  "gitMinimum": "2.50.1",
  "dockerEngineMinimum": "27.1.1",
  "dotnetFrameworkMinimum": "4.6.2",
  "visualCppFirstSupportedYear": 2015,
  "windowsUpdateIgnore": ["Security Intelligence Update"]
}'

expect() {
  local outcome=$1 name=$2 filter=$3
  jq "$filter" <<<"$valid" >"$tmp/policy.json"
  if bash "$here/validate-policy.sh" "$tmp/policy.json" >/dev/null 2>&1; then actual=accepted; else actual=rejected; fi
  if [ "$actual" = "$outcome" ]; then
    echo "PASS: $name"
  else
    echo "FAIL: $name ($actual)"
    failures=$((failures + 1))
  fi
}

expect accepted "the seed policy" '.'
expect accepted "an empty ignore list" '.windowsUpdateIgnore = []'
expect rejected "version 2" '.version = 2'
expect rejected "missing gitMinimum" 'del(.gitMinimum)'
expect rejected "missing windowsUpdateIgnore" 'del(.windowsUpdateIgnore)'
expect rejected "a version with a suffix" '.dockerEngineMinimum = "27.1.1-rc1"'
expect rejected "a version as a number" '.dotnetFrameworkMinimum = 4.6'
expect rejected "a two-digit year" '.visualCppFirstSupportedYear = 15'
expect rejected "a year as a string" '.visualCppFirstSupportedYear = "2015"'
expect rejected "a blank ignore entry" '.windowsUpdateIgnore = [""]'

printf 'not json' >"$tmp/policy.json"
if bash "$here/validate-policy.sh" "$tmp/policy.json" >/dev/null 2>&1; then
  echo "FAIL: malformed JSON (accepted)"; failures=$((failures + 1))
else
  echo "PASS: malformed JSON"
fi

# jq keeps the last duplicate; device-check.sh's sed would read either.
sed 's/"gitMinimum": "2.50.1",/"gitMinimum": "2.0",\n  "gitMinimum": "2.50.1",/' <<<"$valid" >"$tmp/policy.json"
if bash "$here/validate-policy.sh" "$tmp/policy.json" >/dev/null 2>&1; then
  echo "FAIL: a duplicated field (accepted)"; failures=$((failures + 1))
else
  echo "PASS: a duplicated field"
fi

exit "$failures"
