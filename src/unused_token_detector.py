import json
import os
import re
import time
from datetime import datetime, timezone, timedelta
from typing import Optional, Tuple

import boto3
from boto3.dynamodb.conditions import Attr


TRACKING_TABLE = os.environ.get("TOKEN_TRACKING_TABLE", "token-tracking")
UNUSED_TOKEN_THRESHOLD_MINUTES = int(os.environ.get("UNUSED_TOKEN_THRESHOLD_MINUTES", "15"))
UNUSED_TOKEN_ALERT_TOPIC_ARN = os.environ.get("UNUSED_TOKEN_ALERT_TOPIC_ARN", "")
TRANSLATION_BUCKET = os.environ.get("TRANSLATION_BUCKET", "")
BEDROCK_MODEL_ID = os.environ.get("BEDROCK_MODEL_ID", "")
SOAR_PROMPT_PARAM_NAME = os.environ.get("SOAR_PROMPT_PARAM_NAME", "/bedrock/soar-prompt")
SOAR_MAX_OUTPUT_TOKENS = int(os.environ.get("SOAR_MAX_OUTPUT_TOKENS", "300"))
SOAR_TEMPERATURE = float(os.environ.get("SOAR_TEMPERATURE", "0.3"))
SOAR_MAX_FINDINGS_IN_PROMPT = int(os.environ.get("SOAR_MAX_FINDINGS_IN_PROMPT", "5"))
SOAR_TARGET_WORDS = int(os.environ.get("SOAR_TARGET_WORDS", "0"))
SOAR_MAX_BULLETS_PER_SECTION = int(os.environ.get("SOAR_MAX_BULLETS_PER_SECTION", "0"))
SOAR_RISK_FOCUS = os.environ.get("SOAR_RISK_FOCUS", "all").strip().lower()
SOAR_GENERATE_ON_EMPTY = os.environ.get("SOAR_GENERATE_ON_EMPTY", "true").strip().lower() in {    # Always Generate SOAR report even if there are no findings, to provide analysis of the event and reasoning for why there are no findings.
    "1",
    "true",
    "yes",
    "on",
}

dynamodb = boto3.resource("dynamodb")
tracking = dynamodb.Table(TRACKING_TABLE)
sns = boto3.client("sns")
s3 = boto3.client("s3")
bedrock = boto3.client("bedrock-runtime")
ssm = boto3.client("ssm")


def _parse_iso(value: str) -> datetime:
    parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    if parsed.tzinfo is None:
        return parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def _slugify(value: str) -> str:
    value = re.sub(r"[^A-Za-z0-9_-]+", "-", value)
    return value.strip("-").lower() or "unused-token"


def _format_title_timestamp(epoch_seconds: int) -> str:
    return time.strftime("%Y-%m-%d_%H-%M-%S_UTC", time.gmtime(epoch_seconds))


def _normalize_trigger_source(event: dict) -> str:
    source = event.get("source") or event.get("trigger_source")
    if source == "aws.scheduler" or source == "eventbridge-scheduler":
        return "eventbridge-scheduler"
    if event.get("manual") or event.get("force_soar"):
        return "manual"
    return "unused-token-detector"


def _manual_soar_requested(event: dict) -> bool:
    return bool(event.get("manual") or event.get("force_soar"))


def _should_generate_soar(findings: list, event: dict) -> bool:
    return bool(findings) or _manual_soar_requested(event) or SOAR_GENERATE_ON_EMPTY


def _load_soar_prompt_template() -> Tuple[str, str]:
    try:
        result = ssm.get_parameter(Name=SOAR_PROMPT_PARAM_NAME, WithDecryption=True)
        template = result.get("Parameter", {}).get("Value", "").strip()
        if template:
            return template, "ssm"
    except Exception:
        pass

    # Fallback template if the SSM parameter is unavailable.
    return (
        "You are a senior SOC analyst and incident response engineer.\n\n"
        "Analyze this security event:\n"
        "- User authenticated successfully\n"
        "- JWT token issued\n"
        "- Token never used within 15 minutes\n\n"
        "Provide your analysis in the following structure:\n\n"
        "1. Severity assessment with justification.\n"
        "2. Possible explanations ranked by likelihood.\n"
        "3. Recommended analyst actions.\n"
        "4. Short executive summary.\n"
        "5. Recommended remediation explanations.\n"
        "6. Possible code snippets and walkthroughs for remediation."
    ), "fallback"


