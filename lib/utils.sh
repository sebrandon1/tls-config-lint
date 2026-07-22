#!/usr/bin/env bash
# utils.sh - Severity comparison, logging helpers, and common utilities

set -euo pipefail

# CLI mode: auto-detect when running outside GitHub Actions
if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
	CLI_MODE=false
else
	CLI_MODE=true
fi

# Terminal colors (only when stdout is a tty)
# shellcheck disable=SC2034  # COLOR_* variables used by annotations.sh and summary.sh
if [[ -t 1 ]] && [[ "$CLI_MODE" == "true" ]]; then
	COLOR_RED='\033[0;31m'
	COLOR_YELLOW='\033[0;33m'
	COLOR_BLUE='\033[0;34m'
	COLOR_BOLD='\033[1m'
	COLOR_DIM='\033[2m'
	COLOR_RESET='\033[0m'
else
	COLOR_RED=''
	COLOR_YELLOW=''
	COLOR_BLUE=''
	COLOR_BOLD=''
	COLOR_DIM=''
	COLOR_RESET=''
fi

get_tool_version() {
	git describe --tags --always 2>/dev/null || echo "unknown"
}

# Normalize severity string to lowercase
normalize_severity() {
	echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Get numeric severity level
severity_level() {
	local sev
	sev=$(normalize_severity "$1")
	case "$sev" in
		critical) echo 4 ;;
		high) echo 3 ;;
		medium) echo 2 ;;
		info) echo 1 ;;
		*) echo 0 ;;
	esac
}

severity_to_sarif_level() {
	case "$(normalize_severity "$1")" in
		critical | high) echo "error" ;;
		medium) echo "warning" ;;
		info) echo "note" ;;
		*) echo "note" ;;
	esac
}

# Check if severity meets or exceeds threshold
# Returns 0 (true) if finding_severity >= threshold_severity
meets_threshold() {
	local finding_sev="$1"
	local threshold_sev="$2"
	local finding_level threshold_level
	finding_level=$(severity_level "$finding_sev")
	threshold_level=$(severity_level "$threshold_sev")
	[[ "$finding_level" -ge "$threshold_level" ]]
}

# Logging helpers
log_info() {
	if [[ "$CLI_MODE" == "true" ]]; then
		echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"
	else
		echo "::notice::$*"
	fi
}

log_warning() {
	if [[ "$CLI_MODE" == "true" ]]; then
		echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*"
	else
		echo "::warning::$*"
	fi
}

log_error() {
	if [[ "$CLI_MODE" == "true" ]]; then
		echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*"
	else
		echo "::error::$*"
	fi
}

log_debug() {
	if [[ "$CLI_MODE" == "true" ]]; then
		if [[ -n "${DEBUG:-}" ]]; then
			echo -e "${COLOR_DIM}[DEBUG]${COLOR_RESET} $*"
		fi
	else
		echo "::debug::$*"
	fi
}

# Print to stderr for script diagnostics (not GitHub annotations)
log_msg() {
	echo "[tls-config-lint] $*" >&2
}

# Split comma-separated string into array
# Usage: IFS=',' read -ra arr <<< "$(csv_to_list "$input")"
csv_to_list() {
	local input="$1"
	# Trim spaces around commas
	echo "$input" | sed 's/[[:space:]]*,[[:space:]]*/,/g'
}

# Check if a value exists in a comma-separated list
in_csv_list() {
	local needle="$1"
	local haystack="$2"
	if [[ -z "$haystack" ]]; then
		return 1
	fi
	local item
	IFS=',' read -ra items <<<"$haystack"
	for item in "${items[@]+"${items[@]}"}"; do
		if [[ "$item" == "$needle" ]]; then
			return 0
		fi
	done
	return 1
}
