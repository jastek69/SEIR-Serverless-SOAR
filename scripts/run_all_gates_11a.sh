#!/usr/bin/env bash
set -euo pipefail

# Required env vars:
# REGION, LAMBDA_NAME, SECRET_ARN, DB_NAME, DB_ID, RDS_SG_ID, LAMBDA_SG_ID, API_ID, STAGE_NAME

REGION="${REGION:-us-east-1}"
OUT_JSON="${OUT_JSON:-gate_result.json}"
BADGE_TXT="${BADGE_TXT:-badge.txt}"
PR_COMMENT_MD="${PR_COMMENT_MD:-pr_comment.md}"

#Chewbacca: execute gates in order: identity+secrets, network+db, then the API.
chmod +x ./gate_11a_lambda_secret_vpc.sh ./gate_11a_rds_sg_private.sh ./gate_11a_apigw_route_invoke.sh

set +e
OUT_JSON_1="gate_11a_lambda_secret_vpc.json" ./gate_11a_lambda_secret_vpc.sh
rc1=$?
OUT_JSON_2="gate_11a_rds_sg_private.json"    ./gate_11a_rds_sg_private.sh
rc2=$?
OUT_JSON_3="gate_11a_apigw_route_invoke.json" ./gate_11a_apigw_route_invoke.sh
rc3=$?
set -e

overall="PASS"; exit_code=0
if [[ "$rc1" -ne 0 || "$rc2" -ne 0 || "$rc3" -ne 0 ]]; then overall="FAIL"; exit_code=2; fi

# Badge logic: FAIL => RED, PASS+warnings => YELLOW, PASS => GREEN
warn_flag=0
grep -q '"warnings": \[' gate_11a_lambda_secret_vpc.json && ! grep -q '"warnings": \[\]' gate_11a_lambda_secret_vpc.json && warn_flag=1 || true
grep -q '"warnings": \[' gate_11a_rds_sg_private.json    && ! grep -q '"warnings": \[\]' gate_11a_rds_sg_private.json    && warn_flag=1 || true
grep -q '"warnings": \[' gate_11a_apigw_route_invoke.json && ! grep -q '"warnings": \[\]' gate_11a_apigw_route_invoke.json && warn_flag=1 || true

badge="GREEN"
[[ "$overall" == "FAIL" ]] && badge="RED"
[[ "$overall" == "PASS" && "$warn_flag" -eq 1 ]] && badge="YELLOW"
echo "$badge" > "$BADGE_TXT"

# Optional jq rollup if available
if command -v jq >/dev/null 2>&1; then
  jq -s '
    {
      schema_version:"2.0",
      gate:"11a_all_gates",
      timestamp_utc:(now|todate),
      region:(env.REGION // "unknown"),
      badge:(env.BADGE // ""),
      status:(env.OVERALL // ""),
      exit_code:(env.EXIT|tonumber),
      child_gates: [
        {name:"lambda_secret_vpc", file:"gate_11a_lambda_secret_vpc.json", exit_code:(env.RC1|tonumber)},
        {name:"rds_sg_private", file:"gate_11a_rds_sg_private.json", exit_code:(env.RC2|tonumber)},
        {name:"apigw_route_invoke", file:"gate_11a_apigw_route_invoke.json", exit_code:(env.RC3|tonumber)}
      ],
      rollup: {
        failures: ([.[0].failures,.[1].failures,.[2].failures] | add),
        warnings: ([.[0].warnings,.[1].warnings,.[2].warnings] | add)
      }
    }
  ' gate_11a_lambda_secret_vpc.json gate_11a_rds_sg_private.json gate_11a_apigw_route_invoke.json \
  > "$OUT_JSON" \
  || true
else
  # fallback minimal JSON
  cat > "$OUT_JSON" <<EOF
{
  "schema_version":"2.0",
  "gate":"11a_all_gates",
  "timestamp_utc":"$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "region":"$REGION",
  "badge":"$badge",
  "status":"$overall",
  "exit_code":$exit_code,
  "child_gates":[
    {"name":"lambda_secret_vpc","file":"gate_11a_lambda_secret_vpc.json","exit_code":$rc1},
    {"name":"rds_sg_private","file":"gate_11a_rds_sg_private.json","exit_code":$rc2},
    {"name":"apigw_route_invoke","file":"gate_11a_apigw_route_invoke.json","exit_code":$rc3}
  ]
}
EOF
fi

cat > "$PR_COMMENT_MD" <<EOF
### Lab 11A Gate: **$badge** ($overall)

**Child gates**
- lambda_secret_vpc: exit \`$rc1\`
- rds_sg_private: exit \`$rc2\`
- apigw_route_invoke: exit \`$rc3\`

**Next action**
- If **RED**: fix the failures in the child JSON files, then rerun.
- If **YELLOW**: it passes, but warnings mean “fragile.” Stabilize it.
- If **GREEN**: you’re ready for 11B suffering.
EOF

echo "Lab 11A Gate complete: $badge ($overall)"
exit "$exit_code"