def _build_bedrock_prompt_text(template: str, context_payload: dict) -> str:
    context_text = json.dumps(context_payload, indent=2, default=str)
    guidance_lines = [
        "- Provide a deep, evidence-based security analysis.",
        "- Expand on attack paths, blast radius, detection gaps, and risk trade-offs.",
        "- Include practical remediation guidance with implementation detail where helpful.",
        "- Include code examples or pseudo-code when they materially improve remediation clarity.",
        "- Use concise executive language for summary sections and technical depth in detailed sections.",
        "- Complete all six requested sections. Do not stop inside a sentence, list, or code block.",
        "- Use only the supplied implementation facts. Do not invent SQL tables, SIEM indexes, health endpoints, or local log paths.",
        "- Treat zero matched records as zero filter matches, not proof that DynamoDB or the detector failed.",
    ]

    if SOAR_TARGET_WORDS > 0:
        guidance_lines.append(f"- Target report length: about {SOAR_TARGET_WORDS} words.")
    if SOAR_MAX_BULLETS_PER_SECTION > 0:
        guidance_lines.append(
            f"- Use at most {SOAR_MAX_BULLETS_PER_SECTION} bullets per section when using bullet lists."
        )
    if SOAR_RISK_FOCUS in {"high", "high-only", "high_critical", "high-and-critical"}:
        guidance_lines.append(
            "- Focus on High and Critical risk issues first. Include lower-risk issues only if they materially change risk interpretation."
        )

    return "\n\n".join(
        [
            template.strip(),
            "Writing guidance:",
            *guidance_lines,
            "Security event context (JSON):",
            context_text,
        ]
    )


def _bedrock_generate_summary(prompt_text: str) -> Tuple[str, str]:
    if not BEDROCK_MODEL_ID:
        return "Bedrock not configured.", "not_configured"

    if "anthropic." in BEDROCK_MODEL_ID:
        payload = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": SOAR_MAX_OUTPUT_TOKENS,
            "temperature": SOAR_TEMPERATURE,
            "messages": [
                {"role": "user", "content": [{"type": "text", "text": prompt_text}]}
            ],
        }
    else:
        payload = {"inputText": prompt_text}

    try:
        response = bedrock.invoke_model(
            modelId=BEDROCK_MODEL_ID,
            contentType="application/json",
            accept="application/json",
            body=json.dumps(payload),
        )
        body = response.get("body")
        if not body:
            return "Bedrock response body missing.", "missing_body"
        data = json.loads(body.read().decode("utf-8"))
        if isinstance(data, dict) and data.get("content"):
            return data["content"][0].get("text", ""), data.get("stop_reason", "unknown")
        if isinstance(data, dict) and data.get("outputs"):
            return data["outputs"][0].get("text", ""), data.get("stop_reason", "unknown")
        if isinstance(data, dict) and data.get("results"):
            return data["results"][0].get("outputText", ""), data.get("stop_reason", "unknown")
        return json.dumps(data), data.get("stop_reason", "unknown")
    except Exception as exc:
        return f"Bedrock invocation failed: {exc}", "error"


def _ensure_complete_analysis(summary: str, stop_reason: str) -> Tuple[str, list[str]]:
    required_sections = {
        "4. Short Executive Summary": (
            "No stale active-unused tracking records matched this detector run. "
            "This result is not evidence that a Cognito JWT was issued and left unused, "
            "unless the record was explicitly registered from the Cognito bootstrap flow. "
            "Cognito clients outside that flow are not automatically linked to tracking."
        ),
        "5. Recommended Remediation Explanations": (
            "- Keep the DynamoDB attribute name consistently lowercase as `status`.\n"
            "- Track actual Cognito session identifiers through an explicit registration and usage-update flow.\n"
            "- Report DynamoDB `ScannedCount` separately from matching record count.\n"
            "- Generate incident reports only from evidence supplied to the model."
        ),
        "6. Possible Code Snippets and Walkthroughs for Remediation": (
            "```python\n"
            "response = tracking.scan(**scan_kwargs)\n"
            "records_examined += response.get(\"ScannedCount\", 0)\n"
            "matching_records += response.get(\"Count\", 0)\n"
            "```\n\n"
            "Register a stable Cognito session identifier at issuance, then update that same "
            "record when an authorized API request succeeds."
        ),
    }

    completed = summary.rstrip()
    repairs = []
    if completed.count("```") % 2:
        completed += "\n```"
        repairs.append("closed_unterminated_code_fence")

    force_recovery = stop_reason in {"max_tokens", "length"}
    if force_recovery:
        completed += (
            "\n\n> Model output reached its configured limit. "
            "The following deterministic recovery sections complete the report."
        )
        repairs.append("recovered_after_output_limit")

    for heading, fallback_text in required_sections.items():
        if force_recovery or heading.lower() not in completed.lower():
            completed += f"\n\n## {heading}\n\n{fallback_text}"
            repairs.append(f"added_{heading.split('.', 1)[0]}")

    return completed, repairs


