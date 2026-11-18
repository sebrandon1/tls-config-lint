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

# Test: Detect Java from testdata
result=$(detect_languages "$ROOT_DIR/testdata/java" 2>/dev/null)
assert_contains "Detects Java from .java files" "java" "$result"

# Test: Detect Rust from testdata
result=$(detect_languages "$ROOT_DIR/testdata/rust" 2>/dev/null)
assert_contains "Detects Rust from .rs files" "rust" "$result"

# Test: Detect Kotlin from testdata
result=$(detect_languages "$ROOT_DIR/testdata/kotlin" 2>/dev/null)
assert_contains "Detects Kotlin from .kt files" "kotlin" "$result"
# Test: Detect C# from testdata
result=$(detect_languages "$ROOT_DIR/testdata/csharp" 2>/dev/null)
assert_contains "Detects C# from .cs files" "csharp" "$result"
# Test: Detect PHP from testdata (scanned — no unsupported notice)
result=$(detect_languages "$ROOT_DIR/testdata/php" 2>&1)
assert_contains "Detects PHP from .php files" "php" "$result"
assert_equals "No unsupported notice for PHP" "false" "$(printf '%s\n' "$result" | grep -q 'unsupported' && echo true || echo false)"
# Test: Detect Ruby from testdata (scanned — no unsupported notice)
result=$(detect_languages "$ROOT_DIR/testdata/ruby" 2>&1)
assert_contains "Detects Ruby from .rb files" "ruby" "$result"
assert_equals "No unsupported notice for Ruby" "false" "$(printf '%s\n' "$result" | grep -q 'unsupported' && echo true || echo false)"

# Test: Empty directory returns nothing
TEMP_DIR=$(mktemp -d)
result=$(detect_languages "$TEMP_DIR" 2>/dev/null)
assert_equals "Empty dir returns empty string" "" "$result"
rmdir "$TEMP_DIR"

# --- Deep and Extension-Only Detection Tests ---
echo "  --- Deep and Extension-Only Detection Tests ---"

# Test: A marker-less tree deeper than the fast-path depth still detects
deep_dir=$(mktemp -d)
mkdir -p "$deep_dir/a/b/c/d"
touch "$deep_dir/a/b/c/d/x.rb"
result=$(detect_languages "$deep_dir" 2>/dev/null)
assert_equals "Detects Ruby at depth 4" "ruby" "$result"
rm -rf "$deep_dir"

# Test: Extensions the scanner reads but the old walk missed
ext_dir=$(mktemp -d)
touch "$ext_dir/only.mjs"
result=$(detect_languages "$ext_dir" 2>/dev/null)
assert_equals "Detects Node.js from a lone .mjs file" "nodejs" "$result"
rm -rf "$ext_dir"

ext_dir=$(mktemp -d)
touch "$ext_dir/only.h"
result=$(detect_languages "$ext_dir" 2>/dev/null)
assert_equals "Detects C++ from a lone .h file" "cpp" "$result"
rm -rf "$ext_dir"

ext_dir=$(mktemp -d)
touch "$ext_dir/only.cxx"
result=$(detect_languages "$ext_dir" 2>/dev/null)
assert_equals "Detects C++ from a lone .cxx file" "cpp" "$result"
rm -rf "$ext_dir"

ext_dir=$(mktemp -d)
touch "$ext_dir/only.c"
result=$(detect_languages "$ext_dir" 2>/dev/null)
assert_equals "Detects C++ from a lone .c file" "cpp" "$result"
rm -rf "$ext_dir"

ext_dir=$(mktemp -d)
touch "$ext_dir/only.tsx"
result=$(detect_languages "$ext_dir" 2>/dev/null)
assert_equals "Detects Node.js from a lone .tsx file" "nodejs" "$result"
rm -rf "$ext_dir"

ext_dir=$(mktemp -d)
touch "$ext_dir/only.cjs"
result=$(detect_languages "$ext_dir" 2>/dev/null)
assert_equals "Detects Node.js from a lone .cjs file" "nodejs" "$result"
rm -rf "$ext_dir"

