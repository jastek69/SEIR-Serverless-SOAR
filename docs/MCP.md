# MCP.md — MCP Server Setup, Auth, and Operations

# [MCP Reference README](https://github.com/modelcontextprotocol/python-sdk)
## Documentation

**The documentation lives at <https://py.sdk.modelcontextprotocol.io/v2/>.**

It has a [Get started guide](https://py.sdk.modelcontextprotocol.io/v2/get-started/), [What's new in v2](https://py.sdk.modelcontextprotocol.io/v2/whats-new/), the [API reference](https://py.sdk.modelcontextprotocol.io/v2/api/mcp/), and the [migration guide](https://py.sdk.modelcontextprotocol.io/v2/migration/).

## What is MCP?

The [Model Context Protocol](https://modelcontextprotocol.io) lets you build servers that expose data and functionality to LLM applications in a secure, standardized way. Think of it like a web API, but designed for LLM interactions. With this SDK you can:

- **Build MCP servers** that expose tools, resources, and prompts to any MCP host
- **Build MCP clients** that connect to any MCP server
- Speak every standard transport: stdio, Streamable HTTP, and SSE

## Requirements

Python 3.10+.

## Installation

```bash
uv add "mcp[cli]==2.0.0b1"          # or: pip install "mcp[cli]==2.0.0b1"
```

The pin matters while v2 is in pre-release: an unpinned install resolves to the latest stable v1.x, which this README does not describe. Check [PyPI](https://pypi.org/project/mcp/#history) for the newest pre-release, and use `uv run --with "mcp==2.0.0b1"` for one-off commands.

## A server in 15 lines

Create a `server.py`:

<!-- snippet-source docs_src/index/tutorial001.py -->
```python
from mcp.server import MCPServer

mcp = MCPServer("Demo")


@mcp.tool()
def add(a: int, b: int) -> int:
    """Add two numbers."""
    return a + b


@mcp.resource("greeting://{name}")
def greeting(name: str) -> str:
    """Greet someone by name."""
    return f"Hello, {name}!"
```

_Full example: [docs_src/index/tutorial001.py](https://github.com/modelcontextprotocol/python-sdk/blob/main/docs_src/index/tutorial001.py)_
<!-- /snippet-source -->

That's a complete MCP server: one tool, one templated resource. Open it in the [MCP Inspector](https://github.com/modelcontextprotocol/inspector):

```bash
uv run mcp dev server.py
```

Call `add` with `a=1`, `b=2` and you get `3` back.

Notice what you did **not** write: no JSON Schema (`a: int, b: int` _is_ the schema), no request parsing, no validation code, no protocol handling. Two type-hinted Python functions and a docstring.

[Get started](https://py.sdk.modelcontextprotocol.io/v2/get-started/) takes it from here.

## A client in 10 lines

The same package is a full MCP **client**. `Client` connects to a URL, a stdio subprocess, a custom transport, or (for tests) straight to a server object in memory with no transport at all:

```python
import asyncio

from mcp import Client

from server import mcp


async def main() -> None:
    async with Client(mcp) as client:
        result = await client.call_tool("add", {"a": 1, "b": 2})
        print(result.structured_content)  # {'result': 3}


asyncio.run(main())
```

Swap `mcp` for `"http://localhost:8000/mcp"` and the exact same code talks to a remote server.

## Contributing

We are passionate about supporting contributors of all levels of experience and would love to see you get involved in the project. See the [contributing guide](https://github.com/modelcontextprotocol/python-sdk/blob/main/CONTRIBUTING.md) to get started.

## License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/modelcontextprotocol/python-sdk/blob/main/LICENSE) file for details.

[pypi-badge]: https://img.shields.io/pypi/v/mcp.svg
[pypi-url]: https://pypi.org/project/mcp/
[mit-badge]: https://img.shields.io/pypi/l/mcp.svg
[mit-url]: https://github.com/modelcontextprotocol/python-sdk/blob/main/LICENSE
[python-badge]: https://img.shields.io/pypi/pyversions/mcp.svg
[python-url]: https://www.python.org/downloads/
[docs-badge]: https://img.shields.io/badge/docs-python--sdk-blue.svg
[docs-url]: https://py.sdk.modelcontextprotocol.io/v2/
[protocol-badge]: https://img.shields.io/badge/protocol-modelcontextprotocol.io-blue.svg
[protocol-url]: https://modelcontextprotocol.io
[spec-badge]: https://img.shields.io/badge/spec-spec.modelcontextprotocol.io-blue.svg
[spec-url]: https://modelcontextprotocol.io/specification/latest



---

# MCP PROJECT DETAILS

Reference for this project's Model Context Protocol (MCP) integration. Two
servers share the auth/deployment patterns documented here:

1. **`soar-agents`** (implemented, local stdio prototype — section 0): a
   FastMCP control plane over the Phase 12 SOAR agents. Runs locally with
   your AWS credentials today; promotes to the Lambda + API Gateway + Cognito
   deployment described in sections 1–7 once multi-user access is needed.
2. **`ml-tools`** (design, not yet built — sections 1, 3, 4): a PyTorch
   inference server on a container-image Lambda. `mcp.tf.txt` at the repo
   root holds its unwired gateway/authorizer Terraform.


## 0. `soar-agents` — local stdio prototype (current)

**File:** `mcp-server/mcp_server.py` · **Registration:** `.mcp.json` (project
scope, committed — no secrets) or manually:

```bash
pip install -r mcp-server/requirements.txt   # mcp SDK (v1.x) + boto3, into the
                                             # python that .mcp.json launches
claude mcp add soar-agents -- python mcp-server/mcp_server.py
```

Design rule: the MCP server is a **control plane beside the pipeline, never a
step inside it**. The EventBridge-driven flow (correlation agent → SOAR
response agent) runs autonomously regardless of this server. Reads hit
DynamoDB/S3 directly (read-only); actions delegate to the deployed agent
Lambdas via `lambda:InvokeFunction` so business logic lives only in the agents.

| Tool | Kind | What it does |
|---|---|---|
| `list_findings(severity?, status?, limit?)` | read | Compact scan of `waf-correlation-findings`, newest first |
| `get_finding(finding_id, include_evidence?)` | read | Full finding; large `evidence` blob omitted by default |
| `list_incidents(severity?, status?, limit?)` | read | Compact scan of `security-incidents`, newest first |
| `get_incident(incident_id)` | read | Full incident incl. analyst summary (`INC-<finding_id>`) |
| `get_executive_report(report_format?)` | read | Presigned URL (1 h) for the newest PDF/JSON report in S3 |
| `run_correlation(window_minutes?)` | action | Invokes `waf-threat-correlation-agent` synchronously |
| `rerun_soar_response(finding_id)` | action | Re-drives `soar-response-agent` for one finding (idempotent) |
| `generate_executive_report(report_period_hours?)` | action | Invokes `executive-dashboard-agent` (~2 min) |

Configuration is env-var overridable, defaults match the Terraform resource
names: `CORRELATION_FINDINGS_TABLE`, `SECURITY_INCIDENTS_TABLE`,
`CORRELATION_AGENT_FUNCTION`, `SOAR_RESPONSE_FUNCTION`,
`EXECUTIVE_DASHBOARD_FUNCTION`, `REPORT_BUCKET` (else derived as
`taaops-lambda-waf-executive-reports-<account>`), `REPORT_PREFIX`,
`AWS_REGION` (default `us-west-2`).

Implementation notes:

- The server strips a broken `AWS_CA_BUNDLE` env var at startup if it points
  at a nonexistent path (this shell's WSL UNC problem — see CLAUDE.md).
- The directory is named `mcp-server/` (hyphenated, unimportable) on purpose:
  a directory literally named `mcp/` at the repo root would shadow the `mcp`
  SDK package as a namespace package when Python runs from the repo root.
- Action tools are safe to retry: the SOAR agent skips completed findings and
  incident creation is a conditional put on the deterministic incident ID.
- Windows: the `mcp` SDK requires `pywin32`; install into a real venv or the
  system python (`pip --target` installs break `pywintypes`).

Promotion path: keep the tool functions as-is, serve
`mcp.streamable_http_app()` behind the JWT-authorized gateway (sections 1,
3–5), and add the planned `approve_containment(incident_id)` admin tool —
Layer 2 gated on `cognito:groups` — as the human-approval step the Phase 12
architecture defers. Gotcha when wiring `mcp.tf.txt`: the JWT authorizer's
`audience` list must include the M2M app client ID too, or
`client_credentials` tokens will 401 at the gateway.

---

## 1. Architecture

```
Claude Code (client)
   │  claude mcp add --transport http ml-tools <API_GW_URL>/mcp
   │  Authorization: Bearer <Cognito access token>
   ▼
API Gateway (HTTP API, JWT authorizer)      ← Layer 1 RBAC: OAuth scope check
   │  forwards validated JWT claims in request context
   ▼
Lambda (container image, Lambda Web Adapter)
   │  claims arrive via `x-amzn-request-context` header
   ▼
FastMCP server (server.py)                  ← Layer 2 RBAC: cognito:groups / scope
   ├─ tools:   classify (PyTorch), reload_model (admin), health
   ├─ prompts: classify_review (from SSM Parameter Store)
   └─ model:   TorchScript artifact baked into image at model/classifier.pt
```

Two-layer RBAC (mirrors cognito.tf):
1. User/machine authenticates with Cognito; token carries scopes
   (`rbac-api/user`, `rbac-api/admin`).
2. API Gateway JWT authorizer validates the token and enforces
   `authorization_scopes = ["rbac-api/user"]` on the `/mcp` route.
3. Lambda reads validated claims from the `x-amzn-request-context` header and
   enforces per-tool rules (`cognito:groups` for humans, `scope` for M2M).

SECURITY INVARIANT: the Lambda must only be reachable through API Gateway.
No public Function URL (or set it to AWS_IAM). The claims header is only
trustworthy because the gateway is the sole ingress.

---

## 2. Claude Code MCP commands (cheat sheet)

| Command | Purpose |
|---|---|
| `claude mcp add --transport http <name> <url>` | Register remote HTTP server |
| `claude mcp add <name> -- <cmd> [args]` | Register local stdio server |
| `... --header "Authorization: Bearer <token>"` | Static bearer auth |
| `... --env KEY=value` | Env vars for stdio servers |
| `... --scope local\|project\|user` | Where the config is stored |
| `claude mcp list` | Show all servers + connection status |
| `claude mcp get <name>` | Show a server's config and scope |
| `claude mcp remove <name>` | Delete a server entry |
| `claude mcp reset-project-choices` | Reset .mcp.json approval decisions |
| `/mcp` (in session) | Status panel, reconnect, OAuth sign-in |

Scopes:

| Scope | File | Visibility |
|---|---|---|
| `local` (default) | `~/.claude.json` (per-project section) | You, this project only. Use for entries containing tokens. |
| `project` | `.mcp.json` at repo root (committed) | Whole team. Never commit tokens here. |
| `user` | `~/.claude.json` (global) | You, all projects |

Useful env vars: `MCP_TIMEOUT=60000 claude` (startup timeout ms — raise for
Lambda cold starts), `CLAUDE_CONFIG_DIR` (relocate `.claude.json`).

Project config (`.mcp.json`, committed — no secrets):

```json
{
  "mcpServers": {
    "ml-tools": {
      "type": "http",
      "url": "https://<api_id>.execute-api.us-west-2.amazonaws.com/mcp"
    }
  }
}
```

Tokens are attached at local scope by the wrapper script (section 6), never
committed.

---

## 3. Server implementation notes (server.py)

- SDK: official MCP Python SDK, **pin v1.x** (`mcp>=1.27,<2`). v2 is a
  pre-release with breaking changes between pre-releases; do not deploy it.
- `FastMCP("ml-tools", stateless_http=True, json_response=True)`
  - `stateless_http=True`: new transport per request. Required on Lambda —
    no sticky sessions between invocations.
  - `json_response=True`: plain JSON instead of SSE streaming; plays well
    with API Gateway proxy integration.
- `app = mcp.streamable_http_app()` returns an ASGI (Starlette) app served by
  uvicorn; the Lambda Web Adapter makes Lambda speak HTTP to it.
- MCP primitives used:
  - `@mcp.tool()` — type hints are the schema; docstring is the description.
  - `@mcp.prompt()` — exposed to Claude Code as a slash command; template text
    is fetched from SSM at call time.
  - (`@mcp.resource()` available for read-only data if needed later.)
- Auth claims: tools taking `ctx: Context` read
  `ctx.request_context.request.headers["x-amzn-request-context"]` →
  `authorizer.jwt.claims`. Do NOT re-verify the JWT in the Lambda; the
  gateway already did (see security invariant above).
- Layer 2 authorization branch:
  - Human token → check `cognito:groups` (e.g. `admin` for reload_model).
  - M2M token (client_credentials) → NO `cognito:groups` claim exists;
    authorize on the `scope` claim instead (e.g. require `rbac-api/admin`).
- SSM prompts: `get_parameter(WithDecryption=True)` + `lru_cache` = one SSM
  call per parameter per warm container. Trade-off: warm containers serve
  stale prompts until recycled. Use a TTL cache if prompts change often.
  IAM: `ssm:GetParameter`/`GetParametersByPath` on `/mcp/prompts/*`; add
  `kms:Decrypt` if using a customer-managed KMS key.

---

## 4. Packaging and deploy

- PyTorch exceeds Lambda's 250 MB zip limit → **container image** Lambda.
  Use the CPU-only torch wheel (`--index-url https://download.pytorch.org/whl/cpu`).
- Lambda Web Adapter is copied into the image
  (`/opt/extensions/lambda-adapter`); app listens on `$PORT` (8000).
- Lambda config: `memory_size = 2048`+ (more memory = more CPU for inference),
  `timeout = 60`, `AWS_LWA_INVOKE_MODE = response_stream`.
- Deploy order:
  1. `terraform apply -target=aws_ecr_repository.mcp`
  2. `docker build` / `tag` / `push` to ECR
  3. `terraform apply` (Lambda, API Gateway, authorizer, routes, SSM, IAM)
- Expect multi-second cold starts with a PyTorch image; raise `MCP_TIMEOUT`
  client-side if first connection flakes.

---

## 5. Auth flows

### Humans (interactive)
- Cognito user pool `rbac-user-pool`; MFA ON; groups `admin`, `user`;
  resource server `rbac-api` with scopes `admin`, `user`.
- Claude Code's built-in `/mcp` OAuth flow needs dynamic client registration,
  which Cognito does not support → use a bearer token header instead.
- Correct path for scoped tokens: hosted-UI authorization-code flow against
  the pool domain, exchange at `/oauth2/token`. Plain `USER_PASSWORD_AUTH`
  tokens will NOT carry `rbac-api/*` scopes and will be rejected by the
  gateway's scope check. MFA challenge applies
  (`respond-to-auth-challenge` if using the CLI flow).

### Machines (headless / CI)
- Separate app client `mcp-m2m-client`: `generate_secret = true`,
  `allowed_oauth_flows = ["client_credentials"]`, scopes limited to
  `rbac-api/user` (create a second admin client only if needed).
- No user involved → no MFA, no `cognito:groups`. Access tokens default 1h;
  this client raises `access_token_validity` (e.g. 8h).
- Client secret stored at SSM `/mcp/auth/m2m-client-secret` (SecureString);
  never in the repo or .mcp.json.
- Token mint: POST `https://<pool-domain>/oauth2/token` with HTTP Basic
  (client_id:secret), body `grant_type=client_credentials&scope=rbac-api/user`.

---

## 6. Token refresh wrapper (`scripts/mcp-claude`)

Behavior:
1. Read cached token at `~/.cache/mcp-ml-tools-token.json`; if within 5 min of
   expiry, fetch client secret from SSM and mint a new token from
   `/oauth2/token`; cache with `expires_at`, `chmod 600`.
2. `claude mcp remove ml-tools --scope local` (ignore errors), then
   `claude mcp add --transport http ml-tools <url> --header "Authorization: Bearer <token>"`.
3. `exec claude "$@"`.

Always launch sessions through this wrapper. If a session outlives the token,
`claude mcp list` shows the server failing auth — relaunch via the wrapper.
Requires: aws cli, jq, curl.

---

## 7. Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| `✗ Failed` in `claude mcp list` on first try | Lambda cold start; retry or raise `MCP_TIMEOUT` |
| 401 from gateway | Token expired, wrong audience (must be app client ID), or missing `rbac-api/user` scope (wrong auth flow) |
| 403 from a specific tool | Layer 2: missing `cognito:groups` entry (human) or `scope` (M2M) |
| Tool works locally, claims empty on Lambda | Hitting Lambda directly (Function URL) instead of via gateway — claims header only exists behind the gateway |
| Prompt edits in SSM not taking effect | lru_cache on a warm container; wait for recycle or add TTL |
| `import fastmcp` vs `from mcp.server.fastmcp import FastMCP` confusion | Two projects: standalone FastMCP vs SDK-bundled FastMCP. This repo uses the SDK-bundled one |

---
# GLOSSARY

## 8. Reading list

- MCP spec & concepts: https://modelcontextprotocol.io
- MCP Python SDK (pin v1.x): https://github.com/modelcontextprotocol/python-sdk · docs: https://py.sdk.modelcontextprotocol.io
- FastMCP (standalone) docs: https://gofastmcp.com (llms.txt available)
- Claude Code MCP quickstart: https://code.claude.com/docs/en/mcp-quickstart
- Claude Code MCP reference: https://code.claude.com/docs/en/mcp
- Lambda Web Adapter: https://github.com/awslabs/aws-lambda-web-adapter
- API GW JWT authorizers: https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-jwt-authorizer.html
- Cognito token endpoint / client_credentials: https://docs.aws.amazon.com/cognito/latest/developerguide/token-endpoint.html
- SSM Parameter Store: https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html


 MCP fundamentals (start here)

  - https://modelcontextprotocol.io — the spec site's Concepts pages (Architecture, Tools, Resources, Prompts, Transports) are the best short read on the mental model: client ↔
  server, what a tool actually is, stdio vs streamable HTTP. Read "Transports" before testing — it explains exactly what claude mcp add ... -- python ... is doing under the
  hood.
  - MCP Python SDK docs — https://github.com/modelcontextprotocol/python-sdk — the README's FastMCP examples map one-to-one onto mcp-server/mcp_server.py (decorators,
  type-hints-as-schema, mcp.run()). Reading it next to your own server is the fastest way to internalize the SDK.
  - Claude Code MCP docs — https://code.claude.com/docs/en/mcp — covers scopes (local/project/user), .mcp.json approval behavior, and the /mcp panel you'll use during testing.
  - MCP Inspector — npx @modelcontextprotocol/inspector python mcp-server/mcp_server.py — not reading material, but the single most useful learning tool: a browser UI that
  connects to your server, lists tools, and lets you invoke them with hand-typed arguments outside Claude Code. Great for isolating "is this a server bug or a client-config
  problem" while you test today.

  The auth story behind "Claude Connection"

  - MCP Authorization spec — the Authorization section under specification at modelcontextprotocol.io — explains the intended OAuth flow, including why the client expects
  dynamic client registration; makes the Cognito gap concrete.
  - RFC 7591 (Dynamic Client Registration) — skim the intro only; it's the thing Cognito lacks. RFC 7636 (PKCE) — likewise short, and explains why your no-secret app client
  requires the code flow to be PKCE'd.
  - Cognito: resource servers & custom scopes — the "Scopes, M2M, and API authorization with resource servers" page in the Cognito developer guide. This is the definitive
  answer to the sentence you quoted — which flows can mint rbac-api/user and which can't.
  - Cognito token endpoint & client_credentials — https://docs.aws.amazon.com/cognito/latest/developerguide/token-endpoint.html — the exact request you'd script for the M2M
  header path.
  - API Gateway HTTP API JWT authorizers — https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-jwt-authorizer.html — short; pay attention to the
  audience-matching rules (it's where the M2M-client-ID-in-audience gotcha comes from).

  Hosting MCP on AWS (for the promotion step)

  - awslabs/run-model-context-protocol-servers-with-aws-lambda (GitHub) — AWS's reference for exactly your target architecture; worth reading their transport/session handling
  before writing your own.
  - AWS Lambda Web Adapter — https://github.com/awslabs/aws-lambda-web-adapter — the piece that lets the FastMCP ASGI app run unchanged on Lambda; the README covers
  AWS_LWA_INVOKE_MODE and the $PORT contract from your MCP.md §4.
  - awslabs/mcp (GitHub) — AWS's own suite of MCP servers (CloudWatch, DynamoDB, Bedrock, etc.). Two uses: as prior art for tool design (naming, pagination, read-only defaults
  — compare with your list_findings), and because running their CloudWatch/DynamoDB servers alongside soar-agents could replace some manual aws CLI spelunking during incident
  drills.

  Agent/SOAR side (lighter priority)

  - Anthropic's "Building effective agents" essay (anthropic.com/engineering) — the deterministic-workflow-vs-agent distinction it draws is the design principle your Phase 12
  doc already follows (Bedrock explains, playbook selection stays deterministic); good vocabulary for defending that design.
  - Bedrock InvokeModel + inference profiles docs — relevant when a bedrock:InvokeModel IAM error shows up with the us.anthropic... cross-region profile IDs; the
  inference-profiles page explains why the resource ARNs span regions.
