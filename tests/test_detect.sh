#!/usr/bin/env bash
# test_detect.sh - Language detection tests

# Source library modules
source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/lib/detect.sh"

echo "  --- Language Detection Tests ---"

# Test: Detect Go from testdata
result=$(detect_languages "$ROOT_DIR/testdata/go" 2>/dev/null)
assert_contains "Detects Go from .go files" "go" "$result"

# Test: Detect Python from testdata
result=$(detect_languages "$ROOT_DIR/testdata/python" 2>/dev/null)
assert_contains "Detects Python from .py files" "python" "$result"

# Test: Detect Node.js from testdata
result=$(detect_languages "$ROOT_DIR/testdata/nodejs" 2>/dev/null)
assert_contains "Detects Node.js from .js files" "nodejs" "$result"

# Test: Detect C++ from testdata
result=$(detect_languages "$ROOT_DIR/testdata/cpp" 2>/dev/null)
assert_contains "Detects C++ from .cpp files" "cpp" "$result"

# Test: Empty directory returns nothing
TEMP_DIR=$(mktemp -d)
result=$(detect_languages "$TEMP_DIR" 2>/dev/null)
assert_equals "Empty dir returns empty string" "" "$result"
rmdir "$TEMP_DIR"