ext_dir=$(mktemp -d)
mkdir -p "$ext_dir/scripts"
touch "$ext_dir/scripts/build.kts"
result=$(detect_languages "$ext_dir" 2>/dev/null)
assert_equals "Detects Kotlin from a lone .kts script" "kotlin" "$result"
rm -rf "$ext_dir"

# Test: Build and dependency trees never count as detected source
skip_dir=$(mktemp -d)
mkdir -p "$skip_dir/vendor" "$skip_dir/node_modules"
touch "$skip_dir/vendor/x.rb" "$skip_dir/node_modules/y.js"
result=$(detect_languages "$skip_dir" 2>/dev/null)
assert_equals "Pruned directories do not trigger detection" "" "$result"
rm -rf "$skip_dir"

# Test: Deep source next to a pruned tree is still found
mixed_dir=$(mktemp -d)
mkdir -p "$mixed_dir/vendor" "$mixed_dir/services/api/src/handlers"
touch "$mixed_dir/vendor/x.rb"
touch "$mixed_dir/services/api/src/handlers/x.rb"
result=$(detect_languages "$mixed_dir" 2>/dev/null)
assert_equals "Deep source beside a pruned tree is detected" "ruby" "$result"
rm -rf "$mixed_dir"

# Test: The scan path itself is never pruned, even when named like a build dir
root_named_dir="$(mktemp -d)/build"
mkdir -p "$root_named_dir"
touch "$root_named_dir/x.go"
result=$(detect_languages "$root_named_dir" 2>/dev/null)
assert_equals "Scan path named build is still walked" "go" "$result"
rm -rf "${root_named_dir%/build}"

# Test: The unsupported notice is logged once even on the deep walk
swift_dir=$(mktemp -d)
mkdir -p "$swift_dir/a/b/c/d"
touch "$swift_dir/a/b/c/d/x.swift"
result=$(detect_languages "$swift_dir" 2>&1)
swift_notices=$(printf '%s\n' "$result" | grep -c "Swift (not scanned)" || true)
assert_equals "Unsupported notice logged once on deep walk" "1" "$swift_notices"
rm -rf "$swift_dir"

# --- Marker File Detection Tests ---
echo "  --- Marker File Detection Tests ---"

# Test: Detect Go from go.mod (no .go files)
marker_dir=$(mktemp -d)
touch "$marker_dir/go.mod"
result=$(detect_languages "$marker_dir" 2>/dev/null)
assert_contains "Detects Go from go.mod marker" "go" "$result"
rm -rf "$marker_dir"

# Test: Detect Python from pyproject.toml
marker_dir=$(mktemp -d)
touch "$marker_dir/pyproject.toml"
result=$(detect_languages "$marker_dir" 2>/dev/null)
assert_contains "Detects Python from pyproject.toml marker" "python" "$result"
rm -rf "$marker_dir"

# Test: Detect Python from requirements.txt
marker_dir=$(mktemp -d)
touch "$marker_dir/requirements.txt"
result=$(detect_languages "$marker_dir" 2>/dev/null)
assert_contains "Detects Python from requirements.txt marker" "python" "$result"
rm -rf "$marker_dir"

# Test: Detect Node.js from package.json
marker_dir=$(mktemp -d)
touch "$marker_dir/package.json"
result=$(detect_languages "$marker_dir" 2>/dev/null)
assert_contains "Detects Node.js from package.json marker" "nodejs" "$result"
rm -rf "$marker_dir"

# Test: Detect C++ from CMakeLists.txt
marker_dir=$(mktemp -d)
touch "$marker_dir/CMakeLists.txt"
result=$(detect_languages "$marker_dir" 2>/dev/null)
assert_contains "Detects C++ from CMakeLists.txt marker" "cpp" "$result"
rm -rf "$marker_dir"

# Test: Detect Java from pom.xml
marker_dir=$(mktemp -d)
touch "$marker_dir/pom.xml"
result=$(detect_languages "$marker_dir" 2>/dev/null)
assert_contains "Detects Java from pom.xml marker" "java" "$result"
rm -rf "$marker_dir"

