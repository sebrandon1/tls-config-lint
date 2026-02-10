#!/usr/bin/env bash
# scanner.sh - Core grep-based scanning engine

set -euo pipefail

# Global findings storage
# Each finding: "id|severity|name|description|file|line|match"
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0

# Build grep --include flags for a language
build_include_flags() {
	local lang="$1"
	case "$lang" in
	go) echo "--include=*.go" ;;
	python) echo "--include=*.py" ;;
	nodejs) echo "--include=*.js --include=*.mjs --include=*.ts --include=*.mts" ;;
	cpp) echo "--include=*.cpp --include=*.cc --include=*.cxx --include=*.h --include=*.hpp" ;;
	esac
}

# Build grep --exclude flags for test files
build_test_exclude_flags() {
	local lang="$1"
	case "$lang" in
	go) echo "--exclude=*_test.go" ;;
	python) echo "--exclude=*_test.py --exclude=test_*.py --exclude=conftest.py" ;;
	nodejs) echo "--exclude=*.test.js --exclude=*.spec.js --exclude=*.test.mjs --exclude=*.spec.mjs --exclude=*.test.ts --exclude=*.spec.ts --exclude=*.test.mts --exclude=*.spec.mts" ;;
	cpp) echo "--exclude=*_test.cpp --exclude=*_test.cc" ;;
	esac
}

# Build language-specific exclude dirs
build_lang_exclude_dirs() {
	local lang="$1"
	case "$lang" in
	nodejs) echo "--exclude-dir=node_modules --exclude-dir=__tests__" ;;
	python) echo "--exclude-dir=__pycache__ --exclude-dir=venv --exclude-dir=.venv" ;;
	*) echo "" ;;
	esac
}

# Build common exclude dirs
build_common_exclude_dirs() {
	local extra_dirs="$1"
	local flags="--exclude-dir=vendor --exclude-dir=.git --exclude-dir=testdata --exclude-dir=mocks"
	flags="$flags --exclude-dir=test --exclude-dir=tests --exclude-dir=e2e --exclude-dir=testing"
	flags="$flags --exclude-dir=mock --exclude-dir=fakes --exclude-dir=fixtures"

	if [[ -n "$extra_dirs" ]]; then
		IFS=',' read -ra dirs <<<"$extra_dirs"
		for dir in "${dirs[@]}"; do
			dir="${dir// /}"
			if [[ -n "$dir" ]]; then
				flags="$flags --exclude-dir=$dir"
			fi
		done
	fi

	echo "$flags"
}

# Check if a pattern ID is excluded
is_pattern_excluded() {
	local pattern_id="$1"
	local exclude_list="$2"

	if [[ -z "$exclude_list" ]]; then
		return 1
	fi

	IFS=',' read -ra excluded <<<"$exclude_list"
	for excl in "${excluded[@]}"; do
		excl="${excl// /}"
		if [[ "$excl" == "$pattern_id" ]]; then
			return 0
		fi
	done
	return 1
}

# Scan for a single pattern in the scan path
# Appends results to FINDINGS array
scan_pattern() {
	local scan_path="$1"
	local lang="$2"
	local pattern_line="$3"
	local exclude_dirs="$4"
	local exclude_patterns="$5"

	# Parse pattern: "id|severity|name|description|regex"
	IFS='|' read -r pattern_id severity name description regex <<<"$pattern_line"

	# Skip excluded patterns
	if is_pattern_excluded "$pattern_id" "$exclude_patterns"; then
		log_debug "Skipping excluded pattern: $pattern_id"
		return 0
	fi

	# Build grep flags
	local include_flags exclude_test_flags lang_exclude_dirs common_exclude_dirs
	include_flags=$(build_include_flags "$lang")
	exclude_test_flags=$(build_test_exclude_flags "$lang")
	lang_exclude_dirs=$(build_lang_exclude_dirs "$lang")
	common_exclude_dirs=$(build_common_exclude_dirs "$exclude_dirs")

	# Run grep from inside scan_path so --exclude-dir won't match the scan root itself
	local grep_output
	# shellcheck disable=SC2086
	grep_output=$(cd "$scan_path" && grep -rn $include_flags $exclude_test_flags $lang_exclude_dirs $common_exclude_dirs \
		-E "$regex" . 2>/dev/null) || true

	if [[ -z "$grep_output" ]]; then
		return 0
	fi

	# Parse grep output lines: ./file:line:match
	while IFS= read -r match_line; do
		local file line_num match_text
		# Extract file path (everything before first colon-number-colon)
		file=$(echo "$match_line" | sed -E 's/:([0-9]+):.*$//')
		line_num=$(echo "$match_line" | sed -E 's/^[^:]+:([0-9]+):.*$/\1/')
		match_text=$(echo "$match_line" | sed -E 's/^[^:]+:[0-9]+://')

		# Strip leading ./ from file path
		file="${file#./}"

		# Trim match text for readability
		match_text=$(echo "$match_text" | sed 's/^[[:space:]]*//' | cut -c1-200)

		FINDINGS+=("${pattern_id}|${severity}|${name}|${description}|${file}|${line_num}|${match_text}")

		# Update severity counters
		case "$(normalize_severity "$severity")" in
		critical) CRITICAL_COUNT=$((CRITICAL_COUNT + 1)) ;;
		high) HIGH_COUNT=$((HIGH_COUNT + 1)) ;;
		medium) MEDIUM_COUNT=$((MEDIUM_COUNT + 1)) ;;
		info) INFO_COUNT=$((INFO_COUNT + 1)) ;;
		esac
	done <<<"$grep_output"
}