def _build_soar_markdown(report: dict, findings: list[dict], summary: str) -> str:
    finding_lines = [
        f"- {item['token_id']} | user={item['username']} | kind={item['token_kind']} | age_minutes={item['age_minutes']} | issued_at={item['issued_at_iso']}"
        for item in findings[:25]
    ]
    if not finding_lines:
        finding_lines = ["- No stale unused tokens matched the threshold during this run."]

    return "\n".join(
        [
            f"# SOAR Report - {report['incident_id']} - {report['generated_title_timestamp']}",
            "",
            f"- Trigger: {report['trigger_source']}",
            f"- Generated: {report['generated_at']}",
            f"- Threshold Minutes: {report['threshold_minutes']}",
            f"- DynamoDB Records Examined: {report['records_examined']}",
            f"- Active-Unused Records Matched: {report['matched']}",
            f"- Alerts Published: {report['alerted']}",
            f"- Reason: {report['reason']}",
            f"- Prompt Source: {report.get('soar_prompt_source', 'unknown')}",
            f"- Prompt Parameter: {report.get('soar_prompt_param_name', 'unknown')}",
            f"- Bedrock Model: {report.get('bedrock_model_id', 'unknown')}",
            "",
            "## Stale Tokens",
            *finding_lines,
            "",
            "## SOAR Analysis",
            summary,
            "",
        ]
    )


def _upload_soar_artifacts(report: dict, markdown: str) -> Tuple[Optional[str], Optional[str]]:
    if not TRANSLATION_BUCKET:
        return None, None

    soar_key = f"soar/soar-{report['incident_id']}.md"
    evidence_key = f"soar/soar-{report['incident_id']}.json"
    s3.put_object(
        Bucket=TRANSLATION_BUCKET,
        Key=soar_key,
        Body=markdown,
        ContentType="text/markdown",
        Metadata={
            "incident-id": report["incident_id"],
            "report-type": "soar",
            "source-language": "en",
            "trigger-source": report["trigger_source"],
        },
    )
    s3.put_object(
        Bucket=TRANSLATION_BUCKET,
        Key=evidence_key,
        Body=json.dumps(report, indent=2, default=str),
        ContentType="application/json",
        Metadata={
            "incident-id": report["incident_id"],
            "report-type": "soar-evidence",
            "source-language": "en",
            "trigger-source": report["trigger_source"],
        },
    )
    return soar_key, evidence_key


def _publish_unused_token_alert(item: dict, age_minutes: int) -> None:
    if not UNUSED_TOKEN_ALERT_TOPIC_ARN:
        return

    message = {
        "event": "unused_token_detected",
        "token_id": item.get("token_id"),
        "username": item.get("username", "unknown-user"),
        "issued_at_iso": item.get("issued_at_iso"),
        "status": item.get("status", "active"),
        "used": item.get("used", False),
        "age_minutes": age_minutes,
        "threshold_minutes": UNUSED_TOKEN_THRESHOLD_MINUTES,
    }

    sns.publish(
        TopicArn=UNUSED_TOKEN_ALERT_TOPIC_ARN,
        Subject="Unused Token Alert",
        Message=json.dumps(message),
    )


