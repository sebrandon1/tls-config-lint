#!/usr/bin/env bash
# sarif.sh - SARIF 2.1.0 JSON generator (via jq)

set -euo pipefail

file_to_lang_prefix() {
	case "$1" in
		*.go) echo "go" ;;
		*.py) echo "python" ;;
		*.js | *.mjs | *.ts | *.mts) echo "nodejs" ;;
		*.cpp | *.cc | *.cxx | *.h | *.hpp) echo "cpp" ;;
		*.java) echo "java" ;;
		*.rs) echo "rust" ;;
		*) echo "" ;;
	esac
}

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

	# Build rules array from unique pattern IDs
	local rules_json="[]"
	local seen_patterns=()

	for finding in "${FINDINGS[@]}"; do
		IFS='|' read -r pattern_id severity name description finding_file _ _ _ <<<"$finding"

		# Skip if already seen
		local already_seen=false
		for seen in "${seen_patterns[@]+"${seen_patterns[@]}"}"; do
			if [[ "$seen" == "$pattern_id" ]]; then
				already_seen=true
				break
			fi
		done
		if $already_seen; then
			continue
		fi
		seen_patterns+=("$pattern_id")

		local sarif_level
		sarif_level=$(severity_to_sarif_level "$severity")

		local lang_prefix
		lang_prefix=$(file_to_lang_prefix "$finding_file")
		local help_anchor="${lang_prefix:+${lang_prefix}-}${pattern_id}"

		local extra_tag
		extra_tag=$(pattern_tags "$pattern_id")

		rules_json=$(echo "$rules_json" | jq \
			--arg id "$pattern_id" \
			--arg name "$name" \
			--arg desc "$description" \
			--arg level "$sarif_level" \
			--arg helpUri "https://github.com/sebrandon1/tls-config-lint/blob/main/docs/patterns.md#${help_anchor}" \
			--arg extraTag "$extra_tag" \
			'. + [{
				id: $id,
				name: $name,
				shortDescription: { text: $name },
				fullDescription: { text: $desc },
				helpUri: $helpUri,
				defaultConfiguration: { level: $level },
				properties: { tags: ["security", "tls", $extraTag] }
			}]')
	done

	# Build results array
	local results_json="[]"

	for finding in "${FINDINGS[@]}"; do
		IFS='|' read -r pattern_id severity name description file line_num match_text col <<<"$finding"

		local sarif_level
		sarif_level=$(severity_to_sarif_level "$severity")

		# Find rule index
		local rule_index=0
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

		results_json=$(echo "$results_json" | jq \
			--arg id "$pattern_id" \
			--arg msg "$description" \
			--arg file "$file" \
			--argjson line "$line_num" \
			--argjson startCol "${col:-1}" \
			--argjson endCol "$end_col" \
			--arg level "$sarif_level" \
			--argjson ruleIdx "$rule_index" \
			--arg snippet "$match_text" \
			--arg fingerprint "$fingerprint" \
			'. + [{
				ruleId: $id,
				ruleIndex: $ruleIdx,
				level: $level,
				message: { text: $msg },
				locations: [{
					physicalLocation: {
						artifactLocation: { uri: $file, uriBaseId: "%SRCROOT%" },
						region: { startLine: $line, startColumn: $startCol, endColumn: $endCol, snippet: { text: $snippet } }
					}
				}],
				partialFingerprints: { primaryLocationLineHash: $fingerprint }
			}]')
	done

	# Determine tool version from git tag
	local tool_version
	tool_version=$(git describe --tags --always 2>/dev/null || echo "unknown")

	# Assemble full SARIF document
	local sarif_doc
	sarif_doc=$(jq -n \
		--argjson rules "$rules_json" \
		--argjson results "$results_json" \
		--arg version "$tool_version" \
		'{
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
		}')

	echo "$sarif_doc" >"$output_file"
	log_msg "SARIF output written to $output_file"
}
