#!/usr/bin/env bash
# detect.sh - Language auto-detection

set -euo pipefail

# Detect languages present in the scan path
# Returns comma-separated list of detected languages
detect_languages() {
	local scan_path="$1"
	local detected=()

	# Go: check for go.mod or *.go files
	if [[ -f "$scan_path/go.mod" ]] || find "$scan_path" -maxdepth 3 -name '*.go' -print -quit 2>/dev/null | grep -q .; then
		detected+=("go")
	fi

	# Python: check for setup.py, pyproject.toml, requirements.txt, or *.py files
	if [[ -f "$scan_path/setup.py" ]] || [[ -f "$scan_path/pyproject.toml" ]] || [[ -f "$scan_path/requirements.txt" ]] ||
		find "$scan_path" -maxdepth 3 -name '*.py' -print -quit 2>/dev/null | grep -q .; then
		detected+=("python")
	fi

	# Node.js/TypeScript: check for package.json or *.js/*.ts files
	if [[ -f "$scan_path/package.json" ]] ||
		find "$scan_path" -maxdepth 3 \( -name '*.js' -o -name '*.ts' \) -print -quit 2>/dev/null | grep -q .; then
		detected+=("nodejs")
	fi

	# C++: check for CMakeLists.txt, Makefile with cpp, or *.cpp/*.cc/*.h/*.hpp files
	if [[ -f "$scan_path/CMakeLists.txt" ]] ||
		find "$scan_path" -maxdepth 3 \( -name '*.cpp' -o -name '*.cc' -o -name '*.hpp' \) -print -quit 2>/dev/null | grep -q .; then
		detected+=("cpp")
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
