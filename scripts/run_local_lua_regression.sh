#!/usr/bin/env bash
# Lua 5.1 mock regression; default discovery includes all legacy and new tests.
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v lua5.1 >/dev/null 2>&1; then
  echo "NOT RUN: lua5.1 executable is missing" >&2
  exit 2
fi
lua5.1 -e 'assert(_VERSION == "Lua 5.1", "expected Lua 5.1, got "..tostring(_VERSION))'
syntax_pass=0
syntax_fail=0
while IFS= read -r -d '' f; do
  if lua5.1 scripts/check_lua_syntax.lua "$f"; then
    syntax_pass=$((syntax_pass + 1))
  else
    echo "SYNTAX FAIL $f" >&2
    syntax_fail=$((syntax_fail + 1))
  fi
done < <(find KordRotation KordRotationDevTools tests -type f -name '*.lua' -print0 | sort -z)
echo "SYNTAX: $syntax_pass PASS, $syntax_fail FAIL"
if (( $# > 0 )); then
  tests=("$@")
else
  mapfile -d '' -t tests < <(find tests -type f -name '*.lua' -print0 | sort -z)
fi
if (( ${#tests[@]} == 0 )); then
  echo "FAIL: no Lua tests selected" >&2
  exit 1
fi
lua_pass=0
lua_fail=0
failed=()
for t in "${tests[@]}"; do
  echo "RUN $t (Lua 5.1)"
  if lua5.1 "$t"; then
    echo "PASS $t"
    lua_pass=$((lua_pass + 1))
  else
    echo "FAIL $t" >&2
    lua_fail=$((lua_fail + 1))
    failed+=("$t")
  fi
done
echo "LUA 5.1 MOCK: $lua_pass PASS, $lua_fail FAIL of ${#tests[@]}"
if (( lua_fail > 0 )); then printf 'FAILED: %s\n' "${failed[@]}" >&2; fi
python_status=0
python3 -m unittest discover -s tests -p 'test_build_variants.py' -v || python_status=$?
if (( python_status == 0 )); then
  echo "PYTHON PACKAGING: PASS"
else
  echo "PYTHON PACKAGING: FAIL (exit $python_status)" >&2
fi
if (( syntax_fail > 0 || lua_fail > 0 || python_status > 0 )); then
  echo "FAIL local regression; WoW Forever remains NOT RUN" >&2
  exit 1
fi
echo "PASS local Lua 5.1 mock and Python regression; WoW Forever NOT RUN"
