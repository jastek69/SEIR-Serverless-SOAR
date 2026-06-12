exports.handler = async (event) => {
    console.log("Incoming event:", JSON.stringify(event));

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

    if (groups.includes("admin")) {
        response.admin = true;
    } else {
        return {
            statusCode: 403,
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ message: "Access denied: admin group required" }),
        };
    }

    console.log("Response:", JSON.stringify(response));

    return {
        statusCode: 200,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(response),
    };
};