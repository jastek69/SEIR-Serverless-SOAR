const {
  CloudWatchLogsClient,
  StartQueryCommand,
  GetQueryResultsCommand,
} = require("@aws-sdk/client-cloudwatch-logs");

const {
  SSMClient,
  GetParameterCommand,
  StartAutomationExecutionCommand,
} = require("@aws-sdk/client-ssm");
// Reserved for a future database-backed configuration.
// const {
//   SecretsManagerClient,
//   GetSecretValueCommand,
// } = require("@aws-sdk/client-secrets-manager");
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");

const {
  BedrockRuntimeClient,
  InvokeModelCommand,
} = require("@aws-sdk/client-bedrock-runtime");

const logsClient = new CloudWatchLogsClient({});
const ssmClient = new SSMClient({});
// const secretsClient = new SecretsManagerClient({});
const s3Client = new S3Client({});
const bedrockClient = new BedrockRuntimeClient({});

function buildBedrockRequest(modelId, prompt) {
  if (modelId.startsWith("anthropic.")) {
    return {
      anthropic_version: "bedrock-2023-05-31",
      max_tokens: 800,
      temperature: 0.4,
      messages: [
        {
          role: "user",
          content: [{ type: "text", text: prompt }],
        },
      ],
    };
  }

  if (modelId.startsWith("mistral.")) {
    return {
      prompt,
      max_tokens: 800,
      temperature: 0.4,
    };
  }

  return {
    inputText: prompt,
  };
}

function parseBedrockResponse(rawBody) {
  if (!rawBody) {
    return "";
  }

  const decoded = Buffer.from(rawBody).toString("utf8");

  try {
    const parsed = JSON.parse(decoded);

    if (Array.isArray(parsed.content)) {
      return parsed.content
        .filter((item) => item?.type === "text" && item.text)
        .map((item) => item.text)
        .join("\n")
        .trim();
    }

    if (Array.isArray(parsed.outputs) && parsed.outputs[0]?.text) {
      return parsed.outputs[0].text;
    }

    if (Array.isArray(parsed.results) && parsed.results[0]?.outputText) {
      return parsed.results[0].outputText;
    }

    if (typeof parsed.completion === "string") {
      return parsed.completion;
    }
  } catch (_error) {
    return decoded;
  }

  return decoded;
}

function formatTitleTimestamp(date) {
  const iso = date.toISOString().replace(/\.\d{3}Z$/, "Z");
  return iso.replace("T", "_").replace(/:/g, "-").replace("Z", "_UTC");
}

async function runLogsInsightsQuery(logGroupName, queryString, startTime, endTime) {
  const start = await logsClient.send(
    new StartQueryCommand({
      logGroupName,
      startTime,
      endTime,
      queryString,
      limit: 100,
    })
  );
  const queryId = start.queryId;
  if (!queryId) {
    throw new Error("StartQuery did not return a queryId");
  }
  for (let i = 0; i < 20; i += 1) {
    const res = await logsClient.send(new GetQueryResultsCommand({ queryId }));
    if (res.status === "Complete") {
      return res.results || [];
    }
    await new Promise((r) => setTimeout(r, 1500));
  }
  return [];
}

exports.handler = async (event) => {
  console.log("CloudWatch alarm event:", JSON.stringify(event, null, 2));

  const now = Math.floor(Date.now() / 1000);
  const startTime = now - 3600;
  const endTime = now;

  const logGroupName = process.env.LOG_GROUP_NAME || process.env.APP_LOG_GROUP;
  const logsInsightsQuery = process.env.LOGS_INSIGHTS_QUERY;
  const ssmParamName = process.env.SSM_PARAM_NAME;
  // const secretId = process.env.SECRET_ID; // Reserved for a future database-backed configuration.
  const reportBucket = process.env.REPORTS_BUCKET || process.env.REPORT_BUCKET;
  const bedrockModelId = process.env.BEDROCK_MODEL_ID;
  const automationDocumentName = process.env.AUTOMATION_DOCUMENT_NAME || process.env.AUTOMATION_DOC_NAME;
  const automationParametersJson = process.env.AUTOMATION_PARAMETERS_JSON;
  const alarmAsgName = process.env.ALARM_ASG_NAME;

  const logsResults = logGroupName && logsInsightsQuery
    ? await runLogsInsightsQuery(logGroupName, logsInsightsQuery, startTime, endTime)
    : [];

  const ssmParam = ssmParamName
    ? await ssmClient.send(new GetParameterCommand({ Name: ssmParamName, WithDecryption: true }))
    : null;

  // const secretValue = secretId
  //   ? await secretsClient.send(new GetSecretValueCommand({ SecretId: secretId }))
  //   : null;

  const alarm = event?.Records?.[0]?.Sns?.Message
    ? JSON.parse(event.Records[0].Sns.Message)
    : event;

  const prompt = [
    "Generate a short incident report summary for this CloudWatch alarm event.",
    "Include: alarm name/state, likely impact, and immediate checks.",
    "Alarm:",
    JSON.stringify(alarm, null, 2),
    "Logs Insights Results:",
    JSON.stringify(logsResults, null, 2),
  ].join("\n\n");

  let bedrockResponseText = "Bedrock response not requested or model not configured.";
  if (bedrockModelId) {
    const br = await bedrockClient.send(
      new InvokeModelCommand({
        modelId: bedrockModelId,
        contentType: "application/json",
        accept: "application/json",
        body: JSON.stringify(buildBedrockRequest(bedrockModelId, prompt)),
      })
    );
    bedrockResponseText = parseBedrockResponse(br.body);
  }

  const report = {
    generatedAt: new Date().toISOString(),
    generatedTitleTimestamp: formatTitleTimestamp(new Date()),
    alarm,
    logsResults,
    ssmParam,
    bedrockSummary: bedrockResponseText,
  };

  const reportKey = `reports/alarm-${Date.now()}.json`;
  const markdownKey = `reports/alarm-${Date.now()}.md`;

  if (reportBucket) {
    await s3Client.send(
      new PutObjectCommand({
        Bucket: reportBucket,
        Key: reportKey,
        Body: JSON.stringify(report, null, 2),
        ContentType: "application/json",
      })
    );

    await s3Client.send(
      new PutObjectCommand({
        Bucket: reportBucket,
        Key: markdownKey,
        Body: [
          `# Alarm Report - ${report.generatedTitleTimestamp}`,
          `- Generated: ${report.generatedAt}`,
          `- Alarm: ${alarm?.AlarmName || "unknown"}`,
          "",
          "## Summary",
          "```\n" + bedrockResponseText + "\n```",
        ].join("\n"),
        ContentType: "text/markdown",
      })
    );
  }

  if (automationDocumentName) {
    let parameters = {};
    if (automationParametersJson) {
      parameters = JSON.parse(automationParametersJson);
    } else {
      parameters = {
        IncidentId: [String(Date.now())],
        AlarmName: [alarm?.AlarmName || "unknown"],
        ReportBucket: [reportBucket || ""],
        ReportJsonKey: [reportKey],
        ReportMarkdownKey: [markdownKey],
      };
      if (alarmAsgName) {
        parameters.AsgName = [alarmAsgName];
      }
    }
    await ssmClient.send(
      new StartAutomationExecutionCommand({
        DocumentName: automationDocumentName,
        Parameters: parameters,
      })
    );
  }

  return { ok: true, reportKey, markdownKey };
};