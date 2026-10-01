#!/usr/bin/env bash
set -euo pipefail

# Rejects any policy.json that Device Check would ignore, mirroring policy_usable in
# device-check.sh and Test-PolicyUsable in device-check.ps1.
#   bash scripts/validate-policy.sh [policy.json]

file=${1:-policy.json}

jq -e '
  def version: type == "string" and test("^[0-9]+(\\.[0-9]+)*$");
  .version == 1
  and (.deviceCheckLatest | type == "string" and test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))
  and (.gitMinimum | version)
  and (.dockerEngineMinimum | version)
  and (.dotnetFrameworkMinimum | version)
  and (.visualCppFirstSupportedYear | type == "number" and . >= 1000 and . <= 9999 and floor == .)
  and (.windowsUpdateIgnore | type == "array" and all(type == "string" and length > 0))
' "$file" >/dev/null || {
  echo "$file is not a policy Device Check can use; see README.md" >&2
  exit 1
}

# device-check.sh reads fields with sed, one line at a time.
for field in version gitMinimum dockerEngineMinimum dotnetFrameworkMinimum visualCppFirstSupportedYear; do
  [ "$(grep -c "\"$field\"" "$file")" -eq 1 ] || {
    echo "$file: \"$field\" must appear on exactly one line" >&2
    exit 1
  }
done

echo "$file is valid"