# Go-specific: filter out tls.Config findings in files that use TLSSecurityProfile
filter_go_tls_config_noise() {
	local scan_path="$1"
	local exclude_dirs="$2"
	local common_exclude_dirs
	common_exclude_dirs=$(build_common_exclude_dirs "$exclude_dirs")

	# Check if there are any "hardcoded-tls-config" findings
	local has_tls_config=false
	for finding in "${FINDINGS[@]}"; do
		IFS='|' read -r fid _ _ _ _ _ _ <<<"$finding"
		if [[ "$fid" == "hardcoded-tls-config" ]]; then
			has_tls_config=true
			break
		fi
	done

	if ! $has_tls_config; then
		return 0
	fi

	# Check if any Go files reference TLSSecurityProfile
	local profile_files
	# shellcheck disable=SC2086
	profile_files=$(cd "$scan_path" && grep -rl --include="*.go" $common_exclude_dirs \
		--exclude="*_test.go" "TLSSecurityProfile" . 2>/dev/null) || true

	if [[ -z "$profile_files" ]]; then
		return 0
	fi

	# Filter findings: remove hardcoded-tls-config entries where file also references TLSSecurityProfile
	local filtered_findings=()
	for finding in "${FINDINGS[@]}"; do
		IFS='|' read -r fid fsev _ _ ffile _ _ <<<"$finding"
		if [[ "$fid" == "hardcoded-tls-config" ]]; then
			local full_path="$scan_path/$ffile"
			# Keep finding only if file does NOT reference TLSSecurityProfile
			if ! grep -q "TLSSecurityProfile" "$full_path" 2>/dev/null; then
				filtered_findings+=("$finding")
			else
				log_debug "Filtered tls.Config finding in $ffile (uses TLSSecurityProfile)"
				# Decrement counter
				case "$(normalize_severity "$fsev")" in
				critical) CRITICAL_COUNT=$((CRITICAL_COUNT - 1)) ;;
				high) HIGH_COUNT=$((HIGH_COUNT - 1)) ;;
				medium) MEDIUM_COUNT=$((MEDIUM_COUNT - 1)) ;;
				info) INFO_COUNT=$((INFO_COUNT - 1)) ;;
				esac
			fi
		else
			filtered_findings+=("$finding")
		fi
	done

	FINDINGS=("${filtered_findings[@]+"${filtered_findings[@]}"}")  
}

# Scan all patterns for a language
scan_language() {
	local scan_path="$1"
	local lang="$2"
	local exclude_dirs="$3"
	local exclude_patterns="$4"

	log_msg "Scanning for $lang patterns..."

	# Source the pattern file
	local action_path
	action_path="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
	local pattern_file="$action_path/patterns/${lang}.sh"

	if [[ ! -f "$pattern_file" ]]; then
		log_msg "No pattern file found for $lang"
		return 0
	fi

	# Source patterns
	# shellcheck disable=SC1090
	source "$pattern_file"

	# Get patterns array based on language
	local patterns_var
	case "$lang" in
	go) patterns_var="GO_PATTERNS" ;;
	python) patterns_var="PYTHON_PATTERNS" ;;
	nodejs) patterns_var="NODEJS_PATTERNS" ;;
	cpp) patterns_var="CPP_PATTERNS" ;;
	*) return 0 ;;
	esac

	# Use eval to iterate the named array (compatible with bash 3.x+)
	local pattern_line
	eval 'for pattern_line in "${'"$patterns_var"'[@]}"; do
		scan_pattern "$scan_path" "$lang" "$pattern_line" "$exclude_dirs" "$exclude_patterns"
	done'

	# Apply Go-specific noise reduction
	if [[ "$lang" == "go" ]]; then
		filter_go_tls_config_noise "$scan_path" "$exclude_dirs"
	fi
}

# Run the full scan across all specified languages
run_scan() {
	local scan_path="$1"
	local languages="$2"
	local exclude_dirs="$3"
	local exclude_patterns="$4"

	IFS=',' read -ra lang_list <<<"$languages"
	for lang in "${lang_list[@]}"; do
		lang="${lang// /}"
		if [[ -n "$lang" ]]; then
			scan_language "$scan_path" "$lang" "$exclude_dirs" "$exclude_patterns"
		fi
	done

	local total=$((CRITICAL_COUNT + HIGH_COUNT + MEDIUM_COUNT + INFO_COUNT))
	log_msg "Scan complete: $total findings ($CRITICAL_COUNT critical, $HIGH_COUNT high, $MEDIUM_COUNT medium, $INFO_COUNT info)"
}

# Get total findings count
get_findings_count() {
	echo $((CRITICAL_COUNT + HIGH_COUNT + MEDIUM_COUNT + INFO_COUNT))
}
