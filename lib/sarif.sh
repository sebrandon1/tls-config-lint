#!/usr/bin/env bash
# sarif.sh - SARIF 2.1.0 JSON generator (via jq)

set -euo pipefail

pattern_tags() {
	case "$1" in
		*skip-verify* | *verify-false* | *verify-none* | *verify-peer* | *verifypeer* | *verifyhost* | *hostname-verif* | *check-hostname* | *cert-none* | *unverified* | *invalid-cert* | *invalid-hostname* | *trust-all* | *reject-unauthorized* | *tls-reject* | *dangerous-verifier* | *noop-hostname* | *allow-all-hostname*)
			echo "certificate-validation"
			;;
		*version* | *tls1* | *tlsv1* | *sslv3* | *sslcontext* | *proto-tls*)
			echo "protocol-version"
			;;
		*null-cipher* | *cipher* | *3des* | *rc4*)
			echo "cipher-suite"
			;;
		*tls-profile*)
			echo "tls-profile"
			;;
		*grpc-insecure*)
			echo "transport-security"
			;;
		*pqc* | *ml-kem*)
			echo "post-quantum"
			;;
		*)
			echo "configuration"
			;;
	esac
}

sha256_hash() {
	if command -v sha256sum &>/dev/null; then
		sha256sum | cut -d' ' -f1
	else
		shasum -a 256 | cut -d' ' -f1
	fi
}

# Generate SARIF 2.1.0 output
generate_sarif() {
	local output_file="$1"

	if ! command -v jq &>/dev/null; then
		log_error "jq is required for SARIF output but not found"
		return 1
	fi

	# Collect rule and result records for one final jq invocation. NUL-delimited
	# records avoid ambiguity when fields contain spaces or shell metacharacters.
	local temp_dir rules_file results_file
	temp_dir=$(mktemp -d)
	rules_file="$temp_dir/rules"
	results_file="$temp_dir/results"
	: >"$rules_file"
	: >"$results_file"

	local seen_patterns=()
	local rule_index i

	for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
		IFS='|' read -r pattern_id severity name description finding_file _ _ _ <<<"$finding"

		# Skip if already seen
		rule_index=-1
		for i in "${!seen_patterns[@]}"; do
			if [[ "${seen_patterns[$i]}" == "$pattern_id" ]]; then
				rule_index="$i"
				break
			fi
		done
		if ((rule_index >= 0)); then
			continue
		fi
		rule_index=${#seen_patterns[@]}
		seen_patterns+=("$pattern_id")

		local sarif_level
		sarif_level=$(severity_to_sarif_level "$severity")

		local lang_prefix
		lang_prefix=$(file_to_lang_prefix "$finding_file")
		local help_anchor="${lang_prefix:+${lang_prefix}-}${pattern_id}"
		local help_uri="https://github.com/sebrandon1/tls-config-lint/blob/main/docs/patterns.md#${help_anchor}"
		if [[ ",${CUSTOM_PATTERN_IDS:-}," == *",$pattern_id,"* ]]; then
			help_uri="https://github.com/sebrandon1/tls-config-lint/blob/main/docs/configuration.md#custom-patterns"
		fi

		local extra_tag
		extra_tag=$(pattern_tags "$pattern_id")

		printf '%s\037%s\037%s\037%s\037%s\037%s\000' \
			"$pattern_id" "$sarif_level" "$name" "$description" "$help_uri" "$extra_tag" \
			>>"$rules_file"
	done

	for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
		IFS='|' read -r pattern_id severity name description file line_num match_text col <<<"$finding"

		local sarif_level
		sarif_level=$(severity_to_sarif_level "$severity")

		# Find the rule index assigned during rule collection.
		rule_index=0
		for i in "${!seen_patterns[@]}"; do
			if [[ "${seen_patterns[$i]}" == "$pattern_id" ]]; then
				rule_index=$i
				break
			fi
		done

		local fingerprint
		fingerprint=$(printf '%s' "${pattern_id}:${file}:${match_text}" | sha256_hash)

		local end_col
		end_col=$((col + ${#match_text}))

		printf '%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\000' \
			"$pattern_id" "$description" "$file" "$line_num" "${col:--1}" "$end_col" \
			"$sarif_level" "$rule_index" "$match_text" "$fingerprint" >>"$results_file"
	done

	# Determine tool version from git tag
	local tool_version
	tool_version=$(get_tool_version)

	# Assemble full SARIF document
	local sarif_doc
	if ! sarif_doc=$(jq -n \
		--rawfile rule_records "$rules_file" \
		--rawfile result_records "$results_file" \
		--arg version "$tool_version" \
		'
		def records:
			split("\u0000")
			| map(select(length > 0) | split("\u001f"));

		($rule_records | records) as $rule_data
		| ($result_records | records) as $result_data
		| [ $rule_data[] | {
			id: .[0],
			name: .[2],
			shortDescription: { text: .[2] },
			fullDescription: { text: .[3] },
			helpUri: .[4],
			defaultConfiguration: { level: .[1] },
			properties: { tags: ["security", "tls", .[5]] }
		} ] as $rules
		| [ $result_data[] | {
			ruleId: .[0],
			ruleIndex: (.[7] | tonumber),
			level: .[6],
			message: { text: .[1] },
			locations: [{
				physicalLocation: {
					artifactLocation: { uri: .[2], uriBaseId: "%SRCROOT%" },
					region: {
						startLine: (.[3] | tonumber),
						startColumn: (.[4] | tonumber),
						endColumn: (.[5] | tonumber),
						snippet: { text: .[8] }
					}
				}
			}],
			partialFingerprints: { primaryLocationLineHash: .[9] }
		} ] as $results
		| {
			"$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/main/sarif-2.1/schema/sarif-schema-2.1.0.json",
			version: "2.1.0",
			runs: [{
				tool: {
					driver: {
						name: "tls-config-lint",
						informationUri: "https://github.com/sebrandon1/tls-config-lint",
						version: $version,
						rules: $rules
					}
				},
				results: $results
			}]
		}'); then
		rm -rf "$temp_dir"
		log_error "Failed to generate SARIF JSON"
		return 1
	fi
	rm -rf "$temp_dir"

	echo "$sarif_doc" >"$output_file"
	log_msg "SARIF output written to $output_file"
}
