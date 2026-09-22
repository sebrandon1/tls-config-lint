#!/usr/bin/env bash
# detect.sh - Language auto-detection

set -euo pipefail

# Detect languages present in the scan path
# Returns comma-separated list of detected languages
detect_languages() {
	local scan_path="$1"
	local detected=()
	local has_go=false
	local has_python=false
	local has_nodejs=false
	local has_cpp=false
	local has_csharp=false
	local has_java=false
	local has_rust=false
	local has_kotlin=false
	local has_php=false
	local has_ruby=false
	local has_unsupported_php=false
	local has_unsupported_ruby=false
	local has_unsupported_swift=false

	# Check marker files without walking the scan path.
	[[ -f "$scan_path/go.mod" ]] && has_go=true
	[[ -f "$scan_path/setup.py" || -f "$scan_path/pyproject.toml" || -f "$scan_path/requirements.txt" ]] && has_python=true
	[[ -f "$scan_path/package.json" ]] && has_nodejs=true
	[[ -f "$scan_path/CMakeLists.txt" ]] && has_cpp=true
	[[ -f "$scan_path/pom.xml" || -f "$scan_path/build.gradle" ]] && has_java=true
	[[ -f "$scan_path/Cargo.toml" ]] && has_rust=true

	# Find all supported and unsupported source files in one traversal. The
	# per-language checks above used to repeat this walk for every extension.
	while IFS= read -r -d '' file; do
		case "$file" in
			*.go) has_go=true ;;
			*.py) has_python=true ;;
			*.js | *.ts) has_nodejs=true ;;
			*.cpp | *.cc | *.hpp) has_cpp=true ;;
			*.cs) has_csharp=true ;;
			*.java) has_java=true ;;
			*.rs) has_rust=true ;;
			*.kt) has_kotlin=true ;;
			*.php)
				has_php=true
				has_unsupported_php=true
				;;
			*.rb)
				has_ruby=true
				has_unsupported_ruby=true
				;;
			*.swift) has_unsupported_swift=true ;;
		esac
	done < <(find "$scan_path" -maxdepth 3 -type f \( \
		-name '*.go' -o -name '*.py' -o -name '*.js' -o -name '*.ts' \
		-o -name '*.cpp' -o -name '*.cc' -o -name '*.hpp' -o -name '*.cs' \
		-o -name '*.java' -o -name '*.rs' -o -name '*.kt' -o -name '*.php' \
		-o -name '*.rb' -o -name '*.swift' \
		\) -print0 2>/dev/null)

	$has_go && detected+=("go")
	$has_python && detected+=("python")
	$has_nodejs && detected+=("nodejs")
	$has_cpp && detected+=("cpp")
	$has_csharp && detected+=("csharp")
	$has_java && detected+=("java")
	$has_rust && detected+=("rust")
	$has_kotlin && detected+=("kotlin")
	$has_php && detected+=("php")
	$has_ruby && detected+=("ruby")

	# Check for unsupported languages and notify
	local unsupported=()
	if $has_unsupported_ruby; then
		unsupported+=("Ruby")
	fi

	if $has_unsupported_php; then
		unsupported+=("PHP")
	fi
	if $has_unsupported_swift; then
		unsupported+=("Swift")
	fi
	if [[ ${#unsupported[@]} -gt 0 ]]; then
		local unsup_list
		unsup_list=$(
			IFS=', '
			echo "${unsupported[*]}"
		)
		log_msg "Note: detected unsupported language(s): $unsup_list (not scanned)"
	fi

	if [[ ${#detected[@]} -eq 0 ]]; then
		log_msg "No supported languages detected in $scan_path"
		echo ""
		return 0
	fi

	local result
	result=$(
		IFS=','
		echo "${detected[*]}"
	)
	log_msg "Detected languages: $result"
	echo "$result"
}