def lambda_handler(event, context):
    event = event if isinstance(event, dict) else {}
    now = datetime.now(timezone.utc)
    epoch_now = int(now.timestamp())
    threshold = now - timedelta(minutes=UNUSED_TOKEN_THRESHOLD_MINUTES)
    scan_kwargs = {
        # Accept legacy records written with uppercase Status while they age out.
        "FilterExpression": Attr("used").eq(False)
        & (Attr("status").eq("active") | Attr("Status").eq("active")),
    }
    findings = []

    records_examined = 0
    matched = 0
    alerted = 0

    while True:
        response = tracking.scan(**scan_kwargs)
        items = response.get("Items", [])
        records_examined += response.get("ScannedCount", 0)
        matched += response.get("Count", len(items))

        for item in items:
            issued_raw = item.get("issued_at_iso")
            if not issued_raw:
                continue

            issued_at = _parse_iso(issued_raw)
            if issued_at > threshold:
                continue

            age_minutes = int((now - issued_at).total_seconds() // 60)
            findings.append(
                {
                    "token_id": item.get("token_id", "unknown-token"),
                    "username": item.get("username", "unknown-user"),
                    "issued_at_iso": issued_raw,
                    "status": item.get("status", "active"),
                    "used": item.get("used", False),
                    "token_kind": item.get("token_kind", "legacy-or-unknown"),
                    "age_minutes": age_minutes,
                }
            )
            _publish_unused_token_alert(item, age_minutes)
            alerted += 1

        last_key = response.get("LastEvaluatedKey")
        if not last_key:
            break
        scan_kwargs["ExclusiveStartKey"] = last_key

    trigger_source = _normalize_trigger_source(event)
    reason = event.get("reason") or event.get("MessageBody") or "Unused token threshold scan"
    incident_id = _slugify(f"unused-token-{trigger_source}-{epoch_now}")
    soar_key = None
    evidence_key = None

    if _should_generate_soar(findings, event):
        report = {
            "generated_at": now.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "generated_title_timestamp": _format_title_timestamp(epoch_now),
            "incident_id": incident_id,
            "trigger_source": trigger_source,
            "threshold_minutes": UNUSED_TOKEN_THRESHOLD_MINUTES,
            "records_examined": records_examined,
            "matched": matched,
            "alerted": alerted,
            "reason": reason,
            "findings": findings,
        }
        sampled_findings = [
            {
                "token_id": item.get("token_id", "unknown-token"),
                "username": item.get("username", "unknown-user"),
                "issued_at_iso": item.get("issued_at_iso"),
                "age_minutes": item.get("age_minutes", 0),
                "token_kind": item.get("token_kind", "legacy-or-unknown"),
            }
            for item in findings[:SOAR_MAX_FINDINGS_IN_PROMPT]
        ]
        prompt_context = {
            "detector": "unused_token_detector",
            "trigger_source": trigger_source,
            "reason": reason,
            "threshold_minutes": UNUSED_TOKEN_THRESHOLD_MINUTES,
            "records_examined": records_examined,
            "matched": matched,
            "alerted": alerted,
            "findings_total": len(findings),
            "findings_sample": sampled_findings,
            "implementation_facts": {
                "token_store": "Amazon DynamoDB table token-tracking",
                "detector_logs": "CloudWatch Logs group /aws/lambda/unused_token_detector_function",
                "tracking_record_kinds": "Synthetic markers plus explicitly registered Cognito ID tokens from mfa_bootstrap.py --track-token",
                "cognito_jwt_linkage": "The bootstrap/test flow links Cognito jti to usage when --track-token is used; other Cognito clients are not automatically registered",
                "status_migration": "Detector accepts lowercase status and legacy uppercase Status",
            },
        }
        prompt_template, prompt_source = _load_soar_prompt_template()
        prompt_text = _build_bedrock_prompt_text(prompt_template, prompt_context)
        bedrock_summary, bedrock_stop_reason = _bedrock_generate_summary(prompt_text)
        bedrock_summary, completion_repairs = _ensure_complete_analysis(
            bedrock_summary, bedrock_stop_reason
        )
        report["bedrock_summary"] = bedrock_summary
        report["soar_prompt_param_name"] = SOAR_PROMPT_PARAM_NAME
        report["soar_prompt_source"] = prompt_source
        report["bedrock_model_id"] = BEDROCK_MODEL_ID
        report["bedrock_stop_reason"] = bedrock_stop_reason
        report["completion_repairs"] = completion_repairs
        soar_markdown = _build_soar_markdown(report, findings, bedrock_summary)
        soar_key, evidence_key = _upload_soar_artifacts(report, soar_markdown)

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "message": "Unused token scan completed",
                "trigger_source": trigger_source,
                "records_examined": records_examined,
                "matched": matched,
                "alerted": alerted,
                "soar_generated": bool(soar_key),
                "soar_key": soar_key,
                "soar_evidence_key": evidence_key,
                "threshold_minutes": UNUSED_TOKEN_THRESHOLD_MINUTES,
            }
        ),
    }
