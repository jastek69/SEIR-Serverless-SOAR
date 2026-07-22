const { DynamoDBClient, UpdateItemCommand } = require("@aws-sdk/client-dynamodb");

const TRACKING_TABLE = process.env.TOKEN_TRACKING_TABLE || "token-tracking";
const dynamodb = new DynamoDBClient({});

function utcIsoNow() {
    return new Date().toISOString();
}

// Return a copy of the event with bearer tokens redacted — safe to log.
// Never log the real event: API Gateway proxy events carry the caller's
// live Authorization header in both headers and multiValueHeaders, and
// Lambda's own console.log output is plaintext in CloudWatch for however
// long the log group retains it.
function redactEventForLogging(event) {
    const redacted = JSON.parse(JSON.stringify(event));

    for (const key of ["headers", "multiValueHeaders"]) {
        const headers = redacted[key];
        if (headers && typeof headers === "object") {
            for (const name of Object.keys(headers)) {
                if (name.toLowerCase() === "authorization") {
                    headers[name] = "[REDACTED]";
                }
            }
        }
    }

    return redacted;
}

async function markTokenUsed(claims, requestId) {
    const tokenIds = [];
    for (const key of ["jti", "origin_jti"]) {
        const value = claims?.[key];
        if (value && !tokenIds.includes(value)) {
            tokenIds.push(value);
        }
    }

    for (const tokenId of tokenIds) {
        try {
            await dynamodb.send(new UpdateItemCommand({
                TableName: TRACKING_TABLE,
                Key: {
                    token_id: { S: tokenId },
                },
                UpdateExpression: "SET #s = :s, used = :u, updated_at_iso = :t, last_used_request_id = :r",
                ConditionExpression: "attribute_exists(token_id)",
                ExpressionAttributeNames: {
                    "#s": "status",
                },
                ExpressionAttributeValues: {
                    ":s": { S: "used" },
                    ":u": { BOOL: true },
                    ":t": { S: utcIsoNow() },
                    ":r": { S: requestId || "unknown-request" },
                },
            }));
            return tokenId;
        } catch (error) {
            if (error.name !== "ConditionalCheckFailedException") {
                throw error;
            }
        }
    }

    return null;
}

exports.handler = async (event, context) => {
    console.log("Incoming event:", JSON.stringify(redactEventForLogging(event)));

    const name = event.queryStringParameters?.name || "Unknown";

    const response = {
        message: `HELLO ${name.toUpperCase()} FROM NODE!`,
    };

    const rawGroups = event.requestContext?.authorizer?.claims?.["cognito:groups"] || [];
    const groups = Array.isArray(rawGroups)
        ? rawGroups
        : (typeof rawGroups === "string" ? rawGroups.split(",").map(g => g.trim()).filter(Boolean) : []);
    if (groups.length > 0) {
        response.groups = groups;
    }

    const scopes = (event.requestContext?.authorizer?.claims?.scope || "").split(" ").filter(Boolean);
    const isAdmin = groups.includes("admin") || scopes.includes("rbac-api/admin");

    if (isAdmin) {
        response.admin = true;
    } else {
        return {
            statusCode: 403,
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ message: "Access denied: admin group required" }),
        };
    }

    const claims = event.requestContext?.authorizer?.claims || {};
    const matchedTokenId = await markTokenUsed(claims, context.awsRequestId);
    if (matchedTokenId) {
        response.token_tracking_id = matchedTokenId;
    }

    console.log("Response:", JSON.stringify(response));

    return {
        statusCode: 200,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(response),
    };
};