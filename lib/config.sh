#!/usr/bin/env bash
# config.sh - Config file parser (pure bash, no yq dependency)

set -euo pipefail

# Known config keys for typo detection
_VALID_KEYS="severity-threshold languages exclude-dirs exclude-patterns exceptions severity-overrides"

_warn_unknown_key() {
	local key="$1"
	local best="" best_len=0
	for valid in $_VALID_KEYS; do
		# Find longest common prefix length
		local i=0 len=${#key}
		[[ ${#valid} -lt $len ]] && len=${#valid}
		while [[ $i -lt $len ]] && [[ "${key:$i:1}" == "${valid:$i:1}" ]]; do
			i=$((i + 1))
		done
		if [[ $i -gt $best_len ]]; then
			best_len=$i
			best="$valid"
		fi
	done
	if [[ $best_len -ge 3 ]]; then
		log_warning "Unknown config key '$key' — did you mean '$best'?"
	else
		log_warning "Unknown config key '$key' (valid keys: $_VALID_KEYS)"
	fi
}

# Parse .tls-config-lint.yml config file
# Sets global variables: CFG_SEVERITY_THRESHOLD, CFG_LANGUAGES, CFG_EXCLUDE_DIRS,
# CFG_EXCLUDE_PATTERNS, CFG_EXCEPTIONS, CFG_SEVERITY_OVERRIDES
parse_config_file() {
	local config_file="$1"

	# Initialize config defaults (empty = not set in config)
	CFG_SEVERITY_THRESHOLD=""
	CFG_LANGUAGES=""
	CFG_EXCLUDE_DIRS=""
	CFG_EXCLUDE_PATTERNS=""
	CFG_EXCEPTIONS=""
	CFG_SEVERITY_OVERRIDES=""

	if [[ ! -f "$config_file" ]]; then
		log_debug "No config file found at $config_file"
		CONFIG_FILE_USED=""
		return 0
	fi

	# shellcheck disable=SC2034  # Used by summary.sh
	CONFIG_FILE_USED="$config_file"
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
				exceptions)
					if [[ -n "$CFG_EXCEPTIONS" ]]; then
						CFG_EXCEPTIONS="$CFG_EXCEPTIONS,$value"
					else
						CFG_EXCEPTIONS="$value"
					fi
					;;
				severity-overrides)
					if [[ -n "$CFG_SEVERITY_OVERRIDES" ]]; then
						CFG_SEVERITY_OVERRIDES="$CFG_SEVERITY_OVERRIDES,$value"
					else
						CFG_SEVERITY_OVERRIDES="$value"
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
				languages | exclude-dirs | exclude-patterns | exceptions | severity-overrides)
					# If value is on same line (not a list), store it
					if [[ -n "$value" ]]; then
						case "$current_key" in
							languages) CFG_LANGUAGES="$value" ;;
							exclude-dirs) CFG_EXCLUDE_DIRS="$value" ;;
							exclude-patterns) CFG_EXCLUDE_PATTERNS="$value" ;;
							exceptions) CFG_EXCEPTIONS="$value" ;;
							severity-overrides) CFG_SEVERITY_OVERRIDES="$value" ;;
						esac
					fi
					;;
				*)
					_warn_unknown_key "$current_key"
					current_key=""
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
	local input_report_output="${INPUT_REPORT_OUTPUT:-}"

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
	REPORT_OUTPUT="$input_report_output"
	EXCEPTIONS="${CFG_EXCEPTIONS:-}"
	SEVERITY_OVERRIDES="${CFG_SEVERITY_OVERRIDES:-}"

	# Export for use in other scripts
	export SEVERITY_THRESHOLD LANGUAGES EXCLUDE_DIRS EXCLUDE_PATTERNS
	export SCAN_PATH FAIL_ON_FINDINGS SARIF_OUTPUT REPORT_OUTPUT
	export EXCEPTIONS SEVERITY_OVERRIDES

	# Validate merged configuration
	validate_config
}

# Validate configuration values
validate_config() {
	local valid=true

	# Validate severity-threshold
	case "$(normalize_severity "$SEVERITY_THRESHOLD")" in
		critical | high | medium | info) ;;
		*)
			log_error "Invalid severity-threshold: '$SEVERITY_THRESHOLD' (must be critical, high, medium, or info)"
			valid=false
			;;
	esac

	# Validate languages
	if [[ "$LANGUAGES" != "auto" ]]; then
		IFS=',' read -ra lang_list <<<"$LANGUAGES"
		local invalid_langs=()
		for lang in "${lang_list[@]}"; do
			lang="${lang// /}"
			case "$lang" in
				go | python | nodejs | cpp | java | rust) ;;
				*)
					invalid_langs+=("$lang")
					;;
			esac
		done
		if [[ ${#invalid_langs[@]} -gt 0 ]]; then
			log_error "Invalid language(s): ${invalid_langs[*]} (supported: go, python, nodejs, cpp, java, rust)"
			valid=false
		fi
	fi

	# Validate fail-on-findings
	case "$FAIL_ON_FINDINGS" in
		true | false) ;;
		*)
			log_error "Invalid fail-on-findings: '$FAIL_ON_FINDINGS' (must be true or false)"
			valid=false
			;;
	esac

	# Validate severity-overrides
	if [[ -n "${SEVERITY_OVERRIDES:-}" ]]; then
		IFS=',' read -ra ovr_list <<<"$SEVERITY_OVERRIDES"
		for ovr in "${ovr_list[@]}"; do
			ovr="${ovr// /}"
			local ovr_sev="${ovr#*:}"
			case "$(normalize_severity "$ovr_sev")" in
				critical | high | medium | info) ;;
				*)
					log_error "Invalid severity in severity-overrides: '$ovr' (severity must be critical, high, medium, or info)"
					valid=false
					;;
			esac
		done
	fi

	# Validate report-output extension
	if [[ -n "${REPORT_OUTPUT:-}" ]]; then
		case "$REPORT_OUTPUT" in
			*.json | *.csv) ;;
			*)
				log_error "Invalid report-output: '$REPORT_OUTPUT' (must have .json or .csv extension)"
				valid=false
				;;
		esac
	fi

	# Validate scan-path exists
	if [[ ! -d "$SCAN_PATH" ]]; then
		log_error "Scan path does not exist: '$SCAN_PATH'"
		valid=false
	fi

	if [[ "$valid" != "true" ]]; then
		return 1
	fi
}
