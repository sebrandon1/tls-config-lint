#!/usr/bin/env bash
# utils.sh - Severity comparison, logging helpers, and common utilities

set -euo pipefail

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
	echo "::notice::$*"
}

log_warning() {
	echo "::warning::$*"
}

log_error() {
	echo "::error::$*"
}

log_debug() {
	echo "::debug::$*"
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
	local item
	IFS=',' read -ra items <<<"$haystack"
	for item in "${items[@]}"; do
		if [[ "$item" == "$needle" ]]; then
			return 0
		fi
	done
	return 1
}
