#!/usr/bin/env bash
# config.sh - Config file parser (pure bash, no yq dependency)

set -euo pipefail

# Parse .tls-config-lint.yml config file
# Sets global variables: CFG_SEVERITY_THRESHOLD, CFG_LANGUAGES, CFG_EXCLUDE_DIRS,
# CFG_EXCLUDE_PATTERNS
parse_config_file() {
	local config_file="$1"

	# Initialize config defaults (empty = not set in config)
	CFG_SEVERITY_THRESHOLD=""
	CFG_LANGUAGES=""
	CFG_EXCLUDE_DIRS=""
	CFG_EXCLUDE_PATTERNS=""

	if [[ ! -f "$config_file" ]]; then
		log_debug "No config file found at $config_file"
		return 0
	fi

	log_msg "Reading config from $config_file"

	local current_key=""
	while IFS= read -r line || [[ -n "$line" ]]; do
		# Skip comments and empty lines
		[[ "$line" =~ ^[[:space:]]*# ]] && continue
		[[ -z "${line// /}" ]] && continue

		# Detect list items (lines starting with "  - ")
		if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
			local value="${BASH_REMATCH[1]}"
			# Remove inline comments
			value="${value%%#*}"
			# Trim trailing whitespace
			value="${value%"${value##*[![:space:]]}"}"

			case "$current_key" in
				languages)
					if [[ -n "$CFG_LANGUAGES" ]]; then
						CFG_LANGUAGES="$CFG_LANGUAGES,$value"
					else
						CFG_LANGUAGES="$value"
					fi
					;;
				exclude-dirs)
					if [[ -n "$CFG_EXCLUDE_DIRS" ]]; then
						CFG_EXCLUDE_DIRS="$CFG_EXCLUDE_DIRS,$value"
					else
						CFG_EXCLUDE_DIRS="$value"
					fi
					;;
				exclude-patterns)
					if [[ -n "$CFG_EXCLUDE_PATTERNS" ]]; then
						CFG_EXCLUDE_PATTERNS="$CFG_EXCLUDE_PATTERNS,$value"
					else
						CFG_EXCLUDE_PATTERNS="$value"
					fi
					;;
			esac
			continue
		fi

		# Detect key: value pairs
		if [[ "$line" =~ ^([a-z-]+):[[:space:]]*(.*) ]]; then
			current_key="${BASH_REMATCH[1]}"
			local value="${BASH_REMATCH[2]}"
			# Remove inline comments
			value="${value%%#*}"
			# Trim trailing whitespace
			value="${value%"${value##*[![:space:]]}"}"

			case "$current_key" in
				severity-threshold)
					if [[ -n "$value" ]]; then
						CFG_SEVERITY_THRESHOLD="$value"
					fi
					;;
				languages | exclude-dirs | exclude-patterns)
					# If value is on same line (not a list), store it
					if [[ -n "$value" ]]; then
						case "$current_key" in
							languages) CFG_LANGUAGES="$value" ;;
							exclude-dirs) CFG_EXCLUDE_DIRS="$value" ;;
							exclude-patterns) CFG_EXCLUDE_PATTERNS="$value" ;;
						esac
					fi
					;;
			esac
		fi
	done <"$config_file"
}

# Merge inputs with config file values
# Precedence: action inputs > config file > defaults
merge_config() {
	local input_severity="${INPUT_SEVERITY_THRESHOLD:-high}"
	local input_languages="${INPUT_LANGUAGES:-auto}"
	local input_exclude_dirs="${INPUT_EXCLUDE_DIRS:-}"
	local input_exclude_patterns="${INPUT_EXCLUDE_PATTERNS:-}"
	local input_config_file="${INPUT_CONFIG_FILE:-.tls-config-lint.yml}"
	local input_scan_path="${INPUT_SCAN_PATH:-.}"
	local input_fail_on_findings="${INPUT_FAIL_ON_FINDINGS:-true}"
	local input_sarif_output="${INPUT_SARIF_OUTPUT:-}"

	# Parse config file
	parse_config_file "$input_config_file"

	# Merge severity threshold (input wins if not default, else config, else default)
	if [[ "$input_severity" != "high" ]]; then
		SEVERITY_THRESHOLD="$input_severity"
	elif [[ -n "$CFG_SEVERITY_THRESHOLD" ]]; then
		SEVERITY_THRESHOLD="$CFG_SEVERITY_THRESHOLD"
	else
		SEVERITY_THRESHOLD="high"
	fi

	# Merge languages (input wins if not default)
	if [[ "$input_languages" != "auto" ]]; then
		LANGUAGES="$input_languages"
	elif [[ -n "$CFG_LANGUAGES" ]]; then
		LANGUAGES="$CFG_LANGUAGES"
	else
		LANGUAGES="auto"
	fi

	# Merge exclude dirs (union of input + config)
	EXCLUDE_DIRS=""
	if [[ -n "$input_exclude_dirs" ]] && [[ -n "$CFG_EXCLUDE_DIRS" ]]; then
		EXCLUDE_DIRS="$input_exclude_dirs,$CFG_EXCLUDE_DIRS"
	elif [[ -n "$input_exclude_dirs" ]]; then
		EXCLUDE_DIRS="$input_exclude_dirs"
	elif [[ -n "$CFG_EXCLUDE_DIRS" ]]; then
		EXCLUDE_DIRS="$CFG_EXCLUDE_DIRS"
	fi

	# Merge exclude patterns (union of input + config)
	EXCLUDE_PATTERNS=""
	if [[ -n "$input_exclude_patterns" ]] && [[ -n "$CFG_EXCLUDE_PATTERNS" ]]; then
		EXCLUDE_PATTERNS="$input_exclude_patterns,$CFG_EXCLUDE_PATTERNS"
	elif [[ -n "$input_exclude_patterns" ]]; then
		EXCLUDE_PATTERNS="$input_exclude_patterns"
	elif [[ -n "$CFG_EXCLUDE_PATTERNS" ]]; then
		EXCLUDE_PATTERNS="$CFG_EXCLUDE_PATTERNS"
	fi

	SCAN_PATH="$input_scan_path"
	FAIL_ON_FINDINGS="$input_fail_on_findings"
	SARIF_OUTPUT="$input_sarif_output"

	# Export for use in other scripts
	export SEVERITY_THRESHOLD LANGUAGES EXCLUDE_DIRS EXCLUDE_PATTERNS
	export SCAN_PATH FAIL_ON_FINDINGS SARIF_OUTPUT
}
