#!/usr/bin/env bash
# run_tests.sh - Test runner for tls-config-lint

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
export ROOT_DIR

PASS=0
FAIL=0
TOTAL=0

# Colors (if terminal supports them)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

assert_equals() {
	local description="$1"
	local expected="$2"
	local actual="$3"
	TOTAL=$((TOTAL + 1))

	if [[ "$expected" == "$actual" ]]; then
		echo -e "  ${GREEN}PASS${RESET}: $description"
		PASS=$((PASS + 1))
	else
		echo -e "  ${RED}FAIL${RESET}: $description"
		echo "    Expected: '$expected'"
		echo "    Actual:   '$actual'"
		FAIL=$((FAIL + 1))
	fi
}

assert_contains() {
	local description="$1"
	local needle="$2"
	local haystack="$3"
	TOTAL=$((TOTAL + 1))

	if [[ "$haystack" == *"$needle"* ]]; then
		echo -e "  ${GREEN}PASS${RESET}: $description"
		PASS=$((PASS + 1))
	else
		echo -e "  ${RED}FAIL${RESET}: $description"
		echo "    Expected to contain: '$needle'"
		echo "    In: '$haystack'"
		FAIL=$((FAIL + 1))
	fi
}

assert_greater_than() {
	local description="$1"
	local min="$2"
	local actual="$3"
	TOTAL=$((TOTAL + 1))

	if [[ "$actual" -gt "$min" ]]; then
		echo -e "  ${GREEN}PASS${RESET}: $description"
		PASS=$((PASS + 1))
	else
		echo -e "  ${RED}FAIL${RESET}: $description"
		echo "    Expected > $min, got $actual"
		FAIL=$((FAIL + 1))
	fi
}

echo "=== TLS Config Lint Test Suite ==="
echo ""

# Run test modules
for test_file in "$SCRIPT_DIR"/test_*.sh; do
	if [[ -f "$test_file" ]]; then
		echo -e "${YELLOW}Running $(basename "$test_file")...${RESET}"
		# shellcheck source=/dev/null
		source "$test_file"
		echo ""
	fi
done

# Summary
echo "=== Results ==="
echo -e "Total: $TOTAL | ${GREEN}Passed: $PASS${RESET} | ${RED}Failed: $FAIL${RESET}"

if [[ "$FAIL" -gt 0 ]]; then
	exit 1
fi
exit 0
