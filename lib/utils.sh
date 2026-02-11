#!/usr/bin/env bash
# utils.sh - Logging helpers and common utilities

set -euo pipefail

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