# Test: Detect Rust from Cargo.toml
marker_dir=$(mktemp -d)
touch "$marker_dir/Cargo.toml"
result=$(detect_languages "$marker_dir" 2>/dev/null)
assert_contains "Detects Rust from Cargo.toml marker" "rust" "$result"
rm -rf "$marker_dir"

# Test: Detect Kotlin from build.gradle.kts with source beyond find maxdepth
marker_dir=$(mktemp -d)
touch "$marker_dir/build.gradle.kts"
mkdir -p "$marker_dir/src/main/kotlin/com/acme"
touch "$marker_dir/src/main/kotlin/com/acme/insecure.kt"
result=$(detect_languages "$marker_dir" 2>/dev/null)
assert_contains "Detects Kotlin from build.gradle.kts marker" "kotlin" "$result"
rm -rf "$marker_dir"

# Test: Detect Kotlin from settings.gradle.kts (no .kt files)
marker_dir=$(mktemp -d)
touch "$marker_dir/settings.gradle.kts"
result=$(detect_languages "$marker_dir" 2>/dev/null)
assert_contains "Detects Kotlin from settings.gradle.kts marker" "kotlin" "$result"
rm -rf "$marker_dir"

# Test: Detect C# from .csproj with source beyond find maxdepth
marker_dir=$(mktemp -d)
touch "$marker_dir/Project.csproj"
mkdir -p "$marker_dir/src/Services/Deep"
touch "$marker_dir/src/Services/Deep/insecure.cs"
result=$(detect_languages "$marker_dir" 2>/dev/null)
assert_contains "Detects C# from .csproj marker" "csharp" "$result"
rm -rf "$marker_dir"

# Test: Detect C# from .sln (no .cs files)
marker_dir=$(mktemp -d)
touch "$marker_dir/Project.sln"
result=$(detect_languages "$marker_dir" 2>/dev/null)
assert_contains "Detects C# from .sln marker" "csharp" "$result"
rm -rf "$marker_dir"

# Test: Detect Ruby from Gemfile (no .rb files)
marker_dir=$(mktemp -d)
touch "$marker_dir/Gemfile"
result=$(detect_languages "$marker_dir" 2>/dev/null)
assert_contains "Detects Ruby from Gemfile marker" "ruby" "$result"
rm -rf "$marker_dir"

# Test: Detect PHP from composer.json (no .php files)
marker_dir=$(mktemp -d)
touch "$marker_dir/composer.json"
result=$(detect_languages "$marker_dir" 2>/dev/null)
assert_contains "Detects PHP from composer.json marker" "php" "$result"
rm -rf "$marker_dir"

# Test: Swift files still produce the unsupported notice
marker_dir=$(mktemp -d)
touch "$marker_dir/insecure.swift"
result=$(detect_languages "$marker_dir" 2>&1)
assert_contains "Swift still logs unsupported notice" "Swift (not scanned)" "$result"
rm -rf "$marker_dir"

# --- Multi-Language Detection ---
echo "  --- Multi-Language Detection Tests ---"

# Test: Detect multiple languages from marker files
multi_dir=$(mktemp -d)
touch "$multi_dir/go.mod"
mkdir -p "$multi_dir/src"
touch "$multi_dir/src/app.py"
result=$(detect_languages "$multi_dir" 2>/dev/null)
assert_contains "Multi-lang detects Go" "go" "$result"
assert_contains "Multi-lang detects Python" "python" "$result"
rm -rf "$multi_dir"

# Test: Result is comma-separated
multi_dir=$(mktemp -d)
touch "$multi_dir/go.mod"
touch "$multi_dir/package.json"
touch "$multi_dir/Cargo.toml"
result=$(detect_languages "$multi_dir" 2>/dev/null)
stripped="${result//[^,]/}"
comma_count=${#stripped}
assert_equals "Multi-lang result has commas" "2" "$comma_count"
rm -rf "$multi_dir"
