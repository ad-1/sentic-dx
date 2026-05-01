#!/usr/bin/env bash
# test-commit-msg-hook.sh — validate the commit-msg hook script against known pass/fail cases.
# Usage: ./scripts/test-commit-msg-hook.sh [/path/to/validate-commit-message.sh]
#
# By default validates the copy in the same repo. Pass a path to test a different repo's script.
set -euo pipefail

SCRIPT="${1:-$(git rev-parse --show-toplevel)/scripts/validate-commit-message.sh}"

if [[ ! -x "${SCRIPT}" ]]; then
  echo "ERROR: validator not found or not executable: ${SCRIPT}"
  exit 1
fi

PASS=0
FAIL=0
ERRORS=()

run_case() {
  local label="$1"
  local message="$2"
  local expect_exit="$3"   # 0 = should pass, 1 = should fail

  local tmpfile
  tmpfile="$(mktemp)"
  echo "${message}" > "${tmpfile}"

  local actual_exit=0
  "${SCRIPT}" "${tmpfile}" > /dev/null 2>&1 || actual_exit=$?
  rm -f "${tmpfile}"

  if [[ "${actual_exit}" -eq "${expect_exit}" ]]; then
    echo "  PASS  ${label}"
    ((PASS++)) || true
  else
    echo "  FAIL  ${label}"
    echo "        message : ${message}"
    echo "        expected exit ${expect_exit}, got ${actual_exit}"
    ERRORS+=("${label}")
    ((FAIL++)) || true
  fi
}

echo ""
echo "=== commit-msg validator: VALID messages (should all pass) ==="
run_case "ticket prefix short"          "SIG-42: simplify docker install layer order"              0
run_case "ticket prefix long prefix"    "NOTIFY-1: add telegram error handler"                     0
run_case "infra date-stamp prefix"      "INF-20260501-0840: document bootstrap prerequisites"      0
run_case "github-style prefix"          "GH-317: add smoke check for rabbitmq publisher"           0
run_case "starts with digit in body"    "SIG-1: 3rd attempt at fixing retry loop"                  0
run_case "10-char prefix"              "ABCDEFGHIJ-99: valid edge case prefix length"              0

echo ""
echo "=== commit-msg validator: INVALID messages (should all fail) ==="
run_case "no prefix"                    "add retry logic"                                          1
run_case "lowercase prefix"             "sig-42: add retry logic"                                  1
run_case "missing colon-space"          "SIG-42 add retry logic"                                   1
run_case "uppercase body"               "SIG-42: Add retry logic"                                  1
run_case "empty message"               ""                                                          1
run_case "colon but no body"           "SIG-42: "                                                  1
run_case "prefix too short (1 char)"   "S-42: add something"                                       1
run_case "prefix too long (11 chars)"  "ABCDEFGHIJK-1: add something"                              1
run_case "WIP style"                   "WIP"                                                       1
run_case "subject over 120 chars"      "SIG-1: $(python3 -c 'print("x" * 115)')"                  1

echo ""
echo "=== Results ==="
echo "  Passed : ${PASS}"
echo "  Failed : ${FAIL}"

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo ""
  echo "Failing cases:"
  for e in "${ERRORS[@]}"; do
    echo "  - ${e}"
  done
  exit 1
fi

echo "All cases passed."
