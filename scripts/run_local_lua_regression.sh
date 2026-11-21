#!/usr/bin/env bash
# Run locally in a checked-out Kord repository. No GitHub Actions usage.
set -euo pipefail
cd "$(dirname "$0")/.."
if command -v lua5.1 >/dev/null 2>&1; then
  runner=lua5.1
elif command -v texlua >/dev/null 2>&1; then
  runner=texlua
else
  echo "Lua interpreter unavailable: install Lua 5.1 or TeX Lua" >&2
  exit 2
fi
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
    tests/stage_02_08_rotation_engine.lua
    tests/stage_02_08_v14_state.lua
    tests/stage_02_08_v14_argument_guards.lua
    tests/stage_02_08_v14_rotation_contract.lua
    tests/stage_02_08_v14_display.lua
    tests/stage_02_08_v14_observation.lua
    tests/devtools_recorder.lua
    tests/devtools_probe.lua
    tests/devtools_trace.lua
    tests/devtools_boot.lua
    tests/devtools_ui_locale.lua
    tests/devtools_v14_registry.lua
  )
fi
for t in "${tests[@]}"; do
  echo "RUN $t ($runner)"
  "$runner" "$t"
done
python3 -m unittest discover -s tests -p 'test_build_variants.py' -v
echo "PASS local Lua/Python regression (${#tests[@]} Lua suites), NOT an in-game test"
