#!/usr/bin/env bash
# entrypoint.sh - Main orchestrator for tls-config-lint GitHub Action

set -euo pipefail

# Determine action path (directory containing this script)
ACTION_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source library modules
# shellcheck source=lib/utils.sh
source "$ACTION_PATH/lib/utils.sh"
# shellcheck source=lib/config.sh
source "$ACTION_PATH/lib/config.sh"
# shellcheck source=lib/detect.sh
source "$ACTION_PATH/lib/detect.sh"
# shellcheck source=lib/scanner.sh
source "$ACTION_PATH/lib/scanner.sh"
# shellcheck source=lib/annotations.sh
source "$ACTION_PATH/lib/annotations.sh"
# shellcheck source=lib/summary.sh
source "$ACTION_PATH/lib/summary.sh"
# shellcheck source=lib/sarif.sh
source "$ACTION_PATH/lib/sarif.sh"
# shellcheck source=lib/report.sh
source "$ACTION_PATH/lib/report.sh"

main() {
	log_msg "Starting TLS Config Lint..."

	# Step 1: Merge configuration (inputs + config file + defaults)
	if ! merge_config; then
		exit 2
	fi

	# Validate jq availability early when SARIF or JSON report output is requested
	if [[ -n "$SARIF_OUTPUT" ]] || [[ "${REPORT_OUTPUT:-}" == *.json ]]; then
		if ! command -v jq &>/dev/null; then
			log_error "jq is required for SARIF/JSON output but not found. Install jq or remove the output setting."
			exit 2
		fi
	fi

	log_msg "Configuration:"
	log_msg "  Severity threshold: $SEVERITY_THRESHOLD"
	log_msg "  Languages: $LANGUAGES"
	log_msg "  Scan path: $SCAN_PATH"
	log_msg "  Fail on findings: $FAIL_ON_FINDINGS"
	log_msg "  Exclude dirs: ${EXCLUDE_DIRS:-<none>}"
	log_msg "  Exclude patterns: ${EXCLUDE_PATTERNS:-<none>}"
	log_msg "  SARIF output: ${SARIF_OUTPUT:-<disabled>}"
	log_msg "  Report output: ${REPORT_OUTPUT:-<disabled>}"

	# Step 2: Auto-detect languages if needed
	if [[ "$LANGUAGES" == "auto" ]]; then
		LANGUAGES=$(detect_languages "$SCAN_PATH")
		if [[ -z "$LANGUAGES" ]]; then
			log_msg "No supported languages detected. Exiting with success."
			set_outputs 0 0 0 0 0 0
			exit 0
		fi
	fi

	# Step 3: Run scan
	local scan_start=$SECONDS
	run_scan "$SCAN_PATH" "$LANGUAGES" "$EXCLUDE_DIRS" "$EXCLUDE_PATTERNS"
	local scan_duration=$((SECONDS - scan_start))

	# Step 4: Set outputs
	local total
	total=$(get_findings_count)
	set_outputs "$total" "$CRITICAL_COUNT" "$HIGH_COUNT" "$MEDIUM_COUNT" "$INFO_COUNT" "$scan_duration"

	# Step 5: Emit annotations
	emit_annotations

	# Step 6: Generate job summary
	generate_summary "$SEVERITY_THRESHOLD"

	# Step 7: Generate SARIF if requested
	if [[ -n "$SARIF_OUTPUT" ]]; then
		generate_sarif "$SARIF_OUTPUT"
		if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
			echo "sarif-file=$SARIF_OUTPUT" >>"$GITHUB_OUTPUT"
		fi
	fi

	# Step 8: Generate CSV/JSON report if requested
	if [[ -n "${REPORT_OUTPUT:-}" ]]; then
		generate_report "$REPORT_OUTPUT"
		if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
			echo "report-file=$REPORT_OUTPUT" >>"$GITHUB_OUTPUT"
		fi
	fi

	# Step 9: Determine exit code
	if [[ "$FAIL_ON_FINDINGS" == "true" ]]; then
		# Check if any findings meet or exceed threshold
		local should_fail=false
		for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
			IFS='|' read -r _ severity _ _ _ _ _ _ <<<"$finding"
			if meets_threshold "$severity" "$SEVERITY_THRESHOLD"; then
				should_fail=true
				break
			fi
		done

		if $should_fail; then
			log_msg "Findings at or above severity threshold ($SEVERITY_THRESHOLD) detected. Failing."
			exit 1
		fi
	fi

	log_msg "No findings at or above severity threshold ($SEVERITY_THRESHOLD). Passing."
	exit 0
}

# Set GitHub Actions outputs
set_outputs() {
	local total="$1" critical="$2" high="$3" medium="$4" info="$5" duration="$6"

	if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
		{
			echo "findings-count=$total"
			echo "critical-count=$critical"
			echo "high-count=$high"
			echo "medium-count=$medium"
			echo "info-count=$info"
			echo "scan-duration=${duration}s"
		} >>"$GITHUB_OUTPUT"
	fi
}

main "$@"
