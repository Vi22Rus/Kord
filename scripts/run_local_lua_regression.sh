#!/usr/bin/env bash
# Run locally in a checked-out Kord repository. No GitHub Actions usage.
set -euo pipefail
cd "$(dirname "$0")/.."
# Contract acceptance must run under real Lua 5.1; texlua often embeds Lua 5.3.
# Do not silently report Lua 5.3 mock results as 5.1 regression.
if ! command -v lua5.1 >/dev/null 2>&1; then
  echo "Lua 5.1 required for contract regression (texlua is not a substitute)" >&2
  exit 2
fi
runner=lua5.1
version_check=$(mktemp)
trap 'rm -f "$version_check"' EXIT
printf '%s\n' 'assert(_VERSION == "Lua 5.1", "expected Lua 5.1, got "..tostring(_VERSION))' > "$version_check"
"$runner" "$version_check"
# Syntax validation of all shipped addon modules and tests (without running them).
while IFS= read -r -d '' f; do
  "$runner" scripts/check_lua_syntax.lua "$f"
done < <(find KordRotation KordRotationDevTools tests -type f -name '*.lua' -print0)

if (( $# > 0 )); then
  tests=("$@")
else
  tests=(
    tests/stage_02_03_game_state.lua
    tests/stage_02_04_spell_catalogue.lua
    tests/stage_02_05_actionbar.lua
    tests/stage_02_06_bindings.lua
    tests/stage_02_07_eligibility.lua
    tests/profile_contract_v1.lua
    tests/stage_02_08_v14_state.lua
    tests/stage_02_08_v14_argument_guards.lua
    tests/stage_02_08_v14_display.lua
    tests/stage_02_08_v14_observation.lua
    tests/devtools_recorder.lua
    tests/devtools_probe.lua
    tests/devtools_trace.lua
    tests/devtools_boot.lua
    tests/devtools_ui_locale.lua
    tests/devtools_v14_registry.lua
    tests/devtools_trace_signals.lua
  )
fi
for t in "${tests[@]}"; do
  echo "RUN $t ($runner)"
  "$runner" "$t"
done
python3 -m unittest discover -s tests -p 'test_build_variants.py' -v
echo "PASS local Lua/Python regression (${#tests[@]} Lua suites), NOT an in-game test"
