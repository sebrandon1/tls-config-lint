#!/usr/bin/env bash
# baseline.sh - Filter findings already present in a SARIF baseline

set -euo pipefail

# Entries are stored as tab-separated: rule ID, normalized file, line.
BASELINE_ENTRIES=()
BASELINE_SUPPRESSED_COUNT=0
BASELINE_LINE_PROXIMITY=3

normalize_baseline_file() {
	local uri="$1"
	local scan_abs="$2"

	uri="${uri#file://}"
	uri="${uri#%SRCROOT%/}"
	uri="${uri#./}"
	if [[ "$uri" == "$scan_abs/"* ]]; then
		uri="${uri#"$scan_abs"/}"
	fi
	echo "$uri"
}

load_baseline() {
	local baseline_file="$1"
	local scan_path="$2"
	local scan_abs entries_file id uri line normalized

	if [[ ! -r "$baseline_file" ]]; then
		log_error "Baseline file is not readable: '$baseline_file'"
		return 1
	fi
	if ! scan_abs=$(cd "$scan_path" && pwd); then
		log_error "Cannot resolve scan path for baseline comparison: '$scan_path'"
		return 1
	fi

	if ! jq -e '
		def valid_result:
			(type == "object") and
			((.ruleId | type) == "string") and
			((.locations | type) == "array") and
			(.locations | length > 0) and
			((.locations[0].physicalLocation.artifactLocation.uri | type) == "string") and
			((.locations[0].physicalLocation.region.startLine | type) == "number") and
			((.locations[0].physicalLocation.artifactLocation.uri | contains("\t") | not)) and
			((.locations[0].physicalLocation.artifactLocation.uri | contains("\n") | not));
		type == "object" and
		.version == "2.1.0" and
		(.runs | type) == "array" and
		all(.runs[]; (.results | type) == "array" and all(.results[]; valid_result))
	' "$baseline_file" >/dev/null 2>&1; then
		log_error "Invalid SARIF baseline: '$baseline_file' (expected SARIF 2.1.0 results with rule IDs, files, and lines)"
		return 1
	fi

	entries_file=$(mktemp)
	if ! jq -r '.runs[] | .results[] | [.ruleId, .locations[0].physicalLocation.artifactLocation.uri, (.locations[0].physicalLocation.region.startLine | tostring)] | @tsv' "$baseline_file" >"$entries_file"; then
		rm -f "$entries_file"
		log_error "Unable to read SARIF baseline: '$baseline_file'"
		return 1
	fi

	BASELINE_ENTRIES=()
	while IFS=$'\t' read -r id uri line; do
		[[ -z "$id" ]] && continue
		normalized=$(normalize_baseline_file "$uri" "$scan_abs")
		BASELINE_ENTRIES+=("$id"$'\t'"$normalized"$'\t'"$line")
	done <"$entries_file"
	rm -f "$entries_file"
	log_msg "Loaded ${#BASELINE_ENTRIES[@]} baseline finding(s) from $baseline_file"
}

baseline_has_finding() {
	local pattern_id="$1"
	local file="$2"
	local line_num="$3"
	local entry baseline_id baseline_file baseline_line distance

	for entry in "${BASELINE_ENTRIES[@]+${BASELINE_ENTRIES[@]}}"; do
		IFS=$'\t' read -r baseline_id baseline_file baseline_line <<<"$entry"
		if [[ "$baseline_id" != "$pattern_id" || "$baseline_file" != "$file" ]]; then
			continue
		fi
		distance=$((line_num - baseline_line))
		if ((distance < 0)); then
			distance=$((-distance))
		fi
		if ((distance <= BASELINE_LINE_PROXIMITY)); then
			return 0
		fi
	done
	return 1
}

filter_baseline_findings() {
	local finding pattern_id severity file line_num
	local kept_findings=()
	local kept_regexes=()
	local i=0
	BASELINE_SUPPRESSED_COUNT=0

	for finding in "${FINDINGS[@]+${FINDINGS[@]}}"; do
		IFS='|' read -r pattern_id severity _ _ file line_num _ _ <<<"$finding"
		if baseline_has_finding "$pattern_id" "$file" "$line_num"; then
			BASELINE_SUPPRESSED_COUNT=$((BASELINE_SUPPRESSED_COUNT + 1))
			case "$(normalize_severity "$severity")" in
				critical) CRITICAL_COUNT=$((CRITICAL_COUNT - 1)) ;;
				high) HIGH_COUNT=$((HIGH_COUNT - 1)) ;;
				medium) MEDIUM_COUNT=$((MEDIUM_COUNT - 1)) ;;
				info) INFO_COUNT=$((INFO_COUNT - 1)) ;;
			esac
		else
			kept_findings+=("$finding")
			kept_regexes+=("${FINDING_REGEXES[$i]}")
		fi
		i=$((i + 1))
	done

	FINDINGS=("${kept_findings[@]+${kept_findings[@]}}")
	FINDING_REGEXES=("${kept_regexes[@]+${kept_regexes[@]}}")
	log_msg "Baseline comparison suppressed $BASELINE_SUPPRESSED_COUNT finding(s) within ${BASELINE_LINE_PROXIMITY} line(s)"
}
