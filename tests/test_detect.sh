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
